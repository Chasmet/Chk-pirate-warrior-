# Référentiel des personnages 2.5D

## Personnages protégés

Les héros historiques **Cheikh**, **Yvane** et **Nelvyn** conservent leur identité visuelle, leurs couleurs, leurs armes et leur rôle. Aucun asset ennemi ne doit écraser leurs fichiers ou leurs identifiants.

## Répartition obligatoire

Chaque île contient exactement :

- 1 boss principal 2.5D ;
- 3 commandants 2.5D ;
- 3 subordonnés importants 2.5D ;
- des ennemis lambdas, oiseaux et animaux en 3D.

Total : **42 personnages ennemis importants en 2.5D**.

## Deux types de fichiers

### 1. Planche de référence artistique

Le fichier `sheet.webp` est la fiche visuelle officielle du personnage. Il sert à contrôler la continuité du visage, des vêtements, des armes, des proportions et de la palette.

Format :

- `2048 x 2048 px` ;
- fond transparent ;
- vues face, dos, profil gauche et profil droit ;
- portrait rapproché ;
- pose neutre ;
- pose de combat ;
- arme et accessoires séparés ;
- trois couleurs principales clairement visibles.

Cette planche n'est pas chargée pendant le gameplay.

### 2. Bandes d'animation utilisées par Android

Les animations sont séparées en bandes horizontales afin d'éviter de charger une immense texture en mémoire.

Format :

- `WEBP` transparent ;
- hauteur fixe : `256 px` ;
- largeur : nombre de frames multiplié par `256 px` ;
- une cellule : `256 x 256 px` ;
- pivot : centre des pieds ;
- marge anti-débordement : 4 px minimum ;
- aucune partie du corps hors cellule ;
- même échelle et même silhouette pendant toute l'animation.

Exemple pour une marche de 6 frames : `1536 x 256 px`.

## Directions

Chaque animation doit prévoir quatre directions :

1. `front` : face caméra ;
2. `back` : dos caméra ;
3. `left` : profil gauche ;
4. `right` : profil droit.

Le moteur peut retourner horizontalement certains ennemis simples, mais les boss asymétriques doivent posséder leurs propres profils gauche et droit.

## Animations standard

- `idle` ;
- `walk` ;
- `run` ;
- `attack` ;
- `power` ;
- `special` ;
- `dodge` ;
- `hurt` ;
- `knockback` ;
- `defeat` ;
- `intro`.

Les boss ajoutent :

- `rage` ;
- `phase2` ;
- `area_attack` ;
- `ultimate`.

## Arborescence

```text
characters25d/island_XX/<character_id>/
├── sheet.webp
├── sheet.json
├── portrait.webp
├── thumbnail.webp
└── animations/
    ├── front/
    │   ├── idle.webp
    │   ├── walk.webp
    │   └── ...
    ├── back/
    ├── left/
    └── right/
```

## Règles artistiques

- style pirate semi-réaliste cohérent avec les héros originaux ;
- silhouette immédiatement reconnaissable ;
- arme visible dans les poses de combat ;
- palette cohérente avec l'île ;
- proportions humaines crédibles ;
- pas de personnage géant sans justification de gameplay ;
- lisibilité conservée sur un écran de téléphone ;
- aucun détail fin indispensable à la reconnaissance du personnage.

## Validation avant intégration

Un personnage n'est considéré comme terminé que si :

- la planche de référence est validée ;
- toutes les animations obligatoires existent ;
- le personnage reste identique d'une frame à l'autre ;
- le fond est transparent ;
- la collision des pieds correspond au pivot ;
- aucune frame ne dépasse sa cellule ;
- la mémoire est libérée au changement d'île ;
- la planche est testée sur un appareil Android ;
- GitHub Actions valide les tests, le lint et `assembleDebug`.
