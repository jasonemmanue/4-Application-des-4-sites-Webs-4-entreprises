# Profil et pastille « Aucun frais caché » — app client

Application client mobile CHIC RESIDENCE. Refonte : 2026-10-06.

Reprise de trois écrans d'Airbnb (Profil, Explorer avec pastille de prix,
pop-up d'information), adaptés à la marque : rouge `#DC2626` au lieu du rose,
prix en FCFA, photos réelles des logements.

---

## 1. Écran Profil

Fichier : [`lib/screens/profile/profile_screen.dart`](../Application%20client%20Mobile/lib/screens/profile/profile_screen.dart)

| Bloc | Contenu | Action |
|---|---|---|
| En-tête | Cloche ronde + titre « Profil » | Cloche → snackbar « confirmations sur WhatsApp » |
| Carte d'identité | Avatar vert pâle + initiale, nom, « Voyageur » | — |
| Carte photo 1 | Mes réservations (`profil-reservations.jpg`) | `/bookings` |
| Carte photo 2 | Mes favoris (`profil-favoris.jpg`) | `/favorites` |
| Carte large | Proposer votre logement (`profil-proposer.jpg`) | WhatsApp pré-rempli |
| Liste | Paramètres, aide, apparence, mentions légales, version | inchangé |

### D'où vient le nom ?

L'app **n'a pas de compte**. Le nom affiché est celui saisi à la dernière
réservation faite depuis l'appareil :

- `BookingTunnel._submitAndPay` appelle `SessionService.setGuestName()` après
  la création de la réservation ;
- stockage `SharedPreferences`, clé `chic_guest_name` (`ApiConfig.guestNameKey`) ;
- lu par `guestNameProvider` (`providers.dart`).

Sans réservation : avatar icône personne, nom **« Visiteur »**, sous-titre
« Votre nom apparaîtra après votre première réservation ».

### Photos

Les trois vignettes (`assets/images/profil-*.jpg`) sont copiées depuis le site
web (`residences-meublees/frontend/public/images/residences/`). Pour les
changer, remplacer les fichiers en gardant les noms. Elles sont décodées à la
taille affichée (`cacheWidth`) : inutile de les réduire à la main.

### Badges « NOUVEAU »

Volontairement absents : affichés en permanence, ils seraient trompeurs.

---

## 2. Pastille flottante + pop-up

Fichier : [`lib/widgets/fees_notice.dart`](../Application%20client%20Mobile/lib/widgets/fees_notice.dart)

- `FeesNoticePill` est posée en bas de l'Explorer (`home_screen.dart`, dans un
  `Stack`). Apparition en fondu + glissement.
- Un tap ouvre `showFeesNoticeSheet` : bottom sheet arrondi, croix, étiquette
  de prix dessinée (icône `sell_rounded` rouge + carte grise décalée), texte,
  bouton noir « J'ai compris » (`tokens.ctaBg`, s'inverse en sombre).
- Fermée d'une façon ou d'une autre, la pastille disparaît **pour de bon** :
  clé `chic_fees_notice_seen` (`ApiConfig.feesNoticeSeenKey`).

### ⚠️ Le libellé n'est pas celui d'Airbnb

Airbnb écrit « Les prix comprennent tous les frais ». Ce serait **faux** ici :
le prix par nuit des cartes est `base_price_per_night`, **hors** frais de
service de 5 % ajoutés par `POST /bookings/calculate-price`. Le texte promet
ce qui est vrai :

- pastille : « Aucun frais caché » ;
- pop-up : « Aucune surprise : le total, frais de service inclus, s'affiche
  avant de payer. »

Si un jour les cartes affichent un prix frais compris, le libellé Airbnb
redevient possible.

### ⚠️ `useRootNavigator: true` est obligatoire

Sans lui, la feuille s'ouvre dans le navigateur du `ShellRoute` : la barre de
navigation basse reste visible par-dessus, non assombrie, et cache le bouton.

---

## 3. Correctifs Explorer livrés avec la refonte

- **Prix coupé sur les cartes horizontales.** La carte (260 px) mesure ≈ 317 px
  de haut ; le carrousel en réservait 286. Hauteur passée à 324.
- **Seconde section vide.** Avec 5 logements en production, `take(6)` les
  mettait tous dans « Résidences populaires » et « Idéales pour votre prochain
  séjour » restait un titre seul. Le carrousel prend désormais la moitié du
  catalogue (6 max dès 12 logements) et la section est masquée si elle est vide.

---

## 4. Vérifier

```bash
flutter analyze lib
```

Test manuel : premier lancement → pastille visible → tap → pop-up couvrant la
barre basse → « J'ai compris » → pastille disparue, et toujours absente après
redémarrage. Faire une réservation → onglet Profil → le nom apparaît.
