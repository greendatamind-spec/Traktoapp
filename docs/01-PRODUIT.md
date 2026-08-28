# 01 — PRODUIT

## Problème
Dans une PME BTP marocaine, le patron appelle son conducteur de travaux chaque jour : avancement, livraisons, problèmes, réceptions. L'information est dite, jamais écrite ; elle disparaît. Le groupe WhatsApp du chantier reste (ouvriers, chefs d'équipe), mais l'encadrement n'a ni canal structuré ni mémoire.

## Promesse
Trakto remplace l'appel quotidien. Le conducteur alimente en 3 minutes (photos filigranées, rapport pré-rempli par l'agent), le patron consulte sans appeler. Trakto est le canal de l'encadrement et la mémoire de ce qui s'y passe. Usage strictement interne — pas un outil de preuve juridique.

## Les 3 personas
| Persona | Comptes | Appareil | Ce qu'il fait | Ce qu'il y gagne |
|---|---|---|---|---|
| **Patron / chef de projet** | 1–2 | Desktop | Suit l'avancement, lit les rapports, ouvre les photos | Voit le chantier sans appeler |
| **Admin** | 1 | Desktop | Range les documents, traite les factures fournisseurs | Un dossier documentaire à jour, alimenté par l'OCR |
| **Conducteur de travaux** — LE PIVOT | 1–3 | Mobile | Alimente : photos, tâches, formulaire de suivi | 1) Il ne rédige plus rien : l'agent écrit, il corrige. 2) Une caméra meilleure que celle de son téléphone |

Les chefs d'équipe et ouvriers n'ont pas de compte : ils restent sur WhatsApp.

## Features v1 — liste FERMÉE
- **F1** Projets (organisation > projets, membres par projet)
- **F2** Un canal de chat par projet (un seul, sans sélecteur)
- **F3** Caméra maison (jamais l'appareil photo système)
- **F4** Photos géolocalisées + horodatées, filigrane GPS/date/projet/auteur incrusté
- **F5** Annotation photo dans le même geste que la capture
- **F6** Mode document (redressement, contraste, PDF)
- **F7** File d'attente offline (capture sans réseau, envoi différé)
- **F8** Galerie photos du projet
- **F9** Carte du projet (Leaflet/OSM, photos positionnées)
- **F10** Points de vue récurrents (même cadrage dans le temps → avant/après)
- **F11** Pin de photo sur plan PDF
- **F12** Dossier documentaire par projet (Plans / Rapports / Achats / PV)
- **F13** Liste de tâches en saisie libre
- **F14** Formulaire de suivi de chantier (unique, écrit en dur, pré-rempli)
- **F15** Export PDF du rapport
- **F16** OCR sur tout document entrant (avec confirmation humaine)
- **F17** Réception depuis bon de livraison (fournisseur, date, articles, quantités)
- **F18** AI Rapporteur (agent unique, chat épinglé au niveau application)

## Hors périmètre v1 — avec la raison
- Form builder — un seul formulaire suffit ; le builder tuerait la simplicité.
- Vue tableau type Airtable — consultation = fil + dossier, pas de grille.
- Planning — Trakto suit le réalisé, pas le prévisionnel.
- Automatisations — aucune écriture sans humain dans la boucle.
- Intégrations / SSO — 4 à 6 comptes stables, l'auth Supabase suffit.
- Multi-organisations — un utilisateur = une entreprise en v1.
- Comptes ouvriers — ils restent sur WhatsApp, c'est le positionnement.
- Vidéo — poids, réseau chantier, aucune demande du terrain.
- Gestion des achats (budget, rapprochement, règlements) — Trakto enregistre la réception, pas la comptabilité.
- Recherche comparative de prix — hors métier du produit.
- Preuve juridique / signature électronique — usage strictement interne.

## 3 critères de succès mesurables
1. **L'appel disparaît** : ≥ 1 rapport de suivi validé par projet actif et par semaine.
2. **La caméra porte l'adoption** : ≥ 80 % des photos d'un projet passent par la caméra Trakto (filigrane présent).
3. **L'agent fait gagner du temps** : durée médiane entre ouverture du brouillon pré-rempli et validation du rapport ≤ 5 minutes.
