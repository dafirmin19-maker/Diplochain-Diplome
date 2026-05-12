// Point d'entrée DiploChain v2
// Configuration : auth service, thème vert, routes nommées

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les services (SharedPreferences)
  await AuthService.instance.init();

  // Forcer l'orientation portrait (app mobile)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Couleur de la barre de statut système (vert)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DiploChainApp());
}

/// Widget racine de l'application DiploChain
class DiploChainApp extends StatelessWidget {
  const DiploChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DiploChain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Écran de démarrage : page de connexion
      home: const LoginScreen(),

      // Gestion globale des erreurs de rendu (dev)
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
