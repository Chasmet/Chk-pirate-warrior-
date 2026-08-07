# CHK Pirate Warrior — L'Archipel des Onze Royaumes

Jeu d'action-aventure Android natif en Java, jouable hors connexion.

## V2 — reconstruction majeure

La branche `v2-major-rebuild` remplace le prototype V1 par une nouvelle boucle de jeu structurée autour de 11 îles/royaumes.

### Campagne

1. Royaume des Palmes
2. Royaume des Roches
3. Royaume de Nourriture
4. Jungle Interdite
5. Royaume des Glaces
6. Terres du Volcan
7. Archipel du Ciel
8. Cité Néon
9. Mer des Spectres
10. Empire Ancien
11. Royaume Troublé

Chaque île dispose de son biome, sa météo, son objectif, ses ennemis, son boss et sa direction artistique. La dernière île contient l'objet rare qui conclut la campagne.

### Systèmes V2

- trois héros : Cheikh, Yvane et Nelvyn ;
- déplacement tactile relatif à la caméra ;
- caméra orientable par glissement sur la partie droite de l'écran ;
- combat normal, pouvoir et déferlement ;
- ennemis et boss avec montée en difficulté ;
- progression, XP, niveaux, pièces et combos ;
- carte complète des 11 îles avec déblocage progressif ;
- pontons, embarquement et débarquement ;
- bateau contrôlable au joystick ;
- environnements procéduraux par biome ;
- pluie, tempête, neige, cendres et brume dorée ;
- sauvegarde locale automatique ;
- narration française Android TTS ;
- fonctionnement sans compte, publicité ou serveur ;
- nouveau logo CHK et nouvelle interface plein écran.

## Technique

- Android natif ;
- Java uniquement ;
- minSdk 21 ;
- targetSdk 34 ;
- compileSdk 34 ;
- Java 17 ;
- Gradle 8.9 / Android Gradle Plugin 8.7.3.

## Compilation

GitHub Actions exécute réellement :

```bash
./gradlew clean testDebugUnitTest lintDebug assembleDebug
```

L'APK de debug est publié comme Artifact sous le nom `CHK-Pirate-Warrior-V2-APK`.

## Commandes

- joystick gauche : déplacement du héros ou du bateau ;
- glissement à droite : rotation de caméra ;
- **ATTAQUE** : attaque principale ;
- **POUVOIR** : technique spéciale ;
- **AURA** : déferlement lorsque la jauge est pleine ;
- **BATEAU** : embarquer près d'un ponton ;
- **DÉBARQ.** : débarquer en revenant au ponton ;
- **CARTE** : choisir une île débloquée ;
- **PAUSE** : sauvegarde et menu.

## Important

La V1 reste dans `PirateGameView.java` comme référence historique, mais l'application V2 démarre désormais sur `WorldGameView.java` via `MainActivity`.
