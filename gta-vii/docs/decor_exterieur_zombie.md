# Décor extérieur du hall zombie

La première proposition est regroupée dans `scenes/decors/ville/exterieur_ville.tscn`.
Elle est instanciée directement sous la racine de MapTest, à côté de Navigation.
Elle ne contient aucun corps physique, point de spawn ni script de gameplay.
Le navmesh est calculé depuis Navigation : ces façades ne participent pas à son calcul.
Les murs et garde-fous existants du hall continuent de limiter les déplacements.

La rue longe le nord et l’est du hall ; une chaussée est également visible devant
l’entrée du joueur, au sud. À l’ouest, un sol de cour de service prolonge le bâtiment.
Le fond de la porte nord est fermé par un retour en béton : cette entrée reste
un passage de service plutôt qu’une porte suspendue devant les immeubles.
Les trois modèles d’immeubles sont répétés en face des fenêtres nord et est.
Les immeubles hauts ne sont pas placés devant la caméra, au sud.

Pour déplacer un bâtiment : ouvrir la scène extérieure et sélectionner ImmeubleNord
ou ImmeubleEst. Les positions sont éditables directement, sans génération par code.
Les petits éclairages LueurRue donnent une lumière froide à la chaussée.
Le matériau asphalte_ville.tres utilise couleur, normale OpenGL et rugosité.
Il est mat (spéculaire à zéro), avec la normale désactivée et un filtrage anisotrope
pour éviter les points brillants sur la chaussée vue en biais.
La projection triplanaire en coordonnées mondiales garde une échelle identique
entre les différentes portions de chaussée (une répétition tous les quatre mètres).

Assets : Downtown City MegaKit Standard de Quaternius, licence CC0 conservée avec
les modèles dans assets/modeles/decors/ville/Licence_Quaternius.txt.
Source : https://quaternius.com/packs/downtowncitymegakit.html
Asphalt 02 de Rob Tuytel, Poly Haven, CC0 : https://polyhaven.com/a/asphalt_02
Seuls trois immeubles, leurs dépendances et trois textures d’asphalte sont copiés.
Le pack Kenney téléchargé reste disponible pour une autre proposition.

Cette version concerne uniquement MapTest en mode zombie. Les fenêtres, portes,
éclairages du hall et règles d’apparition des ennemis restent ceux du jeu existant.

## Cohérence des accès

La rue nord est reculée de huit mètres. Une cour de service en béton occupe
l'espace entre le hall et la rue : la porte nord conserve son passage de service.
Le trottoir reçoit trottoir_ville.tres, avec les textures béton du pack Quaternius,
un relief léger et aucun reflet spéculaire.
Le mur visible FondCouloir à l'entrée du pompier est supprimé, mais son corps
physique et sa collision sont conservés. RubanIntervention marque cette limite
à hauteur de taille et laisse voir l'extérieur. Son shader dessine des bandes
jaunes et noires. Le spawn du joueur et son trajet d'entrée restent inchangés.

## Annexes et correction des limites

annexes_hall.tscn contient désormais une cour délimitée par trois murs, une porte
de service, et une aile ouest : couloir central, quatre portes d'appartements,
cloisons, volée d'escalier et rampes. Ces éléments sont du décor seulement.
La fenêtre de vue derrière les entrées est dégagée via afficher_fond=false :
seul le maillage FondSombre/Visuel est masqué ; sa collision reste en place.
PorteArrivee reçoit aussi LimiteSeuil, un StaticBody3D sur la couche 1, avec une
BoxShape3D qui bloque le passage même lorsque les battants visuels s'ouvrent.
Les figurants n'ont pas de collision et les vrais ennemis naissent devant le seuil.
Deux poteaux avec socles soutiennent la rubalise à l'entrée du joueur.

Le trottoir utilise maintenant Concrete Tiles 02 (Charlotte Baglioni, CC0),
Poly Haven : https://polyhaven.com/a/concrete_tiles_02
Les trois fichiers 2K (diffuse, normale OpenGL et rugosité) sont téléchargés depuis
le serveur officiel. Répétition physique de 1,8 m, normale faible et spéculaire nul.

## Porte de l'aile et escalier en demi-tour

La brèche gauche de MapTest est remplacée par porte_appartements.tscn.
Cette scène reprend l'entrée de mobs existante, avec battants_sur_gonds=true.
Les nœuds Gauche/Droite sont des pivots aux bords du cadre ; leurs enfants Battant
et Poignee tournent avec eux. _regler_portes adapte le mouvement à ce mode,
sans changer la descente de l'ascenseur ni les autres portes coulissantes.
Des rubans matérialisent les limites aux seuils nord et ouest.
L'escalier comporte deux volées de sept marches (largeur 1,6 m), un palier
intermédiaire à 1,26 m et une seconde volée qui repart dans le sens inverse.
Le local nord et le mobilier des appartements attendent les modèles choisis.

## Mobilier intégré

mobilier_appartements.tscn habille quatre studios : lit, chevet, bibliothèque,
livres, kitchenette et réfrigérateur. Chaque salle d'eau contient douche, WC,
lavabo, sol et cloisons ; une pièce au fond sert de petit salon.
Le local nord accueille cinq poubelles rouillées et trois cartons.
Les modèles Kenney sélectionnés et la poubelle Poly Haven convertie en GLB sont
rangés dans assets/modeles/decors/appartements, avec leurs crédits et licences.

mobilier_annexe.gd instancie le modèle, mesure sa boîte englobante et le met à
la hauteur choisie, sans déformer ses proportions. Le bas est posé au sol et
le centre horizontal correspond au pivot du meuble. Le paramètre Suie règle
la couche noire irrégulière de suie_mobilier.gdshader, sans remplacer les textures.
Ces meubles restent décoratifs : ils ne changent pas la navigation du hall.
Cinq foyers réutilisent foyer_incendie.tscn et son feu, fumée, lumière et crépitement.
Les effets restent dans les annexes : aucun dégât n'est associé à ces foyers.
