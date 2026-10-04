# Habillage du hall de MapTest

Le décor est ajouté à MapTest. Les nouvelles scènes sont réutilisables, mais cet agencement n'est pas ajouté aux salles du mode classique.

MapTest comporte maintenant des pièces et cloisons intérieures. Leur disposition et le coin d'intervention sont détaillés dans [etage_map_test.md](etage_map_test.md).

## Trouver et modifier les éléments

Ouvrir `scenes/decors/hall_incendie/habillage_hall.tscn` pour modifier l'agencement : les fenêtres, portes, appliques et meubles y sont placés à la main. MapTest instancie cette scène sous `Navigation/Decor/HabillageHall`.

Les nœuds `Nord`, `Gauche`, `Droit`, `SudGauche` et `SudDroit` regroupent les détails de chaque mur : soubassement sombre, plinthe métallique, baguette et joints verticaux. Ils sont construits avec des `BoxMesh`, donc éditables directement dans Godot. Les matériaux réutilisent les textures déjà présentes dans le projet.

Les éléments indépendants du dossier `scenes/decors/hall_incendie/` :

- `fenetre_hall.tscn` : modèle importé avec cadre blanc usé, appui et vitrage. Un fond sombre masque le mur derrière les vitres transparentes, et un éclairage bleu doux suggère la lumière extérieure. Le mur conserve sa géométrie et sa collision.
- `porte_condamnee.tscn` : battant, encadrement, poignée, deux planches croisées et inscription. C'est du décor, sans ouverture ni interaction de passage.
- `banc_hall.tscn` : modèle importé en bois, avec dossier et accoudoirs, haut de 1,15 m. Une boîte de collision inclut tout le banc. Un shader ajoute le charbon et les braises.
- `boites_aux_lettres.tscn` : douze boîtes, avec fentes et porte-étiquettes.
- `ascenseur_condamne.tscn` : deux vantaux métalliques, encadrement, boutons et planche de condamnation. C'est une façade décorative, sans cabine.

Le banc, la fenêtre et l'ascenseur utilisent les modèles téléchargés. Leurs proportions et leurs textures originales sont conservées. Les boîtes aux lettres restent construites directement dans Godot.

Les deux bancs ont été retirés de l'agencement du hall. Leur scène, le modèle et le shader incandescent restent disponibles pour d'autres salles.

## Banc incandescent

Sélectionner la racine de `banc_hall.tscn` pour régler `Brulure` (quantité de bois carbonisé) et `Intensite Braises` (luminosité). Le script `banc_incandescent.gd`, exécuté également dans l'éditeur grâce à `@tool`, crée un matériau propre à chaque banc à partir des textures originales : couleur, normales et rugosité.

Le shader `assets/shaders/decors/banc_incandescent.gdshader` conserve les UV du modèle pour le bois et son relief. Des bruits calculés dans l'espace du monde dessinent les zones de charbon et les fines fissures lumineuses. Une sinusoïde fait doucement varier leur émission au fil du temps. Les bancs placés à des endroits différents ont ainsi des marques différentes.

`LumiereBraises` est une vraie lumière locale : elle éclaire le sol, contrairement à la seule émission du matériau. Son énergie suit les deux réglages du banc. Ces braises sont uniquement visuelles et n'infligent aucun dégât.

## Appliques

`applique_murale.tscn` utilise maintenant `applique_hall.gd`. Son `@tool` permet de voir les réglages dans l'éditeur. Sélectionner la racine d'une applique pour modifier `Allumee`, `Couleur`, `Energie` ou `Vacillante`.

À son initialisation, `_ready()` copie le matériau du tube : chaque lampe peut ainsi avoir sa propre émission. `_actualiser()` règle ensemble l'émission du tube et la vraie source lumineuse. Une applique éteinte conserve son modèle mais n'émet plus de lumière.

Si `Vacillante` est activé, `_process(delta)` accumule le temps et applique deux oscillations sinusoïdales à l'énergie. La variation reste modérée ; la lampe ne produit pas de flash violent. Les setters des propriétés réappliquent les réglages quand on les change dans l'inspecteur.

Les appliques alternent entre teintes chaudes et froides. Deux sont éteintes et une vacille.

## Éclairage général du mode zombie

`mode_zombie.gd` remplace l'environnement de l'instance de main par `assets/materiaux/hall_incendie/ambiance_hall.tres`. Les réglages du jeu classique restent inchangés. Sur la racine de `mode_zombie.tscn`, le groupe Éclairage expose `Ambiance` et `Energie Soleil`.

L'ambiance passe de 0,32 à 0,18, avec une teinte légèrement froide. Le soleil passe de 0,8 à 0,3 : ces deux sources gardent le sol et les personnages lisibles, mais laissent les lumières locales ressortir. Le fond est presque noir. Le tonemapping Filmic et un glow modéré adoucissent les émissions fortes ; le bloom est nul pour éviter un voile sur toute l'image.

Les fenêtres utilisent des spots froids plus concentrés : énergie 3, portée 13 m, angle 32 degrés, inclinaison de 0,4 radian vers le sol. Ils éclairent une zone plus éloignée du mur. Leurs ombres sont activées pour que les obstacles interrompent la lumière. Les appliques conservent leurs intensités chaudes : elles ressortent davantage grâce à la réduction de l'éclairage général.

## Traces d'incendie et fissures

`trace_incendie.tscn` pose une surface transparente juste au-dessus du sol. Son shader `assets/shaders/decors/trace_incendie.gdshader` calcule une tache avec un bord irrégulier et différentes densités de suie. Quelques surfaces similaires sont placées au-dessus de portes. Il n'y a aucune suie supplémentaire sur les modèles de béton.

`fissures_beton.tscn` utilise `assets/shaders/decors/fissures_beton.gdshader` pour dessiner trois branches légèrement sinueuses autour d'un impact. Elles sont placées près des gravats et de la porte du fond. Ce sont des marques visuelles, pas des trous dans le sol.

Ces surfaces sont décalées de quelques millimètres pour éviter qu'elles se superposent exactement au sol. Elles n'ont ni collision ni dégâts. Les shaders ne projettent pas d'ombres.

## Atmosphère

## Eau, verre et canalisations

Trois scènes réutilisables sont placées dans `habillage_hall.tscn` :

- `flaque_eau.tscn` : une surface horizontale transparente, à 3,5 cm du sol pour éviter les superpositions avec la suie. Son shader `assets/shaders/decors/flaque_eau.gdshader` dessine un contour irrégulier avec des sinusoïdes, une faible rugosité et de légères variations de normale animées. Les lumières locales produisent des reflets spéculaires ; il ne s'agit pas d'un reflet miroir de toute la salle. Les paramètres Couleur et Rugosite sont accessibles dans son ShaderMaterial.
- `eclats_verre.tscn` : sept petits prismes triangulaires aplatis, avec des tailles et orientations différentes. Un matériau bleuté peu rugueux suggère du verre. Les fragments sont opaques pour garder une solution simple et éviter de cumuler les surfaces transparentes.
- `tuyaux_muraux.tscn` : un tube horizontal, une descente et quatre fixations. Les cylindres à douze segments utilisent un métal brun et terne. Les tubes se rejoignent simplement, sans modèle de raccord détaillé.

Ces éléments sont purement décoratifs, sans collision, dégâts ni modification de la navigation. Les fenêtres et le carrelage restent les modèles et textures déjà intégrés. Aucun téléchargement supplémentaire n'est nécessaire.

## Cendres et fumée

## Carreaux manquants et vitres cassées

Huit instances de `carreau_manquant.tscn` sont regroupées près de trois fenêtres. Une surface de 50 cm remplace visuellement un carreau par les anciennes textures de béton. Le shader `carreau_manquant.gdshader` assombrit son rebord et découpe légèrement ses extrémités pour suggérer une cavité ébréchée. Il ne creuse pas réellement le sol. Les centres sont alignés sur la grille du matériau : 0,25 m plus un multiple de 0,5 m, en X et en Z. Conserver cette échelle lors du placement.

`fenetre_hall.gd` expose `Vitre Cassee` sur la racine de chaque fenêtre. Trois fenêtres l'activent, les deux autres gardent leur vitrage original. Le script `@tool` remplace seulement le matériau de `Modele/Vitrage`, en reprenant ses textures. Le shader `vitre_cassee.gdshader` masque une région irrégulière dans le carreau supérieur gauche et dessine des fissures autour. Les cadres, l'éclairage et les collisions du mur restent intacts. Le fond sombre de la fenêtre apparaît à travers la cassure ; ce n'est pas une ouverture physique vers l'extérieur.

Les dégâts sont visibles dans l'éditeur et pendant la partie. Les textures et modèles importés ne sont pas modifiés. Le chargement des shaders et l'indépendance des fenêtres intactes/cassées ont été vérifiés dans Godot.

## Particules d'ambiance

`atmosphere_hall.tscn` est instanciée sous MapTest. Elle contient des `CPUParticles3D` : 48 petits grains de cendre répartis dans la salle et deux émetteurs de fumée près de zones brûlées.

La direction et une faible gravité positive sur Y font monter les particules lentement. Leur `color_ramp` fait varier l'opacité au cours de leur vie : elles apparaissent et disparaissent progressivement.

`assets/shaders/decors/fumee_hall.gdshader` oriente les petits nuages vers la caméra et rend leurs bords transparents. L'opacité maximale est faible pour conserver la lisibilité des personnages et des annonces d'attaque.

## Camion et gyrophares

Dans `scenes/modes/zombie/victimes/refuge_zombie.gd`, `_actualiser_gyrophares()` distingue désormais deux états :

- Sans sirène active, les gyrophares bleus et rouges pulsent lentement et éclairent légèrement les surfaces voisines.
- Avec le bonus de sirène, l'alternance rapide de 0,2 seconde et l'énergie plus forte sont conservées.

L'émission des matériaux et l'énergie des lumières sont réglées ensemble. Les deux couleurs sont déphasées pour ne pas atteindre leur maximum simultanément. `EclairageRefuge`, ajouté à `refuge_zombie.tscn`, est une petite source chaude qui aide à lire le modèle du camion.

Le camion a été agrandi uniformément de 65 % : environ 3,23 m de haut, 6,70 m de long et 2,43 m de large. Sa collision, les positions des gyrophares et l'éclairage ont été ajustés. Le script place désormais les compteurs et barres à partir de la hauteur de la collision, pour les garder au-dessus du toit. Les quatre marqueurs de spawn les plus proches du camion ont été retirés de MapTest ; il en reste 60.

## Navigation et vérification

Les bancs et portes condamnées sont des `StaticBody3D`, sur la couche du décor, dans le groupe `collider`. Leur présence sous `Navigation/Decor` permet à la cuisson existante de les intégrer aux deux navmeshes.

Vérifications effectuées dans une partie zombie : chargement des scènes et shaders, contournement des piliers, gravats et bancs, points d'apparition dégagés, indépendance des matériaux des lampes, alternance de la sirène et retour au mode discret.

## Modèles intégrés

- [Broken Window 05](https://sketchfab.com/3d-models/broken-window-05-ec90485639ae4e3bad900e7f91006066), par Game Ready Art : fenêtre usée, 86 triangles, téléchargement gratuit sous CC Attribution.
- [Old Wooden Bench](https://sketchfab.com/3d-models/old-wooden-bench-24b9598122574fb689157df4fcd1dce3), par Nikoleta.Zhecheva : banc en bois avec accoudoirs, textures PBR, environ 1 400 triangles, téléchargement gratuit sous CC Attribution.
- [Elevator Door](https://sketchfab.com/3d-models/elevator-door-6704273f7f9644bfb875d978486494eb), par 1-3D.com : façade d'ascenseur légère, 222 triangles, téléchargement gratuit sous CC Attribution.

Les fichiers préparés sont dans `assets/modeles/decors/hall_incendie/`. Les crédits et les adaptations sont conservés dans le fichier `CREDITS.md` de ce dossier. Les téléchargements originaux restent inchangés.
