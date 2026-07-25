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

## Format des planches

Chaque planche finale doit respecter :

- format `WEBP` avec transparence ;
- taille de planche : `2048 x 2048 px` ;
- grille : `8 x 8` ;
- taille d'une cellule : `256 x 256 px` ;
- pivot de chaque frame : centre des pieds ;
- marge anti-débordement : 4 px minimum ;
- aucune ombre coupée ;
- aucune partie du corps hors cellule ;
- même échelle et même silhouette pendant toute l'animation.

## Directions

Les planches doivent prévoir quatre directions :

1. face caméra ;
2. dos caméra ;
3. profil gauche ;
4. profil droit.

Le moteur peut retourner horizontalement certaines poses, mais les boss asymétriques doivent posséder leurs propres profils gauche et droit.

## Animations standard

Ordre logique à respecter dans les métadonnées :

1. `idle` ;
2. `walk` ;
3. `run` ;
4. `attack` ;
5. `power` ;
6. `special` ;
7. `dodge` ;
8. `hurt` ;
9. `knockback` ;
10. `defeat` ;
11. `intro`.

Les boss ajoutent :

- `rage` ;
- `phase2` ;
- `area_attack` ;
- `ultimate`.

## Nommage

Chaque personnage possède ce dossier :

```text
characters25d/island_XX/<character_id>/
```

Fichiers attendus :

```text
sheet.webp
sheet.json
portrait.webp
thumbnail.webp
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

Une planche n'est considérée comme terminée que si :

- toutes les animations obligatoires existent ;
- le personnage reste identique d'une frame à l'autre ;
- le fond est transparent ;
- la collision des pieds correspond au pivot ;
- aucune frame ne dépasse sa cellule ;
- la planche est testée sur un appareil Android ;
- GitHub Actions valide les tests, le lint et `assembleDebug`.
