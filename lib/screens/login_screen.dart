// Écran de Connexion DiploChain
// Authentification sécurisée avec validation côté client
// Design : Vert & Blanc, accessible, WCAG AA

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'register_screen.dart';
import 'diploma_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Soumission du formulaire ──────────────────────────────────────
  Future<void> _handleLogin() async {
    // Fermer le clavier
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      // Navigation vers l'écran principal (remplacement de la pile)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DiplomaListScreen()),
      );
    } else {
      _showErrorSnackBar(result.errorMessage ?? 'Erreur inconnue');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // ── Démonstration rapide (dev only) ─────────────────────────────
  void _fillDemo() {
    _emailController.text = 'demo@example.com';
    _passwordController.text = 'Demo1234';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // En-tête avec logo
              const AuthHeader(
                title: 'Connexion',
                subtitle: 'Accédez à vos certifications sécurisées',
              ),

              const SizedBox(height: 40),

              // Formulaire
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Adresse email',
                      hint: 'vous@exemple.com',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: AuthService.validateEmail,
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Mot de passe',
                      hint: '••••••••',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: AuthService.validatePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),

                    const SizedBox(height: 8),

                    // Se souvenir + mot de passe oublié
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? false),
                          activeColor: AppColors.primary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Flexible(
                          child: const Text('Se souvenir de moi',
                              style: TextStyle(fontSize: 13)),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Écran mot de passe oublié
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Fonctionnalité à venir.')),
                            );
                          },
                          child: const Text('Mot de passe oublié ?',
                              style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Bouton Connexion
                    PrimaryButton(
                      label: 'Se connecter',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                      icon: Icons.login_rounded,
                    ),

                    const SizedBox(height: 16),

                    if (kDebugMode) ...[
                      // Bouton démo uniquement en mode développement
                      OutlinedButton.icon(
                        onPressed: _fillDemo,
                        icon: const Icon(Icons.auto_fix_high, size: 18),
                        label: const Text('Remplir démo'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Lien inscription
              const OrDivider(),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Text(
                    'Pas encore de compte ?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text("S'inscrire"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
