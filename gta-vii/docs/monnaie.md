# Pièces ramassées sur les ennemis

Cette monnaie est distincte des points liés aux victimes. Son solde commence à zéro à chaque partie et reste conservé entre les salles et les vagues. Elle n'est pas encore dépensable dans la boutique.

## Mort et récompense

À l'enregistrement d'un véritable ennemi, CatalogueEnnemis connecte son signal `died` à `Monnaie.lacher_pieces()`. Les modèles du glossaire et les figurants d'arrivée n'ont aucun groupe de combat : ils ne donnent donc rien.

Le mode zombie fournit `type.cout_difficulte` dans la métadonnée `valeur_pieces` avant d'ajouter l'ennemi. Changer ce coût dans une composition change donc aussi la récompense. Sans cette information, le système reprend le coût de `scenes/systemes/ennemis/definitions_ennemis.gd`, partagé avec le debug et le mode classique.

Sbire, chien et kamikaze valent 1 ; artilleur 2 ; démolisseur 3 ; mini-boss 8. Les tourelles n'appartiennent pas au budget des mobiles et utilisent une valeur de repli de 1, modifiable dans la définition commune. Un ennemi avec un enfant Elite rapporte le double.

Les flaques ne donnent aucune pièce, même dorées et même si une valeur de récompense leur est transmise. Monnaie ignore le groupe `flaque` avant le calcul du butin, dans les deux modes : cela empêche de gagner de l'argent en éteignant des feux que les tourelles peuvent recréer indéfiniment.

Une pièce est créée par unité gagnée. La connexion à usage unique et la métadonnée `pieces_lachees` empêchent une double récompense. Le debug qui tue réellement les ennemis peut aussi donner des pièces ; supprimer un nœud sans émettre `died` n'en donne pas.

## Effet visuel

`scenes/effets/monnaie/piece.tscn` utilise deux petits cylindres métalliques pour dessiner la pièce. Aucune collision ni nouveau calcul de navigation. Un rayon vertical cherche le sol sous le point de chute.

`piece.gd` réalise trois étapes : chute avec une petite impulsion (0,4 s), flottement (0,3 s), puis collecte (0,65 s). Les pièces partent légèrement décalées pour éviter un mouvement parfaitement uniforme.

La collecte suit une Bézier quadratique : le départ est la pièce, l'arrivée est le joueur, et le troisième point est au-dessus de leur milieu. La courbe reste dans le plan vertical qui relie les deux personnages. L'arrivée est actualisée à chaque image pour suivre un joueur qui bouge. Une bande de triangles orientée vers la caméra dessine une courte traînée dorée sur cette courbe.

Quand la pièce arrive, elle émet `ramassee`, ajoute une unité au solde puis se supprime. La pause arrête aussi les pièces. Si le joueur est mort, les effets restants sont supprimés.

## Gestionnaire, HUD et son

`scenes/systemes/monnaie/monnaie.tscn` est instanciée dans main et réutilisée par le mode zombie. Elle contient le gestionnaire, le son de collecte et le compteur sous les barres de vie/mousse. Les pièces appartiennent à ce gestionnaire : elles survivent au retrait d'une salle pendant leur collecte.

`monnaie.gd` expose le solde et le signal `solde_change`, utiles pour une future boutique. L'inspecteur permet de régler la dispersion et le volume du son. Les durées et la hauteur de l'arc se règlent sur la scène Piece.

`assets/sounds/interfaces/collecte_piece.wav` est un carillon synthétique original de 0,22 s. De petites variations de hauteur donnent du relief aux collectes ; un délai de 0,055 s entre les déclenchements évite de saturer le son quand plusieurs pièces arrivent ensemble.
