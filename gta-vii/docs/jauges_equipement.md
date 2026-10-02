# Jauges de vie et de mousse

Les deux jauges reprennent le métal usé, les tons bordeaux et l’ivoire de la direction graphique. Les cadres sont opaques et les valeurs restent lisibles.

## Scène commune

`scenes/interfaces/hud/jauge_equipement.tscn` contient une ProgressBar et ses enfants :

- Cadre : TextureRect affichant le dessin métallique.
- Remplissage : TextureRect avec le shader des graduations et du relief.
- Icone : pictogramme de vie ou de mousse.
- Titre et Valeur : Labels utilisant la police Oswald déjà présente dans le projet.

Les styles Godot de la ProgressBar sont vides : ses propriétés value et max_value fonctionnent toujours, mais ses enfants dessinent la jauge. Tous les contrôles ignorent la souris pour que les clics continuent de servir au tir.

`jauge_equipement.gd` actualise le remplissage lorsque les signaux value_changed (valeur) et changed (limites) sont émis. La proportion est calculée à partir des limites, puis envoyée au shader ; une capacité améliorée est donc prise en compte automatiquement. Chaque jauge duplique son matériau pour conserver ses propres couleurs et effets.

Le setter de couleur actualise la teinte lorsque l’interface indique une surchauffe. Le mot-clé @tool permet de voir les jauges dans l’éditeur. Les exports titre, couleur et pictogramme permettent de personnaliser chaque instance.

## Visuels

`assets/textures/interfaces/hud/` contient trois SVG : cadre_equipement, icone_vie et icone_mousse. Le cadre utilise des dégradés, des vis, de fines rayures et des ombres de suie. Ce sont des images vectorielles, sans téléchargement ni effet PBR 3D.

`scenes/interfaces/hud/remplissage_equipement.gdshader` affiche le remplissage, les dix graduations et un dégradé qui simule du relief. Les graduations ne limitent pas la précision de la barre : elle peut se remplir à n’importe quelle valeur. TIME produit un reflet léger uniquement pendant la recharge.

## Connexion au jeu

Dans player.tscn, BarreDeVie et Jauge sont deux instances de la scène commune. Leurs chemins restent Interface/Vie/BarreDeVie et Interface/Reserve/Jauge. Le script du joueur continue à retirer les PV de la même ProgressBar.

`interface_joueur.gd` initialise les limites et lit les valeurs de l’extincteur. Il transmet l’état de recharge et la couleur de surchauffe, puis écrit le texte d’état. Il écoute aussi le signal degats_recus du joueur pour appeler reagir_aux_degats sur la jauge de vie.

Le Tween de dégâts fait revenir le cadre à sa teinte normale et atténue le reflet du remplissage en parallèle, sur 0.4 seconde. Si un nouvel impact arrive, il remplace l’animation précédente. La pause suspend cette animation.

## Modifier l’apparence

Ouvrir player.tscn, puis sélectionner Interface/Vie/BarreDeVie ou Interface/Reserve/Jauge pour modifier les exports de l’instance. Pour changer la structure commune, ouvrir jauge_equipement.tscn. Pour modifier le cadre, éditer cadre_equipement.svg.

Les valeurs de jeu restent dans les scripts habituels : vie_max dans interface_joueur.gd et max_charge dans le script de l’extincteur. La durée de réaction aux dégâts est dans reagir_aux_degats.

