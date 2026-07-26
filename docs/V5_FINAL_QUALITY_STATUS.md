# CHK Pirate Warrior V5 Final Qualité

## Continuité du jeu

La V5 prolonge le projet Godot 3D existant sans supprimer les héros, les neuf îles, la caméra 360°, le bateau pilotable, les combats, la météo, les missions, la progression et la sauvegarde.

## Équipages itinérants originaux

Les références visuelles sous licence fournies par l’utilisateur n’ont pas été copiées dans le jeu. Deux équipages pirates originaux ont été créés :

- Équipage de l’Aurore — navire : L’Aurore Boréale ;
- Flotte Écarlate — navire : Le Souverain Écarlate.

Chaque équipage possède dix membres originaux, soit vingt profils 2.5D. Douze membres sont chargés sur l’île active : six de chaque équipage. Ils peuvent apparaître sur les neuf îles et changer de comportement entre allié, neutre et hostile. Les relations sont conservées dans la sauvegarde.

Les assets 2.5D sont générés en 256 × 256 avec fond transparent. Ils représentent actuellement des poses lisibles et distinctes ; ils ne constituent pas encore les onze animations complètes dans quatre directions pour chacun des vingt membres.

## Navigation et monde

- deux grands navires propres aux équipages ;
- dix navires 3D supplémentaires en circulation ;
- routes maritimes entre les neuf îles ;
- îles agrandies de 24 % ;
- limites jouables, quais, ennemis et boss adaptés aux nouvelles dimensions.

## Sauvegarde exacte

Un bouton `SAUVEG.` est placé immédiatement à côté du bouton `PAUSE`.

La sauvegarde enregistre et restaure :

- la position XYZ exacte ;
- l’orientation du héros ;
- l’orientation de la caméra ;
- l’île active ;
- l’état à terre ou en bateau ;
- le cap et la vitesse du bateau ;
- la progression et les relations avec les équipages.

Un seul emplacement est utilisé : chaque sauvegarde remplace la précédente.

## Faune, météo et rendu

- huit animaux 3D supplémentaires par île ;
- davantage de mouettes et d’aigles 3D ;
- LOD et distance de visibilité appliqués à la faune ;
- soleil visible et couleur dynamique ;
- nuages mobiles ;
- transitions météo progressives ;
- contraste, saturation, éclairage et ombres ajustés ;
- conservation du moteur mobile OpenGL et des protections de stabilité existantes.

## Validation GitHub Actions

Workflow `Construire CHK Pirate Warrior V5 Final Qualité`, run 188 : réussi.

- audit V5 et neuf rosters : réussi ;
- import Godot 4.6.3 sans erreur : réussi ;
- test V5 sauvegarde, équipages, flotte, faune, soleil et îles : réussi ;
- tests historiques des neuf îles et des 63 personnages importants : réussis ;
- tests caméra, navigation, pouvoirs, progression et sauvegarde : réussis ;
- export et validation APK Android : réussis.

APK : `CHK-Pirate-Warrior-V5-Final-Qualite-debug.apk`

- taille : 47 256 320 octets ;
- SHA-256 : `d24ebd2f3f343f911ae1de191252f3ba33aa6b6dc26194ce898e5697c7009efc` ;
- artefact GitHub Actions : `8632674018` ;
- commit validé : `a11921558b6e65b82653a9121ba458047baf3643`.

## Validation encore nécessaire

L’APK est compilée et les tests automatisés sont verts. Un test réel sur téléphone reste obligatoire avant fusion afin de vérifier les performances, la lisibilité des nouveaux personnages, la densité de la faune, les collisions des îles agrandies, les rencontres ami/ennemi et la reprise exacte de la sauvegarde.
