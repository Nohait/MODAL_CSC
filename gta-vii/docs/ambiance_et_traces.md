# Ambiance du Hall et traces de combat

## Fenêtres

`scenes/decors/hall_incendie/fenetre_hall.gd` conserve les deux réglages `lumiere_incendie` et `vitre_cassee`. Le fond utilise maintenant `assets/shaders/decors/lueur_fenetre.gdshader` : seules les fenêtres marquées incendie ont une lueur orange mouvante. Les autres restent froides. Six petites particules de fumée montent dans chaque fenêtre incendiée ; leur transparence suit un dégradé. Les éclats de verre déjà placés dans `habillage_hall.tscn` restent utilisés.

## Pièces

`scenes/decors/hall_incendie/eclairage_pieces.tscn` est instanciée sous `Navigation/Decor` de `scenes/modes/zombie/maps/hall.tscn`. Les lumières froides des archives et du bureau contrastent avec la salle de repos chaude et le local technique légèrement vacillant. Couleur, portée et énergie se règlent sur les quatre OmniLight3D. Le script anime seulement celle du local technique. Les noms Applique permettent à l'événement Blackout de les atténuer comme les autres lampes électriques.

## Camion

`refuge_zombie.gd` crée une lumière d'impact indépendante de la lumière verte d'accueil. Elle est bleue lorsqu'un bouclier absorbe un coup et rouge si les occupants sont blessés. Son énergie décroît pendant 0,3 seconde. Les valeurs des protections et des PV ne sont pas modifiées par cet habillage.

## Sprinklers

`sprinkler.tscn` emploie des gouttes plus fines et allongées, une dispersion plus resserrée et une vitesse légèrement supérieure. La portée réelle et les dégâts sont inchangés. `sprinkler.gd` déclenche une petite éclaboussure et une trace humide toutes les 0,45 s pendant l'arrosage. `scenes/effets/combat/eclaboussure_eau.gd` crée dix gouttes qui retombent sous la gravité puis supprime l'émetteur. La vapeur existante au contact des ennemis est conservée.

## Traces, dans les deux modes

`scenes/effets/combat/trace_combat.gd` est commun aux deux modes. Il crée un plan parallèle à la surface réellement touchée, légèrement décalé pour éviter le scintillement. `trace_combat.gdshader` dessine un contour irrégulier et un grain léger. Chaque trace possède son matériau afin de disparaître indépendamment. Il n'y a ni collision ni effet sur les dégâts ou la navigation.

- `effets_cartes.gd` dépose de la mousse au sol pendant le jet, même sans carte de mousse persistante. Une couleur bleutée accompagne le jet givré. Le trajet est vérifié contre les murs avant de chercher le sol : les traces ne traversent pas une cloison. Intervalle : 0,35 s ; durée : 5 s.
- `projectile_artilleur.gd`, également utilisé par le mini-boss, ajoute une marque de suie sur la paroi touchée.
- `projectile_tour.gd` ajoute une marque au contact du sol ou d'un mur. Les impacts sur les personnages ne créent pas de marque collée à leur corps.
- Les marques noires durent 8 s, puis s'effacent. Les traces humides des sprinklers durent 2,5 s.

Le plafond commun est de 70 traces. Le parent est la salle ou son conteneur de projectiles : supprimer la salle supprime aussi les traces. Les tweens suivent la pause du jeu. Aucun nouvel asset externe n'a été ajouté ; les modèles, fumées et fragments existants sont réutilisés.
