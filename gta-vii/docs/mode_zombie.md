# Mode zombie : refuge et boutique

L’écran titre ouvre la sélection des maps. MapTest est une salle fixe de 40 × 40 mètres avec une entrée au sud. R et Rejouer conservent la map sélectionnée.

## Boucle d’une vague

La course d’entrée précède la première vague. Chaque vague crée 1 à 3 captives et un timer aléatoire de 15 à 30 secondes. Les sbires sont répartis en groupes dans cette durée : leur annonce précède l’apparition et le dernier groupe apparaît à zéro. Les captives perdent progressivement leur vie jusqu’à zéro ; les libérer arrête ces dégâts. Elles suivent automatiquement le joueur et restent vulnérables aux attaques.

Pointer le refuge et cliquer au milieu envoie toute l’escorte vers lui. Il s’éclaire au survol et affiche l’instruction. Chaque victime entre seulement lorsqu’elle atteint le refuge. Ses PV restants, ses PV maximum et son ordre de libération sont conservés dans un dictionnaire ; son personnage est ensuite retiré. Le dernier élément de la liste est toujours la victime sauvée le plus récemment, même si l’ordre d’arrivée diffère. Les attaques touchent uniquement cette victime ; si elle meurt, on la retire et la précédente reprend sa place avec sa propre vie. Le pictogramme et le compteur indiquent le nombre de victimes abritées ; la barre représente la victime attaquable. Un refuge vide n’est plus une cible.

Une vague se termine après le timer et la mort de tous ses ennemis. Chaque victime abritée à cet instant rapporte 1 point ; l’escorte ne rapporte rien. Les points non dépensés sont conservés. Après 3 secondes, la boutique commune ouvre les boosters et leurs choix de cartes ; le combat est en pause. Les défis du jeu principal sont masqués. Fermer la boutique lance un compte à rebours de 3 secondes avant la vague suivante. Le refuge et l’escorte conservent leurs PV. Un refuge vide ne termine pas la partie.

## Organisation

- `mode_zombie.gd` instancie main et spécialise ses gestionnaires avant leur initialisation. Le jeu principal conserve ses scripts et ses règles.
- `vagues_zombie.gd` hérite du RoomManager : salle fixe, population, calendrier des annonces, timer commun, récompense et pauses. Les tourelles apparaissent à partir de la vague 5, au maximum 2. Les sbires augmentent de 3 au départ à un plafond de 30 ; ni leurs PV ni leurs dégâts n’augmentent.
- `victimes/refuge_zombie.tscn` contient le camion importé, réduit uniformément à environ 4,2 mètres de long et 2 mètres de haut, recentré et muni d’une collision en boîte. `refuge_zombie.gd` gère le survol, le dépôt, la liste des PV et l’affichage au-dessus. Le shader surbrillance_refuge ajoute une couche dorée uniquement au survol, sans remplacer les matériaux d’origine.
- `escorte_zombie.gd` hérite du VictimManager. Il adapte seulement la commande au clic milieu, le retour automatique et l’ordre de libération.
- `sbire_zombie.gd` et `tour_zombie.gd` reprennent les ennemis communs et abandonnent une cible refuge vide. Le sbire calcule la distance au bord de la collision rectangulaire du camion dans sa direction pour pouvoir l’attaquer sans atteindre son centre.
- `boutique_zombie.gd` hérite de l’UpgradeManager : points conservés, textes adaptés et signal de fermeture au lieu du changement de salle. Les achats, animations, cartes et effets d’améliorations restent communs. `defis_zombie.gd` fournit un catalogue vide.
- `partie_zombie.gd` et `fin_zombie.gd` conservent la mort, le bilan des vagues et les boutons Rejouer / Écran titre. Aucun succès de victoire du parcours n’est débloqué.

## Réglages et maps

Ouvrir mode_zombie.tscn, sélectionner ModeZombie et déplier Difficulté dans l’Inspecteur. La ressource difficulte_zombie.tres expose les nombres d’ennemis et de victimes, la taille des groupes, la durée du timer et les deux pauses de boutique.

MapTest hérite de salle.tscn pour conserver la navigation. Ses 64 Marker3D de PointsApparition fixent les emplacements possibles ; aucun n’est placé dans le couloir. Le refuge est ajouté au centre, sous Navigation/Decor, avant la construction du navmesh pour que les chemins le contournent. Les victimes rejoignent son voisinage avant d’être déposées.

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
