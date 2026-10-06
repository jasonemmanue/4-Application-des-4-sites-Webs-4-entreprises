# Profil et pastille « acompte 50 % » — Eslie Sport

Refonte : 2026-10-06. Reprise de trois écrans d'Airbnb (Profil, accueil avec
pastille flottante, pop-up d'information), adaptés à la marque : navy
`#0F1724` et or `#FFD600`, thème sombre uniquement, photos de la salle.

Chemins relatifs à `eslie_sport_mobile/`.

---

## 1. Écran Profil (onglet ex-« Compte »)

Fichier : `lib/screens/more/more_screen.dart` — route `/more` inchangée.

| Bloc | Contenu | Action |
|---|---|---|
| En-tête | Cloche ronde + titre « Profil » | Cloche → snackbar « confirmations sur WhatsApp » |
| Carte d'identité | Avatar or pâle + initiale, nom, « Membre » | — |
| Carte photo 1 | Mes formules (`profil-formules.jpg`) | `/subscriptions` |
| Carte photo 2 | Planning des cours (`profil-planning.jpg`) | `/schedule` |
| Carte large | Séance découverte (`profil-decouverte.jpg`) | WhatsApp pré-rempli |
| Liste | Coachs, Équipements, Transformations, Articles, Vidéos, Avis, IMC, Contact | routes existantes |
| Pied | Carte ESLIE SPORT (adresse, téléphone, WhatsApp) | inchangée |

Les cartes ont un contour fin en plus de l'ombre : sur fond navy, l'ombre
seule ne détache pas la carte.

### D'où vient le nom ?

L'app **n'a pas de compte**. Le nom est celui saisi à la dernière inscription
à un cours (`enrollment_screen.dart`) ou commande de formule
(`subscription_order_screen.dart`), juste après la création côté API.

- Provider : `memberNameProvider` (`lib/services/member_profile.dart`)
- Stockage : `SharedPreferences`, clé `eslie_member_name`
- Sans inscription : icône, **« Visiteur »**, « Votre nom apparaîtra après
  votre première inscription »

### Photos

Copiées depuis `salle-de-sport/frontend/public/images/activites/`
(musculation, séance collective, boxe). Décodées à la taille affichée
(`cacheWidth`).

---

## 2. Pastille flottante + pop-up

Fichier : `lib/widgets/deposit_notice.dart`, posé en bas de l'accueil
(`home_screen.dart`).

- Pastille : étiquette or + « Réservez avec 50 % d'acompte ».
- Pop-up : croix, étiquette animée, « Payez 50 % maintenant pour réserver
  votre place, le reste se règle à la salle. », « Wave, Orange Money ou MTN
  MoMo. », bouton or « J'ai compris ».
- Lue une fois → masquée pour de bon (`depositNoticeVisibleProvider`, clé
  `eslie_deposit_notice_seen`).

Source de la règle : `salle-de-sport/DOCUMENTATION-PAIEMENT.md` (« Le solde
se règle à la salle »).

⚠️ L'ancienne pilule disait « Dépôt 50 % inclus dans le prix » — formulation
fausse (le dépôt n'est pas « inclus », c'est une avance sur le prix). Ne pas
y revenir.

⚠️ `useRootNavigator: true` : sans lui la feuille s'ouvre sous la barre de
navigation du `ShellRoute`, qui masque le bouton.

---

## 3. Chips de catégorie

`_ChipCategory` (`home_screen.dart`) passe du style « icône + soulignement » au
style pilule de la maquette : fond plein, contour, ombre douce ; la sélection
se lit au contour or de 2 px.

---

## 4. Vérifier

```bash
flutter analyze lib
```

Test manuel : premier lancement → pastille → pop-up couvrant la barre basse →
« J'ai compris » → pastille disparue après redémarrage. S'inscrire à un cours
→ onglet Profil → le nom apparaît.
