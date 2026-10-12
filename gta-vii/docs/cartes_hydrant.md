# Cartes de la bouche à incendie

L’attaque et ces cartes sont communes aux deux modes. Les définitions sont des Resources dans `scenes/systemes/ameliorations/cartes/hydrant_*.tres`. Elles utilisent les tirages, le carnet, le catalogue de debug et la restauration des acquisitions déjà présents.

## Catalogue initial

| Carte | Rareté | Réglage initial | Condition |
|---|---|---|---|
| Livraison express | Commune | Chute 35 % plus rapide | — |
| Zone inondable | Rare | Rayon +25 % | — |
| Fonte lourde | Rare | Dégâts +60 %, portée −25 % | Exclut Service à distance |
| Service à distance | Rare | Portée +40 %, dégâts −25 % | Exclut Fonte lourde |
| Veuillez patienter | Rare | Ralentissement 45 % pendant la chute | — |
| Marée retour | Épique | Onde de retour après 0,8 s | — |
| Fuite sous pression | Épique | Une onde toutes les 1,6 s, 35 % des dégâts d’impact | — |
| Périmètre de sécurité | Rare | Zone d’eau ralentissant de 35 % | Fuite sous pression |
| Robinet ouvert | Rare | Présence +3 s | Fuite sous pression ; exclut Démontage rapide |
| Démontage rapide | Rare | Présence −2 s | Exclut Robinet ouvert |
| Point d’appui | Rare | Un dash proche récupère 15 % de réserve | Une récupération par utilisation |
| Raccord pompier | Épique | Alimenter la bouche augmente sa prochaine onde jusqu’à ×2 | Fuite sous pression |
| Coup de bélier | Légendaire | 25 dégâts lors d’une collision contre un obstacle statique | Une touche supplémentaire par impulsion |
| Dernière tournée | Légendaire | Dernière onde à pleine puissance avant disparition | — |
| Double livraison | Légendaire | Deux bouches à 65 % de puissance, décalées de 0,6 s | Seconde bouche uniquement si un emplacement voisin est valide |
| Court-circuit | Épique | Dégâts +35 %, paralysie 0,35 s | Remplace les impulsions par la paralysie ; 0,15 s contre le boss |

Les durées, forces, intervalles et gains sont modifiables dans les Resources et dans le nœud `AmeliorationsBouche` de `attaque_bouche.tscn`. Les valeurs de base de l’attaque ne sont jamais modifiées cumulativement : les facteurs sont calculés à partir des cartes actives.

## Synergies

- **Patinoire municipale** : Jet givré + Périmètre de sécurité. Le périmètre devient une plaque de glace. Après 1,2 s de contact continu, les ennemis sont gelés ; quitter la plaque réinitialise leur progression.
- **Essorage intensif** : Marée retour + Dernière tournée. La séquence finale attire les ennemis puis les expulse. Avec Court-circuit, chaque impulsion paralyse à la place de déplacer : l’électricité reste prioritaire.
- **Circuit fermé** : Point d’appui + Raccord pompier. Alimenter la bouche prolonge sa présence, jusqu’à deux secondes supplémentaires. La récupération de mousse reste limitée à une fois par utilisation, pour éviter une boucle infinie.

Leurs Resources sont dans `scenes/systemes/ameliorations/synergies/hydrant_*.tres`. `UpgradeManager` les ajoute au catalogue de synergies de chaque mode. La détection et l’animation de fusion existantes produisent les cartes de rareté Synergie. Court-circuit + Fuite sous pression reste une combinaison naturelle, sans synergie spéciale.

## Responsabilités

- `attaque_bouche.gd` : visée, chute, collision, navigation, HUD et disparition.
- `ameliorations_bouche.gd` : calcul des paramètres, ondes, zone persistante, charge par le jet, récupération au dash, seconde bouche et électricité.
- `arcs_electriques.gd` : petits rubans 3D irréguliers sur la bouche et le long des ondes. Pas de lumière ajoutée ni simulation de fluide.
- `aspect_bouche.gdshader` : peinture bleu sombre et bande cyan lumineuse pour Court-circuit.
- `etat_mousse.gd` : état de paralysie distinct du gel et dégâts de collision après recul. Les tourelles restent immobiles.
- `zone_mousse.gd` : périmètre d’eau et gel progressif, avec exclusion des collisions des bouches dans les tests de visibilité.

Les ondes sont arrêtées par les murs et ne frappent que les ennemis de la salle active. Chaque onde peut toucher de nouveau ; il n’y a pas de liste globale de cibles déjà touchées pendant toute l’utilisation. La seconde bouche rejoint la navigation à l’atterrissage. Un changement de salle supprime bouches, zones, arcs et son.

## Son

`assets/sounds/bouche_incendie/electricite.wav` est le fichier `crackleelectricityloop.wav` de faxcorp, sous CC0 : https://opengameart.org/content/electricity-game-sound-pack . Il joue localement à −29 dB, uniquement après l’atterrissage d’une bouche électrique. Ses lecteurs appartiennent à la bouche et disparaissent avec elle.

## Test rapide

Utiliser le catalogue de cartes du menu de debug : choisir Court-circuit, puis Fuite sous pression. Tester ensuite Périmètre de sécurité et Robinet ouvert, devenus disponibles. Pour les trois synergies, sélectionner leurs ingrédients ; la dernière sélection déclenche la fusion existante. Les incompatibilités et prérequis sont également respectés par ce catalogue.

## Présentation et sensations

`presentation_bouche.tscn` et son script séparent le feedback des calculs de combat. Une courte vibration, un souffle local discret et les raccords lumineux annoncent les ondes périodiques et finales. Les raccords projettent quelques gouttes au relâchement. Raccord pompier ajoute une bande qui se remplit avec la charge ; celle-ci amplifie aussi la hauteur de l'eau projetée. Patinoire municipale ajoute du givre au métal. Périmètre de sécurité utilise `nappe_eau.gdshader`, une pellicule d'eau avec de petites ondulations.

Fonte lourde accélère davantage en fin de chute et renforce le volume d'eau et la secousse, avec un impact plus grave sans augmenter son volume sonore. Ses paramètres sont exposés dans le groupe « Fonte lourde · présentation » de l'attaque. La durée de préparation, la vibration et les gouttes se règlent dans la scène de présentation. Ces effets sont communs aux deux modes. La vibration déplace seulement le visuel : elle ne perturbe ni les collisions ni la navigation.
