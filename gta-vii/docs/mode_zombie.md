# Mode zombie : refuge et boutique

L’écran titre ouvre la sélection des maps. Hall est un étage fixe de 40 × 40 mètres : hall central, quatre pièces latérales et entrée au sud. R et Rejouer conservent la map sélectionnée.

## Boucle d’une vague

La course d’entrée précède la première vague. Chaque vague crée 1 à 3 captives et un timer aléatoire de 15 à 30 secondes. Les ennemis mobiles sont répartis en groupes dans cette durée : leur annonce précède l’apparition et le dernier groupe apparaît à zéro. Les captives perdent progressivement leur vie jusqu’à zéro ; les libérer arrête ces dégâts. Elles suivent automatiquement le joueur et restent vulnérables aux attaques.

Pointer le refuge et cliquer au milieu envoie toute l’escorte vers lui. Il s’éclaire au survol et affiche l’instruction. Chaque victime entre seulement lorsqu’elle atteint le refuge. Ses PV restants, ses PV maximum et son ordre de libération sont conservés dans un dictionnaire ; son personnage est ensuite retiré. Le dernier élément de la liste est toujours la victime sauvée le plus récemment, même si l’ordre d’arrivée diffère. Les attaques touchent uniquement cette victime ; si elle meurt, on la retire et la précédente reprend sa place avec sa propre vie. Le pictogramme et le compteur indiquent le nombre de victimes abritées ; la barre représente la victime attaquable. Un refuge vide n’est plus une cible.

Une vague se termine après le timer et la mort de tous ses ennemis. Chaque victime abritée à cet instant rapporte 1 point ; l’escorte ne rapporte rien. Les points non dépensés sont conservés. Après 3 secondes, la boutique commune ouvre les boosters et leurs choix de cartes ; le combat est en pause. Les défis du jeu principal sont masqués. Fermer la boutique lance un compte à rebours de 3 secondes avant la vague suivante. Le refuge et l’escorte conservent leurs PV. Un refuge vide ne termine pas la partie.

## Organisation

- `mode_zombie.gd` instancie main et spécialise ses gestionnaires avant leur initialisation. Le jeu principal conserve ses scripts et ses règles.
- `vagues_zombie.gd` hérite du RoomManager : salle fixe, population, calendrier des annonces, timer commun, récompense et pauses. Les tourelles apparaissent à partir de la vague 5, au maximum 2. Le budget des mobiles augmente de 3 au départ à un plafond de 30 points ; ni leurs PV ni leurs dégâts n’augmentent.
- `victimes/refuge_zombie.tscn` contient le camion importé, mis à l’échelle uniformément à environ 6,7 mètres de long et 3,2 mètres de haut, recentré et muni d’une collision en boîte. `refuge_zombie.gd` gère le survol, le dépôt, la liste des PV et l’affichage au-dessus. Le shader surbrillance_refuge ajoute une couche dorée uniquement au survol, sans remplacer les matériaux d’origine.
- `escorte_zombie.gd` hérite du VictimManager. Il adapte seulement la commande au clic milieu, le retour automatique et l’ordre de libération.
- `sbire_zombie.gd` et `tour_zombie.gd` reprennent les ennemis communs et abandonnent une cible refuge vide. Le sbire calcule la distance au bord de la collision rectangulaire du camion dans sa direction pour pouvoir l’attaquer sans atteindre son centre.
- `boutique_zombie.gd` hérite de l’UpgradeManager : points conservés, textes adaptés et signal de fermeture au lieu du changement de salle. Les achats, animations, cartes et effets d’améliorations restent communs. `defis_zombie.gd` fournit un catalogue vide.
- `partie_zombie.gd` et `fin_zombie.gd` conservent la mort, le bilan des vagues et les boutons Rejouer / Écran titre. Aucun succès de victoire du parcours n’est débloqué.

## Réglages et maps

Ouvrir mode_zombie.tscn, sélectionner ModeZombie et déplier Difficulté dans l’Inspecteur. La ressource difficulte_zombie.tres expose le budget de difficulté et les nombres de victimes, la taille des groupes, la durée du timer et les deux pauses de boutique.

Hall hérite de salle.tscn pour conserver la navigation. Ses 44 Marker3D de PointsApparition fixent les emplacements possibles ; aucun n’est placé dans le couloir. Le refuge est ajouté au centre, sous Navigation/Decor, avant la construction du navmesh pour que les chemins le contournent. Les victimes rejoignent son voisinage avant d’être déposées.

catalogue_maps.gd contient les titres, scènes et captures. selection_maps.gd construit les cartes ; carte_map.gdshader réutilise le cadre de braises et carte_map.gd anime le survol. Les captures sont statiques et doivent être refaites si le décor change. Ajouter une map consiste à adapter une scène, ses marqueurs et son image, puis l’ajouter au catalogue.

I ouvre le menu debug : invincibilité, dégâts colossaux, points abondants pour la boutique, saut de vague et fin de vague. Les sauts annulent les ennemis et leurs annonces ainsi que les captives précédentes ; ils conservent le refuge et l’escorte.

## Rangement des fichiers

Le point d’entrée mode_zombie.tscn et son script restent à la racine du mode.

- gestion : lancement du niveau et boucle des vagues.
- equilibrage : script et ressource de difficulté.
- victimes : refuge et gestion de l’escorte.
- ennemis : adaptations du sbire et de la tourelle.
- maps : scènes des maps et catalogue.
- interfaces/selection_maps : sélection, carte de map et shader.
- interfaces/boutique : boutique et catalogue de défis du mode.
- interfaces/debug : commandes de test.
- interfaces/fin : scène et script de fin de partie.

Les scènes, scripts et ressources associés restent ensemble dans leur dossier fonctionnel. Leurs fichiers .uid ont été déplacés avec eux et toutes les références res:// ont été actualisées.

## Modèle du camion

Le GLB original se trouve dans assets/modeles/camion_pompier. Il provient du modèle Fire Truck publié par sayedgamal655 sur Sketchfab (bdaa56e372ac43c7abf2c5d652733e76), sous CC BY 4.0. CREDITS.md conserve l’attribution ; source_sketchfab.json garde les métadonnées de licence. Le modèle compte environ 1,7 million de triangles : Godot génère automatiquement ses LOD à l’import, mais une optimisation plus poussée pourra être nécessaire pour les machines moins puissantes. La navigation utilise uniquement la collision simplifiée, pas le maillage détaillé du véhicule.

Pour modifier sa taille, ouvrir victimes/refuge_zombie.tscn et ajuster Modele ainsi que CollisionShape3D ensemble. La mise à l’échelle est uniforme pour préserver les proportions. Le script conserve le nom Refuge car le rôle de cet objet reste celui d’un refuge, indépendamment de son apparence.

## Boosters et améliorations

La boutique propose les boosters permanents commun/rare/épique et le booster turquoise Intervention pour les soins et effets temporaires. Le catalogue commun filtre les cartes avec leurs cases Classique et Zombie. Les soins de victimes ciblent ici les occupants du camion, le blindage protège durablement leurs PV, et la protection d’urgence ajoute une barre bleue valable deux prochaines vagues. Le menu des bonus sépare les effets permanents et temporaires et affiche la durée restante en grand. Voir docs/ameliorations.md pour les réglages et la création de nouvelles cartes.

## Retours visuels du refuge

Lors du dépôt, les PV et l’ordre de libération sont enregistrés immédiatement. depot_victime.gd crée une copie du mesh de la victime qui s’efface en 0,35 seconde, avec neuf petites particules chaudes. La copie ne possède ni collision ni logique de vie. L’effet entier est supprimé après 0,65 seconde. Le compteur et le pictogramme grossissent brièvement, puis retrouvent leur taille.

La file restante est réorganisée après chaque dépôt ; si l’ordre de dépôt reste actif, les suivants gardent le camion comme destination. Le signal escort_changed actualise les autres systèmes.

Un impact fait réagir la barre verte si les occupants perdent des PV, ou la barre bleue si le bouclier absorbe tout. La disparition d’un occupant émet victime_perdue. VaguesZombie relie ce signal à RetoursBonus, qui affiche un petit parchemin « Victime perdue » sous le bouton Bonus pendant environ une seconde. Les pertes rapprochées sont regroupées avec un compteur au lieu d’empiler les messages. « Secours utilisé » utilise aussi ce format discret.

## Premier ennemi de la vague

Un sbire apparaît immédiatement à temps zéro, après la course d’entrée ou le délai entre les vagues. Il est inclus dans le total normal : ce n’est pas un ennemi supplémentaire. Un emplacement lui est réservé avant les captives et les tourelles. Les autres sbires gardent leurs annonces et leur calendrier, avec le dernier groupe à la fin du timer de sauvetage. Le premier sbire ne fait pas attendre une annonce de spawn, mais utilise un emplacement éloigné du joueur si possible.

## Prototype du chien de magma

Pendant une vague, ouvrir le debug avec I et ouvrir « Faire apparaître un ennemi… », puis choisir « Chien de magma ». Ce bouton ajoute un ennemi au compteur ; sa mort est nécessaire pour terminer la vague. Il peut apparaître automatiquement dans les compositions débloquées.

Sa scène et son script sont dans `scenes/ennemis/mobiles/chien_magma/`. Le modèle GLB et les crédits sont dans `assets/modeles/ennemis/mobiles/chien_magma/`.

Le script hérite du sbire pour réutiliser les dégâts reçus, le jet givré et les cendres. Le chien suit le joueur avec le NavigationAgent et l'animation Walk accélérée. Entre 2 et 5 mètres, il continue sa course en se tassant pendant 0,3 seconde puis bondit pendant 0,45 seconde. La direction est mémorisée au début de la préparation : le joueur peut esquiver. Le corps conserve les collisions au sol ; seul le modèle monte puis redescend suivant une courbe en sinus. Le premier contact termine le bond et inflige 12 dégâts s'il touche le joueur. Un mur interrompt aussi le saut.

Au contact (1,4 mètre), il prépare une morsure pendant 0,18 seconde. Deux rangées de petits cônes représentent les crocs et se referment avec un tween. Les 7 dégâts sont appliqués une seule fois, uniquement si le joueur est encore à portée sans obstacle. Les réglages de course, bond et morsure sont exportés dans l'inspecteur de la scène.

Le chien est agrandi de 25 % (`taille_modele`) et court à 18 m/s. Le bond parcourt 6 m en 0,45 s, soit environ 13,3 m/s avant le gel : l'impulsion est nettement plus rapide que la course. L'animation Idle remplace Walk pendant le bond et le repos à l'atterrissage. La morsure utilise dix crocs plus larges et un bref mouvement du corps vers l'avant.

À la réception, un tween termine la descente si une collision interrompt le saut, puis tasse le corps et incline légèrement le museau. Le chien reprend ensuite sa taille et sa posture normales. `duree_reception` et `tassement_reception` règlent l'amortissement ; cette animation fait partie du repos après le bond.

Pendant le bond, une sinusoïde incline le modèle vers le haut à la montée puis vers le bas à la descente. `inclinaison_bond_degres` règle l'angle maximal (12° par défaut). La collision conserve son orientation ; seul le visuel s'incline. Une réception interrompue redresse progressivement le modèle.

## Prototype du démolisseur

La scène et le script se trouvent dans `scenes/ennemis/mobiles/demolisseur/`, le modèle et ses crédits dans `assets/modeles/ennemis/mobiles/demolisseur/`. Le chien est lui aussi rangé sous `scenes/ennemis/mobiles/chien_magma/`.

Le démolisseur se teste avec I → « Faire apparaître un ennemi… » → « Démolisseur ». Il compte comme un ennemi de la vague, et peut apparaître automatiquement dès la vague 5. Le modèle original a été allégé dans Blender, d'environ 1,1 million à 44 000 triangles.

Le golem marche à 3 m/s et possède 200 PV fixes. Il privilégie le camion dès qu'il contient une victime ; sinon il choisit le joueur ou la victime libérée la plus proche. Sa portée se mesure depuis le bord de la carrosserie. Il s'arrête 0,85 s pour préparer son coup, avec un recul du corps et un disque orange au sol. Il frappe en 0,14 s, inflige 28 dégâts une seule fois à sa cible si elle est toujours à portée et devant lui, puis récupère pendant 0,55 s. Le disque est une annonce visuelle : ce premier coup n'inflige pas de dégâts de zone. Les réglages sont exportés dans l'inspecteur. Le gel et la mort en cendres sont repris du sbire.

### Prototype de l’artilleur

Scène commune : `scenes/ennemis/mobiles/artilleur/artilleur.tscn`.
Le choix « Artilleur » du sous-menu des ennemis permet de le tester pendant une vague. Il peut apparaître automatiquement dès la vague 5.

Il possède 70 PV et poursuit le joueur ou une victime libérée (camion occupé inclus) jusqu’à 12 mètres, avec une ligne de vue libre. Il prépare son tir pendant 0,8 seconde puis lance une boule à 18 m/s, infligeant 15 dégâts. La visée suit la cible pendant la préparation et est fixée au départ depuis le cristal du sceptre ; le projectile reste rectiligne et disparaît contre le décor ou une cible, sans générer de flaque. Son délai entre tirs est de 2 secondes. Ces paramètres sont exportés dans l’inspecteur.

Le magicien est centré et mis à l’échelle en conservant ses proportions. Sa robe est teintée en bordeaux et son cristal devient orangé, par duplication des matériaux. L’annonce utilise des tweens sur l’orbe et la posture, ainsi que les particules de feu du sbire (également utilisées pour la traînée du projectile) ; aucune animation de marche n’est ajoutée pour ce prototype.

Pendant la charge de l’artilleur, `scenes/effets/combat/alerte_artilleur.gd` affiche un arc rouge fin et un chevron creux près du joueur ciblé, orientés vers l’ennemi même hors écran. L’alerte disparaît au tir, à l’annulation ou à la mort de l’artilleur.

La traînée du projectile est un cône 3D effilé, animé par `scenes/effets/feu/trainee_artilleur.gdshader`. Les textures originales de Kenney sont dans `assets/textures/feu/kenney/`, avec leurs crédits et leur licence CC0. Le projectile conserve seulement son noyau et cette traînée : les particules de flamme sont réservées à la charge sur le sceptre. La traînée est visuelle uniquement et ne change pas les collisions ni les dégâts.

### Prototype du kamikaze

Scène commune : `scenes/ennemis/mobiles/kamikaze/kamikaze.tscn`. Le modèle et ses crédits sont dans `assets/modeles/ennemis/mobiles/kamikaze/`.
Le choix « Kamikaze » du sous-menu des ennemis permet de le tester pendant une vague. Il peut apparaître automatiquement dès la vague 7.

Le crâne possède 35 PV. Seul le joueur peut déclencher sa poursuite, dans un rayon de 12 mètres et avec une ligne de vue libre. Après une annonce de 0,3 seconde, il accélère vers 12 m/s. Sa rotation est limitée à 160 degrés par seconde : il conserve son élan et peut manquer un joueur qui change rapidement de direction. Il vole à hauteur constante ; un petit mouvement visuel simule la lévitation. Il ne contourne pas les murs avec le navmesh.

Au premier contact avec un corps physique, il explose : 20 dégâts dans un rayon de 2,1 mètres, avec les murs comme protection. L'explosion peut atteindre le joueur, les victimes et le camion ; ceux-ci ne sont jamais des cibles de poursuite à la place du joueur. La mort est comptée une seule fois. Le neutraliser à l'extincteur provoque une mort normale, sans explosion.

`scenes/effets/combat/explosion_kamikaze.tscn` combine une texture d'explosion orientée vers la caméra, des étincelles 3D et un éclair local. Le script anime sa croissance et son fondu, puis supprime l'effet. Les textures du pack Smoke Particles de Kenney sont conservées dans `assets/textures/feu/kenney/explosion/`, avec la licence CC0 et les crédits.

Les flammes existantes du jeu entourent le crâne et grossissent à son activation ; une lumière orange colore le modèle et son environnement proche. Les paramètres de poursuite et d'explosion sont réglables dans l'inspecteur.

### Prototype du mini-boss de lave

Scène commune : `scenes/ennemis/mini_boss/monstre_lave/monstre_lave.tscn`. Le choix « Monstre de lave » du sous-menu des ennemis permet de le tester. Il apparaît désormais dans sa composition spéciale toutes les 10 vagues.

Il possède 600 PV fixes et poursuit le joueur à 2,5 m/s. À moins de 3,4 mètres, il annonce un coup au sol pendant 0,6 seconde, frappe en 0,14 seconde et inflige 30 dégâts une seule fois aux entités alliées dans le disque, si aucun mur ne les protège. Sortir du disque avant l'impact permet d'esquiver. Il récupère ensuite pendant 0,7 seconde.

Un arc rouge et un chevron près du joueur annoncent la préparation de la salve, avec le même effet que l’artilleur. Le repère pointe vers le mini-boss et disparaît au premier tir ; il ne s’affiche pas pour son coup au sol.

À distance, jusqu'à 14 mètres, il prépare une salve pendant 0,5 seconde, puis reste immobile pour lancer 12 boules à 0,1 seconde d'intervalle. Chaque boule vise le joueur au moment du départ, avance en ligne droite à 10 m/s et inflige 12 dégâts. Il réutilise les projectiles et leur traînée de l'artilleur, sans générer de flaques. Après la salve, il récupère pendant 0,9 seconde. Le délai après les deux attaques est de 1,5 seconde.

`monstre_lave.gd` hérite du démolisseur pour conserver ses fonctions de navigation, de ligne de vue, de gel et de dégâts reçus, ainsi que les tweens de la frappe. Il remplace le choix des attaques et les dégâts de zone. Les réglages sont exportés dans l'inspecteur ; le label au-dessus affiche sa vie actuelle.

Le modèle original et ses crédits restent dans `assets/modeles/ennemis/mini_boss/`. Le boss utilise désormais `monstre_lave_anime.glb`, une version allégée qui conserve son squelette et quatre animations Mixamo transférées. Voir `docs/animations_boss.md` pour la synchronisation des attaques.

### Catalogue des ennemis pour les tests

Dans les deux modes, I → « Faire apparaître un ennemi… » ouvre le même sous-menu : mobiles, immobiles et mini-boss. Le jeu reste en pause pour ajouter plusieurs ennemis. « Retour au debug » revient au panneau principal ; I ferme les menus et reprend le jeu. Échap revient au panneau principal depuis le catalogue.

Le catalogue est dans scenes/interfaces/menus/catalogue_ennemis_debug.gd : chaque entrée associe un identifiant, un nom, une catégorie, une scène et une hauteur de placement. Ajouter une entrée suffit à créer son bouton. Le catalogue debug reste indépendant des compositions automatiques.

RoomManager.creer_ennemi_debug cherche un point libre loin du joueur, vérifie les collisions, relie la mort au compteur et affecte la carte de navigation de la salle. Les tourelles et flaques déclenchent aussi l'actualisation habituelle de la navigation. VaguesZombie réutilise cette fonction et autorise les ajouts uniquement pendant une vague.

### Vagues classiques, spéciales et budget de difficulté

Les vagues classiques représentent 65 % des tirages lorsque des spéciales sont disponibles. Leur pool contient des sbires dès la vague 1, des chiens dès la 3, des démolisseurs et artilleurs dès la 5, puis des kamikazes dès la 7. Les types disponibles ne sont pas tous garantis dans chaque vague classique.

Les spéciales ont 35 % de chances au total, puis une composition est tirée selon son poids : Meute dès la 3, Siège dès la 5, Embuscade dès la 7. Le titre de la composition s'affiche dans le HUD. Toutes les 10 vagues, la composition du mini-boss remplace ce tirage : un monstre de lave immédiatement, puis jusqu'à trois sbires, sans tourelles.

La difficulté donne un budget de 3 points au départ, augmenté de 2 par vague, plafonné à 30. Le coût d'un sbire, chien ou kamikaze est 1 ; celui d'un artilleur est 2 ; celui d'un démolisseur est 3. Le mini-boss coûte 8. Les tourelles restent hors de ce budget, limitées à une ou deux à partir de la vague 5.

Le poids de tirage est distinct du coût : il règle la fréquence relative de sélection. Les quantités minimales sont réservées en premier, puis les places restantes sont tirées selon les poids, le budget restant et les plafonds. Une vague contenant des ennemis coûteux contient donc moins d'ennemis. En classique, les plafonds sont 12 chiens, 2 démolisseurs, 3 artilleurs et 6 kamikazes. La meute autorise davantage de chiens.

Pour équilibrer dans Godot :
- Ouvrir `scenes/modes/zombie/equilibrage/difficulte_zombie.tres` pour le budget, les groupes, le timer, les tourelles, la probabilité de spéciale et la périodicité du boss.
- Ouvrir une ressource dans `scenes/modes/zombie/equilibrage/compositions/` pour son titre, sa première vague, son poids et sa liste d'ennemis.
- Déplier un ennemi pour modifier sa scène, sa première vague, son coût, son poids de tirage et ses quantités minimum/maximum. Les réglages d'un type sont propres à cette composition.
- Pour créer une spéciale, dupliquer une composition, modifier ses réglages et l'ajouter à `Compositions spéciales` dans la difficulté.

`composition_vague.gd` construit la liste selon le budget. `difficulte_zombie.gd` choisit la composition. `vagues_zombie.gd` associe chaque position réservée à son type ; `creer_mobile` est appelé par le calendrier commun pour créer le bon ennemi. La navigation, les annonces, le comptage des morts, le sauvetage et les pauses de boutique restent communs. Un ennemi apparaît immédiatement ; les suivants sont répartis jusqu'à la fin du timer. Le mode classique conserve ses propres règles de population.

Le traitement du sauvetage ignore désormais les enfants qui ne sont pas dans le groupe victime : les sons de mort peuvent rester dans le conteneur sans provoquer d'erreur à la vague suivante.


## Arrivées par les accès de la map

Les mobiles entrent désormais par les portes, brèches, fenêtres et l’ascenseur de Hall. Les volants utilisent les fenêtres ; les tourelles restent générées sur leurs emplacements fixes. Le calendrier conserve sa durée et le premier mobile immédiat. Voir [arrivees_ennemis_zombie.md](arrivees_ennemis_zombie.md) pour les scènes, l’animation et les réglages.
