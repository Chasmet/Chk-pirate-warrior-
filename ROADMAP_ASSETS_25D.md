# Feuille de route - Assets 2.5D et faune 3D

## Règle de validation

Un personnage n'est pas terminé uniquement parce que sa fiche JSON ou une illustration de référence existe. Il devient terminé seulement lorsque :

1. sa planche artistique de référence est verrouillée ;
2. toutes ses bandes d'animation WEBP transparentes existent ;
3. les quatre directions sont cohérentes ;
4. le pivot est centré au niveau des pieds ;
5. le moteur Android charge réellement les bandes ;
6. les collisions et attaques correspondent aux frames ;
7. GitHub Actions valide les tests, le lint et `assembleDebug` ;
8. un test sur téléphone confirme le rendu et la stabilité.

## Héros originaux protégés

- [x] Cheikh conservé dans le projet.
- [x] Yvane conservé dans le projet.
- [x] Nelvyn conservé dans le projet.
- [ ] Retrouver et reconnecter les planches artistiques originales exactes du menu officiel.
- [ ] Remplacer les frames provisoires générées par `Character25D`.
- [ ] Valider marche, course, attaque, saut, dégâts, esquive et pilotage.

## Infrastructure commune

- [x] Catalogue Java des 42 ennemis importants 2.5D.
- [x] Catalogue JSON synchronisé avec les six rosters officiels.
- [x] Format WEBP transparent 256 x 256 par frame.
- [x] Chargeur Android `SpriteStrip25D`.
- [x] Cache `Enemy25DAssetBank` limité aux sept personnages de l'île active.
- [x] Libération des textures au changement d'île.
- [x] Journalisation des fichiers manquants et invalides.
- [x] Fallback conservé lorsque les bandes sont absentes.
- [ ] Liaison complète animation / attaque / collision / recul / défaite.
- [ ] Vérification visuelle automatique des pivots et dimensions.

## État réel des six îles

Le PDF officiel contient une référence visuelle pour chaque île. Il ne contient pas encore les bandes WEBP transparentes finales prêtes à être utilisées directement par le moteur.

### Île 1 - Port des Naufragés

Roster officiel :

- Boss : Brakor.
- Commandants : Tireur des Quais, Maître Croc, Ingénieur des Amarres.
- Subordonnés importants : Voleur Agile, Porte-Chaîne, Guetteur du Phare.

État :

- [x] Référence visuelle reçue.
- [x] Noms et identifiants verrouillés.
- [ ] `sheet.webp` transparent de Brakor.
- [ ] Bandes de Brakor : idle, walk, run, attack, power, special, dodge, hurt, knockback, defeat, intro, rage, phase2, area_attack, ultimate.
- [ ] Bandes des six autres personnages.
- [ ] Intégration IA et test sur téléphone.

### Île 2 - Jungle Sauvage

Roster officiel :

- Boss : Malkor.
- Commandants : Zaya, Kongo, Silex.
- Subordonnés importants : Ronce, Tika, Mamba.

État :

- [x] Référence visuelle reçue.
- [x] Noms et identifiants verrouillés.
- [ ] Planches transparentes et bandes d'animation.
- [ ] Intégration IA et test sur téléphone.

### Île 3 - Royaume des Neiges

Roster officiel :

- Boss : Skarn.
- Commandants : Eira, Volkr, Nivor.
- Subordonnés importants : Brume, Harka, Flint.

État :

- [x] Référence visuelle détaillée reçue.
- [x] Noms et identifiants verrouillés.
- [ ] Extraire ou redessiner de vraies bandes transparentes ; les miniatures de la planche ne sont pas des assets finaux.
- [ ] Intégration IA et test sur téléphone.

### Île 4 - Désert des Corsaires

Roster textuel officiel utilisé par le code :

- Boss : Zahrek.
- Commandants : Qamar, Sirok, Dune.
- Subordonnés importants : Khepri, Safra, Rakh.

État :

- [x] Référence visuelle reçue.
- [x] Roster textuel verrouillé dans le code.
- [!] L'illustration du PDF affiche des noms différents ; validation artistique nécessaire avant la production finale.
- [ ] Planches transparentes et bandes d'animation.
- [ ] Intégration IA et test sur téléphone.

### Île 5 - Île Volcanique

Roster officiel :

- Boss : Vulkar.
- Commandants : Cendre, Magma, Pyros.
- Subordonnés importants : Basalte, Scorie, Fumar.

État :

- [x] Référence visuelle détaillée reçue.
- [x] Noms et identifiants verrouillés.
- [ ] Planches transparentes et bandes d'animation.
- [ ] Intégration IA et test sur téléphone.

### Île 6 - Forteresse de la Tempête

Roster officiel :

- Boss : Tempyr.
- Commandants : Orage, Volt, Cyclone.
- Subordonnés importants : Brisk, Tonnerre, Fulgur.

État :

- [x] Référence visuelle détaillée reçue.
- [x] Noms et identifiants verrouillés.
- [ ] Planches transparentes et bandes d'animation.
- [ ] Intégration IA et test sur téléphone.

## Faune et créatures 3D

- [x] Catalogue de 48 espèces ou variantes.
- [x] Huit entrées prévues par île.
- [x] Budget maximal d'instances défini.
- [ ] Modèles GLB optimisés.
- [ ] Textures compressées.
- [ ] LOD proche, moyen et lointain.
- [ ] IA de fuite, chasse, territoire, vol et nage.
- [ ] Limitation automatique selon la puissance du téléphone.

## Ordre de production

1. reconnecter les trois héros originaux ;
2. produire Brakor et ses bandes complètes ;
3. produire les six personnages importants du Port des Naufragés ;
4. intégrer les animations aux états d'IA ;
5. valider mémoire, collisions et fluidité sur Android ;
6. demander une vidéo de gameplay ;
7. corriger avant de passer à la Jungle Sauvage ;
8. continuer île par île dans l'ordre officiel ;
9. intégrer ensuite les animaux 3D avec LOD ;
10. fusionner dans `main` uniquement après validation complète.
