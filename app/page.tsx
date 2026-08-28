import { redirect } from "next/navigation";

// La racine n'a pas d'écran : le middleware envoie les non-connectés
// vers /login, les connectés atterrissent sur /projets.
export default function Home() {
  redirect("/projets");
}
