# Interface de salle

Le panneau du haut utilise une scène dédiée : scenes/interfaces/hud/informations_salle.tscn. Seul le timer possède un fond : assets/textures/interfaces/hud/plaque_salle.svg, une petite bande de papier brûlé. Les informations d’étage, de salle et d’ennemis restent sans panneau, avec une ombre pour être lisibles. La police Oswald est déjà utilisée par les jauges du joueur.

La scène contient le titre Objectifs, une ligne Ennemis et TimerContainer ; ce dernier contient le fond illustré. Le compteur est une ProgressBar fine, accompagnée du Label TimerText.

Le RoomManager appelle mettre_a_jour avec l’étage, le numéro de salle, le total de salles, le nombre d’ennemis restants et ceux à venir. Le script informations_salle.gd affiche ces données sans modifier les règles du jeu. Objectifs reste disponible pour les messages de génération et les erreurs de navigation.

Le timer conserve son chemin et sa valeur en secondes : le RoomManager continue de le faire diminuer. Le signal value_changed actualise le nombre de secondes arrondi vers le haut et la couleur de la barre. Durant les cinq dernières secondes, le texte pulse avec delta, donc se fige lorsque le jeu est en pause. À zéro, il affiche SAUVETAGE TERMINÉ. Lorsque la salle est libérée, la ligne des ennemis affiche PASSAGE OUVERT.

Dans main.tscn, l’instance InformationsSalle reste ancrée au centre supérieur. Ses marges symétriques la maintiennent centrée lorsque la fenêtre change de taille. Le message de fin de salle a été descendu sous le panneau pour éviter un chevauchement.

Pour changer l’agencement, ouvrir informations_salle.tscn. Pour changer les couleurs d’urgence ou les textes, ouvrir informations_salle.gd. Aucun effet de mousse n’est conservé sur la jauge du joueur.
