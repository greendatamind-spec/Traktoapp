# 03 — MODÈLE DE DONNÉES

Deux niveaux : **Organisation > Projet**. Le SQL exécutable est dans `supabase/migrations/0001_init.sql`.

## Vue d'ensemble
- **Identité** : `organizations` · `profiles` (1-1 avec `auth.users`) · `memberships(role : patron | admin | conducteur)`.
- **Projet** : `projects` · `project_members` · `channels` (un seul par projet en v1 — contrainte d'unicité — mais table au pluriel pour l'avenir) · `messages`.
- **Documentaire** : `folders` (Plans/Rapports/Achats/PV créés d'office) · `documents` (`type_detecte`, `ocr_text`, `extraction_json`, `statut_validation`).
- **Photos** : `photos` (porte `project_id` ET `channel_id`, `lat`, `lng`, `taken_at`, pin plan : `plan_document_id`, `plan_page`, `plan_x`, `plan_y` en coordonnées relatives 0–1, et les 4 URLs de variantes) · `viewpoints` · `annotations`.
- **Suivi** : `tasks` · `reports` · `task_progress` (une ligne par tâche et par rapport — c'est l'historique d'avancement) · `report_photos`.
- **Réceptions** : `suppliers` · `materials` · `receptions` (liée au `document` bon de livraison) · `reception_lines`.
- **Agent** : `agent_threads` · `agent_messages` · `agent_runs` (trace de chaque exécution : agent, entrée, sortie, statut, tokens).
- **Monétisation (créées vides, aucun code v1)** : `plans` (offres tarifaires — rien à voir avec les plans PDF, qui sont des `documents`) · `subscriptions` · `agent_entitlements`.

## Règle RLS unique
> On voit un projet si on est **membre de l'organisation ET membre du projet**. Pas de droits par canal en v1.

Implémentation : deux fonctions `security definer` (`app.is_org_member`, `app.is_project_member`) pour éviter la récursion des policies, puis pour chaque table projet la même grille : SELECT/INSERT/UPDATE/DELETE réservés aux membres du projet. Les tables d'organisation (`suppliers`, `materials`) sont visibles de tous les membres de l'organisation. `profiles` : chacun lit les profils de ses collègues d'organisation, ne modifie que le sien. Gestion des membres et invitations : rôles `patron` et `admin` uniquement. Toutes les policies sont écrites table par table dans la migration.

⚠️ À TRANCHER : au-delà de la gestion des membres, faut-il des restrictions d'écriture par rôle (ex. seul le patron supprime un projet) ? V1 part sur : tout membre du projet écrit, patron/admin administrent.

## Stockage — les 4 variantes d'image
Quatre buckets Supabase Storage, chemin commun `org_id/project_id/photo_id.{ext}` :

| Bucket | Contenu | Exposition |
|---|---|---|
| `photos-originals` | Capture brute, sans filigrane | **Jamais exposée.** Aucune URL publique, aucune URL signée servie à l'UI. Conservée comme source pour retraitement uniquement. |
| `photos-watermarked` | Variante filigranée (GPS/date/projet/auteur) | Privée, servie par URL signée. C'est LA variante montrée dans le fil, la galerie et les exports PDF. |
| `photos-annotated` | Filigranée + annotations aplaties | Privée, URL signée. |
| `photos-thumbs` | Vignette de la filigranée | Privée, URL signée (cache long côté client). |

Décision : **aucun bucket public**. Des photos géolocalisées et horodatées de chantiers clients ne doivent pas être accessibles par URL devinable ; le coût des URLs signées est négligeable à 4–6 utilisateurs. Les documents (`documents-files`) suivent la même règle. Policies storage : lecture/écriture si membre du projet correspondant au chemin.

## Contraintes et index clés
- `channels.project_id UNIQUE` — verrouille « un canal par projet » au niveau base.
- `photos` : index `(project_id, taken_at desc)` (galerie), `(viewpoint_id, taken_at)` (séries), index partiel sur `(lat, lng)` non nuls (carte).
- `messages` : index `(channel_id, created_at desc)` (fil temps réel).
- `task_progress.pct` borné 0–100 ; unicité `(report_id, task_id)`.
- `documents.statut_validation` : `en_attente` → `valide`, jamais d'écriture directe en `valide` par l'OCR (confirmation humaine, W3).
- Suppression : projets et tâches s'archivent (`archived_at`), pas de cascade destructive ; les FK photos/rapports utilisent `on delete restrict`.
