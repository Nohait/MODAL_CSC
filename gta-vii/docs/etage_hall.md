# Hall : un ÃƒÂ©tage habillÃƒÂ©

Cette passe concerne le mode zombie. La surface reste de 40 Ãƒâ€” 40 mÃƒÂ¨tres, avec l'entrÃƒÂ©e existante au sud et le camion au centre. Les salles du mode classique ne sont pas modifiÃƒÂ©es.

## Organisation de l'espace

`scenes/modes/zombie/maps/hall.tscn` instancie quatre nouveaux ensembles sous `Navigation/Decor`. Ils sont ÃƒÂ©ditables directement dans Godot : aucun gÃƒÂ©nÃƒÂ©rateur supplÃƒÂ©mentaire ne tourne pendant la partie.

- `cloisons_etage.tscn` : deux sÃƒÂ©parations ÃƒÂ  X = -10 et X = 10 mÃƒÂ©nagent un hall central de 20 mÃƒÂ¨tres de large. Chaque cÃƒÂ´tÃƒÂ© comporte deux ouvertures de quatre mÃƒÂ¨tres, ÃƒÂ  Z = -10 et Z = 10. Dans chaque aile, une cloison ÃƒÂ  Z = 0 sÃƒÂ©pare les deux piÃƒÂ¨ces et conserve une ouverture de quatre mÃƒÂ¨tres. Cela crÃƒÂ©e plusieurs chemins entre les piÃƒÂ¨ces et le hall.
- `signaletique_etage.tscn` : panneaux Accueil, Archives, Local technique, Bureaux et Salle de repos, ainsi que deux affiches de consignes. Les noms sont dÃƒÂ©coratifs ; ces piÃƒÂ¨ces n'ont pas encore de rÃƒÂ¨gles spÃƒÂ©cifiques.
- `coin_intervention.tscn` : trois cÃƒÂ´nes, un tuyau souple et sa lance, ainsi qu'un extincteur posÃƒÂ© prÃƒÂ¨s du camion. L'extincteur rÃƒÂ©utilise seulement le modÃƒÂ¨le importÃƒÂ© existant, sans son script d'attaque. Les autres ÃƒÂ©lÃƒÂ©ments sont construits avec des formes simples et des matÃƒÂ©riaux partagÃƒÂ©s. Ils n'ont ni collision ni interaction.
- `debris_etage.tscn` : trois groupes de gravats qui reprennent le modÃƒÂ¨le PBR tÃƒÂ©lÃƒÂ©chargÃƒÂ©, un cadre tombÃƒÂ© et un petit meuble renversÃƒÂ©. Les gravats et le corps du meuble ont des collisions simples ; les dÃƒÂ©tails plus petits restent visuels.

Les cloisons sont montrÃƒÂ©es en coupe : le visuel mesure 1,4 m, pour ÃƒÂ©viter de cacher les personnages depuis la camÃƒÂ©ra. Leur collision mesure 3 m et bloque aussi les tirs en hauteur. Chaque cloison est un `StaticBody3D` du groupe `collider`, sur la couche du dÃƒÂ©cor ; la cuisson existante l'intÃƒÂ¨gre aux deux navmeshes. L'apparence basse ne signifie donc pas qu'on peut tirer au-dessus.

Les plinthes et les coupes des traverses s'arrÃƒÂªtent avant les ÃƒÂ©lÃƒÂ©ments longitudinaux. Les habillages des murs extÃƒÂ©rieurs sont ÃƒÂ©galement raccourcis aux angles : cela ÃƒÂ©vite les faces superposÃƒÂ©es qui scintillent (z-fighting). Les panneaux des piÃƒÂ¨ces sont placÃƒÂ©s sur les parties pleines des cloisons, ÃƒÂ  Z = -13,2 et Z = 13,2, et leur dos est lÃƒÂ©gÃƒÂ¨rement encastrÃƒÂ© dans le mur. Les affiches extÃƒÂ©rieures sont plaquÃƒÂ©es de la mÃƒÂªme faÃƒÂ§on. Les positions et les dimensions des collisions restent inchangÃƒÂ©es.

Les plinthes intÃƒÂ©rieures sont dÃƒÂ©sormais deux bandes fines sur les faces du mur, plutÃƒÂ´t qu'un bloc traversant son pied. Elles s'interrompent aux jonctions en T et prÃƒÂ¨s des portes. Les plinthes et baguettes extÃƒÂ©rieures sont ÃƒÂ©galement divisÃƒÂ©es pour laisser la place aux cloisons, aux portes et ÃƒÂ  l'ascenseur. Une vÃƒÂ©rification de leurs volumes dans Godot confirme qu'elles ne pÃƒÂ©nÃƒÂ¨trent plus dans les collisions du dÃƒÂ©cor.

## Apparitions et dÃƒÂ©placements

Les seize marqueurs ÃƒÂ  X = -10 ou X = 10 ont ÃƒÂ©tÃƒÂ© retirÃƒÂ©s : ils se retrouvaient dans les cloisons ou leurs passages. Il reste 44 emplacements rÃƒÂ©partis entre le hall et les piÃƒÂ¨ces. Les quatre points proches du camion ÃƒÂ©taient dÃƒÂ©jÃƒÂ  retirÃƒÂ©s lors de son agrandissement.

La logique des vagues est inchangÃƒÂ©e : elle prend les positions de `PointsApparition`. Pour ajuster la disposition, dÃƒÂ©placer les marqueurs dans Hall et conserver assez d'espace autour pour les grands ennemis. Les points ne doivent pas ÃƒÂªtre placÃƒÂ©s dans les murs, les gravats ou le camion.

## LumiÃƒÂ¨res et traces

Quatre appliques supplÃƒÂ©mentaires ÃƒÂ©clairent les piÃƒÂ¨ces depuis les cloisons, avec une ÃƒÂ©nergie de 1,1. Leur modÃƒÂ¨le et leur fonctionnement sont ceux dÃƒÂ©jÃƒÂ  prÃƒÂ©sents dans le hall.

`fenetre_hall.gd` expose maintenant `Lumiere Incendie`. L'activer donne une lumiÃƒÂ¨re orange ÃƒÂ  la fenÃƒÂªtre et fait varier doucement son ÃƒÂ©nergie avec deux sinusoÃƒÂ¯des. Les variations sont dÃƒÂ©phasÃƒÂ©es selon la position ; les fenÃƒÂªtres ne pulsent pas toutes ensemble. L'option est activÃƒÂ©e sur `FenetreNord2` et `FenetreDroit`. Les autres conservent leur lumiÃƒÂ¨re froide. Cela suggÃƒÂ¨re des flammes ÃƒÂ  l'extÃƒÂ©rieur sans ajouter un systÃƒÂ¨me d'incendie.

`traces_ecoulement.tscn` ajoute quatre coulures sous les fenÃƒÂªtres. Le shader `assets/shaders/decors/traces_ecoulement.gdshader` dessine six traces verticales de longueurs diffÃƒÂ©rentes, avec une faible opacitÃƒÂ©. Ce sont des surfaces dÃƒÂ©coratives ; le matÃƒÂ©riau des murs conserve son relief et ses dÃƒÂ©gÃƒÂ¢ts existants.

Les textures de bÃƒÂ©ton, bois carbonisÃƒÂ© et peinture dÃƒÂ©jÃƒÂ  prÃƒÂ©sentes sont rÃƒÂ©utilisÃƒÂ©es. Les modÃƒÂ¨les tÃƒÂ©lÃƒÂ©chargÃƒÂ©s de fenÃƒÂªtres, gravats, appliques et camion restent ceux dont les crÃƒÂ©dits sont conservÃƒÂ©s avec les assets. Aucun nouveau modÃƒÂ¨le externe n'a ÃƒÂ©tÃƒÂ© intÃƒÂ©grÃƒÂ© dans cette passe.

## VÃƒÂ©rifications

Chargement des scÃƒÂ¨nes et shaders, accÃƒÂ¨s aux quatre piÃƒÂ¨ces depuis le hall sur les deux cartes de navigation, contournement du camion et des piliers, proximitÃƒÂ© de chaque point d'apparition avec son navmesh, et absence de collision du dÃƒÂ©cor sur les emplacements de spawn. Le rendu a ÃƒÂ©tÃƒÂ© inspectÃƒÂ© dans Godot. La capture du catalogue des maps a ÃƒÂ©tÃƒÂ© actualisÃƒÂ©e pour reprÃƒÂ©senter le nouvel ÃƒÂ©tage.


## Mobilier importÃ© des archives et du local technique

`scenes/decors/hall_incendie/mobilier_pieces.tscn` regroupe les placements dans deux nÅ“uds, Archives et Technique. Cette scÃ¨ne est instanciÃ©e dans Hall sous `Navigation/Decor/MobilierPieces`.

Les scÃ¨nes rÃ©utilisables sont dans `scenes/decors/hall_incendie/mobilier/` : Ã©tagÃ¨re de 2,2 m, ensemble de classeurs de 1,4 m, cartons de 85 cm et tableau Ã©lectrique de 1,5 m fixÃ© en hauteur. Chaque scÃ¨ne contient le modÃ¨le et une boÃ®te de collision simple. Les personnages contournent ainsi le mobilier lors du calcul des deux navigations. Les meubles restent prÃ¨s des murs pour dÃ©gager les passages ; la carte conserve ses dimensions.

Les GLB et leurs crÃ©dits se trouvent dans `assets/modeles/decors/hall_incendie/mobilier/`. Leur Ã©chelle est uniforme et les textures originales sont conservÃ©es, avec une rÃ©solution maximale de 2K. `cartons_noircis.gd` assombrit les cartons avec une teinte rÃ©glable dans l'inspecteur et copie leurs matÃ©riaux pour prÃ©server l'import d'origine. Ce dÃ©cor ne produit ni feu ni dÃ©gÃ¢ts.

Pour dÃ©placer les objets, ouvrir `mobilier_pieces.tscn`. Pour ajuster les collisions ou la teinte des cartons, ouvrir leur scÃ¨ne individuelle. Les chemins vers les quatre piÃ¨ces et les 44 points d'apparition ont Ã©tÃ© contrÃ´lÃ©s avec le mobilier installÃ©. La capture de sÃ©lection de Hall a Ã©tÃ© actualisÃ©e.


## Foyers d'incendie décoratifs

Cinq instances de `foyer_incendie.tscn` animent Hall : étagère et cartons des archives, tableau électrique et cartons du local technique, gravats de la salle de repos. Quatre sont regroupées dans `mobilier_pieces.tscn` ; la dernière est directement sous `Navigation/Decor` de Hall.

La scène réutilise la texture Kenney `flame_01.png` et le shader existant `fumee_hall.gdshader`. Trois CPUParticles3D produisent des flammes courtes, de la fumée ascendante et de petites braises. Chaque rampe de couleur fait apparaître puis disparaître les particules progressivement. `preprocess` remplit l'effet avant la première image pour éviter de voir le feu démarrer à vide.

`foyer_incendie.gd` module doucement l'énergie d'une OmniLight3D orange avec deux sinusoïdes. Le décalage initial dépend de la position pour éviter que tous les foyers vacillent simultanément. La lumière projette des ombres : les murs et meubles limitent son éclairage. L'émission du matériau rend les flammes brillantes ; c'est l'OmniLight3D qui éclaire réellement l'environnement.

Dans l'inspecteur d'une instance, régler **Taille**, **Energie** et **Portee lumiere**. La taille modifie les trois effets de particules ; la portée de lumière reste indépendante. Le script fonctionne aussi dans l'éditeur grâce à `@tool`. Pour créer un autre foyer, instancier la scène sur un objet et ajuster ces trois valeurs. Ces foyers n'ont ni collision, ni groupe d'ennemis, ni dégâts ; ils restent purement décoratifs.
