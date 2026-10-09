# Bâtiment et ville du mode classique

Le décor se construit dans cet ordre : zone jouable, entrées/sorties, habillage et pièces derrière les portes, remplissage inaccessible du bâtiment, puis installation de la ville autour de la salle active.

## Bâtiment carré

`scenes/salles/enveloppe_batiment.gd` définit un carré à partir du plus grand côté de la grille et d'une marge. Avec une grille de 10 × 8 cellules de 5 m et une marge de 2 cellules, le bâtiment fait 70 × 70 m. La découpe aléatoire de la salle ne change pas cette enveloppe.

La ressource `scenes/salles/enveloppe_batiment.tres`, accessible dans Habillage → Batiment du générateur, expose la marge, les dimensions maximales des pièces, le nombre d'ensembles de mobilier et d'incendies.

Le remplissage soustrait les cases jouables, les trous, les collisions des couloirs/escaliers et les surfaces des pièces déjà installées. Chaque soustraction découpe les rectangles disponibles en quatre morceaux sans recouvrement. Les surfaces restantes deviennent des espaces décoratifs avec sols, cloisons, ouvertures et mobilier correspondant à l'étage. Ce découpage reste une base de disposition : les très petits raccords reçoivent uniquement un sol.

Les pièces derrière les portes sont également refusées lorsqu'elles dépassent le carré. Elles constituent désormais des pièces visibles du même bâtiment, pas des extensions hors de son volume. Le remplissage conserve ces scènes fixes et leurs variantes.

Tout le remplissage est hors de Navigation. Son mobilier n'a pas de collision ; les murs déjà présents au bord de la zone jouable continuent de bloquer le joueur. Il n'ajoute aucun point de spawn. Les trous du plancher restent vides. Les fenêtres de la façade extérieure montrent réellement la ville.

## Ville fixe

`scenes/decors/interieurs/ville_etage.gd` construit huit îlots entourant celui du joueur, avec six immeubles par îlot : 48 immeubles, cinq modèles, des chaussées de 12 m et des trottoirs de 3 m, un marquage central et des lampadaires. Aucun tirage aléatoire n'intervient dans son plan.

Le RoomManager crée une seule ville à la première activation de salle. Lors des transitions, il la déplace autour de la salle active et abaisse son altitude. Elle est placée à côté du conteneur Salles : elle n'entre donc pas dans le comptage des salles. Les ressources importées des modèles sont partagées.

Les réglages du quartier commun sont dans `scenes/salles/exterieur_etage_1.tres`. Les profils des trois étages ne diffèrent actuellement que par leur hauteur sur rue : 4,5 / 9 / 13,5 m. Il n'y a pas trois villes différentes. Modifier les réglages de la ville demande de relancer la partie, puisqu'elle est construite une seule fois.

Les quatre façades des étages inférieurs prolongent le carré jusqu'à la rue ; elles ne reproduisent plus chaque petite découpe du niveau. Aucun plafond n'est ajouté au-dessus du joueur.

## Entrée

Le RoomGenerator n'instancie plus le battant cassé au sol. Le couloir, son fondu sombre, les escaliers éventuels et l'arrivée automatique du joueur restent en place. L'ancienne scène de porte reste disponible comme asset.

## Modèles supplémentaires

Les fichiers téléchargés et leurs licences sont conservés dans `assets/modeles/decors/ville/nyc_building` et `modern_building_002`. Pour le modèle moderne, les dalles extérieures fournies par l'auteur sont retirées de l'instance ; elles ne remplacent pas nos trottoirs. L'échelle est toujours uniforme.

## Densité et lisibilité des pièces inaccessibles

La ville comporte maintenant six immeubles par îlot (48 au total). Les champs `Immeubles par ligne` et `Rangees par ilot` du profil commun règlent cette densité. Les modèles gardent une échelle uniforme et leur emprise est limitée à leur emplacement, avec deux mètres de séparation.

Le remplissage n'est plus limité à douze ensembles sur tout le bâtiment. `amenagement_piece.gd` meuble chaque pièce, avec jusqu'à quatre ensembles dans les grandes pièces. Les espaces étroits accueillent des armoires à l'étage 1, des étagères à l'étage 2 et des équipements électriques à l'étage 3. Valises, sacs, chaises tombées et papiers suggèrent une évacuation. Les ensembles préexistants apportent les salons bousculés, les repas interrompus et les cuisines abandonnées. Il s'agit de variations de placement et d'objets, sans nouveau texte affiché dans le décor.

`scenes/salles/amenagement_pieces.tres` expose l'espacement, le nombre d'ensembles par pièce, la probabilité et la liste des objets abandonnés. Cette ressource se retrouve dans Habillage → Batiment → Amenagement.

`aspect_piece_inaccessible.gd` applique une finition propre aux espaces non jouables, après l'initialisation des meubles. Les matériaux sont copiés pour préserver le niveau navigable : sols plus sombres et mats, mobilier atténué, lumières réduites à 40 % et braises du mobilier à 20 %. Les copies identiques sont partagées dans une même pièce. Le même aspect est appliqué aux pièces fixes derrière les portes. Les flammes restent présentes ; leur nombre demeure limité à trois dans le remplissage.

`scenes/salles/aspect_pieces_inaccessibles.tres` expose ces couleurs et intensités. Il est accessible dans Habillage → Batiment → Aspect, et dans les scènes des pièces fixes. Le traitement ne modifie ni l'éclairage global ni les matériaux des cases jouables.

## Composition des îlots

Chaque îlot utilise désormais une composition fixe différente (`PLANS_ILOTS` dans `ville_etage.gd`). Les parcelles n'ont plus toutes la même largeur ; la séparation entre les rangées varie et les bâtiments ont des retraits et hauteurs différents. Les façades sont orientées vers les rues entourant le bâtiment jouable, avec de légères variations de teinte sur des copies de leurs matériaux. La tour moderne n'apparaît qu'une fois dans la configuration par défaut. La ville reste identique entre les salles et les étages.

## Cloisons et scintillement

`murs_sans_doublons.gd` supprime les recouvrements des volumes visuels. Il traite en priorité les blocs du niveau navigable, puis les sols et murs des pièces fixes, puis ceux du remplissage. Lorsqu'un bloc en recouvre un autre, seule sa partie encore libre est conservée, en quelques fragments. Les collisions existantes restent intactes. Ce traitement corrige aussi les petites bandes de sols superposées au seuil des pièces annexes.

L'enveloppe ne rajoute plus un mur sur le bord de chaque rectangle disponible. Les espaces contigus sont d'abord fusionnés lorsque leur union forme un rectangle libre, puis découpés avec des proportions variables. Seules les séparations intérieures reçoivent des cloisons. Les passages ne sont plus toujours centrés, et certaines séparations restent ouvertes pour réunir visuellement plusieurs espaces. La ressource Batiment expose `Proportion espaces ouverts` (25 % par défaut). L'aléatoire reste celui de l'habillage, indépendant de la génération du combat.
