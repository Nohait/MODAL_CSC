# Raccourci Bonus en forme de booster

Le raccourci en haut à droite reste un Button : B ou un clic ouvre le menu. Son fond utilise booster_bonus.gdshader, dérivé du shader de boutique pour conserver le métal, les soudures et les braises bordeaux. Le reflet glisse au survol. Le texte indique le nombre d’améliorations et la touche configurée, sans la mention technique Physical.

ouverture_booster.tscn est une couche visuelle sans interaction. Son script crée deux copies du fond : cote_dechirure vaut -1 pour la moitié gauche et 1 pour la droite. Le shader calcule la même ligne brisée sur les deux copies, puis masque le côté opposé. Une fine bordure claire évoque l’intérieur du papier métallisé.

Les copies emportent les éléments graphiques du bouton. Le Tween déplace, pivote et efface les morceaux en parallèle pendant 0.35 seconde. Le déplacement droit est limité pour rester dans la fenêtre. Après 0.22 seconde, le menu commence son fondu et son agrandissement habituels.

Le jeu est mis en pause dès le début. Le CanvasLayer reste en mode Always, ce qui laisse l’animation s’exécuter. Fermer le menu interrompt les Tweens et supprime les copies. Cela permet de fermer pendant la déchirure et de rouvrir sans conserver une ancienne animation.

Pour modifier la durée et l’écartement, ouvrir ouverture_booster.gd. Pour modifier la forme de la déchirure, ouvrir booster_bonus.gdshader. Pour modifier la teinte, sélectionner Raccourci/Fond dans menu_bonus.tscn, puis son matériau. Le contenu et les règles du menu des bonus sont conservés.

Le popup vert à l’entrée d’une salle a été retiré du RoomManager. Les messages de fin de salle et de temps écoulé restent présents.

Le raccourci et le fond du menu utilisent désormais un bordeaux plus clair et désaturé. La boutique réutilise la même ouverture : elle masque le booster acheté, anime ses deux moitiés en conservant sa couleur et sa taille, puis affiche les trois cartes après le signal finished du Tween. Le verrou choix_ouverts bloque les doubles achats pendant cette attente. Les boosters rares gratuits suivent aussi cette animation.
