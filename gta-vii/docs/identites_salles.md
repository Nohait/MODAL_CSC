# Identités des salles classiques

Chaque salle choisit un profil dans `scenes/salles/identites/`, adapté à son étage. Le tirage utilise la grille et l'étage : une reprise de la même salle retrouve son identité. Il ne consomme pas le hasard global du combat.

Le profil hérite des réglages d'`AmbianceEtage` : mobilier en feu, fenêtres, appliques, tuyaux, gravats, zones humides et reflets. Il ajoute un titre, un étage, un poids de sélection, une couleur de soubassement, les pièces derrière les portes et les compositions de mobilier des annexes.

## Modifier ou ajouter un profil

1. Ouvrir un `.tres` du dossier `identites` dans Godot pour modifier ses réglages dans l'Inspector.
2. Pour une nouvelle identité, dupliquer un profil, changer son titre et ses ensembles de mobilier.
3. Ajouter cette ressource dans la liste **Identités** de `scenes/salles/habillage_classique.tres`.
4. Un poids de zéro exclut un profil. Les autres poids sont relatifs aux profils du même étage.

L'option **Identités actives** permet de retrouver les anciennes ambiances par étage. Les réglages de finition et d'aménagement sont copiés pour chaque salle : modifier un profil pendant la génération ne modifie pas les autres salles.

Les nouvelles identités réutilisent les règles de placement, les contrôles de place et la navigation existants. Elles ne modifient ni les ennemis, ni les objectifs, ni le mode zombie. Le titre reste une métadonnée de la salle ; aucun panneau ou message supplémentaire n'est ajouté au HUD.

## Incendies

Chaque identité référence un profil dans `scenes/salles/incendies/`. Habitation, réserve, conduites et installations électriques partagent le script `incendie_salle.gd`, avec des réglages distincts d'ampleur, de lumière, de fumée et de braises.

Le profil renforce les foyers déjà placés et ajoute au maximum deux langues de flammes, sans lumière ni son supplémentaire. Il s'applique également aux pièces derrière les portes et aux annexes de l'enveloppe. Les foyers couvants restent possibles, mais deviennent plus rares (8 % par défaut). Tous ces réglages sont accessibles dans l'Inspector via la propriété **Incendie** d'une identité.

Les effets restent décoratifs : aucune nouvelle collision, aucun dégât et aucun changement du mode zombie. Le nombre de particules augmente ; **Langues secondaires** et **Particules par langue** permettent de réduire ce coût.

## Espace jouable et ambiance générale

Les caisses ne sont plus générées dans les salles classiques. Leur scène est conservée, notamment pour les outils de validation.

`scenes/salles/incendies/habillage_incendie.tres` règle les retombées d'incendie : petits gravats sans collision au pied des murs, dépôts locaux de cendre, deux foyers décoratifs supplémentaires et braises dérivantes. Les arrivées et les cellules déjà réservées au mobilier restent exclues. Aucun dépôt ne retire de point de spawn ni ne crée d'obstacle de navigation.

Les braises sont émises depuis les foyers, avec un seul émetteur supplémentaire par salle. Les nombres de foyers, de dépôts et de braises sont modifiables dans l'Inspector. Les foyers ajoutent chacun une lumière sans ombre et un crépitement local atténué.

Dans `scenes/jeu/main.tscn`, l'environnement et la lumière directionnelle du mode classique ont une teinte chaude, légèrement rougeâtre. Le glow est légèrement renforcé. Ces réglages restent ceux des nœuds Godot dans l'Inspector ; l'éclairage du mode zombie n'est pas modifié.

## Niveaux d'incendie

Les profils de `scenes/salles/incendies/niveaux/` modulent les identités : relativement épargnée (poids 0,25), incendie actif (0,45) et salle embrasée (0,30). Le poids est relatif aux autres profils ; zéro exclut un niveau.

Dans `habillage_classique.tres`, **Variations incendie actives** permet de désactiver le tirage, et **Niveaux incendie** contient les profils possibles. Chaque profil expose l'ampleur des flammes, la lumière, la fumée, la chance de foyer couvant, les nombres de braises et de foyers, ainsi que les couleurs d'éclairage.

Le tirage utilise la grille, l'étage et une graine indépendante. Le niveau est conservé comme métadonnée de la salle. Les profils d'identité et d'incendie sont copiés avant modification.

`eclairage_incendie.gd`, attaché au nœud Eclairage de main, écoute le signal `salle_preparee` du RoomManager. Il applique la couleur du niveau choisi pendant la transition, avant l'entrée du joueur. Aucune modification du gameplay ou du mode zombie.

## Braises au vent

`braises_foyer.gd` pilote le nœud Braises de chaque scène foyer. Le budget de la salle est réparti entre ces émetteurs. Une accélération horizontale fait dériver les particules, une oscillation douce produit les rafales et une seconde fait varier légèrement la direction. La variation agit également sur les braises déjà en vol. Aucun calcul individuel, lumière ou collision supplémentaire.

Les niveaux d'incendie exposent **Force vent** et **Force rafales**. Les quantités restent 20, 56 et 80 braises selon le niveau. La période des rafales (6 secondes par défaut) est réglable dans `habillage_incendie.tres`. Les particules partent des foyers de la zone jouable et disparaissent progressivement.

Pour les observer, lancer une partie classique, se placer près d'un foyer et regarder les petits points orange monter puis dériver dans la salle pendant quelques secondes. Pour forcer le test le plus visible, mettre provisoirement les poids des profils épargné et actif à zéro, puis lancer une nouvelle partie ; restaurer 0,25 et 0,45 après le test.

## Pièces embrasées derrière les portes

La ressource `scenes/salles/incendies/piece_embrasee.tres` expose les volutes intérieures et au seuil, leur opacité et durée, le renfort des lumières existantes et les braises du mobilier. Elle est sélectionnée dans **Pièces derrière les portes > Incendie pièces** de `habillage_classique.tres`. Désactiver **Actif** permet de revenir au rendu précédent.

`piece_decorative.gd` applique ce profil après l'assombrissement des annexes. Les émetteurs réutilisent le shader de fumée existant, avec une rampe de couleur indépendante. Le haut des portes laisse échapper des volutes vers la salle jouable. Un cadre tombé et un plafonnier incliné, sans collision ni nouvelle lumière, suggèrent les dégâts matériels.

Les sons structurels sont réglés dans `scenes/systemes/audio/profils/structure_classique.tres` : deux bruits de chute alternent aléatoirement, toutes les 180 à 360 secondes de jeu actif, premier passage compris. Leur source est placée dans une pièce voisine si possible. Le gestionnaire d'ambiances existant empêche les sons ponctuels de se superposer et les suspend pendant les menus. Pour écouter rapidement, réduire provisoirement les délais à quelques secondes, puis les rétablir.


Le profil structurel active **Conserver attente entre salles**. Son temps restant est stocké sur la scène de la partie, par profil sonore. Une nouvelle source reprend ce temps depuis la salle actuelle ; les sources des salles masquées ne le font pas avancer. Un passage terminé tire un nouveau délai de 3 à 6 minutes. Revenir au titre détruit cette horloge avec la scène de jeu : elle ne persiste pas dans les sauvegardes. Les autres profils conservent leur comportement précédent.

## Éteindre les foyers décoratifs

La scène commune `scenes/decors/hall_incendie/foyer_incendie.tscn` possède un enfant **Extinction**, réglé par `extinction_foyer.gd`. Dans son Inspector, **Extinguible** désactive l'interaction et **Durée extinction** règle les secondes de jet nécessaires (2,5 par défaut). **Rayon contact**, **Persistance vapeur** et **Particules vapeur** contrôlent le retour visuel.

La scène commune de l'extincteur possède **ExtinctionDecor** (`extinction_decor.gd`). Toutes les 0,08 secondes de jet, il recherche les foyers visibles à portée, réutilise `cible_dans_jet()` pour respecter les portions de mousse en mouvement et vérifie les obstacles par un rayon physique. Le porteur est exclu ; le meuble associé au foyer peut recevoir le jet sans le bloquer. Aucun nouvel Area3D ni obstacle de navigation n'est ajouté.

Chaque foyer conserve une intensité entre 1 et 0. Le temps réellement passé sous le jet la réduit progressivement. Les flammes rapetissent, la lumière et le crépitement diminuent, puis les émetteurs s'arrêtent : les particules déjà présentes terminent naturellement leur vie. Une vapeur montante réutilise le visuel des impacts de mousse, avec un seul émetteur par foyer touché. Le refroidissement ne dépend pas des dégâts du joueur, des cartes ni des dégâts colossaux de debug.

Le mobilier associé garde sa carbonisation mais perd ses braises lorsqu'il est éteint. Le signal `foyer_eteint` est disponible pour de futures interactions ; il ne change pas les objectifs de salle. Le fonctionnement est commun aux deux modes pour les décors utilisant cette scène de foyer. Les flaques ennemies gardent leur comportement de combat.

