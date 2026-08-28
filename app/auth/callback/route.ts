import { NextResponse } from "next/server";

import { createClient } from "@/lib/supabase/server";

/**
 * Point d'atterrissage des liens envoyés par e-mail (lien magique,
 * confirmation d'inscription) : échange le code contre une session.
 */
export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");

  if (code) {
    const supabase = await createClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      return NextResponse.redirect(`${origin}/projets`);
    }
  }

  return NextResponse.redirect(`${origin}/login?erreur=lien-invalide`);
}
