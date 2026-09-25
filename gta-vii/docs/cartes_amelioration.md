# Cartes d'amélioration

## Voir le résultat

Ouvrir `scenes/interfaces/menus/ameliorations/apercu_cartes.tscn` et lancer cette scène avec F6.
Les trois propositions sont des exemples visuels : les pourcentages ne modifient pas le joueur.
L'illustration de test est volontairement partagée. Clic gauche et Entrée émettent `selected` ;
Tab permet de déplacer le focus. Aucun passage de salle n'est branché à cet aperçu.

## Modifier une carte

La scène réutilisable est `carte_amelioration.tscn`, dans le même dossier.
Sélectionner sa racine pour modifier les exports de la section Contenu : identifiant,
titre, description, effet affiché, catégorie et illustration. Le script `@tool` actualise
les textes et l'image dans l'éditeur. Préférer des textes courts pour le format de 320 × 500.
L'illustration est recadrée au centre sans déformation.

La racine reçoit les interactions ; son enfant Visuel porte le graphisme et s'agrandit
au survol. Le rectangle cliquable ne bouge donc pas avec l'animation. Tous les éléments
décoratifs ignorent la souris pour laisser les événements parvenir à la racine.

## Matière et animation

Les shaders `carte_amelioration.gdshader` et `carte_illustration.gdshader` partagent
`cadre_braise.gdshaderinc`. Ce fichier calcule les coins arrondis, le charbon, le biseau
et les fissures lumineuses. Il simule le relief en 2D : ce n'est pas du PBR 3D.
Le paramètre taille maintient une épaisseur de bord cohérente en pixels.
L'animation change la chaleur des fissures, pas la forme du bord.

Chaque instance duplique ses matériaux pour rendre son survol indépendant des autres.
La carte est en Process Mode Always. Son horloge de shader est fournie par `_process` :
les braises et les Tweens de survol fonctionnent même lorsque le jeu est en pause.
Intensite braises, Hover scale et Hover duration sont réglables dans l'inspecteur.

## Branchement futur du gestionnaire (non implémenté)

La carte reste une vue : elle ne tire pas le pool, ne met pas le jeu en pause et
n'applique pas les bonus. Son signal `selected` ne prend toujours aucun argument.
Le gestionnaire pourra connecter `carte.selected.connect(_sur_choix.bind(carte))`,
puis lire `carte.identifiant`. Les textes ne doivent pas servir à calculer les effets.

Le point d'entrée du parcours est `_on_sortie_franchie(salle)` dans
`scenes/salles/room_manager.gd`. 
