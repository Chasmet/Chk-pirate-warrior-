# CHK Pirate Warrior — L’Archipel des Onze Royaumes

Jeu d’action-aventure 3D Android en français, pensé pour téléphone en mode paysage et jouable hors connexion.

## Version actuelle : V11 Onze Royaumes

La branche `main` utilise désormais la vraie base **Godot 3D**. L’ancienne génération Android Java/Canvas n’est plus la version de référence.

### Monde et exploration

- **11 royaumes/régions** dans le catalogue du monde ouvert ;
- neuf îles historiques reliées par un océan continu ;
- une région de marais accessible en exploration libre ;
- une onzième région finale : **Royaume Troublé** ;
- bateau réellement pilotable en troisième personne ;
- accostage et embarquement via le HUD tactile ;
- caméra troisième personne 360° ;
- météo, état de mer, relief, collisions et navigation ;
- carte du monde des Onze Royaumes.

### Royaume Troublé

La dernière région est volontairement abandonnée :

- aucun habitant ;
- aucune faune ;
- brume dorée et fragments de mémoire ;
- palais fissuré ;
- horloge géante ;
- bibliothèque oubliée ;
- miroirs brisés ;
- portes flottantes ;
- ruines et sanctuaire ;
- quai **Pont du Retour Impossible**.

Le joueur peut réellement y accoster, explorer l’île, trouver le **Cœur des Souvenirs**, sauvegarder sa découverte puis continuer à explorer librement.

## Personnages et monde vivant

- trois héros jouables : **Cheikh**, **Yvane** et **Nelvyn** ;
- combat, combos, compétences, aura et esquive ;
- progression, boss, pièces et sauvegarde locale ;
- deux équipages autonomes supplémentaires avec leurs navires ;
- flotte ambiante ;
- 200 habitants simulés dans les dix régions vivantes ;
- 20 habitants proches maximum matérialisés à la fois ;
- streaming limité à trois racines de régions visibles pour conserver un budget compatible Android ;
- habitants V11 représentés par des silhouettes humaines stylisées articulées au lieu des capsules provisoires V9.

## Interface CHK

La V11 intègre :

- le logo/icône CHK déjà présent dans le projet ;
- le bandeau **CHK PIRATE WARRIOR — L’ARCHIPEL DES ONZE ROYAUMES** ;
- une carte de 11 régions ;
- des messages HUD dédiés au Royaume Troublé ;
- un retour visuel lors de la découverte du Cœur des Souvenirs.

## Télécharger le bon APK

Le bon workflow est désormais :

**Construire CHK Pirate Warrior V11 Onze Royaumes**

Dans l’onglet **Actions** :

1. ouvrir la dernière exécution verte de ce workflow sur `main` ;
2. télécharger l’artifact **CHK-Pirate-Warrior-V11-Onze-Royaumes-APK** ;
3. extraire le ZIP ;
4. installer `CHK-Pirate-Warrior-V11-Onze-Royaumes-debug.apk`.

L’ancien workflow automatique Android V1 a été retiré afin d’éviter de republier par erreur l’ancienne génération Canvas.

## Validation V11

Le workflow V11 :

- importe et analyse tous les scripts Godot ;
- rejoue les tests de stabilité V8 ;
- rejoue les tests monde ouvert V9 ;
- exécute les tests V11 ;
- vérifie notamment le scénario bateau → **ACCOSTER** → débarquement sur le Royaume Troublé → **EMBARQUER** ;
- construit un vrai APK Android avec Godot ;
- vérifie son intégrité et refuse un APK anormalement petit ;
- publie l’APK, sa taille, son SHA-256 et les journaux de validation.

Une compilation verte valide la cohérence technique. Un test visuel et tactile sur téléphone réel reste nécessaire pour régler le ressenti final, les proportions, les performances et la lisibilité.

## Commandes principales

- joystick gauche : déplacement ;
- stick/glissement caméra : caméra 360° ;
- **ATTAQUE** : combo ;
- **POUVOIR** : compétence spéciale ;
- **ESQUIVE** : déplacement rapide ;
- **DÉFERLER** : aura/transformation temporaire ;
- **HÉROS** : changer de personnage ;
- **CARTE** : consulter les royaumes et choisir une destination historique ;
- **EMBARQUER / ACCOSTER** : prendre ou quitter le bateau au quai ;
- **PAUSE** : sauvegarde et menu.

## À propos des GLB

À la date de cette V11, **aucun fichier `.glb` n’est présent dans l’arbre Git de `main`**. Les documents historiques du dépôt indiquaient également que plusieurs modèles GLB optimisés et planches d’animation finales restaient à intégrer.

La V11 n’invente donc aucun faux GLB. Les nouveaux habitants et éléments du Royaume Troublé utilisent actuellement des meshes Godot optimisés générés dans le projet.

Pour une finition visuelle de niveau commercial, les modèles GLB réellement validés devront être ajoutés au dépôt, idéalement via Git LFS si nécessaire, puis raccordés aux personnages, animaux, bâtiments, bateaux et objets.

## Structure

- `godot/` : jeu V11 Godot réellement compilé ;
- `godot/scripts/` : gameplay, monde ouvert, UI, habitants, bateau et systèmes V11 ;
- `godot/tests/` : tests V8/V9/V11 ;
- `.github/workflows/build-v11-onze-royaumes.yml` : validation et compilation APK V11 ;
- `docs/V11_ONZE_ROYAUMES_STATUS.md` : état technique détaillé ;
- `app/` : ancienne base Java conservée uniquement comme référence historique.

L’univers, les héros et les ennemis sont originaux.