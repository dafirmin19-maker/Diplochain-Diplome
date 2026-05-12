// Écran d'Inscription DiploChain
// Création de compte diplômé avec validation complète
// Indicateur de force de mot de passe + confirmation

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'diploma_list_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _institutionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _acceptTerms = false;
  String _passwordValue = '';

  @override
  void initState() {
    super.initState();
    // Écoute le champ password pour l'indicateur de force
    _passwordController.addListener(() {
      setState(() => _passwordValue = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _institutionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Soumission ───────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptTerms) {
      _showSnackBar(
        'Veuillez accepter les conditions d\'utilisation.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      institution: _institutionController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _showSnackBar('Compte créé avec succès !');
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DiplomaListScreen()),
      );
    } else {
      _showSnackBar(result.errorMessage ?? 'Erreur inconnue', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                const AuthHeader(
                  title: 'Nouveau compte',
                  subtitle:
                      'Rejoignez DiploChain et accédez\nà vos certifications vérifiées',
                ),

                const SizedBox(height: 32),

                // ── Section : Informations personnelles ──────────────
                _SectionTitle(title: 'Informations personnelles'),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Nom complet *',
                  hint: 'Ex : Aminata Sawadogo',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline_rounded,
                  validator: AuthService.validateFullName,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 14),

                AppTextField(
                  label: 'Adresse email *',
                  hint: 'vous@exemple.com',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: AuthService.validateEmail,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 14),

                AppTextField(
                  label: 'Téléphone',
                  hint: '+226 70 00 00 00',
                  controller: _phoneController,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 14),

                AppTextField(
                  label: 'Établissement',
                  hint: 'Université / École',
                  controller: _institutionController,
                  prefixIcon: Icons.school_outlined,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 28),

                // ── Section : Sécurité ───────────────────────────────
                _SectionTitle(title: 'Sécurité du compte'),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Mot de passe *',
                  hint: 'Min. 8 caractères, 1 majuscule, 1 chiffre',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: AuthService.validatePassword,
                  textInputAction: TextInputAction.next,
                ),

                // Indicateur de force
                PasswordStrengthIndicator(password: _passwordValue),

                const SizedBox(height: 14),

                AppTextField(
                  label: 'Confirmer le mot de passe *',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_reset_outlined,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirmation requise.';
                    if (v != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas.';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                ),

                const SizedBox(height: 24),

                // ── Conditions d'utilisation ─────────────────────────
                InkWell(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (v) =>
                            setState(() => _acceptTerms = v ?? false),
                        activeColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: "J'accepte les "),
                                TextSpan(
                                  text: "Conditions d'utilisation",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: " et la "),
                                TextSpan(
                                  text: "Politique de confidentialité",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: " de DiploChain."),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Bouton Inscription
                PrimaryButton(
                  label: "Créer mon compte",
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                  icon: Icons.how_to_reg_rounded,
                ),

                const SizedBox(height: 20),

                // Retour connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte ?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Se connecter"),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widget section title ──────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}
