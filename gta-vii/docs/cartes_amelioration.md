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

## Boutique, gestionnaire et cartes acquises

Le passage de porte ouvre maintenant la boutique, et non un choix gratuit direct.
Le fonctionnement, l'équilibrage des raretés, les points et les défis sont décrits dans
[boutique.md](boutique.md). Cette documentation remplace les anciennes règles
fondées sur la puissance proportionnelle au nombre de victimes.

UpgradeManager crée trois cartes lors d'un achat et leur transmet une rareté.
Le shader colore légèrement le papier et utilise les braises de cette rareté autour
de la carte et de l'illustration. Les autres cartes gardent leur aspect original avec
rarete = aucune. Les matériaux sont dupliqués pour que chaque carte reste indépendante.

Les gains sont cumulés de manière additive sur les statistiques de base. Grande
réserve remplit uniquement la capacité gagnée. MenuBonus montre les cartes acquises,
avec leur rareté et le vrai gain de chacune, en lecture seule. Les bonus d'escorte
ne sont plus présentés dans ce menu. Les trois améliorations restent les dégâts,
la capacité et la vitesse de recharge de l'extincteur.
