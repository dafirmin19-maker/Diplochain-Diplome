// Écran Liste des Diplômes
// Affiche les certifications du diplômé connecté
// Design : Vert & Blanc, cartes riches, état de chargement

import 'package:flutter/material.dart';
import '../models/diploma.dart';
import '../services/auth_service.dart';
import '../services/diploma_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'diploma_detail_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DiplomaListScreen extends StatefulWidget {
  const DiplomaListScreen({super.key});

  @override
  State<DiplomaListScreen> createState() => _DiplomaListScreenState();
}

class _DiplomaListScreenState extends State<DiplomaListScreen> {
  late Future<List<Diploma>> _diplomasFuture;

  @override
  void initState() {
    super.initState();
    _loadDiplomas();
  }

  void _loadDiplomas() {
    final userId = AuthService.instance.currentUser?.id ?? 'current_user';
    _diplomasFuture = DiplomaService.instance.getDiplomasForUser(userId);
  }

  void _refresh() => setState(_loadDiplomas);

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Souhaitez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DiploChain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            tooltip: 'Mon profil',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Diploma>>(
          future: _diplomasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (snapshot.hasError) {
              return _ErrorState(onRetry: _refresh);
            }
            final diplomas = snapshot.data ?? [];
            if (diplomas.isEmpty) {
              return const _EmptyState();
            }
            return _DiplomaList(diplomas: diplomas);
          },
        ),
      ),
    );
  }
}

// ── Liste des diplômes ─────────────────────────────────────────────────
class _DiplomaList extends StatelessWidget {
  final List<Diploma> diplomas;
  const _DiplomaList({required this.diplomas});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // En-tête statistiques
        SliverToBoxAdapter(
          child: _StatsHeader(count: diplomas.length),
        ),
        // Cartes diplômes
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _DiplomaCard(diploma: diplomas[index]),
              ),
              childCount: diplomas.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Carte d'un diplôme ─────────────────────────────────────────────────
class _DiplomaCard extends StatelessWidget {
  final Diploma diploma;
  const _DiplomaCard({required this.diploma});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => DiplomaDetailScreen(diploma: diploma)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône diplôme
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  // Titre & université
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          diploma.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diploma.university,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              // Ligne inférieure : date + badge vérifié
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('${diploma.date.day}/${diploma.date.month}/${diploma.date.year}',
                      style: Theme.of(context).textTheme.labelMedium),
                  const Spacer(),
                  VerifiedBadge(isVerified: diploma.isVerified),
                ],
              ),
              // Mention si disponible
              if (diploma.mention != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 6),
                    Text(
                      'Mention : ${diploma.mention}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── En-tête statistiques ───────────────────────────────────────────────
class _StatsHeader extends StatelessWidget {
  final int count;
  const _StatsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count Certification${count > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Toutes vérifiées sur blockchain',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── État vide ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded,
                size: 72, color: AppColors.primaryLight),
            const SizedBox(height: 16),
            Text('Aucune certification',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Vos diplômes vérifiés sur blockchain\napparaîtront ici.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ── État erreur ────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 60, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Erreur de chargement',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Impossible de récupérer vos diplômes.\nVérifiez votre connexion.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
