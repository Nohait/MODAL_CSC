# Graphismes et chargement

Les options (F2 / Start) proposent Économique, Équilibré et Complet. Complet est le profil par défaut et conserve le rendu précédent. Les réglages sont enregistrés dans `user://reglages.cfg`, section `graphismes`.

## Profils

`scenes/systemes/reglages/profils/*.tres` sont modifiables dans l’Inspector : résolution 3D, distance des détails, marge de distance. À 65 %, la largeur et la hauteur du rendu 3D sont chacune multipliées par 0,65 ; l’interface reste à sa résolution habituelle. Les lumières, leur énergie, leurs ombres et l’environnement ne sont pas modifiés.

`graphismes.gd` applique les profils depuis un enfant de l’autoload Reglages. Les branches du groupe `details_decor` sont enregistrées une seule fois, puis leurs instances géométriques reçoivent une distance d’affichage. Le Hall marque le décor extérieur, les annexes inaccessibles, le mobilier, les débris et la signalétique. Les sols de combat, collisions, équipements et ennemis restent inchangés. Une marge évite les apparitions/disparitions répétées à la frontière. Complet restaure les valeurs initiales.

Ce masquage réduit le rendu du décor éloigné, mais ne décharge pas les modèles de la mémoire et ne supprime pas leurs scripts. Les paramètres ne concernent pas les SubViewports du glossaire.

## Chargement

`chargement.gd`, autre enfant de Reglages, affiche un panneau indépendant des scènes. Les menus de nouvelle partie et de sélection des maps lui confient le changement de scène. Le catalogue des maps conserve désormais un chemin, afin de ne pas charger le Hall lors de la simple consultation du menu.

Le panneau affiche d’abord la progression réelle de `ResourceLoader.load_threaded_request`. Il attend le statut LOADED avant de récupérer la scène, puis affiche « Préparation du niveau et de la navigation ». La barre est cachée pendant cette deuxième étape, dont la durée n’est pas connue à l’avance.

RoomManager retire le panneau juste avant le fondu d’entrée, après la préparation de la navigation. La course d’entrée reste visible et la vague démarre toujours après cette course. Cela s’applique également à une nouvelle partie classique.

L’instanciation des nodes et une partie de leur initialisation restent sur le thread principal de Godot : un court arrêt de l’animation est encore possible pendant cette étape. Cet écran ne couvre pas le démarrage de l’exécutable avant les autoloads, ni un rechargement direct avec R depuis le niveau.
