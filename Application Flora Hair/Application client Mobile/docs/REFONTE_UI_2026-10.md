# Refonte UI/UX et fiabilisation des paiements — v1.1.0+2 (2026-10-31)

## Identité visuelle

Maquette de référence : cinq écrans (Accueil, Prestations, Détail, Réservation,
Mon espace) en bordeaux, rose poudré et or sur fond crème rosé.

| Rôle | Constante (`lib/config/theme.dart`) | Valeur |
|------|-------------------------------------|--------|
| Accent principal | `FloraColors.burgundy` (alias `lime`) | `#6B1F3A` |
| Rose poudré | `FloraColors.blush` / `blushLight` | `#F4C9CE` / `#FBE8E6` |
| Or | `FloraColors.gold` | `#D9A441` |
| Brun | `FloraColors.cocoa` | `#3E2723` |
| Fond | `FloraColors.background` | `#FFF7F1` |

Typographie : DM Sans, Allura pour le mot « beauté. » de l'accueil, Playfair
Display pour le nom du salon à côté du logo. Ces polices sont téléchargées au
premier lancement (`google_fonts`).

**Le logo reste celui du salon** (doré, `assets/branding/logo_mark.png`, le même
fichier que l'en-tête du site), en haut à gauche de l'accueil. Le logo bordeaux
de la maquette n'a pas été repris.

Les écrans secondaires (Équipe, Articles, Vidéos, Avis, Devis, Formations,
Contact, Galerie) n'ont pas été réécrits : ils héritent de la palette par les
alias historiques de `FloraColors`.

## Navigation

Barre basse : **Accueil · Prestations · Réserver · Favoris · Profil**.
La Galerie sort des onglets : elle s'ouvre depuis l'accueil et « Mon espace ».

| Écran | Fichier | Ce qui change |
|-------|---------|---------------|
| Accueil | `screens/home/` | Logo, accroche, recherche, catégories de l'API, bandeau des tendances (galerie), prestations, inspirations, équipe, conseils |
| Prestations | `screens/services/services_screen.dart` | Filtres, cartes avec durée, prix et bouton « Choisir » |
| Détail | `screens/services/service_detail_screen.dart` | Photo pleine largeur, favori, note, styles similaires |
| Réservation | `screens/booking/` | **3 étapes** : Prestation, Créneau, Confirmation |
| Favoris | `screens/favorites/` | Nouveau, conservé sur l'appareil |
| Mes rendez-vous | `screens/appointments/` | Nouveau : à venir / historique, payer, annuler |
| Mon espace | `screens/more/more_screen.dart` | Prochain rendez-vous, accès rapides, salon, rubriques |

## Ce qui est volontairement différent de la maquette

Aucune donnée n'est inventée :

- **Note « 4,9 »** : c'est la moyenne réelle des avis approuvés du salon, avec le
  nombre d'avis. L'API ne note pas chaque prestation.
- **Pastille de la cloche** : le nombre de rendez-vous à venir sur l'appareil. La
  cloche ouvre « Mes rendez-vous », il n'y a pas de centre de notifications.
- **Experte sur la fiche prestation** : l'API ne relie pas prestation et
  coiffeuse, le choix se fait à la réservation.
- **Horaires** : ceux du salon, plus précis que « Lun – Sam : 8h – 20h ».
- **Photo de profil et engrenage** : absents, l'application n'a pas de compte.
- **Photos** : celles de l'administration. Une prestation sans image affiche une
  vignette de marque.

## Moyens de paiement

Images dans `assets/paiement/`, déclarées dans `pubspec.yaml`.

| Moyen | Fichier | Origine |
|-------|---------|---------|
| Wave | `wave.png` | Site du salon (logo officiel) |
| Orange Money | `orange-money.png` | Site du salon, SVG Wikimedia converti en PNG |
| MTN MoMo | `mtn-momo.png` | Logo MoMo de l'application Chic Residence |
| Carte | `carte-bancaire.png` | Site du salon : **pictogramme, pas un fichier officiel Visa/Mastercard** |

La liste des moyens vient de `GET /payments/config` : couper la carte avec
`PAYMENT_CARD_ENABLED` la retire aussi de l'application. Si le paiement en ligne
n'est pas configuré, le rendez-vous s'enregistre et l'acompte se règle au salon.

## Bugs de paiement corrigés

| Bug | Conséquence avant correctif | Correctif |
|-----|-----------------------------|-----------|
| Statut `succeeded` non reconnu | Une cliente qui avait payé restait bloquée puis voyait un échec | Reconnu, et l'écran de résultat relit l'état réel |
| Lien Wave jamais ouvert | Le paiement Wave ne pouvait pas aboutir | Navigateur externe, comme l'exige Wave |
| Préfixes 07/05 imposés | Numéros portés refusés alors que le backend les accepte | Dix chiffres, même règle que le backend |
| `payment_method` non envoyé | Une demande abandonnée n'expirait jamais et bloquait le créneau | `Payement electronique` ou `Espèce` |
| Second `POST /bookings` après un refus de paiement | « Créneau déjà réservé » à cause de sa propre demande | La réservation créée est réutilisée |
| Erreurs de paiement masquées | Toujours « Une erreur est survenue » | Message du backend affiché |
| Aucune relance | L'écran proposait de réessayer sans bouton | Relance, changement de moyen, renvoi de la demande |
| Prestation choisie perdue | « Réserver » repartait de zéro | Prestation présélectionnée |
| Heures passées proposées | Créneaux d'aujourd'hui déjà dépassés | Filtrés |

## Lien avec le back-office

```
App ── POST /bookings, /reviews, /contact, /quotes ──► API ──► Admin
       en-tête X-App-Source: android/1.1.0+2                   (badge « Android »)
App ◄── GET /bookings/{id}/status ── API ◄── confirmation / annulation dans l'Admin
App ◄── GET /payments/config ─────── API ◄── moyens ouverts
```

`GET /bookings/{id}/status` est **nouvelle** : sans compte, l'application ne
pouvait pas savoir qu'un rendez-vous avait été confirmé ou annulé par le salon.
Elle ne renvoie aucune donnée personnelle, et les versions précédentes de
l'application ne l'appellent pas.

## Vérifications

- `flutter test` : contrat de paiement, logos, version, et rendu des écrans refondus
  à 360 × 740 (sans débordement).
- `pytest tests/test_booking_status.py tests/test_payments.py` côté backend.

**Non vérifié par ces tests** : le rendu sur un vrai téléphone, et un paiement réel
de bout en bout (argent réel). Voir la recette ci-dessous.

## Recette à faire sur téléphone

1. Accueil : logo doré en haut à gauche, polices et photos chargées.
2. Réserver une prestation jusqu'au paiement, avec un petit montant réel.
3. Wave : l'application Wave s'ouvre, et au retour l'écran passe à « confirmé ».
4. Orange ou MTN : la demande arrive, « Renvoyer la demande » fonctionne.
5. Admin : le rendez-vous porte le badge Android. Le confirmer : « Mes rendez-vous »
   affiche « Confirmé » après rafraîchissement.
