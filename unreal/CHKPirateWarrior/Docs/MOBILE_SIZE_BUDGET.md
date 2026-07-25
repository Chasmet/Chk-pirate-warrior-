# Budget mobile — plafond absolu 5 Go

Le jeu Android CHK Pirate Warrior ne doit jamais dépasser **5 Go installés sur le téléphone**.

## Cible de production

Le dossier Android livré est limité à **4,5 Go maximum** afin de conserver une marge pour l'installation, les fichiers natifs, les sauvegardes et le cache.

| Catégorie | Budget conseillé |
|---|---:|
| Code, moteur et shaders | 650 Mo |
| Héros et animations | 400 Mo |
| Ennemis et six boss | 600 Mo |
| Six îles et bâtiments | 1 100 Mo |
| Végétation, rochers et animaux | 450 Mo |
| Audio, voix et musiques | 300 Mo |
| Interface, cinématiques et effets | 250 Mo |
| Marge de sécurité | 600 Mo |
| **Total cible maximal** | **4 350 Mo** |

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

Le workflow de compilation Android applique deux plafonds :

- **4,5 Go maximum** pour le dossier de livraison Android ;
- **5 Go maximum** comme limite absolue des sources contrôlées.

Un build trop volumineux ne peut donc pas être publié comme artefact GitHub.

## Qualité visuelle

Le plafond de 5 Go ne signifie pas une qualité basse. La priorité est donnée à :

- silhouettes fortes ;
- matériaux PBR optimisés ;
- éclairage cohérent ;
- eau et météo de qualité ;
- animations lisibles ;
- détails concentrés près du joueur ;
- décors lointains simplifiés avec LOD et HLOD.
