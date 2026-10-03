# Entrée dans une salle

La porte de sortie est maintenant `scenes/decors/porte_sortie.tscn`, avec son script du même nom. Ses signaux et son ouverture restent identiques.

`porte_entree.tscn` contient un battant tombé et un fragment. Elle ne comporte ni voyant, ni animation, ni collision : le passage reste libre. Le générateur assombrit une copie de son matériau, sans modifier celui des sorties.

## Ordre des opérations

Dans `room_manager.gd`, `activer_salle()` :
1. bloque les commandes, annule les anciens ordres donnés aux victimes et masque l'écran ;
2. active le nouveau décor, prépare la navigation et place le joueur et l'escorte dans l'entrée ;
3. révèle la salle, puis appelle `joueur.commencer_entree(arrivee)` ;
4. attend le signal `entree_terminee`, envoyé quand le joueur atteint son point d'arrêt ;
5. active le combat, lance le sauvetage et émet `salle_commencee` pour les défis.

Le joueur parcourt trois mètres à sa vitesse normale. Pendant cette course, `player.gd` utilise la physique et l'animation habituelles mais ignore les commandes. Aucun Tween ne traverse donc les collisions.

## Décor et escorte

`room_generator.gd` construit un couloir texturé de six mètres. La première salle des étages suivants reçoit un palier puis des marches descendantes. Ces objets appartiennent à `Navigation/Decor` : les deux navigations en tiennent compte. Le couloir et la case d'entrée ne font pas partie des points de spawn.

`entree_salle.gd` place l'escorte dans ce passage. Chaque victime garde son instance, ses PV et sa cible dans la file. Les victimes qui ne tiennent pas attendent cachées, sans physique ni collision. Quand la précédente libère assez de place, la suivante retrouve ses collisions et recommence à la suivre. Si le joueur reste sur place, l'excédent attend ; il ressort lorsque la file avance.

`obscurite_entree.gdshader` superpose du noir de plus en plus opaque au sol et aux murs, en suivant la hauteur des marches. Le corps et la barre de vie des victimes deviennent eux aussi progressivement visibles en quittant cette zone. Une butée invisible ferme le fond pour empêcher de tomber dans le vide.

## Petits réglages

- Distance de course : les positions locales `1.6` et `-1.4` dans `activer_salle()`.
- Fondu rapide : `0.12` et `0.16` seconde dans `transition_etage.gd`.
- Espacement de la file et point de sortie du noir : `ESPACEMENT` et `POINT_EMERGENCE` dans `entree_salle.gd`.

Les valeurs locales sont mesurées par rapport à la porte : Z positif vers le couloir, Z négatif vers la salle. Le générateur tourne toute l'entrée pour adapter ces positions au mur choisi.
