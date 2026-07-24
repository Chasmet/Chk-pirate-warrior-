# Validation de la V2.5

La branche `v2-godot-3d` lance automatiquement :

1. l’import complet du projet avec Godot 4.7.1 ;
2. l’analyse de toutes les erreurs GDScript ;
3. le démarrage réel du jeu en mode headless ;
4. les 80 contrôles du contact réel avec le relief, du déplacement, de la caméra 360°, du combat, des trois héros, de la traversée complète en bateau, de la météo, du gouvernail, des collisions de décor, des animaux, de l’accostage, des difficultés, des six boss, de la carte et du menu ;
5. l’export d’une APK Android arm64 et x86_64 signée en mode debug ;
6. la vérification du manifeste et du mode paysage ;
7. l’installation et le lancement sur un Pixel 7 Pro virtuel ;
8. la sélection réelle du mode Intermédiaire dans le nouveau menu ;
9. la manipulation des deux sticks, du gouvernail et de l’attaque sur l’émulateur ;
10. la présence du héros dans le monde 3D et du pilote physique à la barre dans la capture Android ;
11. la capture de l’écran Android et le contrôle des crashs dans Logcat.

La compilation est considérée valide uniquement si toutes ces étapes passent.
