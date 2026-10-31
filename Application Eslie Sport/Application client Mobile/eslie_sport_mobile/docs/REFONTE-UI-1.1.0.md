# Refonte UI/UX — version 1.1.0

Refonte d'apres la maquette fournie : fond creme, vert, orange, jaune. Le logo
existant (`assets/images/logo.png`) reste en haut a gauche de l'accueil.

## Ecrans

| Ecran | Contenu | Donnees |
|-------|---------|---------|
| Accueil | Logo, hero « Reserver une seance », acces rapides, prochain cours, tarifs, coachs, transformations | `/schedule`, `/subscriptions`, `/coaches`, `/transformations` |
| Activites | « Trouve ton rythme », filtres ronds, lignes photo + fleche | `/activities` |
| Planning | 7 prochains jours, cartes de cours, places restantes, acompte, horaires | `/schedule`, `/enrollments/slot/{id}/availability`, `/settings/public` |
| Abonnements | Lignes de formules, mensualite « Populaire », groupes par discipline | `/subscriptions` |
| Profil | Identite locale, WhatsApp, rubriques, coordonnees | `/settings/public` |

## Volontairement different de la maquette

La maquette montre des donnees que l'application ne possede pas. Elles n'ont pas
ete simulees :

- **Cloche de notifications** : il n'existe pas de centre de notifications.
- **Progression, visites, « membre depuis »** : il n'y a pas de compte membre.
- **Photo de profil** : remplacee par l'initiale du nom saisi a l'inscription.
- **Photo du hero** : photo reelle du site (Unsplash, voir les credits du site),
  a remplacer par une photo de la salle si elle est disponible.

## Logos de paiement

`assets/images/paiement/` : Wave, Orange Money et MTN (fichiers du site web),
Visa et Mastercard. Sources dans `CREDITS.md`.

## Correctifs de fonctionnement

| Probleme | Effet avant | Correction |
|----------|-------------|------------|
| `payment_type` absent de la reservation | Place prise sans paiement, puis `POST /payments/init` en 409 : aucun acompte de cours ne pouvait aboutir | Choix de la formule a l'etape 2 |
| Date libre, sans lien avec le creneau | Reservation possible un autre jour que celui du cours | Seules les dates du jour du creneau sont proposees |
| `DateFormat` `fr_FR` sans initialisation | Exception a l'affichage de l'etape 2 | Formatage de date sans dependance a la locale |
| `opening_hours` lu comme une map | Erreur de chargement des parametres | Lu comme une chaine, affiche dans l'app |
| Filtres `souplesse`, `arts_martiaux`, `danse`, `debutant`... | Filtres toujours vides | Valeurs reelles du back-office |
| Prefixes `07` et `05` uniquement | Numeros Orange 08/09 et MTN 06/04 refuses | Memes plages que le backend |
| Renvoi USSD ignorant la nouvelle reference | Attente figee sur un paiement abandonne | L'ecran suit la nouvelle reference |
| Compte a rebours fixe de 60 s | Ne correspondait pas a la session de 300 s | `expires_in` du serveur |
| Fin d'attente sans verdict | Ecran bloque | Message et bouton « verifier maintenant », relecture au retour du navigateur |
| Nouvel essai de paiement | Reservation en double au back-office | La reservation deja creee est reutilisee |
| Creneau ou formule introuvable | Le premier de la liste etait reserve a la place | Message d'erreur |
| Videos sans fichier en ligne | Page 404 | Message « bientot disponible » |

## Lien avec le back-office

Toutes les donnees viennent de l'API partagee avec le site et l'admin. Les
reservations et souscriptions portent `X-Client-Source: mobile`, affiche par le
badge de source de l'admin. Aucun changement du backend n'a ete necessaire.

## Limites connues

- Les 5 videos en base pointent vers des fichiers absents (`musculation-demo.mp4`...) :
  a televerser depuis le back-office.
- Les push FCM ne sont pas relies au backend (pas d'endpoint d'enregistrement du token).
