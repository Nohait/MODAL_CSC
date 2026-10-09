# Habillage procédural du mode classique

Le premier étage utilise `sol_appartements.tres` et `mur_appartements.tres`. Les textures téléchargées sont conservées, mais sans la couche de suie uniforme. Le parquet possède désormais sa texture de normales et une rugosité de 0,48 : il reste satiné, plutôt que de devenir un miroir.

Dans `main.tscn`, sélectionner `Salles/RoomGenerator`, puis ouvrir **Habillage** dans l'Inspector. Cette ressource expose les quantités de fenêtres, appliques, meubles incendiés, tuyauteries, l'intensité des lumières, des reflets et des traces de suie. Les nombres sont des maxima : une petite salle peut proposer moins de murs utilisables.

`room_generator.gd` construit d'abord les sols, les murs, les portes et les caisses. Il mémorise les murs pleins dans `bords_habillage`, puis appelle `habillage_salle.gd` avant de préparer les points de spawn. Les murs des portes et les barrières invisibles autour des trous sont exclus de l'habillage.

`habillage_salle.gd` utilise un générateur aléatoire indépendant, initialisé à partir de la grille et de l'étage. Ses variations n'utilisent pas les tirages du combat. Un même parcours sauvegardé retrouve donc les mêmes placements. Les détails appartiennent à chaque salle et suivent son activation et sa désactivation habituelles.

Au premier étage, les murs reçoivent des fenêtres décoratives avec un fond sombre, des appliques, des canalisations et quelques meubles en feu. Ces fenêtres ne découpent pas le mur solide : leur fond simule un renfoncement. Les meubles se placent contre le mur, avec leurs collisions existantes, sous `Navigation/Decor`, afin de participer au calcul des chemins. Leur cellule ne sert plus au spawn des personnages. Les cellules réservées à l'arrivée ne reçoivent aucun meuble.

La suie est limitée aux environs des meubles incendiés : un plan au sol et un autre au mur, avec des bords irréguliers et une opacité réglable. Les foyers sont décoratifs, sans dégâts. Une sonde de réflexion par salle du premier étage capture le décor une fois lorsqu'il devient visible ; elle ne recapture pas chaque image et n'ajoute aucune lumière ambiante. Les lumières locales restent peu nombreuses et sans ombres supplémentaires.

Les fissures téléchargées utilisent leurs scènes `scenes/decors/decals/fissure_*.tscn`, avec relief, tailles et orientations variables. Par défaut : une au sol au premier étage, cinq au deuxième, sept au troisième. Aux étages supérieurs, une partie se place aux murs. Elles n'ont aucune collision. Les blocs générés reçoivent la couche visuelle 20, ciblée par ces decals ; cette couche ne change pas les collisions ni la navigation. Les decals nécessitent Forward+ ou Mobile.

Les étages 2 et 3 utilisent la même logique de placement avec deux ressources supplémentaires : `ambiance_etage_2.tres` et `ambiance_etage_3.tres`. Depuis **RoomGenerator > Habillage > Ambiances des étages supérieurs**, ouvrir le profil voulu pour régler ses quantités, sa couleur d'appliques, ses foyers, sa suie et ses reflets. Leur structure est définie dans `ambiance_etage.gd`. Les meubles incendiés peuvent être choisis dans une liste de petites scènes avec collision, adaptées à un emplacement contre le mur.

L'étage 2 garde ses textures PBR de brique, avec des fenêtres donnant sur l'incendie, des appliques orange, jusqu'à trois meubles incendiés et trois tas de gravats. L'étage 3 garde ses textures PBR de béton, avec des appliques froides, davantage de canalisations, deux armoires électriques et leurs voyants verts. Une applique par salle vacille légèrement, comme au premier étage.

Ces quatre matériaux d'étage ont perdu leur couche de suie uniforme. Les normales et les textures de rugosité sont conservées ; les sols ont une rugosité réduite pour accrocher les lumières sans devenir des miroirs. De petites zones humides, placées sous certaines appliques et juste au-dessus du sol situé à Y = 0,1, ajoutent des reflets plus marqués. Les armoires sont intégrées à `Navigation/Decor`, et leurs cellules exclues du spawn. Les petits gravats ne reprennent que le modèle visuel : sans collision, hors de la navigation, ils restent traversables. Les cartons et les gros meubles conservent leurs collisions. L'habillage des étages supérieurs garde au moins douze cellules disponibles.

Chaque étage possède désormais une sonde de réflexion statique par salle. L'éclairage général appartient à `main.tscn` : les maps zombie et l'éclairage du Parking restent indépendants.

Le mobilier du premier étage peut désormais être composé de trois variantes de coin salon, importées avec leurs textures PBR 1K. Le tableau **Ensembles appartements** de la ressource d'habillage permet de choisir les scènes utilisées. Voir [salons_appartements.md](salons_appartements.md) pour leur structure, leurs collisions et les réglages de brûlure. Le nombre de meubles en feu devient le nombre maximal d'ensembles, avec deux variantes différentes par salle lorsque la place le permet.

