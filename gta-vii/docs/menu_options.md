# Menu Options

Le bouton Options de l'écran titre ouvre le même menu que celui du Carnet en partie.
F2 au clavier ou Start sur la manette permet aussi de l'ouvrir. Échap / B, Start,
F2 ou le bouton Retour permettent de le fermer.

## Les fichiers

- `scenes/systemes/reglages/reglages.gd` : autoload `Reglages`, valeurs courantes,
  application des réglages et sauvegarde. Il reste présent entre deux scènes.
- `scenes/interfaces/menus/options/menu_options.tscn` : voile sombre, panneau de
  papier brûlé, deux onglets, zone de défilement et bouton Retour.
- `scenes/interfaces/menus/options/menu_options.gd` : construction des lignes de
  réglages, ouverture, pause, animation et navigation entre les onglets.
- `scenes/interfaces/menus/options/theme_options.tres` : police, couleurs et
  apparence des curseurs. Les boutons réutilisent ceux de l'écran titre.
- `assets/textures/interfaces/options/poignee_reglage.svg` : poignée dorée des
  curseurs, dessinée en vectoriel pour rester nette.
- `default_bus_layout.tres` : trois bus audio : Master, Ambiance et Effets.

Le fond et ses braises réutilisent le shader et la texture du Carnet. Il n'y a
pas de nouveau shader pour ce menu. Les lignes de réglages sont créées dans
`_ready()` : leurs titres et limites se modifient dans `menu_options.gd`.

## Les volumes

Un bus regroupe des lecteurs audio. Le crépitement des foyers utilise Ambiance ;
les sons d'extincteur, d'ascenseur, de victimes, de mort et de pièces utilisent
Effets. Les lecteurs de mort créés par les scripts sont également raccordés à
Effets. Les deux bus passent ensuite dans Master : le volume général agit donc
sur l'ensemble du son. Aucun volume individuel des lecteurs n'a été augmenté.

Le curseur fournit une valeur entre 0 et 100. `Reglages` la ramène entre 0 et 1,
la convertit en décibels avec `linear_to_db()` et l'applique au bus. À zéro, le
bus est rendu muet. Les réglages restent applicables aux sons futurs : il faudra
choisir leur bus dans le lecteur ou dans le script qui les crée.

## L'affichage et la visée

Le bouton d'affichage alterne entre fenêtré et plein écran via
`DisplayServer.window_set_mode()`. Le système de mise à l'échelle existant du
projet est conservé ; les ancres du panneau lui permettent de suivre le viewport.
Le mode initial maximisé est conservé tant que le joueur n'a pas changé ce choix.

La sensibilité multiplie la vitesse du `CursorManager` commun : ×1 reprend
1000 unités par seconde, ×1,5 donne 1500. Le rapport entre X et Y et la zone
morte existants ne changent pas. Ce réglage concerne uniquement la manette.

## L'onglet Contrôles

La scène du collègue `scenes/interfaces/contrôles/menu_controles.tscn` est
instanciée dans cet onglet avec `integre_options = true`. Ses deux scripts de
remappage restent en place. L'adaptation masque son ancien fond, son titre et
son bouton Retour, réduit les boutons et ajoute des intitulés aux colonnes.
Sa hiérarchie est conservée : les chemins utilisés par ses scripts restent valides.

Après un changement, le signal `commandes_changees` déclenche la sauvegarde.
Échap / B annule une modification en attente. Changer d'onglet ou fermer le menu
annule aussi l'attente pour qu'une touche de jeu ne soit pas capturée ensuite.
Les boutons de réinitialisation reprennent les valeurs de `project.godot` et
conservent les commandes de l'autre périphérique. Le menu propose les six actions
déjà présentes dans celui du collègue ; il n'ajoute pas de nouvelles actions.

L'ancien CursorManager local du menu de contrôles a été retiré : le gestionnaire
autoload s'en occupe déjà. Il ne doit y avoir qu'un pilote du curseur.

## La pause et les entrées

Avant d'ouvrir, le menu mémorise la pause, le mode de souris et le focus actuels.
Il arrête le tir et met le jeu en pause. Son `Process Mode = Always` garde les
boutons, les braises et le Tween d'ouverture actifs pendant cette pause.
Ce Tween joue en parallèle un fondu de 0,16 s et un agrandissement de 0,2 s.

Les traitements `_input`, `_unhandled_input` et `_unhandled_key_input` de la
scène derrière sont temporairement suspendus. Ils sont rétablis dans leur état
précédent au retour. Ainsi, Échap ferme seulement les Options et ne ferme pas
simultanément le Carnet, la boutique ou un autre menu derrière.
La navigation manette de ces menus est également suspendue pour qu'ils ne
reprennent pas le focus du menu Options.

Fermer restaure la pause précédente : si la boutique ou le Carnet étaient ouverts,
la partie reste en pause. Pendant une transition de salle, l'ouverture est refusée
pour ne pas interrompre l'entrée du joueur. La navigation manette existante est
réutilisée et le premier onglet reçoit le focus lorsqu'une manette est connectée.

## La sauvegarde

Les réglages vont dans `user://reglages.cfg`, dans les données locales du jeu,
comme les succès (mais dans un fichier différent). Ils sont chargés au lancement
et enregistrés à chaque modification. Il n'y a pas de bouton Appliquer.

Les touches sont enregistrées sous forme de dictionnaires : type de périphérique,
touche ou bouton, axe et direction. Au lancement, le gestionnaire recrée les
`InputEvent` correspondants dans l'`InputMap`. Les actions de navigation `ui_*`
restent celles du projet pour conserver les commandes de navigation des menus.

## Vérifications

Tests effectués : volume nul et volume à 50 %, sensibilité, sauvegarde/relecture
des commandes, réinitialisation sans perdre la manette, retour depuis une pause
existante, ouverture depuis l'écran titre et le Carnet classique/zombie, F2 et
Échap. Les deux onglets ont été inspectés sur des captures du rendu Godot.
La navigation avec une manette physique reste à essayer sur le poste de jeu.
