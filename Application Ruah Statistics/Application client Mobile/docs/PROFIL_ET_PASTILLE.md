# Profil et pastille « Devis sans engagement » — Ruah Statistics

Refonte : 2026-10-06. Reprise de trois écrans d'Airbnb (Profil, accueil avec
pastille flottante, pop-up d'information), adaptés au cabinet : cyan /
charcoal, thèmes clair et sombre, aucune transaction en ligne.

---

## 1. Écran Profil (onglet ex-« Plus »)

Fichier : `lib/screens/more/more_screen.dart` — route `/more` inchangée.
Les couleurs suivent `Theme.of(context).brightness` (convention existante de
l'app), regroupées dans une petite classe `_Palette`.

| Bloc | Contenu | Action |
|---|---|---|
| En-tête | Cloche ronde + titre « Profil » | Cloche → snackbar « le cabinet vous répond sur WhatsApp » |
| Carte d'identité | Avatar cyan pâle + initiale, nom, entreprise | — |
| Carte 1 | Demander un devis (vignette dégradé cyan + icône) | `AppRoutes.quote` |
| Carte 2 | Nos réalisations (vignette dégradé cyan + icône) | `AppRoutes.projects` |
| Carte large | Parler à un consultant (`profil-consultant.jpg`) | WhatsApp pré-rempli |
| Liste | Équipe, À propos, Vidéos, Témoignages, Contact | routes existantes |

Le site du cabinet ne possède qu'une photo (`hero-bg.jpg`, reprise pour la
carte large) : les deux petites cartes portent donc une vignette illustrée
au dégradé `AppColors.ctaGradient`.

### D'où vient le nom ?

L'app **n'a pas de compte**. Le nom et l'entreprise sont ceux de la dernière
demande de devis (`quote_flow_screen.dart`, juste après
`submitQuoteRequest`).

- Provider : `clientProfileProvider` (`lib/services/client_profile.dart`)
- Stockage : `SharedPreferences`, clés `ruah_client_name` / `ruah_client_company`
- Sous-titre : l'entreprise si renseignée, sinon « Demande de devis envoyée »
- Sans demande : icône, **« Visiteur »**

---

## 2. Pastille flottante + pop-up

Fichier : `lib/widgets/quote_notice.dart`, posé en bas de l'accueil
(`home_screen.dart`) à la place de l'ancien `_FloatingCta`.

- Pastille : document cyan + « Devis sans engagement ».
- Pop-up : croix, document animé, « Décrivez votre projet en quelques
  étapes, un consultant vous répond sur WhatsApp. », « Sans inscription, sans
  paiement. », bouton plein « Demander un devis » (charcoal en clair, blanc
  en sombre) → ouvre le formulaire de devis.
- **La pastille reste affichée** après lecture : contrairement aux autres
  apps, c'est l'appel à l'action principal du cabinet, pas une simple
  information.

⚠️ L'ancien libellé « Consultation gratuite » a été retiré : le site ne promet
nulle part de consultation gratuite. « Sans engagement » est vrai par
construction (aucun paiement, aucune inscription).

⚠️ `useRootNavigator: true` : sans lui la feuille s'ouvre sous la barre de
navigation du `ShellRoute`, qui masque le bouton.

---

## 3. Vérifier

```bash
flutter analyze lib
```

Test manuel, dans les deux thèmes (bascule sur l'accueil) : pastille → pop-up
couvrant la barre basse → « Demander un devis » ouvre le formulaire. Envoyer
une demande → onglet Profil → nom et entreprise apparaissent.
