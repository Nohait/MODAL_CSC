# Les salles générées pendant la partie

À chaque lancement de `scenes/jeu/main.tscn`, le jeu crée trois nouvelles salles aléatoires.
R recharge la scène et relance donc aussi la génération. Les salles ne sont pas
enregistrées dans `scenes/jeu/main.tscn` : pendant un test, choisir **Distant / Remote** dans
l'arbre de Godot pour voir `Salles/Rooms/Salle1`, `Salle2` et `Salle3`.

## Organisation

```text
main
├── player
├── CameraRig
├── VictimManager
├── Escorte                 ← victimes déjà libérées
├── Salles
│   ├── RoomGenerator        ← fabrique le décor et réserve des emplacements
│   ├── Rooms
│   │   ├── Salle1
│   │   ├── Salle2
│   │   └── Salle3
│   └── RoomManager          ← peuple les salles et organise la progression
└── autres éléments : lumière, interfaces, menu des bonus
```

Chaque salle possède `Navigation/Decor`, `Portes`, `Ennemis` et `Victimes`.
Le générateur reprend le découpage aléatoire de la grille et le contrôle de
connexité du générateur initial : toutes les cases de sol restent reliées.
Les sols et murs ont maintenant une collision. Les caisses et les personnages
utilisent des cases différentes ; des places sont réservées pour toute l'escorte.

## Du lancement au changement de salle

1. `main._ready()` demande au RoomManager de démarrer une fois les nœuds prêts.
2. `demarrer_partie()` demande trois décors au générateur puis appelle
   `peupler_salle()` pour y ajouter ennemis, victimes et borne d'évacuation.
3. `activer_salle()` affiche la salle choisie et calcule sa navigation à partir
   des collisions. Il attend qu'un chemin soit disponible avant de lancer le combat.
   Les autres salles restent cachées et désactivées.
4. Chaque victime émet `freed` à sa libération. Le VictimManager l'ajoute à
   l'escorte ; le RoomManager retire une victime au compteur de sa salle d'origine.
   `bind(salle)` mémorise cette salle lors du branchement du signal.
5. Chaque ennemi émet `died` à sa mort : son compteur diminue également.
   `CONNECT_ONE_SHOT` retire la connexion après le premier appel pour éviter
   de compter plusieurs fois le même personnage.
6. Quand les deux compteurs valent zéro, la salle est libérée : message et
   ouverture des portes. Il faut **libérer** les victimes, pas les évacuer.
7. La porte émet `ouverte` à la fin de son animation. Cela active son `Area3D`
   nommée `Passage`. Lorsqu'elle détecte le joueur, la salle émet
   `sortie_franchie`. Le RoomManager vérifie les objectifs et lance la transition.
8. Le joueur et les victimes de `Escorte` sont déplacés dans la salle suivante.
   Ce sont les mêmes nœuds : vie, charge et bonus sont conservés. La caméra est
   immédiatement recentrée. Après la troisième salle, un écran de fin permet
   de recommencer ou de revenir au titre.

Déplacer les victimes dans `Escorte` avec `reparent()` est essentiel : sinon,
désactiver leur ancienne salle les désactiverait elles aussi. Le VictimManager
continue à gérer leur ordre de suivi et leurs bonus comme auparavant.

## Réglages dans l'inspecteur

- `main > Salles > RoomManager` : nombre de salles, minimum et maximum
  d'ennemis par salle, nombre de victimes par salle.
- `main > Salles > RoomGenerator` : `Room Size`, taille de la grille. Chaque
  case mesure 5 unités. La taille est limitée entre 6 × 6 et 20 × 20.
- La scène indépendante `scenes/salles/RoomGenerator.tscn` conserve un aperçu automatique.
  Cocher `Generate` renouvelle cet aperçu. Dans `main`, laisser `Apercu Auto`
  désactivé : c'est le RoomManager qui commande la génération au lancement.

Le nombre de personnages est limité par les emplacements libres. Chaque salle
contient entre 0 et 3 victimes dès le départ. Leur pouvoir est tiré indépendamment :
80 % sans bonus, 10 % dash et 10 % dégâts avec les poids par défaut 8/1/1.
Ce sont des probabilités, pas une répartition garantie dans chaque salle.
Les bonus de même type ne se cumulent toujours pas.

## Limites volontaires de cette première version

Les salles forment un parcours dans un ordre fixe : toutes les sorties d'une
salle conduisent à la suivante. Elles sont espacées dans le monde et le passage
effectue une téléportation ; il n'y a pas encore de couloir ni de retour en arrière.
Les trois décors sont générés dès le début, mais la navigation de chaque salle
est calculée lorsqu'on y entre. L'écran final constate la libération des salles,
il n'impose pas l'évacuation de toutes les victimes.


## Ennemis fixes et vagues de mobiles

Les trois types actuels sont utilisés : ennemi mobile, tour enflammée et flaque
de feu. Les tours (0 à 2) et les flaques initiales (0 à 3) sont créées pendant
`peupler_salle()`. Les victimes aussi. Les nombres sont tirés séparément pour
chaque salle, puis limités par les cases libres.

Pour les mobiles, `nombre_min_ennemis` et `nombre_max_ennemis` désignent le TOTAL
prévu dans la salle (3 à 6), pas le nombre par vague. `peupler_salle()` réserve
leurs positions dans `salle.mobiles_a_creer`, sans encore créer les personnages.
Chaque ennemi prévu est déjà compris dans `remaining_enemies`. Ainsi, une salle
avec 2 fixes et 5 mobiles prévus commence avec un objectif de 7 ennemis.

Après l'activation et la préparation de la navigation, `_process(delta)` diminue
`temps_avant_vague` uniquement pour la salle actuelle. À zéro, `creer_vague()`
prend 1 à 3 positions réservées et instancie les mobiles. Le délai repart à
4 secondes. La première vague attend également 4 secondes. Les vagues peuvent
se chevaucher : il n'est pas nécessaire de tuer la précédente. Le dernier groupe
peut être plus petit s'il ne reste qu'un ennemi à créer.

Le compteur n'augmente PAS à l'apparition : les ennemis étaient déjà comptés.
Il diminue seulement sur le signal `died`. L'interface précise combien sont
encore « À venir ». La pause des menus suspend le compte à rebours, et les salles
futures ne commencent leur attente qu'à leur activation.

Les projectiles et leurs flaques ont maintenant des conteneurs dans chaque
salle. Ils sont donc désactivés avec elle. Les flaques créées par les tirs sont
des dangers supplémentaires : elles ne changent pas les objectifs. Les flaques
initiales, en revanche, doivent être éteintes. Leur nouveau signal `died` est
protégé contre un double appel grâce à `est_mort`.

Dans `main > Salles > RoomManager`, on peut modifier les quantités, la taille
minimale/maximale des vagues, leur délai et les poids des bonus. Un poids est un
nombre de tickets : avec 8/1/1, tirer parmi 10 tickets donne 8 chances sur 10
sans bonus. Si les trois poids valent zéro, aucun pouvoir n'est attribué.
Les places d'arrivée de l'escorte sont réservées selon le maximum de victimes,
afin de garder assez de place même si toutes les salles tirent ce maximum.

Les apparitions utilisent des cases de sol réservées, mais n'ont pas encore
d'avertissement visuel et ne cherchent pas à s'éloigner du joueur s'il occupe
la case au moment de l'apparition. Ces deux améliorations peuvent venir ensuite.
