# CHK Pirate Warrior — L’Archipel des Quinet

Jeu d’action-aventure 3D Android en français, pensé exclusivement pour téléphone en mode paysage et jouable hors connexion.

## Version 2.5 — gameplay, navigation et météo fiabilisés

Cette version reconstruit la V2 autour de l’illustration officielle du jeu :

- menu principal fidèle à l’image de référence, avec toutes les zones tactiles ;
- trois héros uniquement : **Cheikh**, **Yvane** et **Nelvyn** ;
- personnages HD visibles de dos avec quatre poses chacun : repos, course, attaque et déferlement ;
- héros rendu dans le monde 3D avec profondeur réelle, sans copie géante superposée dans le HUD ou le menu Pause ;
- véritable caméra troisième personne derrière l’épaule, avec collision dans le décor et suivi amorti ;
- bâtiments, monuments et quais dotés de collisions afin que le héros et la caméra ne traversent plus les volumes ;
- second stick **CAMÉRA 360°** sur la partie gauche, avec vue du visage puis recentrage progressif derrière le héros ;
- locomotion relative à la caméra : marche/course analogique, accélération, freinage et demi-tours fluides ;
- commandes mobiles revues : joystick analogique proportionnel, glissement caméra, attaque maintenue et esquive ;
- assistance de combat temporaire qui n’arrache plus le contrôle de la caméra au joueur ;
- six grandes îles réellement séparées dans un archipel ouvert, chacune avec quai, balise et monument propre ;
- carte utilisée comme GPS : les îles ne sont plus téléportées, elles se débloquent en y accostant ;
- navigation réellement à la troisième personne : héros visible derrière la barre, mains au gouvernail et poses gauche/centre/droite reliées au joystick ;
- bateau agrandi et détaillé avec coque bordée, cabine, vitres, pont, voile rayée, figure de proue, poste de pilotage, gouvernail arrière, lanternes et sillage ;
- conduite plus naturelle avec accélération progressive, inertie, dérive maîtrisée, gouvernail amorti, roulis et caméra marine cadrant le navire entier ;
- collision navire dédiée, pilote placé physiquement au gouvernail, houle synchronisée et résistance accrue sous mauvais temps ;
- météo dynamique agissant sur les particules, le brouillard, la lumière, le ciel, le vent, les vagues et les performances du bateau ;
- îles entièrement remodélisées avec rivages irréguliers, relief praticable, matériaux sol/sable/roche, zones humides et écume côtière ;
- forêts et sous-bois enrichis : palmes, couronnes de feuillage, arbustes, troncs échoués et herbe dense animée par le vent ;
- soixante animaux animés répartis dans l’archipel : mouettes, sangliers, singes, cerfs, pingouins, aigles, chameaux et lézards ;
- indications permanentes vers le quai et la destination, avec distance et direction ;
- trois difficultés : **Découverte** sans mort, **Intermédiaire** équilibrée et **Difficile** renforcée ;
- ennemis enrichis avec visages, vêtements, rôles, armes et réactions plus lisibles ;
- six boss exclusifs : Brakor, Scorpia, Kryl, Mako, Volkan et Vorga, avec un design propre à chaque île ;
- attaques, pouvoirs, combos et déferlements d’énergie propres à chaque héros ;
- traînées d’impact, télégraphes, assistance de portée et réactions de combat renforcées ;
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
- Stick **CAMÉRA 360°** à gauche : tourner autour du héros et le voir de face.
- Glissement sur la partie droite : rotation libre de la caméra troisième personne.
- Pousser doucement le joystick : marche précise ; pousser jusqu’au bord : course.
- **ATTAQUE** : appui simple ou maintenu pour enchaîner le combo.
- **POUVOIR** : technique spéciale consommant de l’énergie.
- **ESQUIVE** : déplacement rapide avec courte invulnérabilité.
- **DÉFERLER** : transformation temporaire quand l’aura atteint 100 %.
- **HÉROS** : Cheikh → Yvane → Nelvyn.
- **CARTE** : choisir une destination et afficher son cap, sans téléportation.
- **EMBARQUER / ACCOSTER** : prendre la barre au quai et débloquer une île en l’atteignant.
- **PAUSE** : sauvegarde et menu.

## Validation locale

Avec Godot 4.7.1 :

```bash
godot --headless --editor --path godot --quit
godot --headless --path godot --quit-after 180
godot --headless --path godot --script res://tests/smoke_test.gd
```

Le smoke test couvre 84 points : atterrissage réel sur le relief, héros 3D, caméra orbitale avec visage visible, orientation du héros, traversée complète en bateau, dégagement du quai, balise de destination mobile, météo, gouvernail, collisions de décor, animaux, végétation, combat, accostage, déblocage, difficultés, boss, carte et interface. Le workflow GitHub vérifie ensuite l’import, le démarrage, l’APK signée, le mode paysage et l’exécution sur un téléphone Android virtuel.

## Univers

L’univers, les héros et les ennemis sont originaux. Le jeu reprend l’énergie d’une grande aventure de pirates sans utiliser de personnages, logos ou contenus officiels d’une licence existante.
