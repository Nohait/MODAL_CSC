# Progression et polish du mode zombie

## PortÃ©e

Le signal de dash et son habillage appartiennent au joueur commun. Le format de carte, les incompatibilitÃ©s, le moteur de synergies et les dÃ©finitions de succÃ¨s sont rÃ©utilisables. Le mode zombie active seul les nouvelles cartes, les deux synergies, le score, les paliers du Hall et la musique en couches. Le classique conserve ses Ã©lites Ã  une mutation et ses cartes habituelles.

## Dash

Ouvrir `scenes/joueur/player.tscn`, sÃ©lectionner `FeedbackDash`. Son script Ã©coute `dash_commence`, Ã©mis lorsque le joueur dÃ©clenche rÃ©ellement son dash. Il produit deux petits rubans et une gerbe de particules, puis un souffle rÃ©utilisant `swish-3.wav`. La camÃ©ra orthographique change lÃ©gÃ¨rement de `size` et revient Ã  sa taille initiale. Aucun changement de vitesse, distance, collision ou invincibilitÃ©.

Les rubans ne dupliquent pas le squelette animÃ©. Leur nombre est plafonnÃ© et chaque matÃ©riau est propre Ã  une trace, pour que son fondu ne modifie pas les suivantes. Les effets sont enfants du joueur, mais leurs positions restent dans le monde grÃ¢ce Ã  `top_level`. Ils sont supprimÃ©s automatiquement. La taille de camÃ©ra est Ã©galement restaurÃ©e si le joueur disparaÃ®t.

## Mutations

`scenes/systemes/ennemis/equilibrage_elites.tres` expose la chance initiale d'une Ã©lite, son augmentation avec la progression et son plafond. Un ennemi possÃ¨de au maximum une mutation, dans les deux modes.

`elite_ennemi.gd` conserve cette mutation dans `definition`. Elle dÃ©termine les statistiques, la couleur, le symbole et l'aura Ã©ventuelle. Les auras reÃ§ues de voisins restent des effets de proximitÃ©, pas des mutations supplÃ©mentaires. Le butin des Ã©lites reste Ã—2.

Mutation gÃ©nÃ©rale remplace temporairement la mutation d'origine, puis la restaure Ã  la fin de la vague ou Ã  l'expiration de l'effet. Les sources d'aura sont filtrÃ©es avant de parcourir les ennemis.

Les mutations sauvegardÃ©es utilisent les identifiants numÃ©riques des ennemis. `tree_exiting` retire leur entrÃ©e avant leur destruction : conserver les ennemis eux-mÃªmes comme clÃ©s provoquait un blocage lors du nettoyage aprÃ¨s plusieurs Ã©liminations instantanÃ©es. Les survivants retrouvent toujours leur mutation d'origine.

## Sons et musique

Ouvrir `scenes/modes/zombie/audio/feedback_vagues.tscn` pour rÃ©gler les sons et le volume : dÃ©but, fin, boss et apparition d'une Ã©lite multiple. Un dÃ©lai limite les sons d'Ã©lites dans une mÃªme arrivÃ©e. Les vagues spÃ©ciales conservent leur annonce existante. Le son de succÃ¨s est commun, rÃ©glÃ© dans `sons_interface.gd`.

Les sons rÃ©utilisent les fichiers dÃ©jÃ  prÃ©sents et crÃ©ditÃ©s dans le projet. Ce sont des choix de prototype Ã  Ã©couter et ajuster, pas de nouveaux tÃ©lÃ©chargements.

Dans `mode_zombie.tscn`, `Couches musicales` reÃ§oit des Resources `CoucheMusicaleZombie`. Chaque couche indique son fichier, son volume, le seuil d'ennemis vivants, sa vague minimale et Ã©ventuellement la nÃ©cessitÃ© d'une Ã©lite ou d'un boss. `couches_dynamiques.gd` utilise **AudioStreamSynchronized** : tous les stems commencent au mÃªme instant et continuent mÃªme lorsque leur volume est inaudible. Seuls les volumes changent. La boutique conserve sa musique et les couches se retirent progressivement.

Utiliser des stems du mÃªme morceau, de mÃªme durÃ©e et prÃ©parÃ©s pour boucler. Ne pas superposer les morceaux complets actuels. Tant que la liste est vide, le comportement musical actuel est conservÃ©. Le premier pack proposÃ© n'a pas Ã©tÃ© retenu. Une alternative Ã  Ã©couter est Web Crawler de deadrobotmusic : https://freesound.org/people/deadrobotmusic/packs/34406/ â€” morceau drum and bass, stems sÃ©parÃ©s, annoncÃ© CC0 par son auteur. L'intÃ©gration sonore finale attend le choix, les fichiers et leur validation.

## Cartes et branches

Les nouvelles cartes sont dans `scenes/systemes/ameliorations/cartes/`. Leur drapeau `Modes = Zombie` empÃªche leur prÃ©sence en classique. Elles sont Ã  effet fixe et Ã  obtention unique. Le catalogue commun contient aussi les cartes de synergie, mais elles sont inactives pour les tirages.

`branches_zombie.gd` contient les nouvelles interactions. Il est ajoutÃ© au joueur uniquement en zombie. Les effets communs appellent ce composant lorsqu'il existe : aucun joueur ni extincteur n'est dupliquÃ©.

Les valeurs sont rÃ©glables sur chaque `.tres` : valeur, contrepartie, rayon, durÃ©e et intervalle. Le texte d'effet peut utiliser `{valeur}`, `{contrepartie}`, `{duree}` et `{intervalle}` pour suivre l'Ã©quilibrage. Le format existant `%s` reste acceptÃ©. Les incompatibilitÃ©s sont vÃ©rifiÃ©es dans les deux sens et s'appliquent Ã©galement au catalogue de debug.

Le gestionnaire commun expose `Maximum zones mousse` (40 par dÃ©faut). Les chaÃ®nes d'explosions remplacent les plaques les plus anciennes au-delÃ  du plafond, pour contenir le coÃ»t des zones et des particules. Ce garde-fou concerne les deux modes.

## Synergies

Dans `mode_zombie.tscn`, `Synergies zombie` contient les Resources de `scenes/systemes/ameliorations/synergies/`. Une Resource dÃ©crit son identifiant, les identifiants des ingrÃ©dients, les modes autorisÃ©s et la carte rÃ©sultante. Deux ingrÃ©dients ou davantage sont possibles. Une carte peut appartenir Ã  plusieurs recettes.

`synergy_manager.gd` ne connaÃ®t ni le joueur ni l'interface. Il vÃ©rifie les acquisitions, mÃ©morise la dÃ©couverte avant d'Ã©mettre `synergie_decouverte`, puis place la recette dans une file. L'UpgradeManager applique la carte spÃ©ciale et attend la prÃ©sentation aprÃ¨s la sÃ©lection. Les ingrÃ©dients ne sont pas consommÃ©s. Plusieurs recettes dÃ©couvertes en mÃªme temps sont prÃ©sentÃ©es successivement.

`fusion_synergie.tscn/.gd` affiche les ingrÃ©dients, les rapproche simultanÃ©ment avec un Tween parallÃ¨le, dÃ©clenche le flash et les braises, puis rÃ©vÃ¨le la nouvelle carte. Le bouton Continuer laisse le temps de lire avant de revenir Ã  la boutique. La pause dÃ©jÃ  dÃ©tenue par la boutique est conservÃ©e. La raretÃ© turquoise **Synergie** utilise le niveau visuel supÃ©rieur Ã  LÃ©gendaire, sans entrer dans les probabilitÃ©s des boosters. Modifier l'animation ne change pas la dÃ©tection.

Pour ajouter une recette : crÃ©er sa carte avec `rarete = synergie`, `active = false`, la rÃ©fÃ©rencer dans le catalogue des cartes, puis ajouter sa Resource Synergie Ã  la liste du mode. Un effet inÃ©dit nÃ©cessite Ã©videmment son comportement de gameplay ; une recette seule ne crÃ©e pas du code automatiquement.

## ArÃ¨ne et score

Les paliers de `scenes/modes/zombie/evenements/paliers/` sont rÃ©glables dans `mode_zombie.tscn`. Ils peuvent activer une entrÃ©e ou allumer/Ã©teindre un nÅ“ud de lumiÃ¨re, avec une vague minimale, une probabilitÃ© et un dÃ©clenchement unique ou rÃ©pÃ©table. Ils ciblent des NodePath de la map. Le gestionnaire Ã©met un signal ; le mode le relie au message discret existant.

Le Hall ouvre l'ascenseur Ã  5, une seconde fenÃªtre Ã  6 et Ã©teint les archives Ã  12. Il s'agit d'une Ã©volution des entrÃ©es et de la visibilitÃ©, sans nouvelles piÃ¨ces ni modification de navmesh. Les deux entrÃ©es diffÃ©rÃ©es sont prÃ©sentes visuellement dÃ¨s le dÃ©but, mais ne participent pas aux spawns avant leur palier.

`score_combo_manager.tscn` expose les points par Ã©limination, la durÃ©e de chaÃ®ne, les Ã©liminations par palier, le plafond et le seuil sonore. Une Ã©limination prolonge la chaÃ®ne ; perdre de la vie, attendre trop longtemps ou finir une vague la casse. Le score ne donne aucune monnaie. Les flaques n'alimentent pas la chaÃ®ne. L'affichage reste petit, sous le HUD gauche.

## SuccÃ¨s

Les six nouvelles Resources sont dans `scenes/systemes/succes/definitions/`. `scenes/modes/zombie/gestion/succes_zombie.gd` observe uniquement cette partie et transmet les progrÃ¨s au gestionnaire commun. Les objectifs sont : vague 10, 100 ennemis, 10 Ã©lites, un boss, trois vagues consÃ©cutives sans perte de vie et une synergie.

Les succÃ¨s conservent leur sauvegarde `user://succes.cfg`, leurs notifications et leur Ã©cran existants. Les compteurs de ces objectifs repartent Ã  zÃ©ro Ã  chaque partie ; les succÃ¨s dÃ©jÃ  obtenus restent acquis aprÃ¨s fermeture du jeu. Le catalogue affiche les nouvelles entrÃ©es sans changer les conditions de victoire des deux succÃ¨s initiaux.

## VÃ©rification

ContrÃ´les effectuÃ©s : import et compilation Godot ; chargement des deux modes ; retour de camÃ©ra et suppression des traces ; mutation unique et restauration ; acquisition unique d'une synergie ; exclusivitÃ©s ; paliers ; Ã©cran de fusion avec Forward+ et fermeture. Les tests utilisent une sauvegarde de succÃ¨s sÃ©parÃ©e pour ne pas modifier les succÃ¨s du joueur.

Les rÃ©glages de sons, les probabilitÃ©s et la puissance des nouvelles cartes restent des valeurs initiales Ã  Ã©quilibrer par des parties. La musique en stems reste en attente de l'asset. Les paliers sont une premiÃ¨re implÃ©mentation, pas encore un systÃ¨me de piÃ¨ces destructibles ou de reconstruction de navigation.

## Musique adaptative et traînée du dash

Le pack Assault (Luca Baradel) fournit quatre stems alignés, de 115,2 secondes à 100 BPM. `audio/couches_dynamiques.gd` les lance dans un seul AudioStreamSynchronized ; les volumes changent à chaque image, les conditions sont réévaluées toutes les 0,3 seconde. Les pistes restent en lecture silencieuse dans la boutique pour préserver la synchronisation et la progression. La musique de boutique conserve son gestionnaire existant.

Les Resources `audio/couches/*.tres`, référencées dans l’Inspector du ModeZombie, exposent les volumes et seuils : synthétiseurs toujours en combat, cordes à 4 ennemis, percussions à 7, guitares à la vague 8 ou en présence d’une élite. Un boss active toutes les couches. Aucun changement de musique dans le classique.

Le dash partagé utilise désormais GPUTrail (MIT, celyk), dans `addons/GPUTrail`. `scenes/joueur/feedback_dash.gd` pilote un unique ruban GPU, réinitialisé au départ et masqué après résorption. Largeur, hauteur et durée sont exportées. L’attente du rendu de l’addon est évitée sans billboard, notamment pour les tests headless.

## Feedback de survie partagé

`scenes/joueur/feedback_survie.gd` est attaché au nœud FeedbackSurvie du joueur commun. Il écoute les pertes réelles de PV et reçoit les impacts absorbés depuis RetoursBonus. Deux lecteurs distincts et un intervalle minimal limitent les répétitions sans confondre vie et bouclier. Les sons utilisent les assets déjà disponibles.

Une pulsation des bords apparaît sous 25 % de vie, indépendamment des améliorations. La pulsation de Dernier souffle sur le cadre reste propre à cette carte. Les sons, volumes, seuil, intensité, cycle et durées de mort sont exportés dans l’Inspector.

À la mort, le joueur coupe sa physique et son attaque mais reste visible. Main met le combat en pause, attend la réaction et le fondu de FeedbackSurvie (Tween autorisé en pause), puis appelle afficher_ecran_mort. La spécialisation zombie conserve son bilan. Le changement de scène détruit ensuite le joueur et les effets.
