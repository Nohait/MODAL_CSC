# Reprise d’une partie zombie

Un point de reprise est écrit au début de chaque vague, avant les ennemis et le timer. Revenir au titre ou fermer le jeu ne l’écrase pas. Continuer relance cette vague avec les données présentes à son début. Quitter pendant la boutique revient également au début de la dernière vague jouée : les achats de cette boutique ne seront enregistrés qu’au lancement de la suivante.

La sauvegarde concerne uniquement le mode zombie. Une mort termine la partie et efface son point de reprise ; les succès et les records restent indépendants.

## Fichiers

- `scenes/systemes/sauvegarde/fichier_sauvegarde.gd` : lecture/écriture, copie de secours, contrôle d'intégrité et suppression, partagés avec le mode classique.
- `scenes/modes/zombie/sauvegarde/sauvegarde_zombie.gd` : autoload et validation du format zombie ; utilise le fichier indépendant `user://partie_zombie.save`.
- `scenes/modes/zombie/sauvegarde/point_reprise_zombie.gd` : recueille et restaure les données du niveau zombie. Il fige brièvement le joueur et les équipements pendant le fondu de reprise.
- `scenes/systemes/sauvegarde/etat_sauvegarde.gd` : copie les champs explicitement choisis par les composants, sans copier leurs nœuds.
- `vagues_zombie.gd` : crée le point au début d’une vague et rejoue la composition et la graine conservées.
- `upgrade_manager.gd` : encode les acquisitions par identifiant et recharge leur définition depuis le catalogue. Les gains, les boucliers entamés et les durées restantes sont conservés. Les soins et les animations de synergie ne sont pas réappliqués.
- `victim_manager.gd` : recrée les victimes sans émettre une nouvelle libération ; conserve PV, positions, ordre et destination. `escorte_zombie.gd` ajoute la conservation du dépôt dans le camion.
- Les équipements et `arena_event_manager.gd` exposent leur propre état.
- `ecran_titre.gd` et sa scène : rubrique Mode zombie, Continuer ou Nouvelle partie, suppression avec confirmation.
- `menu_bonus.gd` : adapte la confirmation de retour au titre selon le mode.

Le format contient des nombres, des tableaux, des dictionnaires, des vecteurs et des identifiants, jamais des nœuds ni des Resources. Les ressources restent dans le projet. Pour ajouter un état persistant à un équipement, compléter ses fonctions `capturer_sauvegarde` et `restaurer_sauvegarde`. Pour ajouter un système complet, le brancher dans PointRepriseZombie.

L’écriture passe par un fichier temporaire. Le précédent fichier complet devient `.bak` avant que le nouveau le remplace. Une somme de contrôle et un numéro de version permettent de refuser un fichier incomplet/incompatible et d’essayer la copie précédente. Ces protections concernent les écritures interrompues ; elles ne constituent pas une protection contre la triche.

Le type de vague et une graine permettent de reprendre son tirage initial. Les mouvements et décisions ultérieurs des ennemis restent dépendants du joueur : il ne s’agit pas d’un enregistrement vidéo/replay déterministe du combat.

## Vérification

`godot --headless --path . --script res://tests/sauvegarde_zombie.gd`

Le test utilise son propre fichier temporaire, puis le supprime. Il vérifie notamment les PV, la mousse, les pièces, les boucliers entamés, les synergies, les victimes, les équipements, les paliers d’arène, l’avancement du point, une écriture interrompue et l’effacement à la mort. Le chargement classique et le bouton Continuer depuis le titre ont aussi été testés séparément.
