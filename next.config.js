// next-pwa impose un next.config.js en CommonJS.
// Le service worker n'est généré qu'au build de production (désactivé en dev).
const withPWA = require("next-pwa")({
  dest: "public",
  disable: process.env.NODE_ENV === "development",
});

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
};

module.exports = withPWA(nextConfig);
