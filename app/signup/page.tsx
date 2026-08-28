"use client";

import { useState } from "react";
import Link from "next/link";

import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export default function SignupPage() {
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  async function signUp(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage(null);
    const supabase = createClient();
    const { error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`,
        // Repris par le trigger qui crée le profil (0001_init.sql).
        data: { full_name: fullName },
      },
    });
    setLoading(false);
    if (error) {
      setMessage(
        error.message.includes("already registered")
          ? "Un compte existe déjà avec cet e-mail."
          : "Création impossible. Vérifiez les champs et réessayez.",
      );
      return;
    }
    setSent(true);
  }

  return (
    <main className="flex min-h-dvh flex-col items-center justify-center gap-8 p-4">
      <h1 className="text-4xl font-black tracking-tight text-primary">Trakto</h1>
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>Créer un compte</CardTitle>
        </CardHeader>
        <CardContent>
          {sent ? (
            <p className="text-base">
              C&apos;est presque fini : un e-mail de confirmation vient de partir vers{" "}
              <strong>{email}</strong>. Ouvrez-le et cliquez sur le lien pour activer votre compte.
            </p>
          ) : (
            <form onSubmit={signUp} className="flex flex-col gap-4">
              <div className="flex flex-col gap-2">
                <Label htmlFor="fullName">Nom complet</Label>
                <Input
                  id="fullName"
                  autoComplete="name"
                  required
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                />
              </div>
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
                <Label htmlFor="password">Mot de passe (8 caractères minimum)</Label>
                <Input
                  id="password"
                  type="password"
                  autoComplete="new-password"
                  required
                  minLength={8}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                />
              </div>
              {message && <p className="text-base font-medium text-destructive">{message}</p>}
              <Button type="submit" disabled={loading}>
                {loading ? "Création…" : "Créer mon compte"}
              </Button>
            </form>
          )}
          <p className="mt-6 text-center text-base text-muted-foreground">
            Déjà un compte ?{" "}
            <Link href="/login" className="font-semibold text-primary underline-offset-4 hover:underline">
              Se connecter
            </Link>
          </p>
        </CardContent>
      </Card>
    </main>
  );
}
