# Bibliothèque de sons — intégration retirée

Les sons téléchargés restent dans `assets/sounds/design/` pour une reprise ultérieure.
L’atelier audio, son autoload, ses raccourcis et les nouveaux branchements ont été retirés.
Les sons antérieurs à cette tentative d’intégration sont conservés.

## Sources et licences

Les bibliothèques utilisées sont annoncées CC0 par leurs auteurs. Les sources sont conservées ici même si l’attribution n’est pas obligatoire.

- Kenney : [Impact Sounds](https://kenney.nl/assets/impact-sounds), [RPG Audio](https://kenney.nl/assets/rpg-audio), [Interface Sounds](https://kenney.nl/assets/interface-sounds), [Music Jingles](https://kenney.nl/assets/music-jingles).
- rubberduck : [80 CC0 Creature SFX](https://opengameart.org/content/80-cc0-creature-sfx) et [80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx).
- artisticdude : [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack).
- Luckius : [Various Paper Sound Effects](https://opengameart.org/content/various-paper-sound-effects).
- PagDev : [Fireplace Sound Loop](https://opengameart.org/content/fireplace-sound-loop).
- Planet-Leader : [FireExtinguisher.wav](https://freesound.org/people/Planet-Leader/sounds/155516/), imitation d’extincteur avec de l’air comprimé.
- bart : [Chain Winch Sounds](https://opengameart.org/content/chain-winch-sounds).
- aquinn : [Sirens and Alarm Noise](https://opengameart.org/content/sirens-and-alarm-noise).
- EZduzziteh : [Explosions](https://opengameart.org/content/explosions-4).

Le pack Fighter n’est pas utilisé : il contient des annonces parlées en anglais, pas les réactions de douleur attendues. Les portes utilisent pour cette proposition les sons du pack RPG de Kenney ; l’archive qubodup reste dans Téléchargements.


Son d'ouverture de l'ascenseur : `assets/sounds/design/ascenseur/ouverture_portes.wav`.
Source : https://freesound.org/people/rubberduck9999/sounds/678454/
Auteur : rubberduck9999. Licence : CC0.
Conversion du FLAC téléchargé en WAV mono avec Blender (sans changement de vitesse).
Lecture uniquement pendant le glissement des portes ; volume réglable sur le nœud OuverturePortes.

Souffle de l'extincteur : `assets/sounds/design/155516__planet-leader__fireextinguisher.wav`.
Auteur : Planet-Leader, source et licence CC0 indiquées plus haut.
Lecture en boucle pendant le tir, avec un fondu de 0,08 s au démarrage et 0,12 s à l'arrêt.
Volume réglable sur le nœud `Sons/Souffle` de la scène extincteur ; sons d'impact conservés.
