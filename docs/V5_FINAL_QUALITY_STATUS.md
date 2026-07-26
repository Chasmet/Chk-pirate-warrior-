# CHK Pirate Warrior V5 Final Qualité

## Continuité du jeu

La V5 prolonge le projet Godot 3D existant sans supprimer les héros, les neuf îles, la caméra 360°, le bateau pilotable, les combats, la météo, les missions, la progression et la sauvegarde.

## Équipages 2.5D issus des références fournies

Les équipages provisoires inventés ont été retirés.

Deux atlas 2.5D transparents ont été produits directement à partir des images transmises par Cheikh :

- Équipage du Chapeau de Paille ;
- Équipage du Roux.

Chaque roster contient dix personnages identifiés, soit vingt profils 2.5D. Douze personnages sont chargés sur l’île active : six de chaque équipage. Ils peuvent apparaître sur les neuf îles et changer de comportement entre allié, neutre et hostile. Les relations sont conservées dans la sauvegarde.

Les atlas sont découpés en dix cellules puis agrandis vers le format 256 × 256 attendu par le pipeline. Ils utilisent les apparences visibles dans les références fournies ; ils ne constituent pas encore les onze animations complètes dans quatre directions pour chacun des vingt personnages.

Ces personnages et noms appartiennent à une licence tierce. Cette intégration convient à un prototype privé, mais une autorisation des ayants droit ou un remplacement par des créations originales sera nécessaire avant toute diffusion commerciale.

## Navigation et monde

- navire associé au premier équipage : Thousand Sunny ;
- navire associé au second équipage : Red Force ;
- dix navires 3D supplémentaires en circulation ;
- routes maritimes entre les neuf îles ;
- îles agrandies de 24 % ;
- limites jouables, quais, ennemis et boss adaptés aux nouvelles dimensions.

Les deux bateaux d’équipage sont actuellement des modèles 3D simplifiés et colorés selon leur identité. Ils ne sont pas encore des reproductions 3D détaillées de leurs références.

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

Workflow `Construire CHK Pirate Warrior V5 Final Qualité`, run 209 : réussi.

- audit V5 et neuf rosters : réussi ;
- import Godot 4.6.3 sans erreur : réussi ;
- test des deux atlas provenant des références : réussi ;
- test V5 sauvegarde, équipages, flotte, faune, soleil et îles : réussi ;
- tests historiques des neuf îles et des 63 personnages importants : réussis ;
- tests caméra, navigation, pouvoirs, progression et sauvegarde : réussis ;
- export et validation APK Android : réussis.

APK : `CHK-Pirate-Warrior-V5-Final-Qualite-debug.apk`

- taille : 47 272 911 octets ;
- SHA-256 : `dacebd6abeb0115a40f74edeec63980478f4f29bdf3df89df6808424307c0d8e` ;
- artefact GitHub Actions : `8632932661` ;
- commit validé : `8dd34274d7614e38835fa6d4fec57cb051d68ba0`.

## Validation encore nécessaire

L’APK est compilée et les tests automatisés sont verts. Un test réel sur téléphone reste obligatoire avant fusion afin de vérifier les performances, la lisibilité des nouveaux atlas, la densité de la faune, les collisions des îles agrandies, les rencontres allié/neutre/hostile et la reprise exacte de la sauvegarde.
