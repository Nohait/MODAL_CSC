# Créer et équilibrer des cartes

Les cartes sont des ressources Godot. Le catalogue commun est dans `scenes/systemes/ameliorations/catalogue_ameliorations.tres`. Les quinze définitions se trouvent dans son dossier `cartes`. La boutique, le menu des bonus et le catalogue debug lisent ces mêmes données.

## Modifier une carte dans Godot

Ouvrir sa ressource .tres dans l’Inspecteur. Les propriétés sont :

- Identifiant : nom stable et unique utilisé pour reconnaître une acquisition.
- Titre, Description, Pictogramme : contenu graphique de la carte. Les SVG sont dans `assets/textures/interfaces/ameliorations/pictogrammes`.
- Modes : cocher Classique, Zombie ou les deux. Le filtre agit sur les boosters, le bouton debug et l’application des effets.
- Active : décocher pour retirer temporairement la carte des choix.
- Type bonus : permanent ou temporaire, pour choisir son booster et sa colonne du menu des bonus.
- Effet : comportement à appliquer. Les comportements incluent les statistiques, les soins, les boucliers, le gel, le secours, la vitesse d’escorte et la sirène.
- Valeur : puissance de base à 100 %, ou gain exact pour une carte à effet fixe. Les versions communes/rares/épiques des statistiques multiplient cette valeur par 0,5 / 1 / 2. La rareté du booster règle les probabilités, pas directement la puissance.
- Obtention unique : cocher pour limiter la carte à un achat par partie.
- Puissance variable : cocher pour une statistique disponible en trois raretés ; décocher pour conserver une rareté et un gain fixes.
- Rareté : rareté propre à une carte fixe ; ignorée si Puissance variable est coché.
- Durée : zéro pour un soin immédiat ; au moins 1 pour un effet temporaire continu. Les effets permanents ont une durée de zéro.
- Texte effet : `%s` est remplacé par le gain. Écrire `%%` pour afficher le signe pourcentage.

Les prix, puissances des versions et poids de tirage sont dans l’Inspecteur du nœud UpgradeManager. Le mode zombie utilise le même catalogue et fournit automatiquement Mode jeu = zombie.

## Ajouter une carte

1. Dupliquer une ressource existante dans le dossier cartes.
2. Donner un nouvel identifiant et régler son titre, ses modes, son pictogramme, son effet et sa valeur.
3. Ouvrir catalogue_ameliorations.tres et ajouter cette ressource au tableau Cartes.
4. Lancer le mode voulu, ouvrir une boutique et cliquer sur « Debug : toutes les cartes du mode ».

Le bouton debug est présent dans les exécutions de développement, notamment depuis l’éditeur. Il affiche toutes les cartes actives autorisées dans le mode, sans tirage ni paiement. Le clic applique une carte à puissance 100 % et revient à la boutique ; Retour à la boutique permet de sortir sans choisir. Relancer la partie après une modification des ressources pour tester les nouvelles valeurs.

Pour une variation d’un effet existant, aucun nouveau code n’est nécessaire. Pour inventer un nouveau comportement, ajouter son nom dans l’export Effet de amelioration.gd et son traitement dans l’UpgradeManager : `_appliquer_soin` pour une action immédiate, `recalculer_effets` pour un effet durable. Mettre à jour le test correspondant.

## Cartes initiales

| Carte | Modes | Type | Valeur à 100 % |
|---|---|---|---|
| Sous pression | Les deux | Permanent | +20 % de dégâts |
| Grande réserve | Les deux | Permanent | +25 % de charge |
| Second souffle | Les deux | Permanent | +20 % de recharge |
| Solide sur ses appuis | Les deux | Permanent, rare, unique | +20 PV maximum |
| Premiers secours | Les deux | Immédiat, booster Intervention | +30 PV au joueur |
| Prendre soin des autres (escorte) | Classique | Immédiat, booster Intervention | +25 PV par victime qui suit le pompier |
| Prendre soin des autres (camion) | Zombie | Immédiat, booster Intervention | +25 PV par victime abritée |
| Carrosserie renforcée | Zombie | Permanent | −10 % de dégâts aux occupants |
| Protection d’urgence | Zombie | Temporaire, 2 vagues | Bouclier de 60 PV |

Les soins sont plafonnés aux PV maximum et ne ressuscitent personne. Le soin des victimes cible l’escorte en mode classique, les occupants du camion en mode zombie. Augmenter les PV maximum accorde aussi les PV ajoutés.

Le blindage cumule les pourcentages avec une limite de 80 % de réduction, afin de ne pas rendre le camion invulnérable. Au niveau commun, il vaut 5 %, au niveau rare 10 %, au niveau épique 20 %.

## Durée et boucliers

Une carte acquise en boutique attend le début de la prochaine salle ou vague. Le signal salle_commencee la marque comme commencée ; salle_terminee retire ensuite une unité. En mode classique, ce signal est émis au passage de la porte après la libération de la salle. En mode zombie, il est émis à la fin de la vague. À zéro, l’acquisition est retirée et les effets sont recalculés depuis les valeurs de base. Une fermeture de boutique ou une pause ne consomme aucune unité.

Les acquisitions restent indépendantes : acheter un second bouclier ne recharge pas le premier et ne prolonge pas sa durée. Chaque entrée conserve sa réserve restante. Les coups consomment d’abord les boucliers les plus anciens ; le blindage réduit ensuite le reliquat qui atteint la dernière victime sauvée. Les dégâts excédentaires ne passent pas à une autre victime après sa mort.

La barre bleue du camion affiche la somme des réserves de bouclier restantes ; la barre verte reste la vie de la victime attaquable. Les cartes du menu affichent leur réserve restante et, en grand, leur durée. Un bouclier épuisé reste consultable à 0 PV jusqu’à son expiration. Un soin immédiat ne devient pas un bonus actif et n’apparaît donc pas dans ce récapitulatif.

Les bonus permanents et temporaires disposent de deux colonnes avec leur propre défilement. Les pictogrammes conservent leur transparence et leurs proportions ; les fonds et les braises de cartes restent ceux du jeu.

## Six cartes de combat et de protection

| Carte | Modes | Booster | Valeur à puissance 100 % |
|---|---|---|---|
| Jet givré | Les deux | Permanent, épique, unique | −20 % de vitesse pendant 1 seconde après chaque impact |
| Dernier souffle | Les deux | Permanent | +40 % de dégâts à 25 % de vie maximale ou moins |
| Mousse protectrice | Les deux | Intervention | Bouclier de 40 PV pendant la prochaine salle/vague |
| Réserve de secours | Les deux | Permanent | Empêche une mort et rend 30 % de la vie maximale, puis disparaît |
| Escorte agile | Les deux | Permanent | +20 % de vitesse aux victimes qui suivent le joueur |
| Sirène de diversion | Zombie | Permanent | Attire les ennemis à 12 mètres pendant 3 secondes toutes les 10 secondes |

Modifier Valeur dans chaque .tres pour changer la puissance de base. Durée effet règle les secondes du gel ou de la sirène ; Intervalle règle le délai entre les appels ; Seuil vie règle le seuil de Dernier souffle (penser à adapter sa description si on le modifie). Durée reste le nombre de salles/vagues pour Mousse protectrice. Pour les cartes à puissance variable, les versions de rareté font varier la puissance, pas les durées ni le seuil de vie. Les autres cartes gardent leur gain fixe.

Le gel ne touche que les ennemis mobiles : ralentir une tourelle ou une flaque n’aurait pas d’effet. Chaque impact renouvelle la durée. Jet givré ne peut être obtenu qu’une fois et ralentit de 20 %. Le petit nœud Ralentissement du sbire conserve les matériaux avant de poser une teinte bleue ; à l’expiration il les restaure et se supprime. Le jet devient bleu clair.

Dernier souffle lit la vie au moment de calculer les dégâts : un soin qui remonte au-dessus du seuil désactive le bonus immédiatement. Ses gains s’additionnent entre acquisitions et multiplient les dégâts déjà améliorés.

Le bouclier du pompier utilise une couche bleue superposée au remplissage rouge de la vie. Sa largeur vaut les PV de bouclier divisés par les PV maximum : 40 PV couvrent 40 % d’une barre de 100 PV. Le nombre entre parenthèses indique la réserve de protection ; une réserve supérieure aux PV maximum est affichée sur toute la largeur, sans perdre les PV excédentaires. Les réserves sont dépensées de la plus ancienne à la plus récente, sans se recharger lors des recalculs. Seul l’excédent atteint la vie. Il n’empêche pas l’expiration de la carte à la fin de la prochaine étape.

Réserve de secours reste dans les bonus permanents avec « 1 secours disponible » tant qu’elle n’a pas été utilisée. Un coup mortel consomme une acquisition, rend sa proportion de vie et accorde 1 seconde de protection pour éviter une mort immédiate par une salve simultanée. Plusieurs cartes donnent plusieurs secours successifs. La consommation émet ameliorations_changees pour mettre à jour le menu. Ce bonus ne se renouvelle pas à chaque salle.

Escorte agile conserve la vitesse de base de chaque victime et applique un multiplicateur. Le signal escort_changed couvre les futures libérations, les dépôts et les changements dans la file. Les bonus de vitesse s’additionnent.

La sirène ne fonctionne que pendant une vague et attend en pause. Le premier appel arrive après son intervalle. Une onde bleue signale l’appel, sans son pour l’instant. Les sbires et les tourelles proches prennent le camion pour cible, même vide ; les tourelles conservent leur portée de tir. Une attaque déjà en préparation peut finir avant le changement de cible. Après l’appel, la sélection normale reprend ; un camion occupé peut naturellement rester une cible. La fin de vague interrompt l’attraction. Plusieurs acquisitions ne multiplient pas les appels : le plus grand rayon acquis est retenu.

Les effets sont répartis simplement : UpgradeManager lit les ressources, recalcule les bonus et gère les réserves ; l’extincteur applique le gel et calcule Dernier souffle ; le joueur appelle l’absorption avant de retirer ses PV et le secours avant de mourir ; les scripts zombie ajoutent la priorité temporaire du camion sans changer la navigation du jeu classique.

## Retour visuel des bonus

RetoursBonus est une petite scène d’interface ajoutée au joueur par UpgradeManager. Son script se trouve dans scenes/interfaces/hud/retours_bonus.gd : il fait pulser un cadre rouge sur la vie quand Dernier souffle est actif et affiche le nombre de secours disponibles à côté. Le signal ameliorations_changees actualise ce nombre.

Quand un bouclier absorbe un coup, le gestionnaire appelle afficher_impact_bouclier : une enveloppe bleue transparente s’élargit et s’efface autour du pompier. Quand un secours est consommé, afficher_secours joue un léger flash bleu et le message « Secours utilisé ». Ce message réutilise la texture de papier, le shader de bord brûlé et la typographie des menus ; les tweens l’affichent brièvement puis le cachent.

Le jet givré utilise la couleur bleue de ParticleProcessMaterial et le matériau du mesh des particules doit avoir Vertex Color > Use As Albedo activé. Sans cette option, la couleur calculée par les particules était ignorée à l’affichage.

Les deux gyrophares du camion sont éditables dans refuge_zombie.tscn, sous Gyrophares. Le script du refuge alterne leurs matériaux émissifs et leurs petites lumières locales toutes les 0,2 seconde pendant la sirène. Ils reviennent à leur état éteint après l’attraction ou la fin de vague. Il n’y a toujours pas de son de sirène.

## Tirage pondéré et cartes uniques

Un booster commun n’impose plus trois cartes communes. Le tirage commence par choisir une rareté, puis une définition autorisée dans cette rareté. Il retire cette définition avant le choix suivant, pour éviter deux variantes de la même amélioration dans un booster.

| Booster | Poids commun | Poids rare | Poids épique |
|---|---:|---:|---:|
| Commun | 88 | 11 | 1 |
| Rare | 25 | 65 | 10 |
| Épique | 5 | 25 | 70 |
| Intervention | 65 | 30 | 5 |

X, Y et Z dans les propriétés Poids booster du manager correspondent à ces trois colonnes. Les poids sont relatifs : ils n’ont pas besoin de totaliser 100. Quand une catégorie est vide, ses chances sont redistribuées entre les catégories disponibles ; les probabilités peuvent donc évoluer entre les trois choix d’un même booster. Les cartes affichent leur propre rareté et le menu des bonus conserve cette couleur.

Sous pression, Grande réserve, Second souffle et Carrosserie renforcée gardent trois versions à 50 / 100 / 200 % de leur valeur de base. Les autres cartes ont une rareté et une valeur fixes : Escorte agile et les soins sont communs ; la vie supplémentaire, Dernier souffle, Réserve de secours et les boucliers sont rares ; Jet givré et Sirène de diversion sont épiques. Toutes ces raretés sont modifiables dans leurs ressources.

Jet givré et Solide sur ses appuis sont uniques. UpgradeManager conserve cartes_obtenues pour toute la partie, même si un effet disparaît ensuite. Les cartes uniques acquises ne sont plus tirées et le debug les affiche en lecture seule. Une ressource inactive ou réservée à l’autre mode est toujours exclue. Si moins de trois définitions restent, le choix en présente moins ; si aucune ne reste, l’achat est refusé avant de débiter les points.

La proposition conserve la rareté et le multiplicateur exacts sur la carte affichée. Au clic, le manager applique ces valeurs ; il ne déduit plus le gain de la couleur du booster. tirage_ameliorations.gd contient uniquement l’algorithme de tirage, séparé de l’interface et du paiement.

### Consultation depuis la boutique et statistiques

Dans les deux modes, le bouton « Mes bonus et statistiques [B] » et la touche B ouvrent le récapitulatif depuis la boutique. Fermer le récapitulatif restaure l'état de pause précédent : le combat ne reprend pas tant que la boutique est ouverte. Le choix de cartes et l'ouverture d'un booster bloquent cette consultation pour éviter des menus superposés pendant un achat.

`scenes/interfaces/menus/statistiques_joueur.gd` construit le panneau de droite : vie et mousse actuelles/maximales, multiplicateurs de dégâts, recharge, capacité, déplacement et récupération du dash. Le bouclier restant apparaît lorsqu'il est actif. Les valeurs sont lues sur le joueur et son extincteur à l'ouverture ou après un changement d'améliorations ; ce panneau ne modifie pas les statistiques. ×1,20 signifie 20 % de plus que la valeur de base. Les dégâts incluent les effets conditionnels actifs.

Chaque ligne possède un pictogramme et une infobulle assortie au menu. Les pictogrammes des cartes sont réutilisés ; dash.svg est le seul nouveau dessin. Les ressources de recharge gardent leur effet : elles accélèrent la recharge à partir de sa nouvelle base.

L'extincteur consomme 25 unités par seconde et recharge 20 unités par seconde à la base. Le paramètre exporté `delai_avant_recharge` impose 0,25 seconde sans tirer avant de recharger. Chaque nouvel appui redémarre cette attente : les clics rapprochés ne permettent donc pas de profiter des espaces entre les jets pour récupérer constamment de la mousse. Les trois paramètres restent modifiables dans l'inspecteur de l'extincteur.
