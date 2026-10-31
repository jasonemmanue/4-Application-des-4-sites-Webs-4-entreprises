# Refonte UI/UX 1.1.0 (31 octobre 2026)

## Charte

| Token | Valeur | Usage |
|---|---|---|
| `lightBg` | `#FBF6EC` | Fond crème |
| `brand500` / `brand600` | `#0E8784` / `#0B7A77` | Sarcelle : boutons, onglet actif |
| `brandTint` | `#DDF0EE` | Pastilles d'icônes |
| `charcoal900` | `#0B2340` | Bleu nuit : titres et thème sombre |
| `accent500` | `#F39C1F` | Ambre : filet de titre, badge « Projet à la une » |

- Police : Plus Jakarta Sans.
- Thème clair par défaut. Le mode sombre se règle dans Profil.
- Le logo reste `assets/images/logo.png`, en haut à gauche de chaque onglet.
  En thème sombre, il est posé sur une pastille blanche, car il est noir.
- Les briques communes sont dans `lib/widgets/ruah_ui.dart`.

## Navigation

| Onglet | Écran | Contenu |
|---|---|---|
| Accueil | `HomeScreen` | Recherche, filtres, 4 expertises, projet à la une, chiffres clés, Explorer |
| Services | `ServicesListScreen` | Toutes les expertises, 2 réalisations |
| Projets | `ProjectsListScreen` | Réalisations avec filtres secteur, pays, année |
| Contact | `ContactHubScreen` | Demande de devis sur une page, WhatsApp |

Rien n'a été retiré, seul l'accès a changé :

- Publications, Témoignages, Équipe et Vidéos : section Explorer de l'accueil.
- Profil (paiement, devis en 4 étapes, mode sombre) : icône en haut à droite de
  l'accueil.
- Message simple (`POST /contact`) : lien sous le formulaire Contact et Profil.
- La pastille « Devis sans engagement » disparaît, remplacée par l'onglet Contact.

## Écarts assumés avec la maquette

- **Logo** : celui du cabinet, comme demandé, et non celui dessiné sur la maquette.
- **E-mail remplacé par « Numéro WhatsApp »** : `QuoteRequest` n'a pas de champ
  e-mail, et le cabinet répond sur WhatsApp.
- **Titre du projet à la une** : il vient de l'API, pas du texte de la maquette.
- **Icône Profil ajoutée** dans l'en-tête de l'accueil, sinon le paiement et le
  Profil seraient inaccessibles avec 4 onglets.
- **Pas de point orange sur la cloche** : l'app n'a pas de centre de
  notifications, un badge « non lu » serait faux.

## Images

Chemin d'une image : l'admin téléverse (`POST /upload`, renvoie `/uploads/...`),
l'API sert l'URL, `ApiConfig.resolveMediaUrl` la rend absolue, puis `RemoteImage`
ou `RemoteAvatar` l'affiche.

- Pendant le chargement : dégradé de marque.
- URL vide, 404 ou format non décodable (SVG) : icône, ou initiales pour une personne.

## Corrections de compatibilité avec l'API

- `TeamMember.education` : l'API renvoie une liste, le modèle attendait un texte.
  L'écran Équipe plantait à chaque ouverture.
- Filtre Publications : l'app envoyait `article_type`, l'API attend `type`.
  Le filtre était ignoré sans erreur.
- Accueil : les boutons « Réessayer » ne faisaient rien.

## Vérifier

```bash
flutter test
```

```bash
flutter test test/api_contract_live_test.dart --dart-define=LIVE_API=true
```

Le second lit les vraies réponses de production dans les modèles de l'app.

## Compiler l'APK

Le « é » du dossier parent (« ainé ») fait échouer `gen_snapshot` et `impellerc`
avec « Unable to read file ». Il faut compiler depuis un lecteur virtuel :

```powershell
subst R: "<chemin complet de Application client Mobile>"
Set-Location R:\
flutter build apk --release
Set-Location C:\
subst R: /D
```

## Déployer l'API

Un push sur le dépôt web ne déclenche pas de déploiement Railway. Depuis la
racine de `cabinet-etudes` :

```bash
railway up --service api --ci
```
