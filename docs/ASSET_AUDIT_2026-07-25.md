# Audit réel des assets 2.5D - 25 juillet 2026

## Sources vérifiées

- branche `agent/real-3d-foundation-v2` ;
- PR brouillon n°13 ;
- fichier joint `asset chk pirate.pdf` (9 pages) ;
- catalogue Java `Enemy25DCatalog` ;
- catalogue JSON `app/src/main/assets/characters25d/catalog.json` ;
- dossiers et chemins modifiés dans la PR.

## Conclusion immédiate

Le PDF fournit de bonnes **références visuelles** pour les six îles, mais il ne fournit pas les
assets techniques suffisants pour livrer le jeu clé en main.

Aucune île ne peut être déclarée artistiquement terminée selon la règle du projet, car les éléments
suivants ne sont pas présents sous forme de fichiers de production complets :

- bandes WEBP transparentes par animation et par direction ;
- pivots et métadonnées de découpe vérifiés ;
- variantes de phase 2 et ultimes des six boss ;
- modèles GLB optimisés des animaux et ennemis ordinaires ;
- animations de navigation du héros sur le bateau ;
- tests visuels sur téléphone des assets finaux.

Les fichiers JSON et les planches composées visibles dans le PDF sont des références, pas des
sprites transparents prêts à être chargés par `SpriteStrip25D`.

## État par île

| Île | Référence visuelle | Roster officiel | Bandes transparentes jouables | État réel |
|---|---:|---:|---:|---|
| 1. Port des Naufragés | oui | verrouillé | non | référence complète, production technique manquante |
| 2. Jungle Sauvage | oui | verrouillé | non | référence complète, production technique manquante |
| 3. Royaume des Neiges | oui, avec miniatures d'animations | verrouillé | non | miniatures non exploitables directement comme bandes 256 x 256 |
| 4. Désert des Corsaires | oui | verrouillé sur le texte du PDF | non | conflit de noms entre texte et illustration, assets finaux manquants |
| 5. Île Volcanique | oui, avec miniatures d'animations | verrouillé | non | miniatures non exploitables directement comme bandes 256 x 256 |
| 6. Forteresse de la Tempête | oui, avec miniatures d'animations | verrouillé | non | miniatures non exploitables directement comme bandes 256 x 256 |

## Conflit détecté pour l'île 4

La hiérarchie textuelle du PDF indique :

- Zahrek ;
- Qamar ;
- Sirok ;
- Dune ;
- Khepri ;
- Safra ;
- Rakh.

L'illustration intégrée à la même partie du PDF affiche d'autres noms, notamment Zarok, Sabir,
Razka, Al-Varis, Chaal, Mâchoire du Désert et Veilleuse des Dunes.

Pour éviter un nouveau catalogue contradictoire, le code utilise désormais la hiérarchie textuelle
comme source officielle. L'illustration reste une référence d'ambiance tant qu'une validation
artistique explicite n'a pas tranché ce conflit.

## Corrections réalisées pendant cet audit

- remplacement des anciens boss provisoires (Capitaine Hélios, Roi Boréal, Sultan des Dunes,
  Seigneur Magma, Reine Mousson et Amiral Foudre) ;
- verrouillage des 42 noms officiels dans le catalogue Java et le catalogue JSON ;
- conservation de Cheikh, Yvane et Nelvyn hors du catalogue ennemi ;
- validation de la répartition 6 boss / 18 commandants / 18 subordonnés ;
- journalisation claire des bandes manquantes ou invalides ;
- rapport de chargement limité aux sept personnages de l'île active ;
- maintien du fallback lorsqu'un asset manque.

## Ordre de production recommandé

1. **Port des Naufragés** : produire Brakor puis les six personnages liés ;
2. **Jungle Sauvage** : produire Malkor puis les six personnages liés ;
3. **Royaume des Neiges** : exploiter la planche détaillée comme guide, mais redessiner de vraies
   bandes transparentes ;
4. **Désert des Corsaires** : commencer seulement après validation définitive du conflit de noms ;
5. **Île Volcanique** ;
6. **Forteresse de la Tempête**.

## Critère de passage à l'île suivante

Une île ne passe à l'état « terminée » que lorsque ses sept personnages importants disposent de
bandes transparentes chargées dans le jeu, que le boss possède ses animations spéciales, que les
tests et `assembleDebug` passent, puis qu'une vidéo de gameplay sur téléphone confirme le rendu.
