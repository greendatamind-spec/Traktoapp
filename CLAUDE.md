# CLAUDE.md — Trakto

## Le produit en 3 phrases
Trakto est une PWA de suivi de chantier pour PME du BTP au Maroc : elle remplace l'appel quotidien patron → conducteur de travaux, pas le groupe WhatsApp.
Le conducteur alimente depuis le terrain (caméra maison, rapport pré-rempli par l'AI Rapporteur), le patron et l'admin consultent sur desktop sans appeler.
Usage strictement interne : aucune valeur probante, aucune signature électronique — n'introduis jamais ces sujets.

## Les 5 règles absolues
1. Pas de comptes ouvriers ni chefs d'équipe. 4 à 6 comptes par entreprise : patron, admin, conducteurs.
2. UN SEUL canal de chat par projet. Pas de sélecteur de canal, pas de membres par canal, pas de RLS croisées.
3. UN SEUL formulaire : le suivi de chantier, écrit en dur. PAS DE FORM BUILDER, JAMAIS.
4. UN SEUL agent : AI Rapporteur, chat épinglé au niveau application. Il ouvre le formulaire DÉJÀ PRÉ-REMPLI — l'utilisateur corrige, il ne rédige pas.
5. La caméra maison est LE différenciateur : photo + annotation dans le même geste, filigrane GPS/date/projet/auteur incrusté, mode document, file offline, rattachement tâche ou point de vue. Elle N'OUVRE JAMAIS l'appareil photo du système.

## Stack figé — ne pas rediscuter
Next.js 15 App Router · TypeScript · Tailwind · shadcn/ui · Supabase (Postgres/Auth/Storage/Realtime/RLS) · Vercel · Leaflet + OpenStreetMap · Konva.js ou fabric.js (⚠️ à trancher avant B2) · Dexie.js · pdf.js · Puppeteer · Vercel AI SDK + Zod · next-pwa.

## Règles de code
- Server Component par défaut. `"use client"` uniquement si interaction le justifie.
- Aucune clé API côté client. Les secrets vivent dans les variables d'env serveur.
- Toute nouvelle table = migration SQL + policies RLS **dans le même commit**.
- Règle agent 1 : TOUT appel à un modèle IA passe par `POST /api/agents/run`, l'OCR compris. Jamais de fetch direct vers un fournisseur ailleurs dans le code.
- Règle agent 2 : les outils agent s'exécutent avec le client Supabase DE L'UTILISATEUR CONNECTÉ, jamais la `service_role` key.
- Ajouter un agent = ajouter un fichier de définition dans le registre. Rien d'autre.
- Pas de nouvelle dépendance sans demander.
- Terrain : cibles tactiles ≥ 48 px, contraste élevé (une main, des gants, plein soleil).
- Mobile-first sur tout ce qui alimente, desktop-first sur tout ce qui consulte.

## Conventions de nommage
- Tables : snake_case, pluriel (`photos`, `task_progress`). Colonnes : snake_case.
- Migrations : `supabase/migrations/NNNN_description.sql`.
- Composants : PascalCase ; fichiers : kebab-case ; routes App Router en français (`/projets/[id]`).
- UI, commits, docs : en français.

## Ce qu'on ne fait JAMAIS
- Form builder, vue tableau type Airtable, planning, automatisations, intégrations/SSO, multi-organisations, vidéo, gestion des achats (budget/règlements), comparaison de prix, preuve juridique.
- Ouvrir l'appareil photo du système.
- Écrire en base depuis l'OCR sans confirmation humaine explicite.
- Utiliser `service_role` dans le runtime agent ou côté requête utilisateur.
- Créer un deuxième canal, un deuxième formulaire ou un deuxième agent.

## Commandes
- `npm run dev` · `npm run build` · `npm run lint` · `npm run typecheck`
- `npx supabase start` (local) · `npx supabase db push` (migrations) · `npx supabase gen types typescript`
