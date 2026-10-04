# Navigation des menus à la manette

`scenes/interfaces/menus/navigation_manette.gd` est partagé par les menus titre/mort, maps zombie, boutique, choix de cartes, bonus, succès, contrôles et debug (y compris le catalogue d'ennemis).

Chaque menu appelle `installer(racine)` dans `_ready()`. Le petit nœud ajouté fonctionne pendant la pause. Toutes les 0,1 seconde, il vérifie la présence d'une manette avec `Input.get_connected_joypads()` et actualise le focus des boutons et cartes. Sans manette, ils restent utilisables à la souris sans présélection. Avec une manette, les boutons ont `FOCUS_ALL` et Godot gère leur navigation directionnelle.

À l'ouverture, la première carte ou le premier booster est privilégié ; sinon, le premier bouton visible et actif reçoit le focus. Les cartes de consultation et boutons désactivés sont exclus. Les descriptions de défis peuvent être dépliées puis leur bouton d'acceptation sélectionné. Les ScrollContainer suivent le focus pour garder le choix visible. Un focus existant est conservé pendant la navigation et lorsqu'un autre sous-menu est ouvert.

Les cartes et boosters personnalisés utilisent leurs signaux de focus pour reprendre l'animation de survol. Leur `_gui_input` accepte `ui_accept`, en plus du clic gauche ; les Button ordinaires le font déjà nativement. `ui_cancel` consomme désormais l'événement avant le changement de scène de sélection des maps, pour éviter d'appeler `get_viewport()` après son retrait de l'arbre.

Vérifications avec une détection de manette simulée : première map sélectionnée, retour B vers le titre, premier booster sélectionné, voisin de droite, accès au bouton d'un défi déplié et validation des cartes/boosters. Une vérification physique avec la manette reste utile pour confirmer le mapping et le ressenti.
