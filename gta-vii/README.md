# GTA VII — organisation du projet

Ouvrir `project.godot` dans Godot. La scène principale est
`scenes/jeu/main.tscn` (F6 pour cette scène, F5 pour le projet).

## Où trouver les fichiers ?

```text
scenes/
├── jeu/                   main et suivi de caméra
├── joueur/                scène et comportement du joueur
├── armes/extincteur/      extincteur et gestion de sa charge
├── ennemis/
│   ├── mobiles/           ennemi qui poursuit le joueur
│   ├── tourelles/         tour enflammée et projectile
│   └── dangers/           flaque de feu
├── victimes/              victime, escorte et bonus
│   └── evacuation/        borne et menu d'évacuation
├── salles/                salle, génération, objectifs et vagues
├── decors/                caisse, mur et porte
├── interfaces/
│   ├── hud/               affichage du joueur pendant la partie
│   └── menus/             bonus, titre, mort, victoire et navigation des menus
└── effets/feu/            scène de flammes et script d'effet

assets/
├── modeles/               modèles 3D et sources Blender
│   ├── ennemis/           modèle et texture associée
│   ├── extincteur/
│   └── effets/
├── textures/
│   ├── decors/
│   ├── interfaces/
│   └── feu/
├── materiaux/             matériaux partagés
├── maillages/             ressources de géométrie
└── shaders/feu/           shaders de feu

docs/                      explications du fonctionnement
```

## Règles de rangement pour l'équipe

- Garder une scène et son script ensemble : `player.tscn` et `player.gd`
  sont tous les deux dans `scenes/joueur/`.
- Ranger un gestionnaire avec le système qu'il gère : `room_manager.gd`
  dans `scenes/salles/`, `victim_manager.gd` dans `scenes/victimes/`.
- Placer les ressources artistiques dans `assets/`. Une texture associée à
  un modèle importé peut rester près de ce modèle pour préserver ses liens.
- Les fichiers `.uid` et `.import` servent à Godot : les conserver dans Git
  avec les fichiers correspondants. `.godot/` est un cache local ignoré par Git.
- Pour un prochain déplacement, utiliser le panneau **Système de fichiers**
  de Godot, puis vérifier également les chemins écrits dans `load()`,
  `preload()` et `change_scene_to_file()`.
- Ne pas renommer les nœuds internes d'une scène pour simplement ranger ses
  fichiers : les chemins de nœuds et les chemins de fichiers sont distincts.

## Points d'entrée utiles

- Démarrage : `scenes/jeu/main.gd`.
- Population, vagues et progression : `scenes/salles/room_manager.gd`.
- Construction du décor : `scenes/salles/room_generator.gd`.
- Aperçu du générateur : `scenes/salles/RoomGenerator.tscn`.
- Documentation détaillée : [fonctionnement des salles](docs/fonctionnement_salles.md).

Après avoir récupéré cette réorganisation, laisser Godot terminer son scan et
la réimportation des ressources. Les modèles `.blend` utilisent l'installation
de Blender configurée dans les réglages de l'éditeur, comme avant.

## Ancienne ressource à compléter

`assets/maillages/dust.res` est conservé tel quel, mais référence une texture
absente (`res://models/Textures/colormap.png`). Cette dépendance était déjà
manquante avant le rangement. Aucune scène actuelle ne référence ce maillage ;
il faudra retrouver sa texture avant de le réutiliser.
