# Feuille de route — Assets 2.5D et faune 3D

## Règle de validation

Un personnage n'est **pas terminé** uniquement parce que sa fiche JSON existe. Il devient terminé seulement lorsque :

1. sa planche artistique `sheet.webp` est produite ;
2. toutes ses bandes d'animation WEBP existent ;
3. les quatre directions sont cohérentes ;
4. le moteur Android les charge réellement ;
5. les collisions et attaques correspondent aux frames ;
6. GitHub Actions valide les tests, le lint et `assembleDebug` ;
7. un test sur téléphone confirme la stabilité.

## Personnages originaux protégés

- [x] Cheikh conservé dans le projet.
- [x] Yvane conservé dans le projet.
- [x] Nelvyn conservé dans le projet.
- [ ] Retrouver et reconnecter les planches artistiques originales exactes.
- [ ] Remplacer les frames provisoires générées par le code.
- [ ] Valider les animations marche, course, attaque, saut, dégâts et pilotage.

## Infrastructure commune

- [x] Catalogue Java des 42 ennemis importants 2.5D.
- [x] Catalogue JSON des chemins et palettes.
- [x] Format officiel des planches de référence.
- [x] Format mobile des bandes d'animation.
- [x] Chargeur Android `SpriteStrip25D`.
- [x] Tests sur les quantités, identifiants et chemins.
- [ ] Gestionnaire de cache par île.
- [ ] Libération automatique des textures au changement d'île.
- [ ] Fallback visuel lorsque l'asset est absent.
- [ ] Liaison animation/attaque/collision.

## Boss 2.5D

### Île 1 — Baie solaire

- [x] Fiche technique : Capitaine Hélios.
- [ ] Planche artistique WEBP.
- [ ] Bandes d'animation.
- [ ] Phase 2 et attaque ultime.
- [ ] Intégration moteur.

### Île 2 — Royaume des glaces

- [x] Fiche technique : Roi Boréal.
- [ ] Planche artistique WEBP.
- [ ] Bandes d'animation.
- [ ] Phase 2 et attaque ultime.
- [ ] Intégration moteur.

### Île 3 — Désert des corsaires

- [x] Fiche technique : Sultan des Dunes.
- [ ] Planche artistique WEBP.
- [ ] Bandes d'animation.
- [ ] Phase 2 et attaque ultime.
- [ ] Intégration moteur.

### Île 4 — Volcan rouge

- [x] Fiche technique : Seigneur Magma.
- [ ] Planche artistique WEBP.
- [ ] Bandes d'animation.
- [ ] Phase 2 et attaque ultime.
- [ ] Intégration moteur.

### Île 5 — Jungle brumeuse

- [x] Fiche technique : Reine Mousson.
- [ ] Planche artistique WEBP.
- [ ] Bandes d'animation.
- [ ] Phase 2 et attaque ultime.
- [ ] Intégration moteur.

### Île 6 — Mer de la tempête

- [x] Fiche technique : Amiral Foudre.
- [ ] Planche artistique WEBP.
- [ ] Bandes d'animation.
- [ ] Phase 2 et attaque ultime.
- [ ] Intégration moteur.

## Commandants et subordonnés 2.5D

### Baie solaire

- [x] Sirocco + Braise : fiche technique.
- [x] Maréa + Cliquet : fiche technique.
- [x] Baron Tambour + Pavé : fiche technique.
- [ ] Planches artistiques et animations.

### Royaume des glaces

- [x] Hastel + Givre : fiche technique.
- [x] Sylka + Flocon : fiche technique.
- [x] Brakka + Stal : fiche technique.
- [ ] Planches artistiques et animations.

### Désert des corsaires

- [x] Zahir + Kef : fiche technique.
- [x] Noura + Mira : fiche technique.
- [x] Grom + Roc : fiche technique.
- [ ] Planches artistiques et animations.

### Volcan rouge

- [x] Ignara + Cendre : fiche technique.
- [x] Bombax + Mèche : fiche technique.
- [x] Chainor + Crochet : fiche technique.
- [ ] Planches artistiques et animations.

### Jungle brumeuse

- [x] Liane + Ronce : fiche technique.
- [x] Totem + Masque : fiche technique.
- [x] Koba + Singe Rouge : fiche technique.
- [ ] Planches artistiques et animations.

### Mer de la tempête

- [x] Volt + Étincelle : fiche technique.
- [x] Zéphira + Rafale : fiche technique.
- [x] Tonnerre + Mousse Noir : fiche technique.
- [ ] Planches artistiques et animations.

## Faune et créatures 3D

- [x] Catalogue de 48 espèces ou variantes.
- [x] 8 entrées par île.
- [x] 2 paisibles, 2 hostiles, 2 oiseaux, 1 rare et 1 marine par île.
- [x] Budget maximal d'instances par espèce.
- [ ] Modèles GLB optimisés.
- [ ] Textures compressées.
- [ ] LOD proche, moyen et lointain.
- [ ] IA de fuite, chasse, territoire, vol et nage.
- [ ] Limitation automatique selon la puissance du téléphone.

## Ordre de production

1. reconnecter les trois héros originaux ;
2. produire et intégrer Capitaine Hélios ;
3. produire les six personnages liés de l'île 1 ;
4. valider mémoire, collisions et fluidité sur Android ;
5. reproduire le processus île par île ;
6. intégrer ensuite les animaux 3D avec LOD ;
7. fusionner dans `main` seulement après validation complète.
