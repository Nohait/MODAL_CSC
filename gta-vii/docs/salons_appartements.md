# Coins salon de l'étage 1

Les modèles Sofa 02, Industrial Coffee Table et Modern Wooden Cabinet sont importés en glTF avec leurs textures 1K dans `assets/modeles/appartements`. Les dimensions d'origine sont conservées. Les crédits et liens sources se trouvent dans le même dossier.

## Les scènes à modifier dans Godot

Ouvrir `scenes/decors/appartements/salon_abandonne.tscn` : c'est la scène de base. Le nœud `Mobilier` contient le canapé, la table basse et le buffet. La racine est un `StaticBody3D` avec une collision simple par meuble, plutôt qu'une grande collision pleine autour de l'ensemble.

`salon_bouscule.tscn` et `salon_incendie.tscn` héritent de cette scène. Ils changent quelques placements et les paramètres de carbonisation. Une correction du modèle ou de la structure dans la base profite ainsi aux trois variantes. Lorsqu'un meuble est déplacé, déplacer également sa collision correspondante.

La direction locale +Z doit regarder vers l'intérieur de la salle. L'origine se trouve au niveau du sol. Les trois scènes restent contenues dans une case de cinq mètres ; garder cette contrainte en les modifiant, notamment dans les coins des salles.

## Brûlure et feu

Le script `scenes/decors/interieurs/mobilier_incendie.gd` reprend les textures du modèle dans des matériaux séparés. Il transmet couleur, normale, rugosité et métal au shader `assets/shaders/decors/mobilier_appartement.gdshader`. Les textures sources ne sont pas modifiées.

Le shader utilise un bruit pour carboniser certaines zones au lieu d'assombrir uniformément tout le meuble. Les parties les plus brûlées peuvent présenter quelques braises dont la luminosité varie légèrement. Le relief et les canaux PBR du modèle sont conservés.

Dans l'Inspector de la racine, **Brulure** règle l'assombrissement, et **Intensite braises** l'émission. Leur modification actualise l'aperçu dans l'éditeur. **Point foyer** situe le feu en coordonnées locales, et **Taille foyer** règle les particules. Le générateur ajoute le foyer existant à cet emplacement ; ouvrir le salon seul ne montre donc pas les flammes. Ces foyers sont décoratifs et n'infligent pas de dégâts.

## Intégration procédurale

Le seul script de génération modifié pour cet ajout est `scenes/salles/habillage_salle.gd`. À l'étage 1, il choisit les scènes dans son tableau exporté **Ensembles appartements**, avec le générateur aléatoire local déjà utilisé pour le décor. Les variantes sont mélangées : avec deux ensembles par salle et cinq variantes, les deux ensembles sont différents.

Un salon utilise un bord de mur complet, sur une case encore disponible. Les cases d'entrée, de sortie et d'arrivée de l'escorte sont déjà exclues. Le salon est orienté vers l'intérieur, sans rotation supplémentaire de tout l'ensemble qui pourrait le faire entrer dans un mur perpendiculaire.

La case meublée est retirée des points de spawn. Au moins douze cases disponibles sont conservées. Le corps fixe est ajouté sous `Navigation/Decor`, comme le mobilier existant : la cuisson de navigation prend ses collisions en compte. Le foyer et la suie restent sous `Habillage`.

Pour régler le nombre maximal de salons, ouvrir `scenes/salles/habillage_classique.tres`, puis modifier **Nombre meubles en feu** dans l'Inspector (deux par défaut). On peut aussi changer les scènes du tableau **Ensembles appartements**. Un tableau vide rétablit les anciens meubles de l'étage 1.

Les ambiances et modèles des étages 2 et 3 ne sont pas remplacés ; le mode zombie n'est pas modifié.

## Vérifications

Après import : contrôle visuel avec Forward+, vérification des dimensions et collisions, puis audit sur 120 salles couvrant les trois étages, les chemins des deux navigations, les points d'apparition et la reproductibilité des générations. Ces essais ne remplacent pas un test en combat avec une foule.
