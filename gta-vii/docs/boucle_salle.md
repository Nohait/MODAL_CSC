# Boucle d’une salle

RoomManager garantit au moins une victime au peuplement. Au démarrage, il tire une durée entre duree_min_vagues et duree_max_vagues (15 à 30 secondes), découpe les mobiles en petites vagues et répartit leurs échéances sur cette durée. La dernière échéance correspond à zéro seconde restante. Les ennemis immobiles restent présents dès le début.

Chaque annonce commence duree_annonce secondes avant son échéance. Son signal terminee nettoie uniquement la référence à l’effet : le calendrier du RoomManager crée les ennemis. Ainsi le timer et le dernier spawn utilisent la même horloge, même si un Tween finit une image plus tôt ou plus tard. À zéro, forcer_spawn_mobiles_restants consomme les dernières positions et vide le calendrier.

Les victimes captives perdent leurs PV selon la proportion écoulée de cette durée propre à la salle. Les victimes libérées sont ignorées. À la fin, les captives meurent sans reliquat de PV lié aux arrondis.

InformationsSalle fait pulser tout le petit encart sur un cycle d’une seconde pendant les cinq dernières secondes, seulement si des captives restent présentes. L’encart disparaît à zéro. Lorsque tous les ennemis sont morts, il revient avec « Salle libérée ! », sans barre ni alerte. Les informations d’étage, de salle et d’ennemis restent visibles. Le début de la salle suivante réinitialise ce panneau.

Les anciens popups « Temps écoulé ! » et « Salle libérée ! » ne sont plus déclenchés. Les autres utilisations du panneau de messages restent conservées.
