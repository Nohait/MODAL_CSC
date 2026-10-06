# Parking — deuxième arène zombie

La sélection des maps propose désormais Hall et Parking. Le parking mesure 60 × 56 mètres, avec un noyau technique qui lui donne une forme en U et une rampe d'entrée au sud. Le camion se trouve au centre de la partie large. Le mode classique conserve ses salles actuelles.

Les places mesurent environ 6 × 3,3 mètres, avec une butée et un numéro au sol. Vingt-trois véhicules, quatre poteaux centraux et quelques ensembles de gravats, cartons et équipement électrique habillent le parking. Les grands axes restent dégagés. Les ventilations ont une allège et des jambages en béton : seule la partie haute est ouverte, avec une grille.

`Navigation/Decor/SortiePietonne` occupe une partie du noyau central : sol, escalier à deux volées adossé à l'angle arrière gauche, avec palier et mains courantes, façade d'ascenseur condamné et éclairage vert. Une porte condamnée sépare ce décor de l'arène. Aucun point d'apparition n'est ajouté dans cette cage d'escalier.

`Navigation/Decor/Incendies` contient cinq foyers décoratifs supplémentaires avec leurs traces de suie et gravats. Ils réutilisent le composant de feu existant (taille, énergie, portée et densité de fumée réglables dans l'Inspector). Ils ne causent pas de dégâts et ne sont pas des ennemis. Le reste de la partie continue de fonctionner comme avant.

## Où modifier la map

- `scenes/modes/zombie/maps/parking.tscn` : disposition éditable des sols, murs, marquages, véhicules, éclairages, accès ennemis, équipements et points d'apparition.
- `scenes/modes/zombie/maps/parking.gd` : ambiance propre au parking, position du camion et liste des paliers, exposées dans l'Inspector. Le script réutilise l'initialisation du Hall et de la salle commune.
- `scenes/modes/zombie/maps/catalogue_maps.gd` : titre, scène et aperçu proposés dans le menu.

Les vagues, victimes, boutique, équipements, navigation et sauvegarde restent ceux du mode zombie existant. Le gestionnaire utilise `position_refuge` si la map la définit ; le Hall garde sa position habituelle. Le checkpoint mémorise déjà la scène de la map, donc Continuer retrouve également le parking.

## Véhicules

`scenes/decors/parking/vehicule_parking.gd` place un modèle téléchargé dans une enveloppe commune : recentrage, taille uniforme et collision en boîte. La longueur, la couleur de peinture, la salissure et la présence d'un incendie sont réglables dans l'Inspector. Les proportions du modèle sont conservées. Les collisions servent aussi au calcul de navigation : les ennemis contournent les voitures et le noyau technique.

`assets/shaders/decors/voiture_parking.gdshader` conserve les textures du modèle, teinte la carrosserie et ajoute de la suie irrégulière. Les vitres conservent leur matériau. Les voitures incendiées utilisent le foyer existant, avec ses flammes, sa fumée et sa lumière locale.

`scenes/decors/parking/accessoire_parking.gd` recentre et dimensionne les grilles et bornes téléchargées. Les bornes en béton accompagnent une barrière construite avec des formes simples.

`Navigation/Decor/InstallationsTechniques` regroupe les conduits métalliques fixés aux murs hauts, leurs supports, le groupe électrogène près du local technique et les alarmes aux sorties. Ces éléments restent décoratifs. Le groupe possède une collision simple ; les conduits en hauteur et les alarmes n'ajoutent pas de collisions inutiles.

Dans le script d'accessoire, `morceau_choisi` sélectionne un mesh du pack modulaire ; un texte vide conserve le modèle complet. Le recentrage utilise seulement la pièce conservée. `largeur` règle l'échelle uniformément et `collision` ajoute une boîte lorsque l'objet doit bloquer la circulation. Le groupe utilise cette option, contrairement aux alarmes. Aucun son d'alarme ou de moteur n'est lancé automatiquement.

## Sol et lumière

`assets/materiaux/parking/sol_humide.tres` rassemble les textures de couleur, normale et rugosité. Son shader `assets/shaders/decors/sol_parking.gdshader` utilise la position dans le monde pour raccorder les morceaux de sol. Des variations larges cassent la répétition et créent des zones humides plus réfléchissantes. Le relief vient de la normal map, sans ajouter de géométrie.

`assets/materiaux/parking/ambiance_parking.tres` règle l'ambiance sombre, la lueur et les réflexions écran. Les néons bleutés, issues vertes et incendies orange produisent les couleurs localement. Trois sondes de réflexion complètent les réflexions écran. La caméra de jeu conserve son fonctionnement habituel.

## Accès et évolution

Deux accès au sol réutilisent la porte animée. L'accès est possède un linteau et des raccords en béton ajustés à son cadre. Deux accès de ventilation réutilisent le système réservé aux ennemis volants. Les marqueurs de captifs sont placés dans les zones praticables.

Les deux accès automobiles utilisent désormais `scenes/modes/zombie/apparitions/garage_arrivee.tscn`. Son script `entree_garage.gd` conserve le calendrier d'apparition commun et pilote l'AnimationPlayer du modèle téléchargé : montée du rideau, passage des ennemis, puis fermeture. Les positions dans l'animation et les limites temporelles de l'ouverture sont exportées dans l'Inspector. La collision du seuil reste en place pour empêcher le joueur de quitter l'arène.

`Navigation/Decor/FinitionsParking` rassemble les câbles, appliques, ventilateur 1K, traces de freinage, éclats de verre, suie et marquages supplémentaires. Son enfant `Commande` pilote le service de désenfumage proposé dans la boutique du parking.

Les nœuds `FuiteOuest` et `FuiteEst` utilisent `scenes/decors/parking/fuite_eau.gd`. Chacun crée un plan au ras du sol avec le shader `assets/shaders/decors/flaque_eau_parking.gdshader`, puis 22 petites gouttes en jeu. Le masque adoucit et irrégularise les bords de la flaque ; une onde modifie légèrement la rugosité. La hauteur, la taille, la teinte et le nombre de gouttes sont réglables dans l'Inspector. Ces effets n'ont ni collision ni dégâts.

`LumiereApplique2` utilise `scenes/decors/parking/eclairage_defaillant.gd` : l'énergie baisse brièvement à intervalles irréguliers, puis revient à sa valeur initiale. Les délais et l'intensité réduite sont exportés. Les autres sources restent stables pour conserver une bonne lisibilité.

Les ressources `scenes/modes/zombie/evenements/paliers/parking_ventilation.tres` et `parking_eclairage.tres` remplacent les paliers du Hall pour cette map : ventilation supplémentaire à la vague 6, extinction des éclairages d'un secteur à la vague 12. Le numéro et l'action restent modifiables dans les ressources.

`Navigation/Decor/RampesVersMoinsUn` prolonge les deux accès automobiles par une chaussée montante et des murets. Le shader d'obscurité existant assombrit progressivement la fin du sol. Ces rampes sont du décor extérieur, derrière les limites de seuil des portes : elles ne constituent pas une nouvelle zone jouable. Les sprinklers des murs intérieurs sont placés côté allée et orientés vers celle-ci, tête, jet et zone de détection compris.

## Vérifications

`tests/parking_zombie.gd` vérifie le chargement, la position du camion, les accès, les points d'apparition, un trajet contournant le noyau technique et la reprise du checkpoint sur la bonne map. Le test utilise son propre fichier de sauvegarde. Le rendu a également été contrôlé avec Forward+ ; l'aperçu du menu est une capture réelle de la map.

## Incendie progressif

À la vague 8, `parking_incendie.tres` déclenche `Navigation/Decor/IncendieProgressif`, placé sur la berline grise. `incendie_progressif.gd` annonce l’embrasement puis répartit trois foyers sur la carrosserie. Les flammes grandissent progressivement, avec une seule lumière et un seul crépitement. L’incendie reste purement décoratif : aucune zone de dégâts ni collision supplémentaire. Les positions des foyers, la taille des flammes, la lumière et la durée d’embrasement sont exportées.

La sauvegarde des paliers conserve cet événement ; sa restauration ne crée pas de doublon. `tests/incendie_parking.gd` vérifie le déclenchement et l’absence de dégâts au joueur, aux victimes et aux ennemis.

## Désenfumage

`scenes/modes/zombie/equipements/ventilation.gd` conserve l'achat et écoute `salle_commencee`. Pour 5 pièces, le ventilateur se prépare pour la prochaine vague et réduit pendant 30 secondes la fumée dans un rayon de 18 m. Les flammes et les dégâts restent actifs. Un scan par seconde prend en compte les nouveaux foyers ; les quantités initiales de fumée sont rétablies à la fin. Prix, durée, rayon et proportion de fumée sont exportés sur le nœud `Commande`.

La tuile est ajoutée par `boutique_zombie.gd` uniquement si la map contient cet équipement. Son pictogramme est `assets/textures/interfaces/boutique/ventilation.svg`. `point_reprise_zombie.gd` capture et restaure son état comme les autres équipements. Le mode classique et le Hall ne reçoivent pas cette offre.

## Marquages de stationnement

Les inscriptions décoratives de mur et de sol ont été retirées ; seuls les numéros de place restent. Le pictogramme PMR de la place ouest 14 utilise le fichier vectoriel pmr.svg sur un plan fin. La place est 15 contient désormais deux emplacements motos de 2,8 m sur 1,65 m, sans ajout de collision. Le modèle de moto sera intégré après téléchargement.


La BMW stationnée dans l'un des emplacements motos utilise moto.glb, une version allégée à environ 74 000 triangles et textures 1K. Le modèle conserve ses matériaux et reçoit une légère salissure via le script des véhicules. Les anciennes marques de freinage en rectangles sont remplacées par deux plans subdivisés, légèrement courbés par traces_pneus.gdshader. Le shader dessine des stries irrégulières et fond progressivement les extrémités. Il n'ajoute aucune collision ; opacité et courbure restent réglables dans le matériau caoutchouc de la scène.


Les sorties de garage ont leur propre progression : les figurants commencent à marcher après l'ouverture du rideau, à 35 % de l'arrivée, au lieu des 80 % utilisés par l'ascenseur. Cela étale leur déplacement sans modifier les horaires de spawn. Un gyrophare orange annonce l'arrivée, la lumière froide de la rampe suit l'ouverture et la poussière existante est émise une seule fois. Les phases et énergies sont exportées sur la scène garage_arrivee.tscn. Le comportement des autres entrées est conservé.

## Voiture abandonnée

La berline abandonnée près de l'entrée utilise `feux_detresse.gd` : les matériaux des phares existants et des lumières placées dans leurs groupes partagent une horloge. Aucun rectangle supplémentaire n’est ajouté. Les émissions et les reflets clignotent ensemble. Période, temps allumé, énergie, portée et positions sont réglables sur son enfant `FeuxDetresse`. La valise et le sac sont placés de part et d’autre de la porte piétonne, sous Navigation/Decor/ObjetsAbandonnes. Le script accessoire_parking.gd utilise prefixe_morceaux pour sélectionner toutes les pièces de la variante 01 de la valise ; un préfixe vide conserve le modèle complet.

## Paiement et profondeur extérieure

La borne près de la sortie piétonne utilise borne_paiement.gd, qui étend le script d'accessoire pour conserver le recentrage et la collision simple. Le morceau Object_4 correspond à la machine ; la sphère de présentation est exclue. Le shader borne_paiement.gdshader désature la couleur d'origine et rend uniquement l'écran lumineux avec un masque UV de l'atlas. Un sac supplémentaire accompagne la Clio à portière ouverte.

Chaque rampe possède une lumière froide au niveau supérieur, des gravats sur le côté et le script fumee_rampe.gd. Celui-ci extrait uniquement les particules de fumée du foyer existant : aucun son, lumière ou flamme n'est dupliqué. Quantité et taille sont exportées. Le seuil reste fermé au joueur et les allées du parking conservent leur circulation.

