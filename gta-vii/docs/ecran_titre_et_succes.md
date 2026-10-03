# Écran titre et succès

F5 ouvre désormais `scenes/interfaces/menus/ecran_titre.tscn`. Pour tester directement le niveau, ouvrir `main.tscn` et utiliser F6 reste possible.

## L'écran titre

La scène sépare le menu de son illustration :

- `Menu/Colonne` est un `VBoxContainer` : il range le titre, l'accroche et les trois boutons verticalement. Le menu utilise des ancres pour garder sa place à gauche.
- `Illustration` est un `SubViewportContainer`. Il affiche le rendu de `Vue3D`, une petite scène 3D avec son propre monde, sa caméra et ses lumières. Ce décor n'est pas un niveau jouable.
- `decoration_titre.gd` instancie seulement le modèle du pompier, le modèle du sbire et les flammes existantes. Il crée également un sol et deux murs avec les matériaux du jeu. Les scripts de combat et de génération de salles ne sont pas utilisés dans ce décor.
- Le pompier joue son animation Idle. Une lumière orange varie légèrement pour donner l'impression que le feu éclaire le décor.
- `Voile` assombrit progressivement le raccord entre l'illustration et la partie gauche. `Flammes` dessine un feu animé derrière le titre avec un shader : du bruit déformé défile vers le haut.

`titre/ecran_titre.gd` reprend la navigation de `navigation_menus.gd`. Nouvelle partie ouvre une nouvelle instance de main ; Succès ouvre le catalogue ; Quitter appelle `get_tree().quit()`.

## Les boutons et les surfaces

`titre/bouton_menu.tscn` est un bouton réutilisable. Son script conserve le vrai `Button`, donc ses clics et son focus. Il remplace les fonds standards par `plaque_bouton.svg`, un dessin de métal noirci avec des rivets et un liseré de laiton. Au survol, un Tween fait progresser le paramètre `survol` du shader pendant 0,18 seconde : cela éclaircit la plaque et fait glisser son reflet.

`titre/theme_menu.tres` fournit la police Oswald et les couleurs communes. Le titre emploie la police Almendra déjà présente dans le projet. Les boutons de mort et de victoire reprennent aussi la nouvelle plaque.

`titre/surface_menu.gd` duplique le matériau de chaque surface pour qu'elle possède ses propres paramètres, transmet sa taille au shader et fait avancer son horloge. Le catalogue utilise le shader de pochette métallisée déjà employé pour les bonus. Ses lignes réutilisent le papier et le cadre brûlé des améliorations, sous forme de bandeaux horizontaux.

## Le catalogue

`scenes/systemes/succes/catalogue_succes.gd` contient les définitions :

- `id` : nom interne sauvegardé, à conserver même si le titre change ;
- `titre` et `description` : textes du catalogue ; la notification affiche seulement le titre ;
- `rarete` et `couleur` : habillage visuel ;
- `escorte_minimum` : nombre minimal de victimes vivantes à la victoire.

Victoire ! est rare, bleu, avec un seuil de zéro : remporter une partie suffit. Sauveteur hors pair est épique, violet, avec un seuil de dix. Les victimes doivent encore appartenir à l'escorte et être vivantes quand la partie est remportée.

## Le gestionnaire et la sauvegarde

`succes_manager.gd` est enregistré comme Autoload dans `project.godot`. Godot le crée avant l'écran titre et le conserve lorsque main, l'écran de mort ou l'écran de victoire sont remplacés. On peut donc appeler `SuccesManager` depuis ces scènes.

Son dictionnaire `obtenus` contient les identifiants déjà acquis. Au lancement, un `ConfigFile` recharge ces identifiants depuis `user://succes.cfg`. `user://` correspond au dossier de sauvegarde local du jeu, distinct des fichiers suivis par Git.

À la fin du parcours, `RoomManager.passer_salle_suivante()` compte les victimes vivantes de l'escorte, puis appelle `SuccesManager.valider_victoire(nombre)` avant de changer de scène. Le gestionnaire compare ce nombre aux seuils du catalogue. Pour chaque succès rempli, `debloquer()` :

1. vérifie qu'il n'est pas déjà obtenu ;
2. ajoute son identifiant et sauvegarde le dictionnaire ;
3. émet `succes_obtenu(succes)`.

Une nouvelle partie remet le niveau à zéro, mais conserve les succès. Une mort ne débloque pas ces deux succès de victoire.

## Le menu et les notifications

`interfaces/succes/menu_succes.tscn` contient un voile, une pochette, le compteur, la barre de progression, un `ScrollContainer`, la liste et le bouton Retour. Son script reconstruit les lignes depuis le catalogue quand on l'ouvre. Le compteur utilise le nombre d'identifiants acquis et le nombre total de définitions : il n'est pas fixé à deux.

`ligne_succes.tscn` range une médaille, le titre, la description et l'état dans des containers. Les lignes verrouillées sont assombries, sans braises. Les lignes obtenues retrouvent leur papier clair, leur teinte de rareté et leur médaille colorée.

`notifications_succes.tscn` est un `CanvasLayer` enfant de l'Autoload. Il écoute le signal `succes_obtenu`. Les notifications sont placées dans une file et affichées une par une : glissement et fondu de 0,22 seconde, lecture pendant trois secondes, puis disparition de 0,25 seconde. Le panneau est ancré en bas à droite et ne prend pas les clics.

Le CanvasLayer utilise le mode Always : une pause n'interrompt pas l'annonce. Comme son parent est l'Autoload, le passage immédiat à l'écran de victoire ne détruit pas la notification.

## Ajouter un succès

Pour un nouveau succès de victoire basé sur l'escorte, ajouter un dictionnaire au catalogue avec un identifiant unique et un autre seuil suffit. Le menu et la progression suivront automatiquement.

Pour une condition différente, comme tuer cent ennemis, il faudra ajouter son compteur et son déclenchement dans le gestionnaire : le champ `escorte_minimum` ne décrit que les conditions actuelles de fin de partie. L'affichage et le signal de notification restent réutilisables.

Le bouton « Debug : réinitialiser les succès » du catalogue efface les identifiants en mémoire et réécrit `user://succes.cfg` vide. Il actualise les lignes et la progression, et annule les notifications en attente. Il est visible uniquement dans une version de debug (`OS.is_debug_build()`).

Les notifications mesurent 360 × 72 pixels dans la résolution de référence, avec une médaille de 40 pixels et le titre uniquement. La description reste disponible dans le catalogue. La note sur la sauvegarde se trouve sous la progression, au-dessus de la liste.

Le feu du titre adapte le shader « 2D fire » de Godot Shaders / Febucci, publié sous licence CC0 : https://godotshaders.com/shader/2d-fire/. Une `NoiseTexture2D` sans raccord fournit le bruit. Le shader le fait défiler vers le haut, le compare à un gradient vertical, puis colorie trois zones (bord rouge, flamme orange, cœur clair). Les seuils adoucis et le fondu de la base évitent des découpes trop dures. Le matériau `Flames` dans `ecran_titre.tscn` permet de régler les couleurs, la vitesse et l'opacité.
