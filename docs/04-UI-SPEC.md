# 04 — SPÉCIFICATION UI

Principes transverses : mobile-first sur tout ce qui alimente, desktop-first sur tout ce qui consulte. Terrain = une main, des gants, plein soleil : cibles ≥ 48 px, contraste élevé. Format par écran : **But · Ce qu'on voit · Actions · Vide · Chargement · Erreur.**

## Coquilles
**Desktop — 3 colonnes.** Col 1 : chat AI Rapporteur épinglé en haut, puis liste des projets. Col 2 : le fil du projet sélectionné. Col 3 : panneau contextuel à onglets Dossier / Rapport, sections repliables, sauvegarde auto, bouton Télécharger.
**Mobile — 3 onglets** par projet : Galerie | Chat | Dossier. Barre de saisie sous le chat : `[+] [Aa] [📄 rapport] [📷 caméra] [🎤]`. Le bouton rapport est DANS la barre, à côté de la caméra : créer un rapport est aussi banal qu'envoyer une photo.
⚠️ À TRANCHER : le bouton [🎤] envoie-t-il une note vocale dans le fil, ou dicte-t-il du texte ?

## E1 — Connexion & onboarding (W1)
**But** entrer, ou créer son entreprise. **Voit** login email/mot de passe ; si aucune organisation : wizard entreprise → premier projet → invitations avec rôle. **Actions** se connecter, créer, inviter, passer. **Vide** s.o. **Chargement** bouton en spinner. **Erreur** identifiants invalides en clair ; invitation en échec → réessayer sans perdre le wizard.

## E2 — Liste des projets (desktop col 1 / accueil mobile)
**But** choisir un projet ; l'AI Rapporteur toujours à un clic. **Voit** carte AI Rapporteur épinglée, puis projets (nom, dernier message, pastille non-lu). **Actions** ouvrir, créer un projet (patron/admin). **Vide** « Créez votre premier projet » + bouton. **Chargement** squelettes. **Erreur** bandeau hors-ligne, liste en cache affichée.

## E3 — Le fil (canal du projet)
**But** le canal unique de l'encadrement, et sa mémoire. **Voit** messages texte, photos filigranées, cartes rapport cliquables, cartes document ; Realtime. **Actions** envoyer via la barre `[+][Aa][📄][📷][🎤]` ; tap photo → visionneuse ; tap carte rapport → E8 ; pas d'édition ni de suppression de message. **Vide** « Le chantier commence ici — envoyez la première photo. » **Chargement** derniers messages d'abord, scroll infini vers le haut. **Erreur** message non parti → badge « en attente (n) », renvoi auto (W11).

## E4 — Caméra Trakto (plein écran, jamais l'appareil système)
**But** LE différenciateur : photo + annotation dans le même geste. **Voit** viseur, gros déclencheur, torche, bascule Photo/Document, sélecteur point de vue (surimpression fantôme du cadrage de référence si repris), indicateur GPS. **Actions** capturer → éditeur d'annotation (flèches, cercles, texte, couleurs — skippable) → rattacher à une tâche ou un point de vue → envoyer ; le filigrane GPS/date/projet/auteur s'incruste toujours. **Vide** s.o. **Chargement** traitement < 2 s, l'utilisateur peut enchaîner les captures. **Erreur** permission caméra refusée → écran d'explication (l'app est inutilisable sans) ; GPS refusé → capture OK, badge « sans position » ; hors ligne → file locale, badge.

## E5 — Galerie (onglet mobile 1)
**But** retrouver une photo. **Voit** grille par date (vignettes filigranées), filtres tâche / point de vue / sans position ; accès Carte et Points de vue. **Actions** ouvrir, positionner sur plan (W5), comparer avant/après (W4). **Vide** « Aucune photo — ouvrez la caméra », bouton 📷. **Chargement** vignettes progressives. **Erreur** vignette cassée → placeholder + retenter.

## E6 — Carte du projet
**But** voir où les photos ont été prises. **Voit** Leaflet/OSM, clusters, compteur « n photos sans position ». **Actions** zoom, tap cluster → vignettes → photo. **Vide** « Aucune photo géolocalisée ». **Chargement** spinner sur tuiles. **Erreur** hors ligne → « carte indisponible sans réseau ».

## E7 — Dossier (onglet mobile 3 / desktop col 3)
**But** la mémoire documentaire. **Voit** 4 dossiers (Plans, Rapports, Achats, PV) + « à classer », compteurs ; badge `en_attente` sur les documents non confirmés. **Actions** ouvrir (plans via pdf.js avec pins), scanner (→ W3), confirmer/corriger une proposition OCR, télécharger. **Vide** « Scannez votre premier document ». **Chargement** liste puis aperçus. **Erreur** OCR en échec → document rangé sans extraction, mention « OCR indisponible ».

## E8 — Formulaire de suivi (le SEUL formulaire)
**But** remplacer l'appel : corriger, pas rédiger. **Voit** sections repliables — en-tête auto (projet, période du…au…, rédacteur) · avancement par tâche pré-rempli du dernier % connu (%, quantité, commentaire) · moyens (effectif, matériel, jours d'intempérie, jours d'arrêt + motif) · qualité et observations · photos de la période présélectionnées · validation (statut, visa : qui a relu, quand). Sauvegarde auto permanente. **Actions** corriger, ajouter/retirer des photos, soumettre, viser, Télécharger (PDF). **Vide** projet sans tâches → invite à en créer (W7). **Chargement** pré-remplissage < 1 s ; sinon squelette par section. **Erreur** hors ligne → brouillon local (W11) ; échec PDF → réessayer, le rapport reste intact.

## E9 — Chat AI Rapporteur (épinglé, niveau application)
**But** l'agent unique qui prépare le rapport. **Voit** conversation, réponses en streaming, bouton « Ouvrir le rapport pré-rempli ». **Actions** demander un brouillon, poser une question sur ses projets ; l'agent n'écrit jamais un rapport seul — il ouvre E8 pré-rempli. **Vide** 3 suggestions (« Prépare le rapport de la semaine sur [projet]… »). **Chargement** streaming token par token. **Erreur** quota atteint → message clair + accès direct à E8 vierge ; échec modèle → E8 pré-rempli avec les seuls derniers avancements.

## E10 — Confirmation de réception (W10)
**But** transformer un bon de livraison en réception sans saisie. **Voit** aperçu du scan à gauche, lignes extraites éditables à droite (fournisseur en autocomplétion, date, articles, quantités). **Actions** corriger, supprimer une ligne, confirmer — rien n'est écrit avant. **Vide** s.o. **Chargement** extraction en streaming ligne à ligne. **Erreur** extraction partielle → lignes vides à compléter à la main.
