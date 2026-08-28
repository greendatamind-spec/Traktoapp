# 13 — DÉCISIONS EN ATTENTE ET PRISES PAR DÉFAUT

Journal des « ⚠️ À TRANCHER » : la question, l'option prise en attendant, et la
décision finale quand elle tombe. On raye, on ne supprime pas.

## Reportées des docs de cadrage (toujours ouvertes)
- ⚠️ À TRANCHER : **Konva.js ou fabric.js** pour l'annotation — à décider avant B2.
- ⚠️ À TRANCHER : invitations par **e-mail uniquement, ou aussi téléphone/OTP** ?
- ⚠️ À TRANCHER : qui peut poser le **visa** d'un rapport (patron seul ou tout membre) ?
- ⚠️ À TRANCHER : le bouton **[🎤]** — note vocale dans le fil ou dictée de texte ?
- ⚠️ À TRANCHER : **fournisseur du modèle IA** derrière le Vercel AI SDK (Rapporteur + OCR).

## Apparues en Bloc 1 (option simple prise en attendant)
- ⚠️ À TRANCHER : **version de next-pwa**. Pris : `next-pwa@5.6.0` (le paquet du
  stack figé). Il n'est plus activement maintenu ; si le build casse avec une
  future version de Next, le fork `@ducanh2912/next-pwa` est le repli naturel.
- ⚠️ À TRANCHER : **routes d'auth en anglais** (`/login`, `/signup`) alors que la
  convention du projet est des routes en français. Pris : anglais, demandé
  explicitement au lancement du B1. Renommer en `/connexion`, `/inscription`
  plus tard serait trivial (2 dossiers + `PUBLIC_PATHS`).
- ⚠️ À TRANCHER : **politique de mot de passe**. Pris : 8 caractères minimum
  (défaut Supabase), pas de règles supplémentaires — public terrain.
- ⚠️ À TRANCHER : **numérotation des docs**. Ce fichier était demandé en 13 et
  l'architecture en 04 ; 04 étant pris par l'UI-SPEC, l'architecture est en 06.
  Renuméroter proprement toute la série quand la table des matières se stabilise.
