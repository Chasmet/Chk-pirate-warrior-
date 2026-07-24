# Validation de la V2

La branche `v2-godot-3d` lance automatiquement :

1. l’import complet du projet avec Godot 4.7.1 ;
2. l’analyse de toutes les erreurs GDScript ;
3. le démarrage réel du jeu en mode headless ;
4. le smoke test du joystick, du combat, des trois héros, de la carte et du menu ;
5. l’export d’une APK Android arm64 et x86_64 signée en mode debug ;
6. la vérification du manifeste et du mode paysage ;
7. l’installation et le lancement sur un Pixel 7 Pro virtuel ;
8. la capture de l’écran Android et le contrôle des crashs dans Logcat.

La compilation est considérée valide uniquement si toutes ces étapes passent.
