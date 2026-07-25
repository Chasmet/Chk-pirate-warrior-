# CHK Pirate Warrior — migration Unreal Engine 5.8

Cette branche contient une migration parallèle du jeu Godot vers Unreal Engine 5.8. Le projet Godot reste intact tant que la version Unreal n’a pas atteint la parité fonctionnelle.

## Objectifs de la première phase

- recréer la caméra troisième personne et la jouabilité tactile ;
- porter Cheikh, Yvane et Nelvyn ;
- porter le bateau, les quais et la navigation entre les six îles ;
- conserver la progression, les boss vaincus, les pièces, l’expérience et les îles débloquées ;
- préparer une chaîne de production de vrais assets 3D riggés ;
- viser Android 64 bits avec Vulkan, SDK cible 35 et niveau d’installation minimum 26 ;
- garder une version mobile optimisée plutôt qu’un rendu PC impossible à tenir sur téléphone.

## État de cette base

Le dossier `CHKPirateWarrior` contient un projet C++ Unreal Engine 5.8 ouvrable dans l’éditeur. Il fournit :

- un personnage troisième personne ;
- une caméra orbitale avec collision ;
- un pawn de bateau pilotable ;
- une structure de sauvegarde équivalente à la sauvegarde Godot ;
- les six îles et leurs coordonnées de référence ;
- les réglages Android de base ;
- une liste d’assets gratuits à acquérir légalement via Fab ;
- des assets originaux au format OBJ importables dans Unreal ;
- un script d’import Unreal Python ;
- un workflow de validation de la structure du projet.

## Important sur les assets Fab

Les assets gratuits de Fab ne sont pas copiés directement dans ce dépôt public. Leur licence est liée au compte Epic qui les acquiert et ne permet pas toujours de redistribuer les fichiers sources séparément. Le dépôt contient donc un manifeste, des chemins cibles et un script d’intégration. Les assets originaux créés spécialement pour CHK Pirate Warrior sont, eux, inclus dans `ContentSource/Original`.

## Ouverture

1. Installer Unreal Engine 5.8.
2. Installer Android Studio Koala 2024.1.2 Patch 1, SDK 35, NDK r27c et OpenJDK 21.
3. Ouvrir `unreal/CHKPirateWarrior/CHKPirateWarrior.uproject`.
4. Générer les fichiers de projet C++ si Unreal le demande.
5. Compiler la cible `CHKPirateWarriorEditor`.
6. Dans Unreal, activer Python, puis exécuter `Scripts/import_original_assets.py`.
7. Créer les niveaux à partir du plan décrit dans `Docs/ARCHIPEL_UE5.md`.

## Règle de migration

Aucune fonctionnalité Godot n’est supprimée avant d’avoir été reconstruite et testée dans Unreal. La migration se fait système par système, avec validation Android à chaque étape.
