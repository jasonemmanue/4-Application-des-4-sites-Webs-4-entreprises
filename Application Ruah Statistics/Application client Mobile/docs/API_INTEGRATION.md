# Intégration API cabinet-etudes

L'app mobile consomme **la même API FastAPI** que le site web et l'admin,
directement en production sur Railway :

```
https://api-production-bc863.up.railway.app/api/v1
```

C'est la valeur par défaut de `ApiConfig.baseUrl` — un build « nu »
(`flutter build apk --debug`) tape déjà la prod, sans qu'il soit nécessaire
de démarrer quoi que ce soit en local. Docker local reste disponible pour
itérer (`--dart-define=API_BASE_URL=http://10.0.2.2:8001/api/v1`, cf.
`docs/SETUP.md`).

Rapport des tests effectués contre le backend FastAPI local
(`http://localhost:8001/api/v1`) — les mêmes schémas sont servis en prod.

## Header `X-Client-Source`

Toutes les requêtes de l'app posent :

```
X-Client-Source: android
```

Le backend le lit dans `/leads/quote-request` et le stocke dans
`leads.source` (colonne existante, defaut `website`). L'admin distingue
alors les demandes de devis mobiles des demandes site web via une
pastille dans la liste et la colonne « Source » de l'export CSV/XLSX.

Absence de header = defaut backend `"website"` : le site web n'est pas
touche par ce changement (aucune modification cote frontend Next.js).

Toute valeur hors `{website, android, ios}` retombe sur `"website"` cote
backend, pour ne pas perdre un lead sur un header mal forme.

**Extensions prevues** (non encore livrees) : appliquer le meme mecanisme
aux POST `/contact`, `/testimonials/submit` et `/articles/{id}/download`,
ce qui necessite une migration Alembic pour ajouter la colonne `source`
aux tables `contacts`, `testimonials` et `article_downloads`.

## 1. Endpoints testés — statut

| Endpoint | Méthode | Statut | Notes |
|---|---|---|---|
| `/services` | GET | ✅ 200 | 5 services seedés |
| `/services/{slug}` | GET | ✅ 200 | Testé avec `etudes-de-faisabilite` |
| `/projects` | GET | ✅ 200 | Wrapper `{items:[...]}` |
| `/projects/{slug}` | GET | ✅ 200 | — |
| `/team` | GET | ✅ 200 | 4 consultants |
| `/team/{id}` | GET | ❌ **405** — non exposé | Contournement : filtrage côté client à partir de `/team` |
| `/key-figures` | GET | ✅ 200 | 4 chiffres |
| `/testimonials` | GET | ✅ 200 | 3 témoignages |
| `/testimonials/submit` | POST | ✅ | Schéma `TestimonialSubmit` |
| `/partners` | GET | ✅ 200 | 6 partenaires |
| `/videos` | GET | ✅ 200 | 2 vidéos |
| `/articles` | GET | ✅ 200 | Wrapper `{items:[...]}` |
| `/articles/{slug}` | GET | ✅ 200 | — |
| `/articles/{id}/download` | POST | ✅ | Schéma `DownloadRequest` (WhatsApp) |
| `/leads/quote-request` | POST | ✅ | Schéma `QuoteRequest` (WhatsApp) |
| `/contact` | POST | ✅ | Schéma `ContactCreate` (WhatsApp) |
| `/settings` | GET | ⚠️ 401 (auth admin) | **Retiré** du client — ne pas appeler depuis l'app |

## 2. Divergences entre CLAUDE.md et l'API réelle — corrigées

Le CLAUDE.md décrivait des schémas basés sur `email` / `phone`. L'API réelle
utilise **WhatsApp partout** (migration `c8d3f9e7b201`). Modèles Flutter
réécrits en conséquence.

### 2.1 Renommages de champs (GET responses)

| Modèle | CLAUDE.md initial | API réelle → utilisé dans le code |
|---|---|---|
| Service | `cover_image` / `summary` | `image_url`, `description` |
| Project | `client` | `client_name`, `client_logo_url` |
| Project | `cover_image` / `gallery` / `figures` | `images` (liste) |
| TeamMember | `role` / `photo` / `linkedin` / `email` | `title_position`, `photo_url`, `linkedin_url` (pas d'email dans le seed) |
| Testimonial | `author` / `role` / `company` / `message` / `photo` | `client_name`, `client_position`, `client_company`, `quote`, `client_photo_url`, `client_whatsapp` |
| Partner | `logo` / `website` | `logo_url`, `website_url`, `partner_type` |
| Video | `url` / `thumbnail` / `category` | `video_url`, `thumbnail_url`, `video_type` |
| Article | `type` / `cover_image` / `download_url` | `article_type`, `cover_image_url`, `file_url`, `author` (objet imbriqué) |

Les anciens noms restent disponibles en **getters de compatibilité** dans les
modèles Dart pour éviter de casser les widgets.

### 2.2 Corps des POST (formulaires)

| Formulaire | Schéma envoyé |
|---|---|
| Contact | `{ name, whatsapp_number, message, subject?, company? }` |
| Devis | `{ name, whatsapp_number, message?, company?, mission_type?, budget_range?, timeline? }` |
| Témoignage | `{ client_name, client_whatsapp, quote, rating, client_position?, client_company? }` |
| Livre blanc | `{ whatsapp_number, name?, company? }` |

**Aucun champ email n'est envoyé** — confirme la ligne éditoriale « WhatsApp remplace l'email ».

### 2.3 Ajustements UX en conséquence

- Écran **Contact** : champ Email supprimé, remplacé par « Numéro WhatsApp * »
- Écran **Devis** (étape 3) : champs Email et Téléphone supprimés, remplacés par un unique « Numéro WhatsApp * »
- Écran **Témoignages** (bottom sheet de soumission) : ajout du champ « Numéro WhatsApp * »
- Modal **Téléchargement livre blanc** : champ Email remplacé par « Numéro WhatsApp * » ; nom devient optionnel

## 3. Configuration Docker

Un `docker-compose.override.yml` a été ajouté dans `cabinet-etudes/` pour
retirer `uvicorn --reload` (crash `watchfiles: Cannot allocate memory` sous
WSL2). Sans cela, l'API démarre puis meurt en 1-2 secondes.

Migrations et seed exécutés une fois via :
```bash
docker exec cabinet-etudes-api-1 alembic upgrade head
docker exec cabinet-etudes-api-1 python seed.py
```

## 4. Prochaines évolutions API à demander à l'équipe backend

Ces endpoints seraient utiles mais **n'existent pas** aujourd'hui — l'app
fonctionne sans, mais les évolutions suivantes améliorent l'UX :

- `GET /api/v1/team/{id}` — évite le fetch complet + filtrage côté client
- `POST /api/v1/notifications/register` — inscription du token FCM par l'app
- Webhook interne « nouveau devis » → push FCM au staff
- Webhook interne « devis répondu » → push FCM au client
- `GET /api/v1/settings/public` — settings publics accessibles sans auth
  (adresse, horaires, réseaux sociaux) — actuellement `/settings` est
  admin-only
