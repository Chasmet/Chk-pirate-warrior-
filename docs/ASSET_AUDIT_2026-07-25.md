# Audit réel des assets 2.5D — mise à jour du 26 juillet 2026

## Sources vérifiées

- branche `agent/real-3d-foundation-v2` ;
- PR brouillon n°13 ;
- fichier joint `asset chk pirate.pdf` ;
- derniers packs visuels fournis dans la conversation, notamment les planches détaillées des îles 3 à 6 ;
- planches officielles des trois héros Cheikh, Yvane et Nelvyn ;
- catalogue Java `Enemy25DCatalog` ;
- catalogue JSON `app/src/main/assets/characters25d/catalog.json` ;
- chargeur `Enemy25DAssetBank`, rendu `PirateGameAssetOverlay` et tests associés.

## Conclusion immédiate

Les références reçues permettent désormais de verrouiller les six rosters officiels et d'afficher les
sept personnages importants de l'île active dans le jeu : un boss, trois commandants et trois
subordonnés. Le moteur utilise d'abord les vraies bandes `SpriteStrip25D` lorsqu'elles existent, puis
l'atlas officiel comme fallback, sans charger les 42 personnages simultanément.

Aucune île ne peut cependant être déclarée artistiquement terminée selon la règle du projet. Les
planches composées envoyées restent des sources de production tant qu'elles ne sont pas découpées en
bandes WEBP transparentes, validées dans les quatre directions et visibles sur téléphone.

## État par île

| Île | Roster officiel | Affichage fallback | Bandes transparentes complètes | État réel |
|---|---:|---:|---:|---|
| 1. Port des Naufragés | verrouillé | oui | non | roster et gameplay branchés, production technique manquante |
| 2. Jungle Sauvage | verrouillé | oui | non | roster et gameplay branchés, production technique manquante |
| 3. Royaume des Neiges | verrouillé | oui | non | nombreuses miniatures disponibles, découpe finale à produire |
| 4. Désert des Corsaires | verrouillé après validation utilisateur | oui | non | conflit de noms résolu, intégration logique en cours |
| 5. Île Volcanique | verrouillé | oui | non | planches détaillées reçues, bandes finales à produire |
| 6. Forteresse de la Tempête | verrouillé | oui | non | planches détaillées reçues, bandes finales à produire |

## Validation définitive du Désert des Corsaires

Le dernier pack visuel fourni tranche explicitement l'ancien conflit entre le texte du PDF et la
planche de roster. La liste officielle à utiliser dans le jeu est maintenant :

- **Boss** : Zarok, Khan des Sables ;
- **Commandants** : Sabir le Dromadaire, Razka la Lame de Sable, Al-Varis l'Artificier ;
- **Subordonnés** : Chaal le Rapace, Mâchoire du Désert, Veilleuse des Dunes.

Les anciens identifiants Zahrek, Qamar, Sirok, Dune, Khepri, Safra et Rakh sont désormais considérés
comme incompatibles et ne doivent plus être chargés.

## Intégration gameplay des ennemis importants

- exactement sept personnages importants sont attribués sur l'île active ;
- les autres adversaires restent des ennemis ordinaires destinés aux modèles 3D ;
- les commandants et subordonnés ne partagent plus tous les mêmes statistiques ;
- les rôles à distance, assassin, contrôleur et combattant lourd modifient la vie, la vitesse, la
  distance d'engagement, le rayon de collision et le délai d'attaque ;
- le boss conserve son identité propre et ses animations spéciales lorsqu'elles sont disponibles ;
- un asset absent est journalisé et remplacé par un fallback sans faire planter le jeu ;
- le changement d'île libère les textures précédentes avant de préparer le roster suivant.

## Assets encore réellement manquants

- bandes WEBP transparentes par animation et par direction pour les 42 ennemis importants ;
- pivots, hitbox, cadence et métadonnées validés pour chaque personnage ;
- rage, phase 2, attaque de zone et ultime des six boss ;
- modèles GLB optimisés des ennemis ordinaires et de la faune ;
- animations du héros au gouvernail et sur le pont du bateau ;
- validation visuelle sur téléphone des assets finaux.

## Ordre de production maintenu

1. Port des Naufragés : Brakor, puis les trois commandants et les trois subordonnés ;
2. Jungle Sauvage ;
3. Royaume des Neiges ;
4. Désert des Corsaires ;
5. Île Volcanique ;
6. Forteresse de la Tempête.

Une île passe à l'état « terminée » uniquement lorsque ses sept personnages disposent de vraies
bandes transparentes chargées dans le jeu, que les animations spéciales du boss fonctionnent, que les
tests, le lint et `assembleDebug` passent, puis qu'une vidéo Android confirme le rendu sans régression.
