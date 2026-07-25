# CHK Pirate Warrior — Unreal Engine 5.8 Android

Cette branche contient la migration parallèle du jeu vers Unreal Engine 5.8. La version Godot fonctionnelle reste intacte sur `v2-godot-3d`.

## Version autonome actuelle

Le projet Unreal génère le niveau jouable directement en C++. Il ne dépend pas d'une carte Blueprint préparée manuellement pour démarrer.

Au lancement, le jeu construit automatiquement :

- l'océan et l'atmosphère ;
- les six grandes îles ;
- les quais, bâtiments, rochers et végétations de base ;
- Cheikh, Yvane et Nelvyn ;
- le bateau pilotable et son poste de gouvernail ;
- huit ennemis différents par île ;
- un boss en trois phases par île ;
- le HUD mobile et les commandes tactiles ;
- la progression et la sauvegarde automatique.

## Gameplay disponible

### Héros

- **Cheikh** : Épée infernale du Cerbère, attaque lourde et onde de choc.
- **Yvane** : Éclair Serpentine, grande portée et impacts en chaîne.
- **Nelvyn** : Boule du Big Bang, explosion circulaire et forte projection.

Le joueur peut changer de héros en cours d'exploration.

### Combat

- attaques normales distinctes ;
- pouvoirs consommant de l'énergie ;
- esquive avec courte invulnérabilité ;
- ennemis mêlée, tireurs, brutes, soigneurs et assassins ;
- boss avec accélération, montée des dégâts et attaque spéciale par phases ;
- expérience, niveaux et pièces.

### Navigation

- embarquement par interaction près du navire ;
- pilotage manuel avec accélération et inertie ;
- caméra extérieure avec collision ;
- roulis, tangage, voile, gouvernail et pilote visibles ;
- voyage physique entre les six îles ;
- accostage et reprise du contrôle du héros.

## Commandes

### Android

- joystick gauche : déplacement ou direction du bateau ;
- joystick droit : caméra ;
- boutons à droite : attaque, pouvoir, esquive et bateau/accostage ;
- bouton héros en haut à droite : changement de personnage.

### Clavier/manette

- `WASD` / stick gauche : déplacement ;
- souris / stick droit : caméra ;
- clic gauche / bouton bas : attaque ;
- `E` / bouton droit : pouvoir ;
- espace / bouton gauche : esquive ;
- `F` / bouton haut : interaction ;
- `Tab` / gâchette gauche : héros.

## Sauvegarde

La sauvegarde automatique conserve :

- héros actif ;
- niveau ;
- expérience ;
- pièces ;
- zone actuelle ;
- îles débloquées ;
- entraînement ;
- boss vaincus ;
- qualité graphique.

## Budget téléphone

- plafond installé : **5 Go maximum** ;
- plafond de livraison : **4,5 Go maximum** ;
- build Shipping compressé ;
- arm64 uniquement ;
- textures Android ASTC ;
- contenu d'éditeur, test et debug exclu.

Le pipeline refuse automatiquement un paquet dépassant le budget.

## Assets

Le jeu peut fonctionner avec les formes et assets originaux inclus dans le dépôt. Les ressources gratuites Fab/Megascans sont prévues comme remplacements visuels progressifs, mais ne sont pas obligatoires pour lancer la base jouable.

Les assets gratuits liés à un compte Epic ne sont pas redistribués illégalement dans le dépôt public.

## Fichiers principaux

```text
unreal/CHKPirateWarrior/CHKPirateWarrior.uproject
unreal/CHKPirateWarrior/Source/CHKPirateWarrior/CHKGameMode.cpp
unreal/CHKPirateWarrior/Source/CHKPirateWarrior/CHKWorldBootstrap.cpp
unreal/CHKPirateWarrior/Source/CHKPirateWarrior/CHKCharacter.cpp
unreal/CHKPirateWarrior/Source/CHKPirateWarrior/CHKEnemyCharacter.cpp
unreal/CHKPirateWarrior/Source/CHKPirateWarrior/CHKBoatPawn.cpp
unreal/CHKPirateWarrior/Source/CHKPirateWarrior/CHKPlayerController.cpp
unreal/CHKPirateWarrior/Source/CHKPirateWarrior/CHKHUD.cpp
```

## Validation

```bash
python unreal/CHKPirateWarrior/Scripts/validate_turnkey_source.py
python unreal/CHKPirateWarrior/Scripts/check_mobile_size_budget.py unreal/CHKPirateWarrior
```

GitHub Actions valide automatiquement la structure complète et publie une archive du projet source.

## Compilation Android

Le workflow `Construire APK Unreal Engine 5.8` exécute Unreal Automation Tool en mode Shipping, cuisine les ressources, crée le paquet Android, vérifie sa taille et publie l'APK comme artefact.

La génération d'une APK Unreal nécessite obligatoirement qu'Unreal Engine 5.8 s'exécute sur une machine ou un runner compatible. Les sources du jeu sont préparées automatiquement sur GitHub ; l'APK ne doit être annoncée comme disponible qu'après réussite réelle de ce workflow.
