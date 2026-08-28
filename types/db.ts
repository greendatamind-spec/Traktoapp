/**
 * Types de la base de données — écrits À LA MAIN depuis
 * supabase/migrations/0001_init.sql, en attendant de pouvoir lancer
 * `npx supabase gen types typescript` sur le vrai projet.
 * ⚠️ À remplacer par la génération automatique dès que possible ; ne pas
 * laisser diverger de la migration.
 */

export type OrgRole = "patron" | "admin" | "conducteur";
export type ReportStatus = "brouillon" | "soumis" | "vise";
export type DocValidation = "en_attente" | "valide";
export type MessageKind = "texte" | "photo" | "document" | "rapport" | "systeme";
export type AgentRunStatus = "running" | "succeeded" | "failed";
export type AgentMessageRole = "user" | "assistant" | "tool";

type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

/**
 * Construit les formes Row / Insert / Update d'une table :
 * - Insert : les colonnes de `Generated` (défauts, identités) deviennent optionnelles
 * - Update : tout est optionnel
 */
type Table<Row, Generated extends keyof Row = never> = {
  Row: Row;
  Insert: Omit<Row, Generated> & Partial<Pick<Row, Generated>>;
  Update: Partial<Row>;
  Relationships: [];
};

// --- Lignes -----------------------------------------------------------------

export type Organization = {
  id: string;
  name: string;
  created_at: string;
};

export type Profile = {
  id: string;
  full_name: string;
  phone: string | null;
  created_at: string;
};

export type Membership = {
  org_id: string;
  user_id: string;
  role: OrgRole;
  created_at: string;
};

export type Project = {
  id: string;
  org_id: string;
  name: string;
  address: string | null;
  lat: number | null;
  lng: number | null;
  archived_at: string | null;
  created_at: string;
};

export type ProjectMember = {
  project_id: string;
  user_id: string;
  created_at: string;
};

export type Channel = {
  id: string;
  project_id: string;
  name: string;
  created_at: string;
};

export type Folder = {
  id: string;
  project_id: string;
  name: string;
  created_at: string;
};

export type Document = {
  id: string;
  project_id: string;
  folder_id: string | null;
  uploaded_by: string;
  name: string;
  file_url: string;
  mime_type: string | null;
  type_detecte: string | null;
  ocr_text: string | null;
  extraction_json: Json | null;
  statut_validation: DocValidation;
  created_at: string;
};

export type Task = {
  id: string;
  project_id: string;
  label: string;
  position: number;
  archived_at: string | null;
  created_at: string;
};

export type Viewpoint = {
  id: string;
  project_id: string;
  name: string;
  created_at: string;
};

export type Photo = {
  id: string;
  project_id: string;
  channel_id: string;
  author_id: string;
  task_id: string | null;
  viewpoint_id: string | null;
  lat: number | null;
  lng: number | null;
  taken_at: string;
  plan_document_id: string | null;
  plan_page: number | null;
  plan_x: number | null;
  plan_y: number | null;
  original_url: string;
  watermark_url: string;
  annotated_url: string | null;
  thumb_url: string;
  created_at: string;
};

export type Annotation = {
  id: string;
  photo_id: string;
  author_id: string;
  data_json: Json;
  created_at: string;
};

export type Report = {
  id: string;
  project_id: string;
  author_id: string;
  period_start: string;
  period_end: string;
  effectif: number | null;
  materiel: string | null;
  jours_intemperie: number;
  jours_arret: number;
  motif_arret: string | null;
  qualite_observations: string | null;
  statut: ReportStatus;
  visa_user_id: string | null;
  visa_at: string | null;
  created_at: string;
  updated_at: string;
};

export type TaskProgress = {
  id: string;
  report_id: string;
  task_id: string;
  pct: number | null;
  quantite: string | null;
  commentaire: string | null;
};

export type ReportPhoto = {
  report_id: string;
  photo_id: string;
};

export type Message = {
  id: string;
  channel_id: string;
  author_id: string;
  kind: MessageKind;
  body: string | null;
  photo_id: string | null;
  report_id: string | null;
  document_id: string | null;
  created_at: string;
};

export type Supplier = {
  id: string;
  org_id: string;
  name: string;
  created_at: string;
};

export type Material = {
  id: string;
  org_id: string;
  name: string;
  unite: string | null;
  created_at: string;
};

export type Reception = {
  id: string;
  project_id: string;
  supplier_id: string | null;
  document_id: string | null;
  date_reception: string;
  created_by: string;
  created_at: string;
};

export type ReceptionLine = {
  id: string;
  reception_id: string;
  material_id: string | null;
  label: string;
  quantite: number | null;
  unite: string | null;
};

export type AgentThread = {
  id: string;
  org_id: string;
  user_id: string;
  title: string | null;
  created_at: string;
};

export type AgentMessage = {
  id: string;
  thread_id: string;
  role: AgentMessageRole;
  content: Json;
  created_at: string;
};

export type AgentRun = {
  id: string;
  org_id: string;
  user_id: string;
  thread_id: string | null;
  agent_name: string;
  status: AgentRunStatus;
  input_json: Json | null;
  output_json: Json | null;
  tokens_in: number | null;
  tokens_out: number | null;
  created_at: string;
  finished_at: string | null;
};

export type Plan = {
  id: string;
  code: string;
  name: string;
  created_at: string;
};

export type Subscription = {
  id: string;
  org_id: string;
  plan_id: string;
  status: string;
  created_at: string;
};

export type AgentEntitlement = {
  id: string;
  org_id: string;
  agent_name: string;
  quota_runs: number | null;
  created_at: string;
};

// --- Le type Database consommé par les clients Supabase ---------------------

export type Database = {
  public: {
    Tables: {
      organizations: Table<Organization, "id" | "created_at">;
      profiles: Table<Profile, "created_at">;
      memberships: Table<Membership, "role" | "created_at">;
      projects: Table<Project, "id" | "archived_at" | "created_at">;
      project_members: Table<ProjectMember, "created_at">;
      channels: Table<Channel, "id" | "name" | "created_at">;
      folders: Table<Folder, "id" | "created_at">;
      documents: Table<Document, "id" | "statut_validation" | "created_at">;
      tasks: Table<Task, "id" | "position" | "archived_at" | "created_at">;
      viewpoints: Table<Viewpoint, "id" | "created_at">;
      photos: Table<Photo, "id" | "created_at">;
      annotations: Table<Annotation, "id" | "created_at">;
      reports: Table<Report, "id" | "statut" | "jours_intemperie" | "jours_arret" | "created_at" | "updated_at">;
      task_progress: Table<TaskProgress, "id">;
      report_photos: Table<ReportPhoto>;
      messages: Table<Message, "id" | "kind" | "created_at">;
      suppliers: Table<Supplier, "id" | "created_at">;
      materials: Table<Material, "id" | "created_at">;
      receptions: Table<Reception, "id" | "created_at">;
      reception_lines: Table<ReceptionLine, "id">;
      agent_threads: Table<AgentThread, "id" | "created_at">;
      agent_messages: Table<AgentMessage, "id" | "created_at">;
      agent_runs: Table<AgentRun, "id" | "status" | "created_at">;
      plans: Table<Plan, "id" | "created_at">;
      subscriptions: Table<Subscription, "id" | "status" | "created_at">;
      agent_entitlements: Table<AgentEntitlement, "id" | "created_at">;
    };
    Views: Record<string, never>;
    Functions: Record<string, never>;
    Enums: {
      org_role: OrgRole;
      report_status: ReportStatus;
      doc_validation: DocValidation;
      message_kind: MessageKind;
    };
    CompositeTypes: Record<string, never>;
  };
};
