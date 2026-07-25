# Budget mobile — plafond absolu 5 Gio

Le jeu Android CHK Pirate Warrior ne doit jamais dépasser **5 Gio** dans le dossier livré au téléphone.

## Cible de production

La cible normale reste inférieure au plafond afin de garder une marge pour les sauvegardes, caches et mises à jour :

| Catégorie | Budget conseillé |
|---|---:|
| Code, moteur et shaders | 650 Mio |
| Héros et animations | 450 Mio |
| Ennemis et six boss | 700 Mio |
| Six îles et bâtiments | 1 250 Mio |
| Végétation, rochers et animaux | 550 Mio |
| Audio, voix et musiques | 350 Mio |
| Interface, cinématiques et effets | 300 Mio |
| Marge de sécurité | 550 Mio |
| **Total cible maximal** | **4 800 Mio** |

## Règles obligatoires

- textures Android limitées principalement à 1024 ou 2048 pixels ;
- 4096 pixels uniquement pour quelques éléments majeurs proches de la caméra ;
- ASTC pour les textures Android ;
- LOD sur tous les personnages, bâtiments, bateaux, arbres et rochers ;
- une seule copie des matériaux partagés ;
- animations compressées et nettoyées des pistes inutiles ;
- sons d'ambiance compressés et diffusés en streaming lorsqu'ils sont longs ;
- pas de contenu de test, d'éditeur ou de prototype dans le build final ;
- pas de doublons Fab ou Megascans ;
- cuire uniquement les cartes réellement utilisées ;
- build Shipping, compressé, sans symboles de débogage.

## Contrôle automatique

Le script suivant bloque le pipeline dès que la limite est dépassée :

```text
Scripts/check_mobile_size_budget.py
```

Le workflow de compilation Android appelle ce script après l'empaquetage. Un build supérieur à 5 Gio ne peut donc pas être publié comme artefact.

## Qualité visuelle

Le plafond de 5 Gio ne signifie pas une qualité basse. La priorité est donnée à :

- silhouettes fortes ;
- matériaux PBR optimisés ;
- éclairage cohérent ;
- eau et météo de qualité ;
- animations lisibles ;
- détails concentrés près du joueur ;
- décors lointains simplifiés avec LOD et HLOD.
