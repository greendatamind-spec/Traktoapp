-- ============================================================================
-- 0001_init.sql — Trakto : schéma initial complet
-- Règle RLS unique : on voit un projet si on est membre de l'organisation
-- ET membre du projet. Pas de droits par canal en v1.
-- ============================================================================

create extension if not exists pgcrypto;

-- Enums ----------------------------------------------------------------------
create type org_role        as enum ('patron', 'admin', 'conducteur');
create type report_status   as enum ('brouillon', 'soumis', 'vise');
create type doc_validation  as enum ('en_attente', 'valide');
create type message_kind    as enum ('texte', 'photo', 'document', 'rapport', 'systeme');

-- ============================================================================
-- IDENTITÉ
-- ============================================================================

create table organizations (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  created_at  timestamptz not null default now()
);

-- 1-1 avec auth.users, créé par trigger au signup.
create table profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  full_name   text not null default '',
  phone       text,
  created_at  timestamptz not null default now()
);

create table memberships (
  org_id      uuid not null references organizations (id) on delete cascade,
  user_id     uuid not null references profiles (id) on delete cascade,
  role        org_role not null default 'conducteur',
  created_at  timestamptz not null default now(),
  primary key (org_id, user_id)
);

-- ============================================================================
-- PROJET
-- ============================================================================

create table projects (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references organizations (id) on delete cascade,
  name        text not null,
  address     text,
  lat         double precision,
  lng         double precision,
  archived_at timestamptz,               -- on archive, on ne supprime pas
  created_at  timestamptz not null default now()
);
create index projects_org_idx on projects (org_id);

create table project_members (
  project_id  uuid not null references projects (id) on delete cascade,
  user_id     uuid not null references profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (project_id, user_id)
);

-- ============================================================================
-- HELPERS RLS (security definer : évite la récursion entre policies)
-- ============================================================================
create schema if not exists app;

create or replace function app.is_org_member(p_org uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from memberships m
    where m.org_id = p_org and m.user_id = auth.uid()
  );
$$;

create or replace function app.is_org_admin(p_org uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1 from memberships m
    where m.org_id = p_org and m.user_id = auth.uid()
      and m.role in ('patron', 'admin')
  );
$$;

-- Membre du projet = membre de l'organisation ET membre du projet.
create or replace function app.is_project_member(p_project uuid)
returns boolean language sql security definer stable set search_path = public as $$
  select exists (
    select 1
    from projects p
    join project_members pm on pm.project_id = p.id and pm.user_id = auth.uid()
    join memberships m     on m.org_id = p.org_id  and m.user_id = auth.uid()
    where p.id = p_project
  );
$$;

-- org d'un projet (pour les policies des tables filles)
create or replace function app.project_org(p_project uuid)
returns uuid language sql security definer stable set search_path = public as $$
  select org_id from projects where id = p_project;
$$;

-- ============================================================================
-- CANAL & DOSSIER
-- ============================================================================

create table channels (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects (id) on delete cascade,
  name        text not null default 'Chantier',
  created_at  timestamptz not null default now(),
  unique (project_id)   -- UN SEUL canal par projet en v1, verrouillé en base
);

create table folders (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects (id) on delete cascade,
  name        text not null,              -- Plans / Rapports / Achats / PV, créés d'office
  created_at  timestamptz not null default now(),
  unique (project_id, name)
);

create table documents (
  id                uuid primary key default gen_random_uuid(),
  project_id        uuid not null references projects (id) on delete cascade,
  folder_id         uuid references folders (id) on delete set null,
  uploaded_by       uuid not null references profiles (id),
  name              text not null,
  file_url          text not null,        -- chemin dans le bucket documents-files (privé)
  mime_type         text,
  type_detecte      text,                 -- plan, pv, facture, bon_livraison…
  ocr_text          text,
  extraction_json   jsonb,
  statut_validation doc_validation not null default 'en_attente', -- jamais 'valide' sans humain (W3)
  created_at        timestamptz not null default now()
);
create index documents_project_idx on documents (project_id, created_at desc);

-- ============================================================================
-- TÂCHES, POINTS DE VUE, PHOTOS
-- ============================================================================

create table tasks (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects (id) on delete cascade,
  label       text not null,              -- saisie libre
  position    int  not null default 0,
  archived_at timestamptz,                -- archivage, jamais de suppression (W7)
  created_at  timestamptz not null default now()
);
create index tasks_project_idx on tasks (project_id, position);

create table viewpoints (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid not null references projects (id) on delete cascade,
  name        text not null,
  created_at  timestamptz not null default now()
);

create table photos (
  id               uuid primary key default gen_random_uuid(),
  project_id       uuid not null references projects (id) on delete cascade,
  channel_id       uuid not null references channels (id) on delete restrict,
  author_id        uuid not null references profiles (id),
  task_id          uuid references tasks (id) on delete set null,
  viewpoint_id     uuid references viewpoints (id) on delete set null,
  lat              double precision,
  lng              double precision,
  taken_at         timestamptz not null,  -- horodatage de la CAPTURE (peut précéder l'upload, offline)
  -- pin sur plan PDF : coordonnées relatives 0–1 sur une page d'un document plan
  plan_document_id uuid references documents (id) on delete set null,
  plan_page        int,
  plan_x           double precision check (plan_x is null or (plan_x >= 0 and plan_x <= 1)),
  plan_y           double precision check (plan_y is null or (plan_y >= 0 and plan_y <= 1)),
  -- les 4 variantes (chemins de bucket ; voir stratégie de stockage plus bas)
  original_url     text not null,         -- JAMAIS exposée à l'UI
  watermark_url    text not null,         -- la variante de référence (fil, galerie, PDF)
  annotated_url    text,
  thumb_url        text not null,
  created_at       timestamptz not null default now()
);
create index photos_gallery_idx   on photos (project_id, taken_at desc);
create index photos_viewpoint_idx on photos (viewpoint_id, taken_at);
create index photos_map_idx       on photos (project_id) where lat is not null and lng is not null;

create table annotations (
  id          uuid primary key default gen_random_uuid(),
  photo_id    uuid not null references photos (id) on delete cascade,
  author_id   uuid not null references profiles (id),
  data_json   jsonb not null,             -- formes vectorielles (Konva/fabric)
  created_at  timestamptz not null default now()
);
create index annotations_photo_idx on annotations (photo_id);

-- ============================================================================
-- RAPPORTS DE SUIVI
-- ============================================================================

create table reports (
  id                    uuid primary key default gen_random_uuid(),
  project_id            uuid not null references projects (id) on delete cascade,
  author_id             uuid not null references profiles (id),
  period_start          date not null,
  period_end            date not null check (period_end >= period_start),
  effectif              int,
  materiel              text,
  jours_intemperie      numeric(4,1) not null default 0,
  jours_arret           numeric(4,1) not null default 0,
  motif_arret           text,
  qualite_observations  text,
  statut                report_status not null default 'brouillon',
  visa_user_id          uuid references profiles (id),  -- qui a relu
  visa_at               timestamptz,                    -- quand
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
create index reports_project_idx on reports (project_id, period_end desc);

-- Une ligne par tâche et par rapport : c'est l'historique d'avancement,
-- et la source du pré-remplissage (dernier avancement connu par tâche).
create table task_progress (
  id           uuid primary key default gen_random_uuid(),
  report_id    uuid not null references reports (id) on delete cascade,
  task_id      uuid not null references tasks (id) on delete restrict,
  pct          numeric(5,2) check (pct is null or (pct >= 0 and pct <= 100)),
  quantite     text,                      -- "120 m³" : libre, pas de référentiel d'unités en v1
  commentaire  text,
  unique (report_id, task_id)
);
create index task_progress_task_idx on task_progress (task_id);

create table report_photos (
  report_id  uuid not null references reports (id) on delete cascade,
  photo_id   uuid not null references photos (id) on delete restrict,
  primary key (report_id, photo_id)
);

-- ============================================================================
-- MESSAGES (après photos/reports/documents pour les FK)
-- ============================================================================

create table messages (
  id           uuid primary key default gen_random_uuid(),
  channel_id   uuid not null references channels (id) on delete cascade,
  author_id    uuid not null references profiles (id),
  kind         message_kind not null default 'texte',
  body         text,
  photo_id     uuid references photos (id) on delete restrict,
  report_id    uuid references reports (id) on delete restrict,   -- carte cliquable dans le fil
  document_id  uuid references documents (id) on delete restrict,
  created_at   timestamptz not null default now()
);
create index messages_channel_idx on messages (channel_id, created_at desc);

-- ============================================================================
-- RÉCEPTIONS (bon de livraison → réception, W10)
-- ============================================================================

create table suppliers (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references organizations (id) on delete cascade,
  name        text not null,
  created_at  timestamptz not null default now(),
  unique (org_id, name)
);

create table materials (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references organizations (id) on delete cascade,
  name        text not null,
  unite       text,
  created_at  timestamptz not null default now(),
  unique (org_id, name)
);

create table receptions (
  id              uuid primary key default gen_random_uuid(),
  project_id      uuid not null references projects (id) on delete cascade,
  supplier_id     uuid references suppliers (id) on delete restrict,
  document_id     uuid references documents (id) on delete set null, -- le bon de livraison scanné
  date_reception  date not null,
  created_by      uuid not null references profiles (id),
  created_at      timestamptz not null default now()
);
create index receptions_project_idx on receptions (project_id, date_reception desc);

create table reception_lines (
  id            uuid primary key default gen_random_uuid(),
  reception_id  uuid not null references receptions (id) on delete cascade,
  material_id   uuid references materials (id) on delete set null,
  label         text not null,            -- libellé tel que lu sur le bon
  quantite      numeric(12,3),
  unite         text
);
create index reception_lines_reception_idx on reception_lines (reception_id);

-- ============================================================================
-- AGENT (une seule porte d'entrée : POST /api/agents/run)
-- ============================================================================

create table agent_threads (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references organizations (id) on delete cascade,
  user_id     uuid not null references profiles (id) on delete cascade,
  title       text,
  created_at  timestamptz not null default now()
);
create index agent_threads_user_idx on agent_threads (user_id, created_at desc);

create table agent_messages (
  id          uuid primary key default gen_random_uuid(),
  thread_id   uuid not null references agent_threads (id) on delete cascade,
  role        text not null check (role in ('user', 'assistant', 'tool')),
  content     jsonb not null,
  created_at  timestamptz not null default now()
);
create index agent_messages_thread_idx on agent_messages (thread_id, created_at);

create table agent_runs (
  id           uuid primary key default gen_random_uuid(),
  org_id       uuid not null references organizations (id) on delete cascade,
  user_id      uuid not null references profiles (id),
  thread_id    uuid references agent_threads (id) on delete set null,
  agent_name   text not null,             -- clé dans le registre d'agents ('rapporteur', 'ocr')
  status       text not null default 'running' check (status in ('running', 'succeeded', 'failed')),
  input_json   jsonb,
  output_json  jsonb,
  tokens_in    int,
  tokens_out   int,
  created_at   timestamptz not null default now(),
  finished_at  timestamptz
);
create index agent_runs_org_idx on agent_runs (org_id, created_at desc);

-- ============================================================================
-- MONÉTISATION — créées VIDES, aucun code v1 ne les utilise.
-- 'plans' = offres tarifaires (rien à voir avec les plans PDF = documents).
-- ============================================================================

create table plans (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,
  name        text not null,
  created_at  timestamptz not null default now()
);

create table subscriptions (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references organizations (id) on delete cascade,
  plan_id     uuid not null references plans (id),
  status      text not null default 'active',
  created_at  timestamptz not null default now()
);

create table agent_entitlements (
  id          uuid primary key default gen_random_uuid(),
  org_id      uuid not null references organizations (id) on delete cascade,
  agent_name  text not null,
  quota_runs  int,                        -- quota mensuel ; null = illimité
  created_at  timestamptz not null default now(),
  unique (org_id, agent_name)
);

-- ============================================================================
-- TRIGGER : profil créé au signup
-- ============================================================================
create or replace function app.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  return new;
end;
$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_user();

-- ============================================================================
-- RLS — activée sur TOUTES les tables, policies écrites table par table
-- ============================================================================
alter table organizations      enable row level security;
alter table profiles           enable row level security;
alter table memberships        enable row level security;
alter table projects           enable row level security;
alter table project_members    enable row level security;
alter table channels           enable row level security;
alter table folders            enable row level security;
alter table documents          enable row level security;
alter table tasks              enable row level security;
alter table viewpoints         enable row level security;
alter table photos             enable row level security;
alter table annotations        enable row level security;
alter table reports            enable row level security;
alter table task_progress      enable row level security;
alter table report_photos      enable row level security;
alter table messages           enable row level security;
alter table suppliers          enable row level security;
alter table materials          enable row level security;
alter table receptions         enable row level security;
alter table reception_lines    enable row level security;
alter table agent_threads      enable row level security;
alter table agent_messages     enable row level security;
alter table agent_runs         enable row level security;
alter table plans              enable row level security;
alter table subscriptions      enable row level security;
alter table agent_entitlements enable row level security;

-- organizations : lecture par ses membres ; création par tout connecté
-- (onboarding W1) ; modification par patron/admin.
create policy org_select on organizations for select using (app.is_org_member(id));
create policy org_insert on organizations for insert with check (auth.uid() is not null);
create policy org_update on organizations for update using (app.is_org_admin(id));

-- profiles : je lis les profils de mes collègues d'organisation (et le mien),
-- je ne modifie que le mien. L'insert vient du trigger (security definer).
create policy profiles_select on profiles for select using (
  id = auth.uid()
  or exists (select 1 from memberships m1
             join memberships m2 on m1.org_id = m2.org_id
             where m1.user_id = auth.uid() and m2.user_id = profiles.id)
);
create policy profiles_update on profiles for update using (id = auth.uid());

-- memberships : lecture par les membres de l'org ; gestion par patron/admin.
-- Cas particulier onboarding : le créateur de l'org s'insère lui-même patron.
create policy memberships_select on memberships for select using (app.is_org_member(org_id));
create policy memberships_insert on memberships for insert with check (
  app.is_org_admin(org_id)
  or (user_id = auth.uid() and role = 'patron'
      and not exists (select 1 from memberships m where m.org_id = memberships.org_id))
);
create policy memberships_update on memberships for update using (app.is_org_admin(org_id));
create policy memberships_delete on memberships for delete using (app.is_org_admin(org_id));

-- projects : visibles par leurs membres ; création/gestion par patron/admin de l'org.
create policy projects_select on projects for select using (app.is_project_member(id));
create policy projects_insert on projects for insert with check (app.is_org_admin(org_id));
create policy projects_update on projects for update using (app.is_org_admin(org_id));

-- project_members : lecture par les membres du projet ; gestion par patron/admin.
create policy project_members_select on project_members for select
  using (app.is_project_member(project_id));
create policy project_members_insert on project_members for insert
  with check (app.is_org_admin(app.project_org(project_id)));
create policy project_members_delete on project_members for delete
  using (app.is_org_admin(app.project_org(project_id)));

-- Grille standard des tables projet : tout membre du projet lit et écrit.
-- channels
create policy channels_select on channels for select using (app.is_project_member(project_id));
create policy channels_insert on channels for insert with check (app.is_org_admin(app.project_org(project_id)));
-- folders
create policy folders_select on folders for select using (app.is_project_member(project_id));
create policy folders_insert on folders for insert with check (app.is_project_member(project_id));
create policy folders_update on folders for update using (app.is_project_member(project_id));
-- documents
create policy documents_select on documents for select using (app.is_project_member(project_id));
create policy documents_insert on documents for insert with check (app.is_project_member(project_id) and uploaded_by = auth.uid());
create policy documents_update on documents for update using (app.is_project_member(project_id));
create policy documents_delete on documents for delete using (app.is_org_admin(app.project_org(project_id)));
-- tasks
create policy tasks_select on tasks for select using (app.is_project_member(project_id));
create policy tasks_insert on tasks for insert with check (app.is_project_member(project_id));
create policy tasks_update on tasks for update using (app.is_project_member(project_id));
-- viewpoints
create policy viewpoints_select on viewpoints for select using (app.is_project_member(project_id));
create policy viewpoints_insert on viewpoints for insert with check (app.is_project_member(project_id));
create policy viewpoints_update on viewpoints for update using (app.is_project_member(project_id));
-- photos : l'auteur est toujours l'utilisateur connecté ; pas de delete (mémoire du chantier)
create policy photos_select on photos for select using (app.is_project_member(project_id));
create policy photos_insert on photos for insert with check (app.is_project_member(project_id) and author_id = auth.uid());
create policy photos_update on photos for update using (app.is_project_member(project_id));
-- annotations (droit hérité de la photo)
create policy annotations_select on annotations for select
  using (exists (select 1 from photos p where p.id = photo_id and app.is_project_member(p.project_id)));
create policy annotations_insert on annotations for insert
  with check (author_id = auth.uid()
    and exists (select 1 from photos p where p.id = photo_id and app.is_project_member(p.project_id)));
-- reports
create policy reports_select on reports for select using (app.is_project_member(project_id));
create policy reports_insert on reports for insert with check (app.is_project_member(project_id) and author_id = auth.uid());
create policy reports_update on reports for update using (app.is_project_member(project_id));
-- task_progress (droit hérité du rapport)
create policy task_progress_select on task_progress for select
  using (exists (select 1 from reports r where r.id = report_id and app.is_project_member(r.project_id)));
create policy task_progress_insert on task_progress for insert
  with check (exists (select 1 from reports r where r.id = report_id and app.is_project_member(r.project_id)));
create policy task_progress_update on task_progress for update
  using (exists (select 1 from reports r where r.id = report_id and app.is_project_member(r.project_id)));
create policy task_progress_delete on task_progress for delete
  using (exists (select 1 from reports r where r.id = report_id and app.is_project_member(r.project_id)));
-- report_photos (droit hérité du rapport)
create policy report_photos_select on report_photos for select
  using (exists (select 1 from reports r where r.id = report_id and app.is_project_member(r.project_id)));
create policy report_photos_insert on report_photos for insert
  with check (exists (select 1 from reports r where r.id = report_id and app.is_project_member(r.project_id)));
create policy report_photos_delete on report_photos for delete
  using (exists (select 1 from reports r where r.id = report_id and app.is_project_member(r.project_id)));
-- messages (droit hérité du canal ; pas d'édition ni de suppression en v1 : c'est la mémoire)
create policy messages_select on messages for select
  using (exists (select 1 from channels c where c.id = channel_id and app.is_project_member(c.project_id)));
create policy messages_insert on messages for insert
  with check (author_id = auth.uid()
    and exists (select 1 from channels c where c.id = channel_id and app.is_project_member(c.project_id)));

-- suppliers / materials : niveau organisation, visibles et alimentés par tous les membres.
create policy suppliers_select on suppliers for select using (app.is_org_member(org_id));
create policy suppliers_insert on suppliers for insert with check (app.is_org_member(org_id));
create policy suppliers_update on suppliers for update using (app.is_org_member(org_id));
create policy materials_select on materials for select using (app.is_org_member(org_id));
create policy materials_insert on materials for insert with check (app.is_org_member(org_id));
create policy materials_update on materials for update using (app.is_org_member(org_id));

-- receptions
create policy receptions_select on receptions for select using (app.is_project_member(project_id));
create policy receptions_insert on receptions for insert with check (app.is_project_member(project_id) and created_by = auth.uid());
create policy receptions_update on receptions for update using (app.is_project_member(project_id));
-- reception_lines (droit hérité de la réception)
create policy reception_lines_select on reception_lines for select
  using (exists (select 1 from receptions r where r.id = reception_id and app.is_project_member(r.project_id)));
create policy reception_lines_insert on reception_lines for insert
  with check (exists (select 1 from receptions r where r.id = reception_id and app.is_project_member(r.project_id)));
create policy reception_lines_update on reception_lines for update
  using (exists (select 1 from receptions r where r.id = reception_id and app.is_project_member(r.project_id)));
create policy reception_lines_delete on reception_lines for delete
  using (exists (select 1 from receptions r where r.id = reception_id and app.is_project_member(r.project_id)));

-- agent_threads / agent_messages / agent_runs : privés à leur propriétaire.
-- Écrits par le runtime avec le client de l'utilisateur connecté (jamais service_role).
create policy agent_threads_select on agent_threads for select using (user_id = auth.uid());
create policy agent_threads_insert on agent_threads for insert
  with check (user_id = auth.uid() and app.is_org_member(org_id));
create policy agent_threads_update on agent_threads for update using (user_id = auth.uid());
create policy agent_messages_select on agent_messages for select
  using (exists (select 1 from agent_threads t where t.id = thread_id and t.user_id = auth.uid()));
create policy agent_messages_insert on agent_messages for insert
  with check (exists (select 1 from agent_threads t where t.id = thread_id and t.user_id = auth.uid()));
create policy agent_runs_select on agent_runs for select using (user_id = auth.uid());
create policy agent_runs_insert on agent_runs for insert
  with check (user_id = auth.uid() and app.is_org_member(org_id));
create policy agent_runs_update on agent_runs for update using (user_id = auth.uid());

-- plans / subscriptions / agent_entitlements : RLS activée, AUCUNE policy
-- d'écriture (deny all par défaut). Lecture de sa souscription par les membres.
create policy plans_select on plans for select using (auth.uid() is not null);
create policy subscriptions_select on subscriptions for select using (app.is_org_member(org_id));
create policy agent_entitlements_select on agent_entitlements for select using (app.is_org_member(org_id));

-- ============================================================================
-- STORAGE — 4 buckets photos + 1 documents, TOUS PRIVÉS (URLs signées).
-- Chemin : org_id/project_id/<fichier>. Le 2e segment donne le projet.
-- ============================================================================
insert into storage.buckets (id, name, public) values
  ('photos-originals',   'photos-originals',   false),  -- JAMAIS servie à l'UI
  ('photos-watermarked', 'photos-watermarked', false),
  ('photos-annotated',   'photos-annotated',   false),
  ('photos-thumbs',      'photos-thumbs',      false),
  ('documents-files',    'documents-files',    false)
on conflict (id) do nothing;

-- Écriture : membre du projet indiqué par le chemin.
create policy storage_insert_project on storage.objects for insert
  with check (
    bucket_id in ('photos-originals','photos-watermarked','photos-annotated','photos-thumbs','documents-files')
    and app.is_project_member(((storage.foldername(name))[2])::uuid)
  );
-- Lecture : membre du projet — SAUF le bucket des originales, qui n'a
-- volontairement AUCUNE policy select (aucune URL signée possible).
create policy storage_select_project on storage.objects for select
  using (
    bucket_id in ('photos-watermarked','photos-annotated','photos-thumbs','documents-files')
    and app.is_project_member(((storage.foldername(name))[2])::uuid)
  );
