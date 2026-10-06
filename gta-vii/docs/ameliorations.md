# Créer et équilibrer des cartes

Les cartes sont des ressources Godot. Le catalogue commun est dans `scenes/systemes/ameliorations/catalogue_ameliorations.tres`. Les 46 définitions se trouvent dans son dossier `cartes`. La boutique, le menu des bonus et le catalogue debug lisent ces mêmes données.

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
- Prérequis : identifiants des cartes à acheter auparavant. Une carte verrouillée est exclue des boosters et reste visible, désactivée, dans le catalogue debug. L'historique des achats compte même si un bouclier temporaire a expiré.
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

Pour une variation d’un effet existant, aucun nouveau code n’est nécessaire. Pour inventer un nouveau comportement, ajouter son nom dans l’export Effet de amelioration.gd et son traitement dans l’UpgradeManager : `_appliquer_soin` pour une action immédiate, `recalculer_effets` pour une statistique durable. Les comportements de combat, de dash et d'équipement sont regroupés dans `scenes/systemes/ameliorations/effets_cartes.gd`.

Les nouvelles cartes et les combos sont expliqués dans [combos_ameliorations.md](combos_ameliorations.md).

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

| Booster | Prix | Poids commun | Poids rare | Poids épique | Poids légendaire |
|---|---:|---:|---:|---:|---:|
| Commun | 1 | 88 | 10,9 | 1 | 0,1 |
| Rare | 2 | 25 | 64 | 10 | 1 |
| Épique | 3 | 5 | 22 | 65 | 8 |
| Légendaire | 5 | 0 | 20 | 50 | 30 |
| Intervention | 1 | 65 | 30 | 5 | 0 |

X, Y, Z et W dans les propriétés Poids booster du manager correspondent aux quatre raretés. Les poids sont relatifs : ils n’ont pas besoin de totaliser 100. Quand une catégorie est vide, ses chances sont redistribuées entre les catégories disponibles ; les probabilités peuvent donc évoluer entre les trois choix d’un même booster. Les cartes affichent leur propre rareté et le menu des bonus conserve cette couleur.

Le booster légendaire est doré, avec les mêmes braises et animation d'ouverture que les autres. Il coûte 5 points, réglables dans le manager. Il est grisé et son achat est refusé sans paiement si aucune carte légendaire ne peut être obtenue. Choc thermique, Réaction en chaîne et Extraction d'urgence sont les trois premières légendaires : effets fixes, uniques et disponibles dans les deux modes. Les statistiques variables restent communes, rares ou épiques.

Sous pression, Grande réserve, Second souffle et Carrosserie renforcée gardent trois versions à 50 / 100 / 200 % de leur valeur de base. Les autres cartes ont une rareté et une valeur fixes : Escorte agile et les soins sont communs ; la vie supplémentaire, Dernier souffle, Réserve de secours et les boucliers sont rares ; Jet givré et Sirène de diversion sont épiques. Toutes ces raretés sont modifiables dans leurs ressources.

Jet givré et Solide sur ses appuis sont uniques. UpgradeManager conserve cartes_obtenues pour toute la partie, même si un effet disparaît ensuite. Les cartes uniques acquises ne sont plus tirées et le debug les affiche en lecture seule. Une ressource inactive ou réservée à l’autre mode est toujours exclue. Si moins de trois définitions restent, le choix en présente moins ; si aucune ne reste, l’achat est refusé avant de débiter les points.

La proposition conserve la rareté et le multiplicateur exacts sur la carte affichée. Au clic, le manager applique ces valeurs ; il ne déduit plus le gain de la couleur du booster. tirage_ameliorations.gd contient uniquement l’algorithme de tirage, séparé de l’interface et du paiement.

### Consultation depuis la boutique et statistiques

Dans les deux modes, le bouton « Mes bonus et statistiques [B] » et la touche B ouvrent le récapitulatif depuis la boutique. Fermer le récapitulatif restaure l'état de pause précédent : le combat ne reprend pas tant que la boutique est ouverte. Le choix de cartes et l'ouverture d'un booster bloquent cette consultation pour éviter des menus superposés pendant un achat.

`scenes/interfaces/menus/statistiques_joueur.gd` construit le panneau de droite : vie et mousse actuelles/maximales, multiplicateurs de dégâts, recharge, capacité, déplacement et récupération du dash. Le bouclier restant apparaît lorsqu'il est actif. Les valeurs sont lues sur le joueur et son extincteur à l'ouverture ou après un changement d'améliorations ; ce panneau ne modifie pas les statistiques. ×1,20 signifie 20 % de plus que la valeur de base. Les dégâts incluent les effets conditionnels actifs.

Chaque ligne possède un pictogramme et une infobulle assortie au menu. Les pictogrammes des cartes sont réutilisés ; dash.svg est le seul nouveau dessin. Les ressources de recharge gardent leur effet : elles accélèrent la recharge à partir de sa nouvelle base.

L'extincteur consomme 25 unités par seconde et recharge 20 unités par seconde à la base. Le paramètre exporté `delai_avant_recharge` impose 0,25 seconde sans tirer avant de recharger. Chaque nouvel appui redémarre cette attente : les clics rapprochés ne permettent donc pas de profiter des espaces entre les jets pour récupérer constamment de la mousse. Les trois paramètres restent modifiables dans l'inspecteur de l'extincteur.

## Révélation des boosters

L'achat affiche trois dos en papier, puis retourne les cartes de gauche à droite. `UpgradeManager._reveler_cartes()` orchestre l'ordre ; `carte_amelioration.gd` anime la largeur du visuel avec un Tween, dévoile le contenu au milieu et joue le son de sa rareté. Les cartes restent bloquées jusqu'à la fin de la séquence, pour la souris comme pour la manette. Le catalogue de debug et le Carnet n'utilisent pas cette animation.

`dos_carte.svg` est un petit motif vectoriel créé pour le projet, posé sur le papier existant. `eclat_revelation.gd` dessine un halo et des braises autour de la carte. Les quatre niveaux augmentent la quantité de braises, leur portée, la lueur et le rebond. L'effet reste local : aucun flash de tout l'écran ni nouvelles particules 3D.

Les sons sont ceux des packs Kenney déjà crédités dans `docs/sons_et_atelier_audio.md` : Music Jingles (`jingles_PIZZI00`, `jingles_PIZZI04`, `jingles_HIT00`, `jingles_HIT04`, dans cet ordre pour commun / rare / épique / légendaire). Ils passent par le bus Effets et respectent donc le volume des options. Les chemins et volumes sont réunis dans `_montrer_face()` pour les remplacer facilement après écoute en jeu.

Le dos utilise également `dos_carte.gdshader` : le canal alpha du SVG délimite les motifs incandescents. Un bruit déformé forme la croûte sombre et les poches de lave orange / jaunes. Cette matière forme des remous dans les deux axes, avec un halo discret. Chaque carte reçoit un décalage aléatoire pour éviter des mouvements identiques. Le paramètre vitesse_coulee règle la vitesse du mouvement. La carte transmet son horloge au shader chaque image, y compris pendant la pause. Les sons courts sont musicaux : cordes pincées pour commun / rare, impacts musicaux pour épique / légendaire.

Le nœud `Menu/FondRevelation` de `upgrade_manager.tscn` habille les achats avec une brume, des rais lumineux et des braises. Le fond commence neutre, puis prend progressivement la couleur de la meilleure carte déjà révélée, sans dévoiler les cartes cachées. Son script `fond_revelation.gd` anime les paramètres de `fond_revelation.gdshader`, même pendant la pause. Le signal `revelee` de chaque carte appelle `accentuer()` pour renforcer brièvement le halo selon sa rareté. Ce fond est derrière le défilement, ignore les clics et reste masqué dans le catalogue de debug. Il est réinitialisé à chaque achat. Les cartes obtenues sont triées après le tirage, de la moins rare à la plus rare ; les probabilités et effets restent inchangés. La luminosité et la quantité de braises augmentent avec la rareté révélée.

La densité des braises du fond progresse fortement avec la rareté déjà dévoilée : environ 115 pour commune, 210 pour rare, 355 pour épique, 530 pour légendaire, avant masquage par les cartes. Leur taille et leur position sont variées ; leur vitesse augmente légèrement avec la rareté. Ces valeurs sont définies dans `fond_revelation.gdshader`.

Dans le mode zombie, la boutique joue désormais Cipher de Kevin MacLeod (fichier `assets/sounds/musique/zombie/cipher.mp3`). La scène `musique_zombie.tscn` sélectionne cette piste ; `musique_zombie.gd` conserve les fondus, la boucle et la position mémorisée. Les crédits et la licence sont dans `assets/sounds/musique/zombie/credits.md`. La musique du mode classique reste gérée par son système existant.

## Séquence physique et confirmation

La boutique appelle `ouverture_booster.ouvrir()` : une copie du paquet vient au centre, gonfle et alterne rotation / déplacement sur six secousses. Le shader `booster_bonus.gdshader` reçoit le paramètre `pression` pour éclairer la fissure. La déchirure existante sépare ensuite les moitiés, avec une gerbe, un froissement et un son de papier déchiré. Le Carnet garde son ouverture rapide via `lancer()`.

Les visuels des cartes sortent empilés au centre, puis rejoignent leurs cases. Chaque carte se soulève et chauffe avant son retournement. Une légendaire marque une courte suspension, atténue les cartes voisines et ajoute une onde et un accord de trois tintements. Le tri croissant et la coloration après révélation sont conservés.

`SonsInterface.preparer_carte()` atténue la musique de 4 dB pour une épique et 7 dB pour une légendaire, avec un AudioEffectAmplify sur le bus Musique. Cet effet est distinct du réglage de volume des options. Le Tween de restauration appartient à cet autoload pour fonctionner même après fermeture du menu. Les sons utilisés sont déjà présents et crédités : Swishes Sound Pack, Various Paper Sound Effects et packs Kenney.

La sélection anime `confirmer_acquisition()` sur la carte choisie et `consumer()` sur les autres. Le paramètre `disparition` du shader brûle le papier depuis les bords. Le manager bloque les interactions pendant cette confirmation, puis applique le bonus et revient à la boutique. Le mode zombie attend cette fin avant de compter l'amélioration dans ses statistiques. Le catalogue de debug reste immédiat.

La lumière du paquet utilise lumiere_ouverture.gd et lumiere_ouverture.gdshader. Un CanvasLayer indépendant ajoute un halo orange sur tout l’écran : il monte pendant les secousses, culmine à la déchirure puis disparaît en 0,6 seconde. Le mélange additif éclaircit le menu sans masquer les clics.
Les sons commun / rare sont désormais PIZZI04 / PIZZI00. La légendaire utilise Achievement de mdkieran, joué par SonsInterface pour terminer sa résonance même après sélection.


Le son épique est maintenant la troisième variante de Up (upshort.wav), renommée revelation_epique.wav. Les lecteurs des révélations sont rattachés à SonsInterface pour ne pas couper leur fin lorsque le menu se ferme ; chaque lecteur se supprime à la fin du son.


Habillage des boosters : booster.gdshader éclaire davantage le métal et dessine un sceau circulaire / losange derrière le chiffre. Le reflet mobile apparaît au survol. booster_apercu.gd reçoit niveau_eclat (0 à 3) depuis la boutique : cette rareté augmente le halo, les braises, la montée et l’inclinaison du visuel. La zone cliquable reste fixe. booster_bonus.gdshader conserve le même habillage pendant la déchirure.


Les faces des cartes distinguent désormais leur rareté : nom dans l’en-tête, filet coloré (double dès rare), coins gravés et médaillon lumineux autour du pictogramme. Les épiques et légendaires ajoutent des étoiles animées, avec une intensité croissante. carte_amelioration.gd transmet le rang et la position réelle de l’illustration à carte_amelioration.gdshader ; les cartes compactes du Carnet conservent le même habillage. Le dos reste neutre jusqu’au retournement grâce à rarete_coloree. Au survol, les cartes sélectionnables se soulèvent davantage selon la rareté ; celles du Carnet gardent leur taille et position.


Refonte métal / parchemin : la partie haute de carte_amelioration.gdshader dessine une plaque brossée sombre, teintée selon la rareté. La séparation suit la position du premier texte (durée si visible, sinon titre), pour conserver les informations sur le parchemin même dans le Carnet. pictogramme_metal.gdshader transforme la silhouette du SVG en emblème clair avec un biseau simulé par les variations d’alpha. Chaque carte possède son matériau, et le script conserve une marge autour du pictogramme. Le relief est une illusion 2D, sans éclairage PBR réel ni nouvelle texture téléchargée.


Le Carnet utilise désormais fond_carnet.gdshader : métal graphite brossé, double filet cuivré et encarts distincts pour les deux familles de bonus. Le fond bordeaux partagé des autres écrans reste dans fond_menu_bonus.gdshader. Les cartes acquises sont contenues dans carte_carnet.gd : taille visuelle réduite à 60 %, avec une copie agrandie au survol dans une couche au-dessus du défilement. La copie ignore les clics, ne permet aucun achat et disparaît au départ de la souris ou à la fermeture du Carnet. Aucun effet de jeu n’est modifié.


Le Carnet harmonise ses onglets et le panneau de statistiques en graphite avec des accents cuivrés. ECHELLE_VIGNETTE dans carte_carnet.gd vaut désormais 0,5. Toutes les cartes en consultation utilisent 240 × 365, y compris les temporaires : celles-ci réservent davantage de place à leur durée en réduisant l’illustration et l’espacement, plutôt qu’en allongeant leur cadre.


Le zoom des vignettes est désormais déterminé par leur rectangle fixe et les limites des parents qui coupent le défilement. Tous les descendants de la petite carte ignorent la souris, car leurs rectangles de mise en page restent à la taille normale malgré le dessin réduit. Un aperçu existant est conservé, sans recréer son animation à chaque image. Sortir de la fenêtre ferme l’aperçu et bloque sa réapparition jusqu’au retour de la souris. Les infobulles des statistiques et les boutons du glossaire reprennent le graphite ; bouton_glossaire.gd utilise le shader des onglets et garde le vrai Button pour la navigation manette.


Mousse protectrice et Protection d’urgence ont désormais une durée à zéro : elles accordent immédiatement une réserve de bouclier, conservée sans limite de salle/vague. Le manager les distingue des soins instantanés : leur acquisition reste active et chaque coup réduit bouclier_restant. La fin d’une étape conserve les réserves positives et retire seulement celles épuisées. Le Carnet indique JUSQU’À ÉPUISEMENT et les PV restants. Leurs modes, raretés, puissances et pools ne changent pas.


Les options et le catalogue des succès partagent désormais fond_carnet.gdshader avec le Carnet : graphite brossé, filets cuivrés et bords brûlés. Les boutons utilisent onglet_carnet.gdshader avec un matériau distinct par bouton. Les réglages et la page de contrôles gardent leurs scripts et actions. Les lignes de succès utilisent parchemin_succes.gdshader, séparé des cartes d’amélioration pour rester des bandeaux de parchemin, avec des raretés colorées et un état non obtenu grisé.

