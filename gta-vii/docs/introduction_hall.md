# Introduction du Hall

L'introduction se joue uniquement lors d'une nouvelle partie zombie sur le Hall. Une reprise de sauvegarde et le Parking conservent leur arrivée habituelle.

## Fichiers

- `scenes/modes/zombie/evenements/introduction_hall/introduction_hall.tscn` : durée du bond, hauteur, durée du jet, vitesse des collègues et repères de leur trajet.
- `introduction_hall.gd`, dans le même dossier : création des figurants, saut du loup, réaction du joueur, passage des collègues et disparition.
- `scenes/decors/ville/intervention_secours/intervention_secours.tscn` : deux camions, deux voitures de police et deux policiers devant l'entrée sud.
- `gyrophares.gd`, dans le même dossier : éclats alternés, couleurs, intensité, portée et décalage réglables.
- `scenes/modes/zombie/gestion/vagues_zombie.gd` : choisit l'introduction du Hall ou la course habituelle.
- `scenes/salles/room_manager.gd` : attend la fin de `jouer_entree_salle()` avant de lancer le combat. Sa version habituelle reste celle du mode classique.

## Déroulement

1. Pendant le fondu, `preparer()` copie uniquement le modèle du pompier deux fois. Le modèle, ses proportions et son animation de course sont conservés. Les collègues conservent un extincteur visible, avec son traitement désactivé.
2. Après le chargement, le groupe arrive en courant depuis le repère DepartRue. La vitesse d’arrivée est réglable, à 5 m/s par défaut. Le premier collègue regarde à gauche, le joueur marche en deuxième position en regardant à droite, le troisième devant. L'AnimationTree existant mélange les animations avant, arrière et latérales selon la vitesse et le regard. Le joueur réutilise sa fonction animate() ; les figurants alimentent le même arbre à partir du déplacement mesuré entre deux images. Aucun os n'est modifié manuellement et aucune animation directe ne concurrence cet arbre. La caméra habituelle suit toujours le joueur.
3. La musique commence dès l'entrée. Un loup figurant arrive en courant depuis la droite, hors du cadre initial. Le joueur remarque son approche pendant que le groupe court : le modèle et l'animation PopUp du point d'exclamation des sbires apparaissent et un cri local est joué, en réutilisant un son du pompier. Le joueur court pour intercepter le loup pendant que ses collègues fuient. Les trajets de course dépassent le point d'embuscade et sont interrompus à la détection : personne n'attend le loup à l'arrêt. Le loup ne parcourt plus toute l'approche en sautant : son bond final mesure environ 1,6 m avec les valeurs par défaut. Le vrai extincteur émet son jet et le loup disparaît avec l'effet de cendres existant.
4. Le contrôle revient au joueur, tandis que les collègues continuent de courir vers les appartements.
5. Le premier collègue ouvre la porte ; le second s'arrête au repère `AttentePorte` et passe après l'ouverture et le premier collègue. Chacun incrémente le compteur `passes` après le repère `ApresPorte`. Le deuxième referme les battants, puis émet `collegues_passes` : l'attente se termine et la première vague peut démarrer.
6. Les collègues continuent le long du couloir et de l'escalier, puis deviennent transparents et sont supprimés.

Le loup n'est pas un véritable ennemi : il ne donne ni pièces, ni score, ni entrée dans le glossaire. Les collègues n'ont aucune collision et ne font pas partie de l'escorte. Leur trajet est chorégraphié par des Tweens, plutôt que calculé par la navigation de combat.

`ApprochePorte`, `ApresPorte`, `VersEscalier` et `Disparition` contiennent les repères modifiables dans l'éditeur. Leur hauteur correspond au sol ou à la marche ; le script ajoute la hauteur du centre du personnage.

Le script de l'entrée des ennemis est suspendu temporairement pendant l'ouverture des battants, afin qu'il ne referme pas la porte pendant le passage des collègues. Il reprend avant la première vague.

## Modèles et crédits

Les nouveaux modèles se trouvent dans `assets/modeles/decors/ville/intervention_secours/`. Chaque dossier conserve son fichier `CREDITS.txt` et la licence CC BY 4.0 du téléchargement.

La Crown Victoria est ramenée à 5,4 mètres de long en conservant ses proportions. Le policier mesure 1,8 mètre ; ce modèle est statique, ses coudes sont pliés de manière asymétrique, sa tête légèrement tournée et ses pieds écartés pour une posture d'attente plus détendue. Les camions et pompiers viennent des modèles déjà utilisés dans le jeu.

La rubalise et ses supports à l’entrée ont été retirés. Une grille ajourée (grille_entree.tscn) est placée côté rue, à l’entrée du couloir, à Z = 24, dans les derniers centimètres des murs du couloir. La porte cassée au sol a été retirée uniquement du Hall. Un linteau fin de 0,22 m de haut masque la grille enroulée : sa hauteur et son échelle verticale sont interpolées ensemble pendant la fermeture. Elle descend derrière le dernier pompier, une fois le passage dégagé. Sa collision est ensuite activée et la géométrie de navigation est recalculée une fois. Lors d’une reprise, elle reste fermée. Aucun ennemi ne peut apparaître dans la rue.

La hauteur du joueur pendant la scène est calculée depuis le sol par un rayon physique et la demi-hauteur de sa capsule. Le point d’arrivée conserve cette hauteur, pour éviter une chute à la reprise de la physique.
