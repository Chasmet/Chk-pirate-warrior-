# Architecture de l’archipel Unreal Engine

Les coordonnées Godot sont conservées, converties de mètres en centimètres Unreal. L’axe Godot Z horizontal devient l’axe Unreal Y.

| Île | Centre Unreal | Rayon | Météo | Boss |
|---|---:|---:|---|---|
| Port des Naufragés | X 0, Y 0 | 10 800 cm | soleil marin | Brakor |
| Jungle Sauvage | X 31 500, Y -17 500 | 11 600 cm | pluie tropicale | Scorpia |
| Royaume des Neiges | X 65 500, Y -7 200 | 10 400 cm | neige | Kryl |
| Désert des Corsaires | X 27 500, Y 26 000 | 12 200 cm | chaleur et sable | Mako |
| Île Volcanique | X 62 500, Y 29 500 | 10 200 cm | cendres | Volkan |
| Forteresse de la Tempête | X 95 500, Y 10 500 | 13 200 cm | orage violent | Vorga |

## Structure des niveaux

- `L_PersistentArchipelago` : océan, ciel, météo globale, streaming et routes maritimes.
- `L_Island_01_Port` à `L_Island_06_StormFortress` : un niveau streamé par île.
- `L_BossArena_01` à `L_BossArena_06` : arènes dédiées, chargées avec l’île correspondante.
- `L_Training` : entraînement indépendant.
- `L_MainMenu` : menu conforme à la bible graphique.

## World Partition

Le monde persistant doit utiliser World Partition avec cellules adaptées au mobile. Les îles éloignées ne doivent pas rester chargées simultanément avec leurs ennemis, animaux, effets et audio complets.

## Cibles Android

- 60 images/s sur appareils haut de gamme ;
- profil de secours à 30 images/s ;
- mémoire textures contrôlée ;
- maximum conseillé de 2K pour un asset principal et 1K pour la majorité des accessoires ;
- HLOD pour bâtiments et végétation ;
- ombres dynamiques limitées aux personnages, boss et éléments proches ;
- effets Niagara avec budgets par qualité.

## Ordre de migration

1. Port des Naufragés complet.
2. Cheikh jouable et riggé.
3. Bateau et traversée vers la Jungle.
4. Huit ennemis et Brakor.
5. Sauvegarde compatible avec la progression existante.
6. Duplication de la structure vers les cinq autres îles, sans cloner leur identité visuelle.
