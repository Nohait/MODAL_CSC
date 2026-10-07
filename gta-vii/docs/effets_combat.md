# Effets de combat : mousse et cendres

## Essayer et régler

Lancer main et attaquer un ennemi mobile ou une tourelle avec l'extincteur.
De petites bouffées de vapeur claire apparaissent au contact pendant le jet. À sa mort, le corps devient
charbon puis se dissout en petites zones, avec quelques poussières de cendres.
Les flaques conservent leur fonctionnement et leur disparition actuels.

Dans extincteur.tscn, sélectionner la racine : la section Retour visuel — impacts
permet de désactiver la mousse et de régler intervalle_impacts (0,14 s par défaut).
Ce délai est purement graphique : il ne modifie ni les dégâts, ni la portée du jet.

Dans sbire.tscn ou tour_enflammee.tscn, sélectionner la racine : afficher_cendres
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

## Pulvérisation de l'extincteur

Le jet commun aux deux modes utilise des images transparentes (`QuadMesh`) orientées vers la caméra, à la place des petites sphères. La texture Kenney `assets/textures/extincteur/pulverisation.png` apporte les contours irréguliers ; sa licence CC0 est conservée à côté.

Dans `scenes/armes/extincteur/extincteur.tscn`, le matériau affiche cette texture et la couleur des particules. Le dégradé `FonduJet` adoucit leur apparition puis leur disparition. Une rotation aléatoire évite que toutes les images se superposent de la même façon.

Dans `extincteur.gd`, `configurer_jet()` construit la courbe de taille : les particules sont petites à la buse et s'élargissent au cours du trajet. Les réglages sont sur le nœud Extincteur, groupe Jet / Aspect de la pulvérisation : nombre de particules, taille de départ et taille de fin, en mètres avant la variation aléatoire. L'opacité reste dans Jet.

La portée, le demi-angle, la vitesse et les portions actives de dégâts gardent leur fonctionnement. Le double jet reprend la même courbe ; la couleur du jet givré reste pilotée par les améliorations. Aucun dépôt de mousse au sol n'est ajouté.

Polish partagé du jet et des victimes :

- `scenes/effets/combat/contact_jet_murs.tscn` est ajouté sous chaque extincteur. Cinq rayons répartis dans le cône détectent les corps physiques toutes les 0,08 s, sur toutes les couches. Le porteur est exclu, ainsi que les Area3D de détection. Le nombre de rayons et le masque sont réglables. Leurs BoxShape3D sont copiées dans des GPUParticlesCollisionBox3D temporaires ; seule la pulvérisation utilise leur couche visuelle 18. Les particules disparaissent au contact, avec deux petites bouffées latérales utilisant la texture existante. Les volumes sont conservés le temps des derniers fragments du jet puis supprimés. Pour les autres formes (sphères, capsules, polygones, meshes), une petite boîte fine orientée selon la normale représente la surface au point de contact. Ce volume est approximatif, sans recopier tout le mesh. Les volumes suivent leur objet ; une référence faible permet de les retirer si celui-ci disparaît. Taille de contact réglable. Aucun dégât ni trace au sol ajouté. Réglages sur la scène ContactJetMurs.
- `extincteur.gd`, groupe Souffle sonore : sous 25 % de réserve, le volume diminue progressivement jusqu'à -4 dB supplémentaires. Le fichier audio et sa vitesse restent inchangés ; les fondus de démarrage et d'arrêt sont conservés.
- `zone_mousse.gd` et son shader : les zones gelées fondent depuis leurs bords pendant les dernières 0,9 s. Le paramètre `fonte` réduit la couverture, sans réduire la collision ou la durée des effets. Les zones non gelées gardent leur ancien fondu.
- `victime.gd`, groupe Appel au secours : délai aléatoire de 0,1 à 0,9 s après le seuil de 50 % des PV. Un Timer enfant respecte la pause et disparaît avec la victime. Avant le cri, vérifier qu'elle est encore captive et vivante. L'appel reste unique et spatialisé ; le hasard du délai ne modifie pas les graines des combats.

Verglas utilise désormais `scenes/systemes/ameliorations/depot_verglas.tscn`, ajouté sous EffetsCartes. Son script relève les portions actives du jet toutes les 0,18 s et construit leur empreinte au sol : longueur actuelle, angle et direction, avec découpe contre les obstacles de la couche sélectionnée. Le double jet dépose deux empreintes. Les traces restent dans la salle lorsque le joueur tourne ; des dépôts successifs dessinent donc son balayage. Une trace identique est rafraîchie plutôt que dupliquée. Intervalle, durée (4 s), précision du contour et masque d'obstacles sont réglables sur DepotVerglas.

`zone_mousse.gd` transforme ce contour en ArrayMesh et utilise le même polygone pour vérifier quels ennemis sont réellement dedans. Le cylindre de détection ne sert qu'à obtenir une première liste de corps proches. Le shader conserve la couleur glacée et érode les bords en fin de vie. Mousse expansive agrandit aussi ces empreintes ; sa croissance possède son propre chronomètre pour ne pas repartir de zéro à chaque rafraîchissement. La silhouette suit l'enveloppe du jet, pas chaque particule individuelle. Les autres zones de mousse gardent leur forme circulaire.

Les zones gelées utilisent le matériau `assets/materiaux/verglas.tres` et le shader `verglas.gdshader`. Les textures Ice003 d'ambientCG (CC0, licence à côté des images) apportent couleur, normale OpenGL et rugosité. Le matériau reçoit les lumières, avec un relief discret et une faible rugosité ; il n'est pas métallique. Les coordonnées de texture sont calculées dans le monde pour garder une échelle constante entre dépôts. Dans Shader Parameters du matériau, taille_texture règle la largeur du motif en mètres, relief l'intensité de la normale, rugosite les brillances et transparence l'opacité (1 = opaque). Chaque zone duplique le matériau pour conserver sa propre fonte. La mousse ordinaire et les abris gardent leur shader précédent.
