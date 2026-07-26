# CHK Pirate Warrior — V5 Final Qualité

## Base conservée

La V5 continue le véritable projet Godot 3D existant : neuf îles, océan continu, bateau pilotable, héros Cheikh/Yvane/Nelvyn, caméra troisième personne 360°, combats, météo, progression et sauvegarde.

## Correction des équipages 2.5D

Le rendu en rectangles ou blocs noirs a été supprimé.

Les deux équipages issus des références transmises utilisent maintenant le même principe de rendu que les trois héros :

- Sprite3D vertical dans le monde 3D ;
- fond noir détouré depuis les bords sans effacer les vêtements noirs ;
- personnage recadré sur sa silhouette réelle ;
- toile transparente de 256 × 256 ;
- pivot constant aux pieds ;
- taille physique propre à chaque personnage ;
- capsule de collision adaptée à la taille ;
- ombre au sol séparée ;
- planche de quatre poses : attente, deux poses de marche, attaque ;
- billboard fixe en Y, profondeur active et alpha scissor comme les héros.

La source visuelle reste l’atlas fourni. Le code ne remplace pas les personnages par des formes générées et ne génère aucune nouvelle image.

## Limite actuelle

Les atlas de référence embarqués ont une cellule source de 48 × 48 pixels. Le nouveau pipeline améliore fortement la présentation, le détourage et les proportions, mais il ne peut pas recréer les détails absents de la source. Pour obtenir exactement la finesse visuelle de Cheikh, Yvane et Nelvyn, il faudra ensuite disposer de véritables planches propres et haute résolution pour chaque personnage, idéalement avec les onze animations et quatre directions.

Ces personnages et noms appartiennent à une licence tierce. Cette intégration convient à un prototype privé, mais une autorisation des ayants droit ou un remplacement sera nécessaire avant une diffusion commerciale.

## Autres systèmes V5

- bouton de sauvegarde exacte à côté de Pause ;
- un seul emplacement, la nouvelle sauvegarde remplace l’ancienne ;
- position, rotation, caméra et état du bateau enregistrés ;
- deux équipages libres alliés, neutres ou hostiles sur les neuf îles ;
- deux navires associés et petits navires en circulation ;
- îles agrandies ;
- faune 3D et oiseaux supplémentaires ;
- soleil, nuages et transitions météo améliorés.

## Validation

GitHub Actions V5 run 220 :

- import Godot 4.6.3 : réussi ;
- test du pipeline 2.5D quatre poses : réussi ;
- test des deux équipages et de leurs proportions : réussi ;
- neuf îles et systèmes historiques : réussis ;
- caméra, navigation, pouvoirs, progression et sauvegarde : réussis ;
- APK Android construite, signée et publiée.

APK : `CHK-Pirate-Warrior-V5-Final-Qualite-debug.apk`

- taille : 47 277 007 octets ;
- SHA-256 : `633ec46e6f4043f3f72e7c954ca1543a21ebfc4a95a893458fd8b49d4bca579d` ;
- artefact GitHub Actions : `8633201701` ;
- commit validé : `aeed6a4d379d4d629d3380d733192455b6d3ecad`.

## Validation encore nécessaire

La PR reste en Draft jusqu’au test visuel sur téléphone. Il faut contrôler le détourage, les tailles relatives, les quatre poses, les performances et les collisions dans les neuf îles. Une compilation verte confirme le fonctionnement technique, pas la qualité visuelle finale sur chaque appareil Android.
