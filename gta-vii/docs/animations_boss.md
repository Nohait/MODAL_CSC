# Animations du monstre de lave

Le boss possède le coup au sol, la salve et une première attaque d'invocation. `monstre_lave.tscn` utilise `assets/modeles/ennemis/mini_boss/monstre_lave_anime.glb`, avec son squelette et sept clips : attente (Orc Idle), marche (Orc Walk), coup_sol (mutant jump attack, avec élan, saut et réception) salve (Standing 2H Magic Attack 03), invocation (Standing 2H Magic Area Attack 02, deuxième téléchargement) , colere (mutant roaring) et mort (mutant dying).

`monstre_lave.gd` décide des attaques et applique les dégâts. Les anciens tweens qui inclinaient et écrasaient tout le modèle ont été retirés du boss. Les tweens du disque et de l'orbe restent actifs.

`animations_boss.gd`, attaché au nœud AnimationsBoss, lit l'état du combat. Il étale les portions du clip sur les durées de préparation, frappe et récupération. Les secondes repères (début de descente, impact, projection) et le fondu des postures sont exportés sur ce nœud. Gel et pause suspendent l'animation. Pendant la salve, l'orbe et le départ des projectiles suivent le milieu des mains.

Le coup_sol reprend les images 1 à 91 du clip d'origine : l'élan et le saut précèdent la réception. AnimationsBoss fait monter uniquement le visuel, avec une collision stable au sol, selon une courbe arrondie réglable dans l'Inspector (hauteur, décollage, sommet). L'agent de navigation reste au sol et aucun déplacement horizontal du clip n'est ajouté. La hauteur revient à zéro exactement à l'instant de l'impact. La marche reste pilotée par le NavigationAgent du boss, pas par les déplacements enregistrés dans les clips.

`tools/importer_animations_boss.py` permet de refaire le transfert avec Blender en arrière-plan. Il lit Creature Pack.zip, Orc Idle.fbx, Orc Walk.fbx, Standing 2H Magic Attack 03.fbx et Standing 2H Magic Area Attack 02 (1).fbx dans Téléchargements. Les correspondances anatomiques corrigent notamment les noms inversés des trois vertèbres du monstre. Les rotations sont converties entre les repères des deux squelettes, la pose importée est conservée et la hauteur est corrigée pour poser le modèle au sol. Les pistes sont calculées à l'import : aucun transfert de squelette n'est effectué pendant le jeu.

Test rapide : menu de debug → apparition d'ennemis → Monstre de lave. S'éloigner pour la salve, puis s'approcher pour le coup au sol.
Le saut avance désormais le CharacterBody3D de `avance_saut` (0,9 m par défaut). La direction est fixée au début de la préparation ; `test_move` raccourcit le trajet si un obstacle le bloque, puis `move_and_collide` réalise l'avancée. Le déplacement est réparti sur le vol avec une interpolation douce.

AnimationsBoss mesure le milieu des mains à l'instant d'impact du clip. Room/boss utilise ce décalage pour fixer `centre_impact` à la future réception. L'annonce et la distance de dégâts utilisent ce même centre ; `decalage_impact` permet une correction manuelle (0 par défaut). Le rayon reste `rayon_impact`.

`assets/shaders/effets/annonce_impact_boss.gdshader` dessine un contour exact, des braises irrégulières à l'intérieur, un remplissage léger et un cercle qui converge pendant la préparation. La couleur est exportée sur le boss. Le matériau est propre à chaque boss et disparaît après l'impact.

À chaque attaque, un rayon vertical cherche le sol sous le futur impact. `hauteur_annonce_sol` place le cercle légèrement au-dessus de cette surface, même si la hauteur du boss varie. L'ancien fondu est annulé avant de réafficher le cercle. Sa charge suit les temps du combat ; les contours du shader sont lissés selon la taille des pixels à l'écran.

## Sons du boss

`sons_boss.gd`, sur le nœud SonsBoss, réutilise les impacts et sorts de feu déjà présents dans le projet. Quatre lecteurs AudioStreamPlayer3D jouent les pas, la réception, la charge et les projections sur le bus Effets. Sons, volumes, portée et tonalités sont exportés. Les impacts de poing ralentis servent aux pas lourds. La réception utilise Deep Cinematic Impact de MeijstroAudio, à sa tonalité originale ; chaque projectile utilise Fireball de Julien Matthey. Les fichiers et leurs crédits sont dans `assets/sounds/ennemis/monstre_lave`.

AnimationsBoss émet `pas_pose` lorsque la marche franchit les instants de contact réglables (0,2 et 0,8 s). Le combat émet `impact_sol` au moment des dégâts, `charge_salve` à la préparation, `boule_projetee` pour chaque projectile et `salve_terminee` pour arrêter la charge. Les tirs utilisent jusqu'à quatre voix simultanées avec un volume réduit. Un générateur aléatoire propre aux sons varie légèrement leur tonalité sans modifier les tirages du gameplay.

## Mort du mini-boss

Le signal de mort et les récompenses sont déclenchés immédiatement par le fonctionnement existant. Avant cela, `monstre_lave.gd` transfère son modèle vers `mort_boss.tscn`, un effet voisin sans collision ni comportement d'ennemi. `mort_boss.gd` joue le clip Mixamo mort, refroidit des copies des matériaux, déclenche le choc de réception, puis utilise le shader de cendres sur les vrais maillages animés. Le squelette reste en place, ce qui conserve la pose couchée pendant la dissolution. La pause suspend l'animation et les tweens.

Durée de chute, fraction du clip où le choc arrive, attente au sol, dissolution, volume et secousse se règlent sur la racine de `mort_boss.tscn`. Modifier le choc permet d'affiner sa synchronisation avec le clip. Aucun ennemi ne reste actif pendant la séquence ; les projectiles déjà tirés conservent leur fonctionnement habituel.

L’effet de mort cherche le sol avec un rayon et recale son pivot à `hauteur_pivot_modele` (1,35 m au-dessus du sol pour ce modèle). `delai_apres_salve` sur le boss impose 3 s avant une nouvelle salve, sans bloquer la poursuite ni le coup au sol ; `repos_salve` reste la courte récupération immobile.

La collision ne monte plus avec le visuel du saut : sa descente pouvait chevaucher le joueur et laisser le CharacterBody repoussé en hauteur. Le trajet du saut reste horizontal, et un rayon vers le décor recale la hauteur du corps au sol. `hauteur_corps_au_sol` correspond au pivot du modèle (1,35 m).

À l’import de la mort, le contact passe progressivement des pieds à la partie basse du corps (5e percentile des hauteurs des sommets). Le minimum absolu était trompeur : une extrémité touchait le sol alors que le corps couché restait presque un mètre plus haut. Cette correction est calculée dans Blender et enregistrée dans le clip, sans recalcul des sommets pendant le jeu. Les autres animations gardent leur placement initial.

## Jauge du boss

`barre_boss.tscn` présente le nom et une rainure de métal incandescent en haut de l’écran. `barre_boss.gdshader` dessine un remplissage rouge avec des fissures orangées dont la chaleur varie doucement. Intensité, vitesse, présentation et retard des dégâts se règlent sur la racine de la scène.

`degats_subis` actualise les PV, puis une jauge orangée rejoint leur valeur avec retard. Pendant la présentation, `barre_boss.gd` masque les informations de combat inscrites dans le groupe `informations_combat`. Le timer et les compteurs continuent de fonctionner. Après le fondu de fermeture, l’opacité est restaurée ; la visibilité du HUD reste inchangée pour respecter l’écran de mort. Plusieurs boss de debug sont pris en compte sans réafficher l’encart trop tôt. Vie, mousse et monnaies restent affichées.

## Invocation — premier prototype

Dans `monstre_lave.tscn`, le nœud `InvocationBoss` porte `invocation_boss.gd`. Par défaut, la première invocation devient possible après 6 s, puis 12 s après la précédente. Le boss attend la fin de son attaque en cours, prépare le geste pendant 2,2 s, invoque jusqu’à 3 sbires et récupère pendant 0,8 s. Au maximum 6 sbires invoqués par ce boss peuvent rester vivants. Tous ces réglages sont exportés sur ce nœud.

Le composant cherche jusqu’à 24 emplacements autour du boss, contrôle le sol, la navigation des ennemis et la vraie collision du sbire, puis annonce les emplacements par des disques orangés. Au moment de l’invocation, il recontrôle les collisions : un emplacement occupé est abandonné. Les cercles n’infligent aucun dégât. Une mort pendant la préparation retire les annonces avec le boss et ne crée aucun ennemi.

`animations_boss.gd` étale les premiers 75 % du clip sur la préparation et le reste sur la récupération. Pause et gel arrêtent aussi la préparation et le délai entre invocations. Le clip est transféré au squelette du monstre dans Blender par `tools/importer_animations_boss.py`, comme les autres gestes.

Le signal `invocation_demandee` transmet les positions au RoomManager. `relier_invocation` branche ce signal lors de l’apparition naturelle du boss zombie ou de son ajout par le debug dans les deux modes. `_invoquer_ennemis` compte les nouveaux ennemis et réutilise `creer_sbire` : l’aggro propre au mode et la navigation restent celles du système existant. Les invocations survivantes empêchent la fin du combat même si le boss meurt. Leurs métadonnées identifient leur invocateur pour calculer le plafond, sans les confondre avec les autres sbires.

## Apparition des sbires

Le cercle orangé est mutualisé dans `scenes/effets/apparition/cercle_apparition.tscn`. Les annonces du mode classique et les invocations du boss utilisent ce même composant, avec un matériau indépendant par cercle. Le placement cherche la surface du sol par rayon pour tenir compte de son épaisseur.

`apparition_sbire.tscn` est ajouté au sbire par `creer_sbire`. Son script applique temporairement le shader `apparition_sbire.gdshader` au corps : une frontière irrégulière incandescente monte de sa partie basse à sa partie haute. Les flammes des mains grandissent et 18 petites braises montent du cercle. Après 0,55 s, les matériaux d’origine sont restaurés et le sbire reprend son comportement. Collision, PV et comptage des ennemis restent actifs pendant la formation. Durée et nombre de braises se règlent sur cette scène.

Une mort pendant la formation annule le tween et restaure les matériaux avant l’effet de cendres. Le calendrier des apparitions n’est pas décalé. Les sbires qui sortent normalement des portes du mode zombie conservent leur arrivée existante ; la nouvelle formation concerne les apparitions classiques et les sbires créés par l’invocation ou le debug.

## Colère à mi-vie

`PhaseBoss`, dans `monstre_lave.tscn`, porte `phase_boss.gd`. Entre deux attaques, le boss vérifie s’il lui reste au maximum 50 % de ses PV. Il joue alors une seule fois le clip `colere` (mutant roaring du Creature Pack), avec un cri existant, une lueur orangée plus intense et une légère secousse. La transition dure 2,2 s. Un coup au sol ou une salve en cours se termine avant cette transition ; le gel et la pause suspendent le geste et ses annonces. Le titre de la jauge ajoute ENRAGÉ, sans nouveau panneau.

La transition annonce jusqu’à 6 sbires et 4 kamikazes. Ils apparaissent à la fin du geste, puis le boss récupère. Les invocations suivantes demandent 3 sbires et 2 kamikazes, avec 9 s de délai au lieu de 12. Le plafond est de 12 invocations vivantes de ce boss, toutes espèces confondues. Les ennemis déjà présents occupent des places dans ce plafond ; des obstacles peuvent réduire le groupe. Les nouveaux groupes n’excèdent jamais la place restante.

Les délais entre coups au sol et salves sont multipliés par 0,85 en phase deux. Les annonces, dégâts et récupérations restent inchangés. Seuil, durée, multiplicateur, son, volume, portée du cri, lueur et secousse se règlent sur PhaseBoss. Effectifs et plafonds se règlent sur InvocationBoss.

Le signal d’invocation transmet désormais pour chaque demande une position, une scène et une hauteur d’apparition. Le RoomManager garde l’aggro du sbire adaptée au mode et crée les kamikazes avec leur comportement normal. Le même effet `apparition_sbire.tscn` accepte maintenant les deux modèles : le droplet n’est traité que s’il est un maillage, et les flammes du corps des kamikazes sont animées comme les flammes des mains du sbire. Les arrivées naturelles habituelles du kamikaze ne sont pas modifiées.

Le cri de colère reste spatial, mais son atténuation de volume est désactivée et sa portée vaut 0 : aucune coupure selon la distance. Il est ainsi audible dans toute la salle ; ces réglages sont exportés sur PhaseBoss.

## Fissure de feu

`FissureBoss`, dans `monstre_lave.tscn`, porte `fissure_boss.gd`. À distance, le boss alterne cette attaque avec les salves, selon les délais disponibles. Au corps à corps, il conserve son coup circulaire. La fissure réutilise le clip de frappe au sol, sans avancée du corps ; elle remplace les dégâts circulaires pour cette attaque.

La direction est fixée au début du geste. Le composant cherche des surfaces sous une ligne de segments et arrête le trajet devant le décor ou un vide. Les plans se placent au-dessus de la surface réelle, épaisseur du sol comprise. Le shader `assets/shaders/effets/fissure_boss.gdshader` dessine des veines sinueuses orangées. Après l'impact, chaque segment charge pendant 0,55 s, puis les flammes existantes jaillissent ; le décalage entre segments dépend de la vitesse de progression. Aucun ennemi supplémentaire n'est créé.

Pendant l'éruption, les positions du joueur et des victimes sont testées dans le repère de la fissure. Chaque personnage reçoit au maximum un coup par attaque. Le feu dure 0,65 s par segment, puis disparaît. Le trajet reste fixe si le boss tourne ensuite ; les effets sont supprimés quand l'attaque se termine ou quand le boss meurt. Gel et pause suspendent sa progression.

Réglages sur FissureBoss : activation, portée (14 m), largeur (2,2 m), vitesse (7 m/s), avertissement, durée du feu, dégâts (24 avant difficulté par étage), délai (8 s) et longueur des segments. Les valeurs sont propres à cette attaque et ne changent pas les flammes utilisées ailleurs.

Le matériau utilise désormais Lava003 d'ambientCG, dans `assets/textures/effets/fissure_lave` : couleur de la roche, normales OpenGL pour le relief, rugosité et émission des veines de lave. Les coordonnées de texture se poursuivent d'un segment à l'autre. Un masque irrégulier découpe ses bords. L'intensité de la lave et le relief sont exportés. Chaque éruption émet 12 petites braises ascendantes qui rétrécissent ; leur nombre est réglable et elles sont supprimées avec la portion de faille.
