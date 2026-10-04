# Hall de MapTest

Le décor est placé dans `scenes/modes/zombie/maps/map_test.tscn`, sous `Navigation/Decor`.

## Modèles et scènes

Les modèles préparés et leurs crédits sont dans `assets/modeles/decors/hall_incendie/`. Les scènes réutilisables sont dans `scenes/decors/hall_incendie/` :

- `pilier_beton.tscn` : une colonne de 2,9 m, isolée du scan, sans plafond ni poutres qui cacheraient le joueur.
- `piliers_hall.tscn` : six colonnes, en deux rangées à X = -6 et X = 6, avec trois positions à Z = -8, 0 et 8. L'alignement évoque une structure porteuse et laisse une allée centrale pour l'entrée et le camion, ainsi que deux passages latéraux.
- `gravats_beton.tscn` : trois fragments couchés et regroupés au sol.
- `applique_murale.tscn` : une applique de 1,2 m de largeur, salie, légèrement inclinée et éclairant en jaune chaud.
- `coin_hall.tscn` : l'applique et deux tas de gravats, placés contre le mur gauche. Les piliers sont indépendants de cet ensemble.

Les colonnes et gravats utilisent leurs matériaux PBR d'origine. Aucun bruit de suie ni assombrissement supplémentaire n'est appliqué : le script `beton_incendie.gd` a été retiré. Les textures intégrées ont été réduites à 2K et les fichiers téléchargés restent intacts.

## Sol et murs

Les matériaux propres à MapTest sont dans `assets/materiaux/hall_incendie/` :

- `sol_carrelage.tres` utilise désormais **Worn Tile Floor**, par Dimitrios Savva sur Poly Haven (CC0). Couleur, normale OpenGL et rugosité sont téléchargées en 2K. Une répétition couvre deux mètres, en coordonnées du monde, sur le sol et le couloir. Le matériau standard garde les joints nets ; les traces de suie indépendantes restent au-dessus du sol.
- `sol_beton.tres` et ses textures **Concrete Floor Damaged 01** sont conservés pour une utilisation future.
- `mur_beton.tres` réutilise les textures **Concrete Wall 009** déjà présentes pour l'étage 3, sans modifier le matériau de cet étage.

La normale donne l'impression de relief à l'éclairage ; elle ne déforme pas la géométrie. La rugosité règle les reflets. Le mur utilise une projection triplanaire en coordonnées du monde : son échelle ne dépend pas de la taille de chaque bloc. Une répétition correspond à quatre mètres (`uv1_scale = 0.25`). Les matériaux sont aussi appliqués au couloir d'entrée de MapTest.

## Ancien sol en béton : réduction de la répétition

Ce shader reste disponible, mais n'est plus appliqué à MapTest. Son mélange de textures serait inadapté aux joints réguliers du nouveau carrelage.

`assets/shaders/decors/sol_beton.gdshader` mélange trois versions de la même texture, chacune décalée et tournée d'un multiple de 90 degrés. La variante choisie dépend de la position dans le monde : le résultat reste fixe, sans animation ni nouveaux tirages pendant la partie.

Le shader répartit le sol en triangles. Les trois sommets de chaque triangle déterminent les variantes ; leurs poids changent progressivement entre les sommets. Les triangles voisins partagent leurs variantes au bord commun, ce qui évite les raccords visibles. La rotation et le décalage s'appliquent ensemble à la couleur, à la normale et à la rugosité. Les normales sont réorientées pour conserver la bonne direction du relief.

Sélectionner `sol_beton.tres`, puis ouvrir **Shader Parameters** dans l'inspecteur :

- `Taille Texture` : taille en mètres d'une répétition de la texture source. Une valeur plus grande agrandit les détails ; valeur actuelle : 4.
- `Taille Variations` : espacement des zones qui mélangent différentes variantes ; valeur actuelle : 5.
- `Intensite Relief` : force de la normale ; valeur actuelle : 0,8.
- `Teinte` : couleur qui multiplie celle du béton.

Le sol et le couloir utilisent les mêmes coordonnées du monde pour garder une continuité à leur jonction. Le shader lit trois versions des textures, ce qui demande davantage de travail graphique que le matériau précédent ; il ne modifie ni les collisions ni la navigation.

## Applique et lumière

L'applique utilise `applique_hall.gd` pour régler son état allumé, sa couleur, son énergie et une éventuelle oscillation légère. Son métal moins brillant reçoit le bruit `suie_variations.tres`. `FixationDeformee` l'incline d'environ deux degrés.

Le matériau du `Diffuseur` utilise l'émission pour rendre le tube lumineux. Le nœud `Lumiere`, un `OmniLight3D`, éclaire réellement les surfaces voisines. Sa couleur, son énergie et sa portée sont modifiables dans l'inspecteur.

## Collisions et navigation

Chaque colonne et chaque tas de gravats sont des `StaticBody3D` avec une boîte de collision simple. La cuisson existante lit ces collisions sous `Navigation/Decor` et les intègre aux deux navmeshes. Aucun nouveau code de navigation n'est nécessaire.

Les points d'apparition existants restent à distance des piliers et des gravats. Les tests vérifient que les deux navmeshes contournent ces obstacles et que les points de spawn ne sont pas obstrués par les nouveaux décors.

Le détail du nouvel habillage des murs, des fenêtres, des portes condamnées, du mobilier, de l'atmosphère et des gyrophares est expliqué dans [habillage_hall.md](habillage_hall.md).
