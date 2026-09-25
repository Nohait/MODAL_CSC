# Cartes d'amélioration

## Voir le résultat

Ouvrir `scenes/interfaces/menus/ameliorations/apercu_cartes.tscn` et lancer cette scène avec F6.
Les trois propositions sont des exemples visuels : les pourcentages ne modifient pas le joueur.
L'illustration de test est volontairement partagée. Clic gauche et Entrée émettent `selected` ;
Tab permet de déplacer le focus. Aucun passage de salle n'est branché à cet aperçu.

## Modifier une carte

La scène réutilisable est `carte_amelioration.tscn`, dans le même dossier.
Sélectionner sa racine pour modifier les exports de la section Contenu : identifiant,
titre, description, effet affiché, catégorie et illustration. Le script `@tool` actualise
les textes et l'image dans l'éditeur. Préférer des textes courts pour le format de 320 × 500.
L'illustration est recadrée au centre sans déformation.

La racine reçoit les interactions ; son enfant Visuel porte le graphisme et s'agrandit
au survol. Le rectangle cliquable ne bouge donc pas avec l'animation. Tous les éléments
décoratifs ignorent la souris pour laisser les événements parvenir à la racine.

## Matière et animation

Les shaders `carte_amelioration.gdshader` et `carte_illustration.gdshader` partagent
`cadre_braise.gdshaderinc`. Ce fichier calcule les coins arrondis, le charbon, le biseau
et les fissures lumineuses. Il simule le relief en 2D : ce n'est pas du PBR 3D.
Le paramètre taille maintient une épaisseur de bord cohérente en pixels.
L'animation change la chaleur des fissures, pas la forme du bord.

Chaque instance duplique ses matériaux pour rendre son survol indépendant des autres.
La carte est en Process Mode Always. Son horloge de shader est fournie par `_process` :
les braises et les Tweens de survol fonctionnent même lorsque le jeu est en pause.
Intensite braises, Hover scale et Hover duration sont réglables dans l'inspecteur.

## Gestionnaire et passage de porte

La scène upgrade_manager.tscn est instanciée sous main/UpgradeManager. Son script
upgrade_manager.gd écoute choix_amelioration_demande du RoomManager. Ce signal arrive
après validation de la zone de passage d'une salle libérée et après le traitement physique.

Le gestionnaire mélange une copie du POOL et crée trois cartes distinctes. Avec trois
entrées, seuls leurs emplacements varient. Le jeu est mis en pause et le curseur est visible.
Le choix est obligatoire. Un verrou empêche de recevoir plusieurs récompenses par double clic.
Après sélection : appliquer le bonus, fermer les cartes, restaurer le curseur, retirer
la pause, puis demander passer_salle_suivante(). La dernière sortie mène directement
à la victoire sans proposer de récompense inutile.

## Équilibrage et cumul

Dans main.tscn, sélectionner UpgradeManager puis « Équilibrage — bonus par choix ».
Les trois exports fixent les gains de dégâts, capacité et vitesse de recharge.
Saisir 20 pour +20 %. Régler ces valeurs avant de lancer une partie ; les textes des
cartes et le récapitulatif utilisent ces mêmes pourcentages.

Les niveaux sont conservés par le gestionnaire de la partie, détruit au changement
de scène : aucune sauvegarde permanente entre parties. Le cumul est additif sur la
base : deux choix à +20 % donnent +40 %. Le bonus de dégâts d'escorte s'applique
ensuite séparément : avec une spécialiste et un choix à +20 %, dégâts = base × 1.2 × 1.25.

Grande réserve ajoute à la charge actuelle seulement la capacité gagnée.
La jauge suit automatiquement le nouveau maximum. Les choix acquis apparaissent
dans la section des bonus permanents du MenuBonus. Évacuer une victime ne les retire pas.

## Menu des bonus acquis

MenuBonus reprend les mêmes cartes en lecture seule, dans un format compact de
240 × 365. Le fond utilise le papier existant teinté bordeaux et le shader commun
des contours brûlés. Les deux sections restent séparées : escorte et renforts acquis.
Une amélioration répétée apparaît une seule fois avec son niveau et son effet total.
Seuls les bonus possédés sont montrés ; chaque section possède son propre état vide.

Les cartes d'escorte utilisent deux pictogrammes SVG remplaçables dans
assets/textures/interfaces/ameliorations. Leurs effets sont lus depuis les constantes
du joueur et de l'extincteur. Elles disparaissent dès que le bonus d'escorte n'est plus actif.
Le menu se reconstruit sur escort_changed et ameliorations_changees, ainsi qu'à l'ouverture.

Le mode lecture_seule de carte_amelioration.gd désactive selected et le focus de choix.
Le survol conserve seulement l'accent lumineux ; il n'agrandit pas les cartes du récapitulatif.
Les cartes de l'écran de choix gardent leur format et leur comportement d'origine.
