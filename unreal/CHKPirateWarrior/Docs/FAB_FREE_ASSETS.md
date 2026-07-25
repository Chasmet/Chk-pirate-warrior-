# Politique des assets gratuits Fab et Epic

## Règle légale

Les contenus Fab sont acquis depuis le compte Epic du propriétaire du projet. Ils ne sont pas recopiés comme fichiers sources dans ce dépôt public, sauf lorsque leur licence autorise explicitement cette redistribution. Les fichiers cuisinés peuvent être distribués dans le jeu final selon la licence applicable, mais les sources du pack ne doivent pas être proposées séparément.

## Sources gratuites prévues

### Quixel Megascans

Utilisation ciblée :

- rochers côtiers ;
- falaises ;
- sable, boue, neige et lave ;
- troncs, souches et petits éléments de végétation ;
- surfaces de bois, pierre et métal.

Les scans doivent être réduits pour Android : textures 1K ou 2K, LOD générés, collision simplifiée et Nanite désactivé pour les appareils mobiles visés.

### Contenu gratuit Epic Games

Utilisation ciblée :

- animations temporaires ;
- effets Niagara ;
- matériaux et exemples techniques ;
- personnages de test avant la création des héros définitifs ;
- accessoires de décor compatibles avec la bible graphique après modification.

### Starter Content Unreal

Utilisation uniquement comme base technique : matériaux, particules et sons de prototype. Aucun asset Starter Content ne doit définir l’identité finale du jeu.

## Assets créés spécialement pour CHK Pirate Warrior

Les sources suivantes sont déjà incluses dans le dépôt :

- `SM_CHK_Crate.obj` ;
- `SM_CHK_Rock_A.obj` ;
- `SM_CHK_Anchor.obj` ;
- `SM_CHK_DockModule.obj` ;
- `CHK_Original.mtl`.

Ces premiers modèles servent de base importable et seront remplacés ou enrichis par des versions sculptées, UV, texturées PBR et dotées de plusieurs LOD.

## Critères obligatoires avant intégration

- licence vérifiée ;
- style compatible avec le menu officiel ;
- textures limitées à la résolution réellement utile sur Android ;
- nombre de matériaux réduit ;
- LOD0 à LOD3 ;
- collision simple ;
- pas de Blueprint tiers indispensable au cœur du gameplay ;
- test sur téléphone avant validation.
