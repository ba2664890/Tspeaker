# T.Speak - Application Flutter

Application d'apprentissage des langues avec une identité visuelle africaine distinctive, inspirée du design fourni.

## 🎨 Design System

### Couleurs Principales
- **Primary (Orange)**: #A83900 / #FF6B2B - Énergie, passion, action
- **Secondary (Emerald)**: #006B55 / #6DFAD2 - Croissance, succès
- **Tertiary (Gold)**: #855300 / #D58800 - Excellence, récompense

### Typographie
- **Headlines**: Plus Jakarta Sans (ExtraBold, Bold)
- **Body**: Be Vietnam Pro (Regular, Medium, SemiBold)
- **Labels**: Space Grotesk / Space Mono (pour les éléments techniques)

## 📱 Écrans Implémentés

### 1. Splash Screen
- Animation de logo avec effet de son
- Progress indicator
- Tagline "Fait pour l'Afrique"

### 2. Onboarding (3 slides)
- "Parle. Apprends. Progresse."
- "Ton accent africain est une force."
- "Simule. Performe. Réussis."

### 3. Inscription
- Formulaire avec nom et email
- Sélection de langue maternelle (Wolof, Pulaar, Bambara, etc.)
- Sélection du niveau (Débutant, Intermédiaire, Avancé)
- Preview du profil

### 4. Test de Niveau
- Interface d'enregistrement vocale
- Animation de pulsation
- Visualiseur audio
- Timer

### 5. Accueil (Home)
- Carte de série (streak)
- Barre de progression XP
- Session en cours
- Sessions recommandées (horizontal scroll)
- Floating action button micro

### 6. Catalogue
- Filtres (Tous, Business, Entretiens, Social)
- Carte featured (large)
- Grid de simulations
- Badges Premium

### 7. Simulation Active
- Environnement de réunion virtuelle
- Avatars des investisseurs
- Bulle de dialogue
- Visualiseur audio
- Contrôles d'enregistrement

### 8. Session Vocale
- Avatar T.AI
- Transcription en temps réel
- Visualiseur audio
- Contrôles de session

### 9. Résultats
- Score circulaire
- Animation confetti
- Métriques détaillées (Prononciation, Fluidité, Grammaire, Vocabulaire)
- Feedback IA
- Boutons d'action

### 10. Classement
- Podium (Top 3 avec gradients Or/Argent/Bronze)
- Liste des classements
- Mise en évidence de l'utilisateur courant
- Onglets (Cette semaine / Mon pays)

### 11. Profil
- Avatar avec niveau
- Statistiques (Sessions, Streak, Avg. Score)
- Graphique de performance (30 jours)
- Collection de badges
- Paramètres

## 🏗️ Architecture

```
lib/
├── main.dart                 # Point d'entrée
├── theme/
│   └── app_theme.dart        # Design system (couleurs, typographie)
├── models/
│   └── user.dart             # Modèles de données
├── widgets/
│   ├── bottom_nav_bar.dart   # Navigation inférieure
│   └── top_app_bar.dart      # Barre d'application supérieure
└── screens/
    ├── splash_screen.dart
    ├── onboarding_screen.dart
    ├── inscription_screen.dart
    ├── test_niveau_screen.dart
    ├── home_screen.dart
    ├── catalogue_screen.dart
    ├── simulation_active_screen.dart
    ├── session_vocale_screen.dart
    ├── resultats_screen.dart
    ├── classement_screen.dart
    └── profil_screen.dart
```

## 📦 Dépendances

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  percent_indicator: ^4.2.3
  fl_chart: ^0.66.0
  shimmer: ^3.0.0
  flutter_animate: ^4.3.0
  go_router: ^12.1.1
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  shared_preferences: ^2.2.2
  intl: ^0.18.1
  record: ^5.0.4
  audioplayers: ^5.2.1
  confetti: ^0.7.0
  smooth_page_indicator: ^1.1.0
```

## 🚀 Démarrage

1. **Cloner le projet**
```bash
cd tspeak_flutter
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Lancer l'application**
```bash
flutter run
```

## 🎯 Fonctionnalités Clés

### Design Africain
- Motifs Bogolan subtils
- Palette de couleurs terreuses (orange brûlé, émeraude, or)
- Typographie moderne avec une touche africaine
- Célébration de la diversité linguistique africaine

### Interactions
- Animations fluides et réactives
- Feedback haptique sur les boutons
- Transitions entre écrans
- Micro-interactions (pulsation, ondulation)

### Accessibilité
- Contraste élevé
- Tailles de texte adaptables
- Support du mode sombre (préparé)

## 🔧 Configuration Backend

L'application est prête à être connectée à un backend Flutter/Dart. Les services à implémenter :

- `AuthService` - Authentification utilisateur
- `UserService` - Gestion du profil
- `SessionService` - Gestion des sessions d'apprentissage
- `SpeechService` - Reconnaissance vocale et évaluation
- `LeaderboardService` - Classements

## 📱 Compatibilité

- **iOS**: 12.0+
- **Android**: API 21+
- **Orientation**: Portrait uniquement

## 📝 Notes

- Les images utilisées sont des placeholders (Unsplash)
- Les fonctionnalités vocales nécessitent des permissions
- Le mode sombre est préparé mais désactivé par défaut
- Les animations sont optimisées pour 60fps

## 🏆 Badges et Récompenses

Le système de gamification inclut :
- Lève-tôt (série matinale)
- Série 7 Jours (consistance)
- Polyglotte (multilingue)
- Orateur (excellence vocale)
- Elite 50 (top performers)
- Explorateur (variété de scénarios)
- Mentor (aide aux autres)
- Scribe (maîtrise de l'écrit)

## 🌍 Langues Supportées

Langues maternelles africaines :
- Wolof (Sénégal)
- Pulaar (Afrique de l'Ouest)
- Bambara (Mali)
- Serer (Sénégal)
- Diola (Casamance)
- Soninké (Afrique de l'Ouest)

Langues d'apprentissage :
- Anglais
- Français

---

**T.Speak** - *Fait pour l'Afrique* 🌍
