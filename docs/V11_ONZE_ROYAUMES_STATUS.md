# CHK Pirate Warrior — V11 Onze Royaumes

## Base officielle de travail

La V11 part de `agent/open-world-v9-foundation`, elle-même issue de la reconstruction Godot 3D validée. Elle ne repart pas de la version Android Canvas historique de `main`.

La scène principale `godot/scenes/main.tscn` charge désormais `res://scripts/main_v11.gd`.

## Monde

- 11 royaumes/régions dans le catalogue V11.
- 9 îles historiques jouables et reliées par l'océan continu.
- 1 région supplémentaire de marais accessible par exploration libre.
- 1 région finale : **Royaume Troublé**.
- Le Royaume Troublé est abandonné : aucun habitant et aucune faune.
- Dix points d'intérêt dédiés y sont placés : palais, horloge, bibliothèque, miroirs, porte flottante, ruines et sanctuaire.
- Un terrain physique avec collisions, terrasses, côte irrégulière, ruines et ponton a été ajouté pour la région finale.
- Le joueur peut réellement y accoster et repartir avec le bateau.
- La navigation tactile active `ACCOSTER` puis `EMBARQUER` au bon endroit.

## Fin de l'aventure

Le Royaume Troublé contient l'objet rare **Cœur des Souvenirs**.

La collecte :

- déclenche la conclusion en français ;
- est enregistrée dans la sauvegarde (`final_relic_found`) ;
- n'empêche pas l'exploration libre après la fin.

## Habitants et simulation

- 200 habitants restent simulés dans les dix régions vivantes.
- 20 habitants maximum sont matérialisés dans la région proche.
- Les autres continuent une simulation distante.
- Les capsules monoblocs V9 ont été remplacées en V11 par des silhouettes humaines stylisées avec tête, torse, bras, jambes, cheveux et accessoires liés au métier.
- Les membres reçoivent une animation de marche simple.
- Le budget de streaming reste limité à trois racines de régions visibles autour du joueur pour Android.

## Interface et identité

- Nouveau bandeau **CHK PIRATE WARRIOR — L'ARCHIPEL DES ONZE ROYAUMES**.
- Réutilisation du logo/icône officiel déjà présent : `res://assets/ui/icon_512.png`.
- Nouvelle carte du monde avec onze cartes de régions.
- Les régions atteignables directement via le système historique conservent leurs destinations.
- Le Marais et le Royaume Troublé sont explicitement indiqués comme zones d'exploration libre pour ne pas créer de faux téléporteurs.
- Messages HUD dédiés à l'entrée du Royaume Troublé et à la découverte du Cœur des Souvenirs.

## Jouabilité conservée

La V11 conserve les systèmes validés des versions précédentes :

- Cheikh, Yvane et Nelvyn ;
- caméra troisième personne 360° ;
- contrôle tactile et joystick caméra ;
- combat, combos, compétences, aura et esquive ;
- bateau pilotable en troisième personne ;
- météo et état de mer ;
- progression, boss et sauvegarde exacte ;
- deux équipages autonomes supplémentaires et leurs navires ;
- flotte ambiante ;
- monde agrandi de la V5/V7 ;
- fondation de streaming monde ouvert V9.

## Validation automatisée

Le workflow `.github/workflows/build-v11-onze-royaumes.yml` :

1. installe Java, Android SDK et Godot 4.6.3 ;
2. régénère la banque audio ;
3. importe/analyse tous les scripts Godot avec erreurs de parsing bloquantes ;
4. rejoue les tests de stabilité V8 ;
5. rejoue les tests monde ouvert V9 ;
6. exécute `v11_onze_royaumes_test.gd` ;
7. teste notamment l'accostage tactile réel sur l'île finale ;
8. exporte un vrai APK Android Godot ;
9. vérifie l'intégrité ZIP/APK et refuse un artefact anormalement petit ;
10. publie APK, SHA-256, taille et journaux via GitHub Actions.

## Point important sur les GLB

À la date de cette V11, aucun fichier `.glb` n'est présent dans l'arbre Git de la branche de jeu. Les documents historiques du dépôt indiquent également que les modèles GLB optimisés et plusieurs planches d'animation finales restaient à produire/intégrer.

La V11 n'invente donc pas de faux modèles 3D et ne prétend pas avoir intégré des GLB qui ne sont pas dans Git. Les décors supplémentaires et les habitants V11 utilisent pour l'instant des meshes Godot optimisés générés par code.

Pour une finition visuelle de niveau commercial, les modèles GLB source réellement validés doivent être ajoutés au dépôt (idéalement via Git LFS si nécessaire), puis remplacés dans les fabriques de personnages, faune, bâtiments, bateaux et objets.

## Critère de qualité

Une compilation verte valide la cohérence technique, les régressions et l'APK. Elle ne remplace pas un test visuel et tactile sur téléphone réel. Les contrôles, proportions, performances, collisions, lisibilité de l'interface et densité visuelle doivent être testés sur l'appareil cible avant de qualifier la version de finale commerciale.
