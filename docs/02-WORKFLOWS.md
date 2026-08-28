# 02 — WORKFLOWS

Format : **Déclencheur → Étapes → Ce que voit l'utilisateur → Écrit en base → Cas d'erreur.**

## W1 — Création entreprise, projet, invitations
- **Déclencheur** : premier login d'un utilisateur sans organisation.
- **Étapes** : signup Supabase Auth → formulaire « Créer votre entreprise » → création projet (nom, adresse, position sur carte) → invitation des collègues par email avec choix du rôle (patron / admin / conducteur). L'invité qui accepte est ajouté à l'organisation ET aux projets cochés à l'invitation.
- **Voit** : wizard 3 écrans (entreprise → premier projet → invitations), puis l'écran principal avec le canal du projet vide.
- **Base** : `organizations`, `profiles`, `memberships(role)`, `projects`, `project_members`, `channels` (créé automatiquement, un par projet), `folders` (les 4 dossiers Plans/Rapports/Achats/PV créés d'office).
- **Erreurs** : email déjà membre → message « déjà dans l'entreprise » ; invitation expirée → renvoyer.
- ⚠️ À TRANCHER : invitation par email uniquement, ou aussi par téléphone/OTP (les conducteurs vivent sur mobile) ?

## W2 — Photo avec la caméra maison (F3–F5, F8)
- **Déclencheur** : bouton [📷] de la barre de saisie (mobile).
- **Étapes** : ouverture caméra Trakto (jamais le système) → capture → GPS + horodatage saisis à la prise → écran d'annotation immédiat (flèches, cercles, texte — skippable) → filigrane incrusté (GPS, date, projet, auteur) → génération des 4 variantes (originale, filigranée, annotée, vignette) → rattachement optionnel à une tâche ou un point de vue → envoi dans le fil.
- **Voit** : viseur plein écran, gros déclencheur (≥ 48 px), puis l'éditeur d'annotation, puis la photo dans le fil du canal.
- **Base** : `photos` (project_id, channel_id, lat, lng, taken_at, 4 URLs, task_id/viewpoint_id éventuels), `annotations`, `messages` (kind=photo).
- **Erreurs** : GPS refusé → photo acceptée, filigrane sans coordonnées, badge « sans position » ; pas de réseau → W11.

## W3 — Scan d'un document papier (F6, F16)
- **Déclencheur** : caméra en « mode document », ou upload d'un PDF/photo dans le Dossier.
- **Étapes** : capture → redressement + contraste → PDF → pipeline OCR via `POST /api/agents/run` : OCR + classification → type détecté (plan, PV, facture, bon…) → extraction → proposition de nom et de dossier cible → **confirmation humaine obligatoire** → rangement.
- **Voit** : aperçu redressé, puis une carte de proposition « Facture — Fournisseur X — ranger dans Achats ? [Confirmer / Modifier] ». Jamais d'écriture silencieuse.
- **Base** : `documents` (folder_id, type_detecte, ocr_text, extraction_json, statut_validation), `agent_runs`.
- **Erreurs** : OCR illisible → document rangé « à classer », sans extraction ; type incertain → l'utilisateur choisit le type.

## W4 — Point de vue récurrent et comparaison (F10)
- **Déclencheur** : depuis la caméra « nouveau point de vue », ou reprise d'un point de vue existant.
- **Étapes** : création : nom + première photo de référence. Reprise : la caméra affiche la photo de référence en surimpression fantôme pour retrouver le même cadrage → capture → la photo rejoint la série.
- **Voit** : liste des points de vue du projet, et pour chacun un curseur avant/après entre deux dates.
- **Base** : `viewpoints`, `photos.viewpoint_id`.
- **Erreurs** : point de vue sans nouvelle photo depuis 14 jours → simple badge « à reprendre » dans la liste (pas de notification).

## W5 — Pin d'une photo sur plan PDF (F11)
- **Déclencheur** : action « Positionner sur le plan » sur une photo, ou depuis la visionneuse de plan.
- **Étapes** : choix du plan (document du dossier Plans, rendu pdf.js) → choix de la page → tap à l'endroit voulu → pin enregistré.
- **Voit** : le plan avec des pins ; tap sur un pin → la photo s'ouvre.
- **Base** : `photos.plan_page`, `plan_x`, `plan_y` (coordonnées relatives 0–1) + référence au document plan.
- **Erreurs** : aucun plan dans le dossier → invite « Ajoutez un plan dans Dossier > Plans ».

## W6 — Carte du projet (F9)
- **Déclencheur** : onglet/vue Carte du projet.
- **Étapes** : Leaflet + OSM centré sur le projet → marqueurs des photos géolocalisées, regroupés en clusters → tap = vignette → photo.
- **Voit** : carte, clusters, compteur de photos sans position.
- **Base** : lecture seule de `photos(lat, lng)`.
- **Erreurs** : tuiles OSM inaccessibles hors ligne → message « carte indisponible sans réseau », la galerie reste utilisable.

## W7 — Tâches (F13)
- **Déclencheur** : section Tâches du panneau projet.
- **Étapes** : saisie libre d'une ligne (« Dalle R+1 ») → la tâche devient rattachable aux photos et alimente le formulaire de suivi. Réordonnable, archivable.
- **Voit** : liste simple, dernier % connu affiché à côté de chaque tâche.
- **Base** : `tasks` ; le % vient du dernier `task_progress`.
- **Erreurs** : suppression d'une tâche référencée → archivage (jamais de suppression physique), l'historique des rapports reste intact.

## W8 — Formulaire de suivi (F14, F15)
- **Déclencheur** : bouton [📄 rapport] dans la barre de saisie — aussi banal qu'envoyer une photo.
- **Étapes** : le formulaire s'ouvre **pré-rempli** : en-tête (projet, période du…au…, rédacteur auto) + dernier avancement connu de chaque tâche → le conducteur corrige : % / quantité / commentaire par tâche, moyens (effectif, matériel, jours d'intempérie, jours d'arrêt + motif), qualité et observations, photos de la période → statut → visa interne (qui a relu, quand) → le rapport apparaît dans le fil comme carte cliquable → export PDF (Puppeteer) via « Télécharger ».
- **Voit** : sections repliables, sauvegarde auto, bouton Télécharger.
- **Base** : `reports`, `task_progress` (une ligne par tâche), `report_photos`, `messages` (kind=rapport).
- **Erreurs** : brouillon jamais soumis → reste visible « brouillon » dans le panneau ; période chevauchant un rapport existant → avertissement non bloquant.
- ⚠️ À TRANCHER : qui a le droit de poser le visa — patron seul, ou tout membre du projet ?

## W9 — Brouillon par AI Rapporteur (F18)
- **Déclencheur** : l'utilisateur demande un rapport dans le chat AI Rapporteur (épinglé en haut de la liste des projets), ou ouvre le formulaire depuis ce chat.
- **Étapes** : requête → `POST /api/agents/run` (identité → droit → quota → registre → boucle modèle/outils → `agent_runs` → streaming) → l'agent lit, avec les droits Supabase **de l'utilisateur**, les photos, tâches, réceptions et messages de la période → il ouvre le formulaire DÉJÀ PRÉ-REMPLI → l'utilisateur corrige puis valide. L'agent ne rédige pas à la place de l'utilisateur : il propose, l'humain valide.
- **Voit** : streaming de la préparation, puis le formulaire pré-rempli (W8).
- **Base** : `agent_threads`, `agent_messages`, `agent_runs` ; le rapport n'est écrit que via W8 (validation humaine).
- **Erreurs** : quota atteint → message clair + formulaire vierge en repli ; échec modèle → formulaire pré-rempli avec les seuls derniers `task_progress` (sans synthèse).

## W10 — Bon de livraison → réception (F17)
- **Déclencheur** : W3 détecte le type « bon de livraison ».
- **Étapes** : extraction (fournisseur, date, articles, quantités) → écran de confirmation ligne à ligne → création de la RÉCEPTION → visible dans le projet et proposée dans le prochain formulaire de suivi.
- **Voit** : tableau éditable des lignes extraites, fournisseur en autocomplétion.
- **Base** : `suppliers` (créé si nouveau, après confirmation), `materials`, `receptions`, `reception_lines`, `documents` lié.
- **Erreurs** : quantités illisibles → lignes vides à saisir à la main ; fournisseur ambigu → choix manuel.

## W11 — Sans réseau (F7)
- **Déclencheur** : perte de réseau, fréquente sur chantier.
- **Étapes** : la caméra continue de fonctionner ; captures, annotations et brouillons stockés en local (Dexie.js) dans une file d'attente → au retour du réseau, envoi automatique dans l'ordre → les messages partent, les photos montent, le filigrane ayant été incrusté à la capture (GPS/heure du moment de la prise).
- **Voit** : badge « en attente d'envoi (n) » sur les éléments concernés ; jamais de blocage de la capture.
- **Base** : rien tant que hors ligne ; à la synchro : `photos`, `messages`, brouillons de `reports`.
- **Erreurs** : conflit (tâche archivée entre-temps) → l'élément part quand même, rattachement retiré avec mention ; échec d'envoi répété → l'élément reste en file, relance manuelle possible.
