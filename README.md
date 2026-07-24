# CHK Pirate Warrior — L’Archipel des Quinet

Jeu d’action-aventure 3D Android en français, pensé exclusivement pour téléphone en mode paysage et jouable hors connexion.

## Version 2.1 — édition fidèle

Cette version reconstruit la V2 autour de l’illustration officielle du jeu :

- menu principal fidèle à l’image de référence, avec toutes les zones tactiles ;
- trois héros uniquement : **Cheikh**, **Yvane** et **Nelvyn** ;
- personnages HD distincts avec quatre poses chacun : repos, course, attaque et déferlement ;
- commandes mobiles revues : joystick analogique proportionnel, attaque maintenue, esquive et caméra tactile ;
- caméra de combat stabilisée avec assistance temporaire à la cible ;
- six régions, météo, cycle jour/nuit, ennemis, boss et limites d’île sécurisées ;
- attaques, pouvoirs, combos et déferlements d’énergie propres à chaque héros ;
- progression, niveaux, pièces, entraînement et sauvegarde automatique locale ;
- narration française Android, sans compte, publicité ni serveur.

Le projet V2 réellement compilé se trouve dans `godot/`. Le dossier `app/` contient l’ancienne V1 Java conservée comme référence.

## Installer l’APK V2

1. Ouvrir l’onglet **Actions** du dépôt.
2. Ouvrir la dernière exécution verte **Valider et construire V2 Godot 3D**.
3. Télécharger l’artifact **CHK-Pirate-Warrior-V2-APK**.
4. Extraire le ZIP puis installer `CHK-Pirate-Warrior-V2-debug.apk`.

Android peut demander l’autorisation d’installer une application provenant du navigateur ou de GitHub.

## Commandes

- Joystick gauche : déplacement analogique.
- Glissement au centre/droite : rotation de la caméra.
- **ATTAQUE** : appui simple ou maintenu pour enchaîner le combo.
- **POUVOIR** : technique spéciale consommant de l’énergie.
- **ESQUIVE** : déplacement rapide avec courte invulnérabilité.
- **DÉFERLER** : transformation temporaire quand l’aura atteint 100 %.
- **HÉROS** : Cheikh → Yvane → Nelvyn.
- **CARTE** : voyage entre les six régions.
- **PAUSE** : sauvegarde et menu.

## Validation locale

Avec Godot 4.7.1 :

```bash
godot --headless --editor --path godot --quit
godot --headless --path godot --quit-after 180
godot --headless --path godot --script res://tests/smoke_test.gd
```

Le workflow GitHub vérifie ensuite l’import, le démarrage, le gameplay, l’APK signée, le mode paysage et l’exécution sur un téléphone Android virtuel.

## Univers

L’univers, les héros et les ennemis sont originaux. Le jeu reprend l’énergie d’une grande aventure de pirates sans utiliser de personnages, logos ou contenus officiels d’une licence existante.
