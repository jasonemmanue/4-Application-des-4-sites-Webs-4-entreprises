# Profil et pastille « acompte 50 % » — Flora Hair

Refonte : 2026-10-06. Reprise de trois écrans d'Airbnb (Profil, accueil avec
pastille flottante, pop-up d'information), adaptés à la marque : crème,
chocolat et or, photos de réalisations du salon.

Chemins relatifs à `flora_hair_mobile/`.

---

## 1. Écran Profil (onglet ex-« Plus »)

Fichier : `lib/screens/more/more_screen.dart` — route `/more` inchangée.
Les couleurs passent par `Theme.of(context).colorScheme` (convention du
thème Flora), jamais par `FloraColors` en dur.

| Bloc | Contenu | Action |
|---|---|---|
| En-tête | Cloche ronde + titre « Profil » | Cloche → snackbar « confirmations sur WhatsApp » |
| Carte d'identité | Avatar or pâle + initiale, nom, « Cliente Flora Hair » | — |
| Carte photo 1 | Prendre rendez-vous (`profil-rdv.jpg`) | `/booking` |
| Carte photo 2 | Nos réalisations (`profil-galerie.jpg`) | `/gallery` |
| Carte large | Devis sur photo (`profil-devis.jpg`) | `/quote` |
| Liste | Équipe, Articles, Vidéos, Avis, Formations, Contact & WhatsApp | routes existantes |

Ombre des cartes teintée chocolat (`#1A1510`) plutôt que noire, pour rester
dans la palette crème.

### D'où vient le nom ?

L'app **n'a pas de compte**. Le nom est celui saisi au dernier rendez-vous
(`booking_screen.dart`, juste après `createBooking`).

- Provider : `clientNameProvider` (`lib/services/client_profile.dart`)
- Stockage : `SharedPreferences`, clé `flora_client_name` — dépendance
  `shared_preferences` ajoutée au `pubspec.yaml`
- Sans rendez-vous : icône, **« Visiteuse »**, « Votre nom apparaîtra après
  votre premier rendez-vous »

### Photos

Copiées depuis `salon-coiffure/frontend/public/images/prestations/`
(tresses perlées, chignon, maquillage mariée) : détourées sur fond crème,
elles jouent le rôle des illustrations 3D d'Airbnb.

---

## 2. Pastille flottante + pop-up

Fichier : `lib/widgets/deposit_notice.dart`, posé en bas de l'accueil
(`home_screen.dart`, la `ListView` passe dans un `Stack`).

- Pastille : étiquette or + « Réservez avec 50 % d'acompte ».
- Pop-up : croix, étiquette animée, « Payez 50 % en ligne pour confirmer votre
  rendez-vous, le reste se règle au salon. », « Par Mobile Money, en toute
  sécurité. », bouton chocolat plein « J'ai compris ».
- Lue une fois → masquée pour de bon (`depositNoticeVisibleProvider`, clé
  `flora_deposit_notice_seen`).

Source de la règle : `salon-coiffure/CLAUDE.md`, section « ACOMPTE DE 50 %
PAYÉ EN LIGNE — GENIUSPAY ».

⚠️ `useRootNavigator: true` : sans lui la feuille s'ouvre sous la barre de
navigation du `ShellRoute`, qui masque le bouton.

---

## 3. Vérifier

```bash
flutter pub get
flutter analyze lib
```

Test manuel : premier lancement → pastille → pop-up couvrant la barre basse →
« J'ai compris » → pastille disparue après redémarrage. Prendre un
rendez-vous → onglet Profil → le nom apparaît.
