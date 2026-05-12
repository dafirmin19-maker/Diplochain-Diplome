# DiploChain v2 – Application Flutter

Vérification de diplômes sur blockchain pour les diplômés.  
Thème **Vert & Blanc** — Interface professionnelle, sécurisée et accessible.

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # Point d'entrée, config thème
├── theme/
│   └── app_theme.dart           # Couleurs, typographie, composants
├── models/
│   ├── diploma.dart             # Modèle diplôme (immuable, JSON)
│   └── user.dart                # Modèle utilisateur connecté
├── services/
│   ├── auth_service.dart        # Login, inscription, validation, logout
│   └── diploma_service.dart     # Récupération diplômes (→ API blockchain)
├── screens/
│   ├── login_screen.dart        # Page de connexion
│   ├── register_screen.dart     # Page d'inscription
│   ├── diploma_list_screen.dart # Liste des certifications
│   └── diploma_detail_screen.dart # Détail + QR Code blockchain
└── widgets/
    └── common_widgets.dart      # PrimaryButton, AppTextField, VerifiedBadge…
test/
└── auth_test.dart               # Tests unitaires (AuthService, modèles)
```

### Pattern architectural
- **Séparation des responsabilités** : models / services / screens / widgets
- **Services stateless** : AuthService et DiplomaService indépendants de l'UI
- **Widgets réutilisables** : composants centralisés dans `common_widgets.dart`
- **Prêt pour Provider** : AuthService étend ChangeNotifier

---

## ⚙️ Installation

### Prérequis
- Flutter >= 3.0.0
- Dart >= 3.0.0
- Android Studio ou VS Code avec Flutter plugin

### Étapes

```bash
# 1. Cloner le projet
git clone https://github.com/diplochain/app.git
cd diplochain_app

# 2. Installer les dépendances
flutter pub get

# 3. Lancer sur émulateur / device
flutter run

# 4. Lancer les tests
flutter test

# 5. Build APK release
flutter build apk --release
```

---

## 🔒 Sécurité appliquée

| Mesure | Implémentation |
|--------|---------------|
| Validation email | Regex RFC 5322 côté client |
| Mot de passe fort | Min 8 chars + majuscule + chiffre |
| Indicateur de force | Calcul temps-réel dans le formulaire |
| Champs obscurcis | Toggle voir/masquer le mot de passe |
| Confirmation mdp | Double saisie obligatoire |
| Entrées sanitisées | `.trim()` systématique avant envoi API |
| Navigation sécurisée | `pushReplacement` (pile nettoyée après login) |
| Gestion erreurs | Try/catch + messages utilisateurs non techniques |

---

## ✅ Bonnes pratiques appliquées

- [x] Material Design 3 (useMaterial3: true)
- [x] Widgets const partout où possible
- [x] Dispose des TextEditingController
- [x] FutureBuilder avec états loading/error/empty
- [x] RefreshIndicator pour pull-to-refresh
- [x] Accès par clavier (textInputAction, onFieldSubmitted)
- [x] Tooltips sur tous les IconButton
- [x] SafeArea sur tous les Scaffold
- [x] Aucune couleur hardcodée (tout dans AppColors)
- [x] Tests unitaires pour la logique métier

---

## 🔮 Prochaines étapes (production)

1. **Remplacer les mocks** par de vraies requêtes HTTP (`dio` ou `http`)
2. **Ajouter `shared_preferences`** pour la persistance de session
3. **Intégrer `url_launcher`** pour ouvrir les URLs de vérification
4. **Ajouter `share_plus`** pour le partage de certifications
5. **Authentification biométrique** via `local_auth`
6. **Mode hors-ligne** avec cache local des diplômes
7. **Notifications push** (Firebase Cloud Messaging)
