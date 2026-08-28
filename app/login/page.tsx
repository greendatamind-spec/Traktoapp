"use client";

import { useState } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { Suspense } from "react";

import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(
    searchParams.get("erreur") === "lien-invalide"
      ? "Lien invalide ou expiré. Réessayez."
      : null,
  );

  async function signInWithPassword(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) {
      setMessage("E-mail ou mot de passe incorrect.");
      setLoading(false);
      return;
    }
    router.push("/projets");
    router.refresh();
  }

  async function signInWithMagicLink() {
    if (!email) {
      setMessage("Saisissez d'abord votre e-mail.");
      return;
    }
    setLoading(true);
    setMessage(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/auth/callback` },
    });
    setLoading(false);
    setMessage(
      error
        ? "Envoi impossible. Vérifiez l'e-mail et réessayez."
        : "Lien envoyé ! Ouvrez votre boîte mail depuis ce téléphone.",
    );
  }

  return (
    <Card className="w-full max-w-sm">
      <CardHeader>
        <CardTitle>Connexion</CardTitle>
      </CardHeader>
      <CardContent>
        <form onSubmit={signInWithPassword} className="flex flex-col gap-4">
          <div className="flex flex-col gap-2">
            <Label htmlFor="email">E-mail</Label>
            <Input
              id="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
          <div className="flex flex-col gap-2">
            <Label htmlFor="password">Mot de passe</Label>
            <Input
              id="password"
              type="password"
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
          {message && <p className="text-base font-medium text-destructive">{message}</p>}
          <Button type="submit" disabled={loading}>
            {loading ? "Connexion…" : "Se connecter"}
          </Button>
          <Button type="button" variant="outline" disabled={loading} onClick={signInWithMagicLink}>
            Recevoir un lien par e-mail
          </Button>
        </form>
        <p className="mt-6 text-center text-base text-muted-foreground">
          Pas encore de compte ?{" "}
          <Link href="/signup" className="font-semibold text-primary underline-offset-4 hover:underline">
            Créer un compte
          </Link>
        </p>
      </CardContent>
    </Card>
  );
}

export default function LoginPage() {
  return (
    <main className="flex min-h-dvh flex-col items-center justify-center gap-8 p-4">
      <h1 className="text-4xl font-black tracking-tight text-primary">Trakto</h1>
      <Suspense>
        <LoginForm />
      </Suspense>
    </main>
  );
}
