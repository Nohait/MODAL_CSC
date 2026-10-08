Explosion essence : Gasoline Explosion 01, JangaFX / EmberGen.
Source : https://jangafx.com/software/embergen/download/free-vdb-animations
Licence CC0, fichier LICENSE.txt conservé.
Simulation VDB convertie en 32 textures 3D de 64 x 64 x 64 voxels.
Canal rouge : densité de fumée ; canal vert : flammes.
Les coordonnées Z de la simulation deviennent l'axe vertical Y de Godot.
Chaque volume est stocké dans volumes/ sous forme de ressource Godot compressée.
Le rendu en jeu traverse les volumes en 3D ; il ne repose pas sur des images planes.

Version HD : 48 volumes 128³ en RG8, cadrage indices X/Y [16, 239], Z [0, 335].
Interpolation spatiale trilineaire ; encodage racine des deux canaux, décodé par le shader.
La version 64³ d'origine reste disponible pour le profil économique.
