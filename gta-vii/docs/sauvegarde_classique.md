# Reprise du mode classique

Un point de reprise est écrit au début de chaque salle, une fois la course d'entrée terminée et avant la planification des vagues. Quitter dans la boutique revient au début de la salle précédente ; les achats deviennent persistants à l'entrée de la suivante. Une mort ou une victoire efface uniquement la partie classique. Les succès, records et la partie zombie sont indépendants.

## Fichiers

- `scenes/systemes/sauvegarde/fichier_sauvegarde.gd` : écriture temporaire, copie de secours, contrôle SHA-256 et lecture sans sérialiser de nœuds. Les deux modes héritent de ce service.
- `scenes/jeu/sauvegarde/sauvegarde_classique.gd` : autoload et validation des données classiques ; fichier `user://partie_classique.save`.
- `scenes/jeu/sauvegarde/point_reprise_classique.gd` : coordination de la génération, capture et restauration du joueur, de l'escorte, des cartes, des pièces et des défis.
- `scenes/victimes/victim_manager.gd` : reconstruction commune de l'escorte, avec PV, ordre, destination et protections. Le dépôt reste spécialisé dans `escorte_zombie.gd`.
- `scenes/interfaces/menus/boutique/defi_manager.gd` : conservation des défis et rattachement de la victime fragile via son indice dans l'escorte sauvegardée.

## Génération et restauration

Une graine est conservée pour chaque salle. Avant chaque génération, RoomManager initialise l'aléatoire avec la graine correspondante. Le nombre d'étages est également sauvegardé. On reconstruit le parcours, puis on active directement la salle du point de reprise, sans rejouer les salles précédentes.

Les captifs et les positions des mobiles sont conservés explicitement : le défi de population peut les avoir augmentés après la génération initiale. Une graine de combat distincte retrouve la durée du timer et la planification initiale des vagues. Cela ne constitue pas un replay déterministe des déplacements et des décisions de combat.

Les cartes sont reconstruites par identifiant puis leurs effets recalculés, sans rejouer un achat ou un soin. La vie et la charge sauvegardées sont ensuite rétablies. Le joueur et son arme sont figés pendant le fondu ; la course d'entrée n'est pas rejouée. L'escorte est restaurée sans émettre de nouvelle libération.

La graine suppose les mêmes règles de génération ; une modification future du générateur peut nécessiter une migration ou un changement de version de sauvegarde. Les objets ne sont jamais stockés tels quels dans le fichier.

## Vérification

`godot --headless --path . --script res://tests/sauvegarde_classique.gd`

Le test utilise un fichier temporaire dans `.godot`, sans toucher à la partie réelle. Il vérifie la géométrie, le timer, les réserves, les cartes, les boucliers, les défis, la victime fragile, le retour titre, Continuer et la suppression. Le test zombie reste disponible dans `tests/sauvegarde_zombie.gd`.
