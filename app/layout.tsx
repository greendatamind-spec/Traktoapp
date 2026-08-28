import type { Metadata, Viewport } from "next";

import "./globals.css";

export const metadata: Metadata = {
  title: "Trakto",
  description: "Suivi de chantier pour PME du BTP — le canal de l'encadrement.",
  manifest: "/manifest.webmanifest",
  icons: {
    apple: "/icons/apple-touch-icon.png",
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Trakto",
  },
};

export const viewport: Viewport = {
  themeColor: "#d9640a",
  width: "device-width",
  initialScale: 1,
  // Pas de zoom bloqué : accessibilité d'abord.
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="fr">
      <body className="min-h-dvh">{children}</body>
    </html>
  );
}
