# Effets de combat : mousse et cendres

## Essayer et régler

Lancer main et attaquer un ennemi mobile ou une tourelle avec l'extincteur.
De petites bouffées de vapeur claire apparaissent au contact pendant le jet. À sa mort, le corps devient
charbon puis se dissout en petites zones, avec quelques poussières de cendres.
Les flaques conservent leur fonctionnement et leur disparition actuels.

Dans extincteur.tscn, sélectionner la racine : la section Retour visuel — impacts
permet de désactiver la mousse et de régler intervalle_impacts (0,14 s par défaut).
Ce délai est purement graphique : il ne modifie ni les dégâts, ni la portée du jet.

Dans ennemi.tscn ou tour_enflammee.tscn, sélectionner la racine : afficher_cendres
active l'effet, et duree_cendres règle la dissolution (0,7 s par défaut).
Dans scenes/effets/combat/impact_mousse.tscn, sélectionner Vapeur pour régler amount,
lifetime, initial_velocity_min/max et la taille du QuadMesh utilisé comme nuage.
Même principe pour Poussieres dans disparition_cendres.tscn.

## Comment cela fonctionne

L'extincteur appelle retour_combat.gd avant d'infliger les dégâts. Un dictionnaire
conserve un délai pour chaque cible, identifié par get_instance_id(). Les délais
diminuent avec delta dans _physics_process. Quand l'un expire, sa clé est effacée :
le prochain impact peut créer une nouvelle bouffée de vapeur. Les dégâts continuent
pendant le délai, indépendamment des particules.

creer_impact utilise un petit rayon physique pour placer le visuel sur la collision
atteinte. Ce rayon ne décide jamais si la cible reçoit des dégâts : les tests du jet
existant gardent cette responsabilité. La collision reste une approximation du
modèle visible. Un point proche de la cible sert de repli si aucun contact n'est trouvé.

La vapeur contient 7 rectangles orientés vers la caméra (billboard), émis par
CPUParticles3D. Une GradientTexture2D radiale rend leurs bords progressivement
transparents. La courbe de taille agrandit chaque nuage ; le dégradé de couleur
fait apparaître puis disparaître sa transparence. Les particules montent verticalement
(direction = Vector3.UP), avec un angle de dispersion réduit à 18 degrés. Aucune texture externe n'est nécessaire.
local_coords = false laisse la vapeur dans le monde lorsque l'ennemi bouge.
Le signal finished supprime l'effet une fois toutes les particules terminées.

À la mort, creer_cendres copie uniquement les maillages du corps en conservant
leurs transformations. Le modèle mobile et la tour partagent cette même logique.
L'effet ne copie aucun script de combat, collision, lumière, feu ou NavigationAgent.
Il n'appartient pas au groupe enemies. Le vrai ennemi émet died et disparaît
immédiatement : le RoomManager compte la mort sans attendre l'animation.
Les copies partagent la géométrie mais possèdent leurs propres matériaux.

Le shader disparition_cendres.gdshader lit progression entre 0 et 1. Il assombrit
les couleurs du modèle, puis discard retire des fragments selon un motif irrégulier.
Quelques points orange marquent les bords qui se désagrègent. La géométrie du
corps ne tombe pas en morceaux : c'est une dissolution visuelle de sa surface.
Les poussières sont un second système de particules, réparti autour du volume du corps.

Dans disparition_cendres.gd, tween_method actualise progression sur chaque matériau.
Le Tween laisse ensuite finir les poussières, puis supprime l'effet avec queue_free.
Il respecte la pause du jeu. L'effet est un voisin de l'ennemi dans sa salle : il
survit à sa suppression, et est supprimé si la scène qui le contient est détruite.

## Réutiliser

Une nouvelle cible peut appeler RETOUR_COMBAT.creer_cendres(self, [son_visuel], duree).
Le tableau doit contenir les racines des maillages du corps, sans les indicateurs
ni les particules de feu. Ne pas fournir à la fois un parent et son enfant : le même
maillage serait copié deux fois. Conserver le verrou est_mort avant cet appel pour
éviter plusieurs effets et plusieurs signaux de mort lors d'impacts rapprochés.

La gravité de Vapeur est positive sur Y (0, 0.3, 0) : elle ajoute une légère
accélération vers le haut. Contrairement à la gravité du monde, ce réglage est
local au système de particules et ne modifie aucun personnage.

## Libération des victimes

La scène scenes/effets/liberation/liberation_victime.tscn contient un anneau vert
(TorusMesh aplati) et un pictogramme (Sprite3D en billboard). Le signal freed de la
victime crée cet effet comme enfant : il suit son mouvement. Le Tween parallèle
réduit l'anneau, fait monter l'icône et diminue leurs opacités pendant 0,55 seconde.
chain attend la fin des pistes avant queue_free. La durée et l'activation sont
réglables sur la racine de victime.tscn. Les victimes achetées en boutique ne jouent
pas cet effet, car leur arrivée n'est pas une libération dans la salle.

## Transition entre étages

main contient TransitionEtage, une instance de
scenes/interfaces/transitions/transition_etage.tscn. Son CanvasLayer place un voile
noir et un parchemin titré au-dessus de l'interface. Le shader du papier est celui
des cartes existantes. Sur sa racine, duree_noir, duree_titre et duree_retour règlent
le rythme de la transition.

Après Continuer dans la boutique, le RoomManager compare l'étage actuel à celui
de la salle d'arrivée. Si l'étage change, il gèle le combat, attend masquer() pour
obtenir un noir complet, puis prépare la nouvelle salle et ses chemins. Il attend
ensuite reveler(numero) : apparition du titre, courte lecture, disparition du titre
et du voile. Seulement ensuite, il rend le contrôle et lance le timer de sauvetage.

await suspend la fonction de changement de salle, pas toute la scène. L'arbre
reste dépausé pour que la physique et le serveur de navigation puissent préparer
les chemins. Les ennemis, victimes et le joueur restent gelés séparément pendant
l'animation. transition_en_cours empêche le timer de progresser.
Le premier lancement et les passages dans le même étage n'ont pas cette animation.
Les sauts d'étage du debug utilisent la même transition.
