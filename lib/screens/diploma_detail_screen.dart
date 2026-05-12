// Écran Détail d'un Diplôme
// Affiche la carte certifiée complète avec QR code blockchain
// Design : Vert & Blanc, gradient vert, QR haute résolution

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/diploma.dart';
import '../services/diploma_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class DiplomaDetailScreen extends StatelessWidget {
  final Diploma diploma;

  const DiplomaDetailScreen({super.key, required this.diploma});

  String get _verificationUrl =>
      DiplomaService.instance.getPublicDiplomaUrl(diploma);

  String get _shareText {
    return 'Diplome certifie DiploChain\n'
        '${diploma.title}\n'
        'Titulaire : ${diploma.studentName}\n'
        'Verification blockchain : $_verificationUrl';
  }

  // Copie le hash dans le presse-papier
  void _copyHash(BuildContext context) {
    Clipboard.setData(ClipboardData(text: diploma.blockchainHash));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hash copié dans le presse-papier')),
    );
  }

  Future<void> _shareDiploma(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: diploma.title,
          subject: 'Diplome certifie DiploChain - ${diploma.title}',
          text: _shareText,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d ouvrir le partage.')),
      );
    }
  }

  Future<void> _openVerification(BuildContext context) async {
    final uri = Uri.parse(_verificationUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d ouvrir le navigateur.')),
      );
    }
  }

  Future<void> _shareQrCode(BuildContext context) async {
    try {
      final painter = QrPainter(
        data: _verificationUrl,
        version: QrVersions.auto,
        gapless: false,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.primaryDark,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.primaryDark,
        ),
      );
      final imageData = await painter.toImageData(
        720,
        format: ui.ImageByteFormat.png,
      );
      if (imageData == null) {
        throw StateError('QR image unavailable');
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/diplochain_qr_${diploma.id}.png');
      await file.writeAsBytes(imageData.buffer.asUint8List());

      await SharePlus.instance.share(
        ShareParams(
          title: 'QR Code ${diploma.title}',
          text: _shareText,
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de partager le QR Code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du Diplôme'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            key: const Key('shareDiplomaButton'),
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _shareDiploma(context),
            tooltip: 'Partager',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Carte certifiée ────────────────────────────────────
            _CertificateCard(diploma: diploma),

            const SizedBox(height: 24),

            // ── Informations détaillées ───────────────────────────
            _InfoSection(
              diploma: diploma,
              verificationUrl: _verificationUrl,
              onCopyHash: () => _copyHash(context),
            ),

            const SizedBox(height: 28),

            // ── QR Code blockchain ────────────────────────────────
            _QrSection(
              diploma: diploma,
              verificationUrl: _verificationUrl,
              onOpenVerification: () => _openVerification(context),
              onShareQrCode: () => _shareQrCode(context),
            ),

          ],
        ),
      ),
    );
  }
}

// ── Carte diplôme (gradient vert) ──────────────────────────────────────
class _CertificateCard extends StatelessWidget {
  final Diploma diploma;
  const _CertificateCard({required this.diploma});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Motif décoratif
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                Icons.verified_rounded,
                size: 140,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo DiploChain
                Row(
                  children: [
                    const Icon(Icons.link_rounded,
                        color: Colors.white70, size: 20),
                    const SizedBox(width: 6),
                    const Text(
                      'DiploChain',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    const VerifiedBadge(),
                  ],
                ),

                const SizedBox(height: 20),

                // Titre du diplôme
                Text(
                  diploma.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                if (diploma.specialization != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    diploma.specialization!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],

                const SizedBox(height: 8),
                Text(
                  diploma.university,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),

                Divider(color: Colors.white.withValues(alpha: 0.2), height: 36),

                // Informations titulaire
                _CardRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Titulaire',
                    value: diploma.studentName),
                const SizedBox(height: 8),
                _CardRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Délivré le',
                    value: '${diploma.date.day} ${diploma.date.month} ${diploma.date.year}'),
                if (diploma.mention != null) ...[
                  const SizedBox(height: 8),
                  _CardRow(
                      icon: Icons.star_outline_rounded,
                      label: 'Mention',
                      value: diploma.mention!),
                ],

                Divider(color: Colors.white.withValues(alpha: 0.2), height: 24),

                // Hash court
                Row(
                  children: [
                    const Icon(Icons.fingerprint_rounded,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      diploma.shortHash,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CardRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text('$label : ',
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Section informations blockchain ───────────────────────────────────
class _InfoSection extends StatelessWidget {
  final Diploma diploma;
  final String verificationUrl;
  final VoidCallback onCopyHash;
  const _InfoSection({
    required this.diploma,
    required this.verificationUrl,
    required this.onCopyHash,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text('Données blockchain',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Hash complet avec bouton copier
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hash de transaction',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        diploma.blockchainHash,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      key: const Key('copyHashButton'),
                      icon: const Icon(Icons.copy_rounded,
                          color: AppColors.primary, size: 18),
                      onPressed: onCopyHash,
                      tooltip: 'Copier',
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // URL de vérification
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('URL de vérification',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  verificationUrl,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.info,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section QR Code ────────────────────────────────────────────────────
class _QrSection extends StatelessWidget {
  final Diploma diploma;
  final String verificationUrl;
  final VoidCallback onOpenVerification;
  final VoidCallback onShareQrCode;

  const _QrSection({
    required this.diploma,
    required this.verificationUrl,
    required this.onOpenVerification,
    required this.onShareQrCode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Vérification QR Code',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Scannez pour vérifier l\'authenticité sur la blockchain',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: QrImageView(
                data: verificationUrl,
                version: QrVersions.auto,
                size: 200,
                gapless: false,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.primaryDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              key: const Key('openVerificationButton'),
              onPressed: onOpenVerification,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Vérifier en ligne'),
            ),
            TextButton.icon(
              key: const Key('shareQrCodeButton'),
              onPressed: onShareQrCode,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
              label: const Text('Partager le QR Code'),
            ),
          ],
        ),
      ),
    );
  }
}
