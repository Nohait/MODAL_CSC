# Voitures en feu à l'extérieur du Hall

`scenes/decors/ville/voiture_incendie.tscn` réunit l'épave importée, trois foyers de flammes et la fumée, les braises, la lumière et le crépitement du foyer déjà utilisé dans le hall. Les anciennes particules de flamme de ce foyer sont masquées, pour ne pas superposer deux styles de feu.

Le modèle est dans `assets/modeles/decors/ville/voiture_brulee.glb`. Ses textures passent de 4K à 2K ; la géométrie est conservée. L'échelle uniforme de 0,75 donne une longueur d'environ 4,6 m. L'épave reste un décor inaccessible, sans collision ni dégâts.

`assets/textures/feu/mikodrak/feu_anime.png` combine les deux couches fournies dans FIRE.zip pour chacune des 40 images, puis les regroupe en 8 colonnes et 5 lignes. `assets/shaders/decors/flamme_animee.gdshader` change de cellule à 18 images/s. Trois plans croisés par foyer donnent du volume au capot, à l'habitacle et à l'arrière. `voiture_incendie.gd` décale les animations des foyers.

Deux instances sont placées dans `exterieur_ville.tscn` : une rue nord, une rue est, en regard des fenêtres exposées à l'incendie. Elles sont réglables directement dans cette scène.

Dans `hall.tscn`, les parties visuelles des murs nord et est sont découpées autour des deux fenêtres concernées. Les collisions d'origine restent présentes, donc aucune ouverture jouable ou changement de navigation n'est ajouté. `vue_exterieure` dans `fenetre_hall.gd` retire le faux fond et rend le vitrage plus transparent. Les autres fenêtres conservent leur habillage.

Les crédits, licences et modifications sont dans `assets/modeles/decors/ville/CREDITS_voiture.md`.

Les cinq fenêtres du Hall sont centrées dans les murs de 50 cm d’épaisseur (axes à ±20,25 m), au lieu d’être plaquées sur leur face intérieure. Le mur gauche possède aussi une ouverture visuelle autour de sa fenêtre ; sa collision reste conservée.
