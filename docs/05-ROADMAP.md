# 05 — ROADMAP (12 semaines, 5 blocs)

Le bloc 2 est le plus long et c'est justifié : la caméra est le différenciateur — ne jamais le rogner. Les blocs 4 et 5 sont la variable d'ajustement si le calendrier glisse.

## B1 — Fondations (S1–S2)
Setup Next.js 15 + Supabase, auth, migration `0001_init.sql`, onboarding entreprise/projet/invitations, PWA installable.
**Critère de fin** : un patron crée son entreprise et un projet, invite un conducteur qui installe la PWA sur son téléphone et se connecte.

## B2 — LA CAMÉRA CHANTIER (S3–S7)
Capture, GPS, horodatage, filigrane incrusté, annotation dans le même geste, mode document, file offline (Dexie.js), galerie, carte (Leaflet/OSM), points de vue récurrents, pin sur plan PDF.
**Critère de fin** : sur chantier sans réseau, un conducteur capture une photo annotée depuis un point de vue existant, elle part seule au retour du réseau avec filigrane GPS/date/projet/auteur, et se retrouve dans la galerie, sur la carte et pinnée sur le plan.

## B3 — Canal, coquilles, dossier, tâches, formulaire (S8–S9)
Le canal unique par projet (Realtime), mise en page desktop 3 colonnes et mobile 3 onglets, barre de saisie, dossier documentaire (4 dossiers), tâches en saisie libre, formulaire de suivi pré-rempli, export PDF (Puppeteer).
**Critère de fin** : un conducteur remplit un rapport pré-rempli du dernier avancement connu depuis le bouton [📄], le patron le lit en carte dans le fil et télécharge le PDF.

## B4 — Runtime agent + AI Rapporteur (S10–S11)
`POST /api/agents/run` (identité → droit → quota → registre → boucle modèle/outils → `agent_runs` → streaming), outils avec le client Supabase de l'utilisateur, chat épinglé.
**Critère de fin** : depuis le chat épinglé, l'AI Rapporteur ouvre le formulaire pré-rempli à partir des photos, tâches et réceptions de la période, et l'utilisateur valide en moins de 5 minutes.

## B5 — Pipeline OCR, bon de livraison uniquement (S12)
Scan → OCR + classification → extraction → confirmation humaine → réception créée. Les autres types de documents sont rangés sans extraction (elle arrivera après v1).
**Critère de fin** : un bon de livraison photographié devient une réception confirmée (fournisseur, date, lignes) qui apparaît dans le prochain formulaire de suivi.
