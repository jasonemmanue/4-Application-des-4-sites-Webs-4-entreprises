# Système de thème — mode clair & mode sombre

Application client mobile CHIC RESIDENCE. Dernière refonte : 2026-09-20.

---

## 1. Le problème que ce système résout

Avant cette refonte, les widgets posaient des couleurs nommées directement :

```dart
Text('Bonjour', style: TextStyle(color: AppColors.lightText))   // #222222
Container(color: Colors.white)
Border.all(color: AppColors.lightBorder)                        // #EBEBEB
```

Ces valeurs sont **figées**. En mode sombre, le fond passait bien au noir
(le `ThemeData` le gérait), mais le texte restait `#222222` — donc **noir sur
noir, invisible**. Même chose pour la barre de navigation (`Colors.white` en
dur), les badges flottants et les squelettes de chargement, qui restaient
blancs et éblouissaient.

68 usages de ce type étaient répartis sur 11 fichiers.

La correction n'est pas de dupliquer chaque widget en deux versions, mais de
remplacer une valeur par un **rôle**.

---

## 2. Tokens sémantiques

Le fichier [`lib/config/theme.dart`](../Application%20client%20Mobile/lib/config/theme.dart)
définit `AppTokens`, une `ThemeExtension` enregistrée dans les deux
`ThemeData`. Chaque token porte une intention, pas une couleur.

| Token | Rôle | Clair | Sombre |
|---|---|---|---|
| `surface` | Fond des écrans | `#FFFFFF` | `#0F0F10` |
| `surfaceElevated` | Cards, barres, feuilles | `#FFFFFF` | `#1C1C1E` |
| `surfaceSunken` | Champ inline, chip active | `#F7F7F7` | `#2C2C2E` |
| `textPrimary` | Texte principal | `#222222` | `#F7F7F7` |
| `textSecondary` | Sous-titres, prix, légendes | `#717171` | `#A1A1A6` |
| `textOnPhoto` | Texte/icône **sur une photo** | `#FFFFFF` | `#FFFFFF` |
| `border` | Bordure standard | `#DDDDDD` | `#3A3A3C` |
| `borderStrong` | Chip sélectionnée, champ focus | `#222222` | `#F7F7F7` |
| `chipBg` / `chipBgSelected` | Fond des chips | `#FFFFFF` / `#F7F7F7` | `#1C1C1E` / `#2C2C2E` |
| `navBg` | Fond de la barre basse | `#FFFFFF` | `#161618` |
| `pillBg` / `pillText` | Badge flottant | `#FFFFFF` / `#222222` | `#1C1C1E` / `#F7F7F7` |
| `ctaBg` / `ctaFg` | Bouton d'action principal | `#222222` / blanc | `#F7F7F7` / `#0F0F10` |
| `brand` | Rouge Chic Residence | `#DC2626` | `#EF4444` |
| `imagePlaceholder` | Fond avant chargement photo | `#FAF3E8` | `#232325` |
| `shadow` | Ombre portée | `#0000001F` | `#00000066` |
| `skeletonBase` / `skeletonHighlight` | Shimmer de chargement | `#EEEEEE` / `#F7F7F7` | `#1F1F21` / `#2A2A2D` |

### Trois choix non déductibles du code

1. **Le CTA principal s'inverse.** `ctaBg` vaut noir en clair et **blanc en
   sombre** (`ctaFg` suit à l'inverse). Un bouton noir sur fond noir
   disparaîtrait ; Airbnb fait la même inversion. C'est le seul token dont
   les deux valeurs sont opposées plutôt que analogues.

2. **`brand` change de nuance selon le thème.** `#DC2626` (primary600) manque
   de contraste sur fond noir : on passe à `#EF4444` (primary500) en sombre.
   La marque reste reconnaissable, la lisibilité est préservée.

3. **`textOnPhoto` est blanc dans les deux thèmes.** Le cœur des cards et le
   badge « Coup de cœur » sont posés sur une photo, pas sur une surface du
   thème. Les faire basculer les rendrait invisibles sur une photo claire en
   mode clair.

---

## 3. Comment écrire un widget

```dart
import '../config/theme.dart';   // apporte l'extension context.tokens

@override
Widget build(BuildContext context) {
  final t = context.tokens;      // à faire une fois en tête de build

  return Container(
    color: t.surfaceElevated,
    child: Text(
      'Réservations',
      style: TextStyle(color: t.textPrimary),
    ),
  );
}
```

### Règles

- **Aucun widget ne référence `AppColors.light*` ou `AppColors.dark*`.**
  Ces constantes sont marquées `@Deprecated` — l'analyseur les signale.
- Préférer `Theme.of(context).textTheme.*` quand un style de texte complet
  existe : il porte déjà la bonne couleur.
- `const` et tokens sont incompatibles : `context.tokens` est évalué à
  l'exécution. Retirer le `const` du widget concerné.
- Les couleurs d'état (`AppColors.success`, `error`, `warning`, `info`) et la
  palette de marque (`primary*`, `accent*`) restent des constantes : elles ne
  dépendent pas du thème.

### Exceptions légitimes à `Colors.white` / `Colors.black`

Uniquement quand le fond n'est pas une surface du thème :

- texte ou icône posés **sur une photo** → utiliser `t.textOnPhoto` ;
- badge blanc **sur une photo** (« Coup de cœur ») → `Colors.white` littéral
  est correct, avec un texte `#222222` littéral ;
- `onPrimary` d'un bouton rouge de marque → blanc dans les deux thèmes.

---

## 4. Ce que `_build(AppTokens)` configure

Les deux `ThemeData` sont produits par **la même fonction**, seule
l'instance de tokens change. Ajouter un token le rend donc disponible des
deux côtés, sans duplication. Sont dérivés des tokens :

`colorScheme`, `scaffoldBackgroundColor`, `canvasColor`, `cardColor`,
`dividerColor`, `textTheme`, `primaryTextTheme`, `iconTheme`, `appBarTheme`,
`cardTheme`, `listTileTheme`, `dialogTheme`, `bottomSheetTheme`,
`snackBarTheme`, `inputDecorationTheme`, `elevatedButtonTheme`,
`filledButtonTheme`, `outlinedButtonTheme`, `textButtonTheme`,
`segmentedButtonTheme`, `chipTheme`, `dividerTheme`,
`progressIndicatorTheme`.

C'est ce qui corrige le mode sombre « mal affiché sur les services » : les
`SnackBar`, `Dialog`, `BottomSheet` et `ListTile` héritaient jusqu'ici des
valeurs Material par défaut.

> ⚠️ **`textTheme` doit porter explicitement la couleur.** Sans
> `?.copyWith(color: t.textPrimary)` sur chaque style, Material retombe sur le
> noir du thème clair même quand `brightness` vaut `dark`.

---

## 5. Densité des contours (« encerclements »)

Les chips paraissaient flotter sans contour par rapport à Airbnb. Trois
correctifs dans [`category_chips.dart`](../Application%20client%20Mobile/lib/widgets/category_chips.dart) :

1. **Bordure plus dense** — `border` est passé de `#EBEBEB` à `#DDDDDD`. Une
   bordure trop pâle disparaît sur fond blanc.
2. **Ombre portée sur chaque chip**, y compris non sélectionnée. C'est elle
   qui détache la pilule du fond — Airbnb en pose une, discrète.
3. **Fond distinct quand sélectionnée** (`chipBgSelected`) en plus de la
   bordure épaissie à 2 px. La sélection se lit alors en un coup d'œil.

---

## 6. Choix du mode par l'utilisateur

Trois options dans **Profil → Apparence** : ☀️ Clair, 🔄 Auto, 🌙 Sombre.

- Provider : `themeModeProvider` (`StateNotifierProvider<ThemeModeNotifier,
  ThemeMode>`) dans
  [`providers.dart`](../Application%20client%20Mobile/lib/providers/providers.dart).
- Persistance : `SharedPreferences`, clé `theme_mode`, valeurs `light` /
  `dark` / `system`.
- Défaut au premier lancement : `system`. L'utilisateur n'a pas à rebasculer
  manuellement chaque matin selon le mode de son téléphone.
- Branchement : `MaterialApp.router(themeMode: ref.watch(themeModeProvider))`
  dans [`app.dart`](../Application%20client%20Mobile/lib/app.dart).

---

## 7. Vérifier une régression

```bash
# Aucun widget ne doit référencer les constantes figées
grep -rn "AppColors.light\|AppColors.dark" lib/ --include="*.dart" \
  | grep -v "lib/config/theme.dart"
# → attendu : aucune ligne

# Colors.white / Colors.black hors contexte photo
grep -rn "Colors\.white\|Colors\.black" lib/ --include="*.dart" \
  | grep -v "lib/config/theme.dart"
# → attendu : uniquement badges sur photo, onPrimary de boutons de marque,
#   et ombres (Colors.black38 dans un Shadow)
```

Test visuel : ouvrir **Profil → Apparence**, basculer Clair → Sombre, puis
parcourir Explorer, Recherche (avec le dropdown d'autocomplétion ouvert),
Détail résidence, Tunnel de réservation, Favoris, Messages. Chaque texte doit
rester lisible et chaque surface changer de teinte.
