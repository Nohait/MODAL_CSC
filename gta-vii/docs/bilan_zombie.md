# Rapport d'intervention du mode zombie

Le bilan remplace uniquement la fin du mode zombie. Il affiche un total d'ennemis
éliminés, sans détail par type ou variante. L'écran de mort classique est conservé.

## Les fichiers

- `scenes/modes/zombie/statistiques/statistiques_zombie.gd` : autoload
  `StatistiquesZombie`, suivi de la partie et sauvegarde des meilleurs résultats.
- `scenes/modes/zombie/gestion/partie_zombie.gd` : démarre le suivi puis fige le
  bilan avant le changement de scène à la mort du joueur.
- `scenes/modes/zombie/interfaces/fin/fin_zombie.tscn` : illustration, voile,
  papier brûlé, titres, grille et boutons de navigation.
- `scenes/modes/zombie/interfaces/fin/fin_zombie.gd` : construit les douze
  indicateurs et anime leurs nombres. La liste `LIGNES` détermine leur ordre,
  leur titre et leur pictogramme.
- `scenes/modes/zombie/interfaces/fin/icone_bilan.gdshader` : éclaircit les
  pictogrammes sombres pour les rendre lisibles sur le papier bordeaux.

Le fond réutilise la texture et le shader du Carnet. Les boutons réutilisent ceux
de l'écran titre. Le `GridContainer` répartit les indicateurs sur quatre colonnes ;
le `ScrollContainer` permet de les consulter si le contenu dépasse la place disponible.

## Les statistiques

- Vague atteinte et vagues terminées : valeurs du gestionnaire de vagues à la fin.
- Ennemis éliminés : chaque signal `died` d'un véritable ennemi ajoute un au total.
  Cela comprend les dangers qui sont des ennemis du catalogue. Les kamikazes qui
  explosent sont également comptés. Un nettoyage par `queue_free()` ne compte pas.
- Victimes libérées : chaque victime ajoute un au total lors de son signal `freed`.
  Une victime libérée puis perdue reste comptée parmi les libérations.
- Victimes perdues : morts des captives et de l'escorte, plus pertes dans le camion.
  Déposer une victime dans le camion supprime son personnage, mais n'émet pas
  `died` : cela ne compte donc pas comme une perte.
- Dans le camion / dans l'escorte : victimes encore vivantes au moment du bilan.
- Dégâts infligés : somme des PV réellement retirés aux ennemis, après résistance.
  Un coup de 1000 sur une cible à 20 PV ajoute 20, pas 1000.
- PV perdus : signal existant `degats_recus` du joueur, après absorption par les
  boucliers. Les soins ne diminuent pas le total des PV perdus pendant la partie.
- Pièces ramassées : augmentations du solde du gestionnaire de monnaie. Les pièces
  encore au sol ou en trajet à la mort du joueur ne sont pas ramassées.
- Points dépensés : coût des boosters effectivement achetés. Il s'agit des points
  de boutique liés aux victimes, pas des pièces. Un achat refusé ne compte pas.
- Améliorations choisies : cartes sélectionnées dans le menu du mode zombie.
- Temps actif : temps écoulé dans la partie, sans les pauses de boutique ou de menus.
  Les délais entre les vagues et la course d'entrée comptent, puisqu'ils sont en jeu.

Les actions effectuées avec le debug comptent aussi dans cette première version.
Les records sont communs au mode zombie, sans séparation par map pour l'instant.

## Les signaux et la durée de vie des scènes

Le catalogue commun annonce les vrais ennemis avec `ennemi_enregistre`. Le suivi
branche alors leurs signaux `died` et `degats_subis`. Les groupes de combat et le
catalogue excluent déjà les figurants d'arrivée et les modèles du glossaire.

Le signal `degats_subis(quantite)` a été ajouté aux trois bases : sbire, tourelle
et flaque. Les autres mobiles et le mini-boss héritent du sbire. Ces signaux ne
changent ni les dégâts ni le comportement du classique : son suivi est inactif.

Les victimes sont repérées après leur `_ready()`. Un dictionnaire d'identifiants
empêche de les brancher à nouveau lors d'un changement de parent. Les connexions
de libération et de mort utilisent `CONNECT_ONE_SHOT` : un événement ne peut pas
être compté deux fois pour le même personnage.

Chaque nouvelle partie reçoit un numéro de `session`. Les callbacks mémorisent
ce numéro avec `bind()`. Un signal tardif provenant d'une ancienne partie est
ignoré lorsqu'il ne correspond plus à la session courante.

`terminer()` copie les compteurs dans `dernier_bilan`, puis désactive le suivi.
La copie contient seulement des nombres et la liste des nouveaux records : elle
reste exploitable après la suppression de toute la scène de combat. Une partie
rechargée ou abandonnée est arrêtée sans sauvegarder un bilan de fin.

## Records et animation

Les records concernent les vagues terminées, les ennemis éliminés, les victimes
libérées et abritées et les pièces ramassées. Le temps actif est seulement affiché
comme durée de la partie, sans record. Les pertes et les
dépenses ne sont pas traitées comme des records à maximiser.

Les valeurs sont enregistrées dans `user://records_zombie.cfg` avec `ConfigFile`,
comme les autres données locales du jeu. Ce fichier est indépendant des réglages,
succès et découvertes du glossaire. Les nouveaux records sont signalés en doré.

Un Tween parallèle fait apparaître chaque bloc en 0,25 s avec un décalage de
0,04 s, et fait progresser son nombre de zéro à la valeur finale en 0,65 s.
`tween_method()` appelle `_animer_valeur()` avec les valeurs intermédiaires ;
`bind()` lui fournit le Label et l'identifiant à formater. Les boutons fonctionnent
immédiatement, même si l'animation n'est pas encore terminée.

## Vérifications

Tests sur une vraie partie : coup fatal et mort unique, libération unique,
dépôt sans perte, décès dans le camion, collecte, achat refusé puis accepté,
choix de carte, PV perdus, arrêt du temps pendant une pause, copie figée du bilan,
sauvegarde des records et retour au titre. Le rapport a également été inspecté
sur une capture Godot avec des chiffres d'exemple.
