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

Révélation légendaire : assets/sounds/interfaces/revelation_legendaire.wav.
Achievement, par mdkieran, licence CC0 : https://opengameart.org/content/achievement .
Fichier téléchargé par Rodrigo, conservé sans modification. Remplace le jingle et les tintements précédents ; lecture sur le bus Effets depuis SonsInterface.


Révélation épique : assets/sounds/interfaces/revelation_epique.wav.
Up (3x), par qubodup, licence CC0 : https://opengameart.org/content/up-3x .
Troisième variante de l’archive (upshort.wav), conservée sans modification. Lecture à la révélation, sur le bus Effets, à -18 dB.


Équilibrage : le son épique est joué à -8 dB (au lieu de -18 dB), car son fichier est plus discret que les autres révélations. Les volumes commun et rare restent à -22 et -20 dB.


Volumes actuels de révélation : commune -18 dB, rare -16 dB, épique -2 dB, légendaire -14 dB. Ces réglages compensent les différences de niveau des fichiers et passent toujours par le bus Effets.


Sirène lointaine (mode zombie) : le nœud `Ambiances/SireneLointaine` de chaque map utilise le lecteur commun en diffusion Global, avec le profil `scenes/systemes/audio/profils/sirene.tres`. Délai de 300 à 600 secondes après chaque passage, premier passage également retardé, volume -22 dB, fondus de 3 secondes. Le gestionnaire la coordonne avec les autres sons ponctuels et l'interrompt en fondu pendant la boutique.

Appels des victimes (deux modes) : `scenes/victimes/victime.gd` déclenche une seule des deux voix « help me » quand une victime encore captive atteint 50 % de ses PV. Chaque victime mémorise son propre appel pour éviter les répétitions. Les lecteurs 3D sont placés à 1,2 m au-dessus d'elle et utilisent le bus Effets ; les WAV sont importés en mono pour la localisation spatiale. Réglages dans le groupe Inspector « Appel au secours » : volume -12 dB, distance de référence 6 m, portée maximale 35 m. Le RoomManager ne déclenche plus lui-même les cris à mi-timer.

Organisation des ambiances :

- Les sources sont placées dans les maps. Les ambiances globales sont sous le dossier `Ambiances` ; les sources locales restent sous les voitures, fuites et installations qui les produisent.
- Glisser `scenes/systemes/audio/ambiance_locale.tscn` à l'endroit souhaité, puis choisir son Profil et sa Diffusion (Local ou Global) dans l'Inspector. Le son local utilise la position de ce nœud : on peut le décaler librement. Global utilise un AudioStreamPlayer, Local un AudioStreamPlayer3D.
- Les profils partagés sont dans `scenes/systemes/audio/profils/`. Ils contiennent sons, boucle, délais, volume, portée, hauteur, vitesse et fondu. Aucun filtre de map ni liste d'emplacements dans les profils.
- Cible est facultatif : la RadioCamion référence `../../Navigation/Decor/Refuge`, car le camion est créé après la map. Les autres sources n'en ont pas besoin.
- `scenes/modes/zombie/audio/environnement/ambiance_arene.gd` recense les sources de la map prête via le groupe `ambiances_locales`. Il ne crée pas les sources et ne connaît pas leurs chemins.
- Un seul son ponctuel est autorisé à la fois, puis 15 secondes de silence séparent les passages. Les sources utilisant le même profil partagent une horloge ; ajouter une voiture ne multiplie pas la fréquence des alarmes. Le gestionnaire évite de reprendre deux fois de suite la même source lorsqu'il y en a plusieurs.
- Les boucles locales restent indépendantes. La pause suspend lectures et délais. La boutique interrompt toutes les sources avec un fondu de 0,6 seconde malgré la pause, puis les réactive à sa fermeture. Les sons ponctuels repartent avec un nouveau délai.

Réglages actuels : métal -14 dB / 55 m (délai 30 s actuellement ; 180–360 s conseillé pour des passages rares), alarmes -16 dB / 50 m / 300–600 s, radio -10 dB / 24 m / 180–300 s, ruissellement -6 dB / 14 m, gouttes -18 dB / 10 m. La radio et la sirène sont dans les deux maps ; eau, métal et alarmes uniquement dans le Parking.

Fichiers audio dans `assets/sounds/ambiance/environnement/`, crédits et découpes dans `CREDITS.md`. Aucun craquement de bois ni ancien Pipe leak utilisé ; les craquements minéraux du bâtiment restent à sélectionner. Pour un essai rapide, baisser temporairement les délais d'un profil, puis les rétablir après écoute. Les générateurs aléatoires sonores n'affectent pas les graines des combats.
