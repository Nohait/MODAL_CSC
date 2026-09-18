# Les salles générées pendant la partie

À chaque lancement de `main.tscn`, le jeu crée trois nouvelles salles aléatoires.
R recharge la scène et relance donc aussi la génération. Les salles ne sont pas
enregistrées dans `main.tscn` : pendant un test, choisir **Distant / Remote** dans
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
- La scène indépendante `RoomGenerator.tscn` conserve un aperçu automatique.
  Cocher `Generate` renouvelle cet aperçu. Dans `main`, laisser `Apercu Auto`
  désactivé : c'est le RoomManager qui commande la génération au lancement.

Le nombre de personnages est limité par les emplacements libres. Les trois
victimes par défaut comprennent une sportive, une spécialiste et une victime
sans bonus. Les bonus de même type ne se cumulent toujours pas.

## Limites volontaires de cette première version

Les salles forment un parcours dans un ordre fixe : toutes les sorties d'une
salle conduisent à la suivante. Elles sont espacées dans le monde et le passage
effectue une téléportation ; il n'y a pas encore de couloir ni de retour en arrière.
Les trois décors sont générés dès le début, mais la navigation de chaque salle
est calculée lorsqu'on y entre. L'écran final constate la libération des salles,
il n'impose pas l'évacuation de toutes les victimes.
