import { HardHat, Plus } from "lucide-react";

import { createClient } from "@/lib/supabase/server";
import { Button } from "@/components/ui/button";

// Server Component : lit la session et les projets de l'utilisateur.
// En Bloc 1 la liste est vide par construction (pas encore de CRUD projet).
export default async function ProjetsPage() {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  const { data: projets } = await supabase
    .from("projects")
    .select("id, name, address")
    .is("archived_at", null)
    .order("created_at", { ascending: false });

  return (
    <main className="mx-auto flex min-h-dvh w-full max-w-lg flex-col p-4">
      <header className="flex items-center justify-between py-2">
        <h1 className="text-2xl font-black tracking-tight text-primary">Trakto</h1>
        <form action="/auth/deconnexion" method="post">
          <Button type="submit" variant="ghost" size="sm">
            Se déconnecter
          </Button>
        </form>
      </header>

      <h2 className="mt-4 text-xl font-bold">Mes chantiers</h2>
      {user?.email && <p className="text-base text-muted-foreground">{user.email}</p>}

      {projets && projets.length > 0 ? (
        <ul className="mt-6 flex flex-col gap-3">
          {projets.map((p) => (
            <li key={p.id} className="rounded-lg border bg-card p-4">
              <span className="text-lg font-semibold">{p.name}</span>
              {p.address && <p className="text-base text-muted-foreground">{p.address}</p>}
            </li>
          ))}
        </ul>
      ) : (
        <div className="mt-16 flex flex-1 flex-col items-center gap-4 text-center">
          <HardHat className="size-16 text-muted-foreground" aria-hidden />
          <p className="max-w-xs text-lg font-medium">
            Aucun chantier pour l&apos;instant.
          </p>
          <p className="max-w-xs text-base text-muted-foreground">
            Créez votre premier projet pour ouvrir son canal et commencer le suivi.
          </p>
        </div>
      )}

      {/* Non fonctionnel en Bloc 1 : le CRUD projet arrive avec l'onboarding. */}
      <div className="sticky bottom-4 mt-auto flex justify-center pt-6">
        <Button size="lg" disabled title="Bientôt disponible">
          <Plus aria-hidden />
          Nouveau projet
        </Button>
      </div>
    </main>
  );
}
