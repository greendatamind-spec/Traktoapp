# 06 — ARCHITECTURE DU CODE

> Nommé 06 (et non 04 comme prévu initialement) : 04-UI-SPEC.md existait déjà.

## Structure des dossiers
```
app/                    Routes App Router (en français côté app : /projets)
  login/  signup/       Pages d'auth (client components, mobile-first)
  auth/callback/        Échange du code des liens e-mail contre une session
  auth/deconnexion/     POST de déconnexion
  projets/              Écran d'accueil connecté (Server Component)
  layout.tsx            Coquille racine (lang=fr, manifest PWA, tokens)
  globals.css           LES TOKENS DE DESIGN (variables CSS, source unique)
components/
  ui/                   Primitives shadcn/ui (button, input, label, card)
  features/             Composants métier (vide en B1, se remplit par bloc)
lib/
  supabase/             Les 3 clients : client.ts (navigateur), server.ts
                        (Server Components/Actions), middleware.ts (session)
  utils.ts              cn() et utilitaires transverses
types/
  db.ts                 Types de la base, écrits à la main depuis 0001_init.sql
                        (à remplacer par `supabase gen types` dès que possible)
supabase/migrations/    Migrations SQL numérotées, RLS dans le même fichier
public/                 manifest.webmanifest, icons/ (placeholders à remplacer)
middleware.ts           Protège tout sauf /login, /signup, /auth/*
```

## Décisions structurantes
- **Server Component par défaut.** `"use client"` uniquement là où il y a
  interaction (formulaires d'auth). `/projets` est un Server Component.
- **Auth** : e-mail + mot de passe et lien magique, via `@supabase/ssr`
  (flux PKCE, cookies gérés par le middleware). La protection des routes vit
  dans `lib/supabase/middleware.ts` — une seule liste `PUBLIC_PATHS`.
- **Tokens de design** : les valeurs vivent dans `globals.css` (variables CSS),
  `tailwind.config.ts` ne fait que les exposer. Accent orange chantier
  (`#d9640a`), mode clair uniquement. Cibles tactiles : `min-h-touch` (48 px)
  câblé dans les primitives ui — un bouton ne peut pas être trop petit par accident.
- **PWA** : `next-pwa` génère le service worker au build de production
  uniquement ; manifest statique dans `public/`, icônes placeholder (T orange).
- **Secrets** : seules 2 variables, toutes deux publiques par conception
  (`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`). La sécurité
  repose sur RLS. Aucune variable `service_role` dans ce dépôt, volontairement.
