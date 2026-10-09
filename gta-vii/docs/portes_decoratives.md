# Portes décoratives des salles classiques

Quatre scènes se trouvent dans `scenes/decors/interieurs` :
- `porte_entrouverte.tscn` : battant incliné, fond sombre et lueur chaude ;
- `porte_enfumee.tscn` : porte fermée, fumée et lueur sous le battant ;
- `porte_bloquee.tscn` : porte barricadée par des planches et un buffet ;
- `placard_entretien.tscn` : deux battants et petites grilles d'aération.

Ces portes ne sont pas des sorties et ne s'ouvrent pas. En génération, elles donnent désormais sur de vraies pièces décoratives fixes : voir `pieces_decoratives.md`. Le mur est ouvert visuellement, mais sa collision reste au seuil. Le fond sombre et la fausse bande lumineuse sont masqués lorsqu'une pièce est installée. Les matériaux de bois et de métal et la fumée proviennent des assets existants.

## Placement et navigation

`scenes/salles/habillage_salle.gd` choisit parmi les variantes mélangées avec le générateur aléatoire du décor. Il ne place les portes que sur des murs complets disponibles, après les autres ensembles, et seulement si une pièce tient derrière. Deux portes au maximum sont prévues par salle ; les petites salles peuvent en recevoir moins pour conserver au moins douze cases disponibles.

Les portes sont ajoutées sous `Navigation/Decor`, afin que leurs collisions soient incluses dans la navigation. La case occupée est retirée des points possibles d'apparition des personnages. Les vrais passages et les emplacements réservés à l'arrivée sont préservés.

## Réglages dans Godot

Ouvrir `scenes/salles/habillage_classique.tres` : `Nombre portes decoratives` règle l'étage 1. La section `Portes condamnées — tous les étages` contient les quatre scènes et permet d'ajouter une variante. Pour les étages supérieurs, régler le nombre dans `ambiance_etage_2.tres` ou `ambiance_etage_3.tres`.

Dans une scène de porte, sélectionner le nœud racine : `Energie lueur`, `Portee lueur` et `Nombre particules fumee` règlent les effets. Le script commun `porte_decorative.gd` applique ces valeurs aux nœuds `Lueur` et `Fumee` s'ils existent. Il fait varier doucement l'énergie lumineuse avec deux sinusoïdes, sans ombres supplémentaires. Les variantes sans lumière n'exécutent pas cette animation.

Une nouvelle variante doit avoir ses pieds à Y = 0 et sa face tournée vers +Z. Conserver des collisions ajustées aux éléments qui dépassent du mur.

## Vérification

Import et compilation Godot réussis. L'audit de génération a contrôlé 120 salles sur les trois étages, sans problème de collision ou de chemin détecté. Un aperçu séparé a servi à vérifier les quatre variantes. Ces contrôles ne remplacent pas un essai en jeu avec plusieurs personnages.
