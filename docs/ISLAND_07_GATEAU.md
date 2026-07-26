# Île 7 — Île des Gâteaux

## Architecture retenue

L’île reste une zone du monde ouvert 3D. Les personnages importants utilisent les deux planches 2.5D fournies par le créateur ; les ennemis ordinaires et la faune restent en 3D.

Le roster actif respecte le budget mobile existant :

- 1 boss ;
- 3 commandants ;
- 3 nakamas ;
- jamais plus de sept personnages importants préparés simultanément.

## Roster technique provisoire

1. Matriarche Sucrée — boss ;
2. Prince Mochi — commandant ;
3. Duc Biscuit — commandant ;
4. Chevalier Caramel — commandant ;
5. Maître Bonbon — nakama ;
6. Gardienne Meringue — nakama ;
7. Tireur Praliné — nakama.

Ces identifiants servent à relier les emplacements de la planche reçue au moteur. Ils pourront être renommés sans remplacer les visuels fournis.

## Intégration 2.5D

`PdfAtlas25D` connaît les zones de découpe des sept personnages sur la planche de groupe. `Enemy25DAssetBank` tente toujours de charger les bandes directionnelles réelles en premier, puis emploie cette planche comme fallback. Les anciennes textures restent libérées au changement d’île.

## État réel

Le catalogue Java, le catalogue d’atlas, les métadonnées et les tests de répartition sont étendus à sept îles. Les fichiers image reçus doivent encore être déposés dans le dépôt sous les chemins attendus, puis la navigation et la largeur du monde doivent être étendues de six à sept zones. L’île ne doit pas être annoncée comme jouable avant un `assembleDebug` vert et un test visuel sur téléphone.
