# CHK Pirate Warrior V4.0 — neuf îles

## Base conservée

La V4.0 continue le véritable projet Godot 3D existant. Elle conserve Cheikh, Yvane et Nelvyn, la caméra libre à 360°, le bateau pilotable, l’océan, les combats, les missions, la météo, la progression et la sauvegarde.

## Archipel 3D

Les six îles existantes sont conservées et trois zones sont ajoutées au même monde ouvert :

7. Île des Gâteaux : terrain, ville pâtissière, château, tours, caramel, arbres et maisons en volumes 3D.
8. Citadelle du Crâne : forteresse-crâne, tours, cornes, magma et failles en volumes 3D.
9. Royaume Céleste : masse rocheuse suspendue, palais blanc et or, nuages, colonnes d’eau et quai maritime en volumes 3D.

Le joueur navigue lui-même sur l’océan jusqu’aux quais. Pour l’île 9, le bateau atteint un quai au niveau de la mer, puis l’accès céleste conduit au plateau suspendu.

## Personnages

Chaque île possède 1 Boss, 3 Commandants et 3 Nakamas. Les 63 personnages importants sont rendus en 2.5D dans le monde 3D. Les terrains, bâtiments, animaux, ennemis ordinaires, bateau et collisions restent en 3D.

`Enemy25DAssetBank` charge uniquement les sept personnages importants de l’île active et libère l’ancien atlas au changement d’île.

## Validation GitHub Actions

Workflow V4.0, run 150 : réussi sur le commit `d6892ca8cd14d24c20cb29e7c615464647368f92`.

- audit des neuf rosters : réussi ;
- import Godot 4.6.3 : réussi ;
- test des neuf îles, de l’océan et des quais : réussi ;
- vérification des décors 3D des îles 7, 8 et 9 : réussie ;
- test des 63 personnages importants et du bateau : réussi ;
- tests caméra, pouvoirs, navigation et progression : réussis ;
- export APK Android : réussi.

APK : `CHK-Pirate-Warrior-V4.0-debug.apk`

- taille : 47 201 211 octets ;
- SHA-256 : `7deede8abf62162f4441023c18da8d9dddb4994e5db1b85b3cd6b5acf2fde195`.

## Limite actuelle

Les atlas 2.5D représentent les personnages fournis, mais les onze animations complètes dans quatre directions ne sont pas encore toutes disponibles. La validation visuelle et des performances sur téléphone reste obligatoire avant fusion.
