# Vagues spéciales du mode zombie

Ces sept compositions rejoignent Meute, Siège et Embuscade dans le même tirage.
Le mode classique ne déclenche aucun de ces événements.

## Équilibrage

Dans `scenes/modes/zombie/equilibrage/difficulte_zombie.tres`, **Probabilité vague spéciale** reste à 0,35 : 65 % de classiques, 35 % de spéciales quand elles sont disponibles. Les vagues de boss restent prioritaires, toutes les dix vagues.

Le **Poids** détermine ensuite la part de chaque composition dans ces 35 %. Les anciennes compositions gardent leur poids de 3, contre 1 pour la plupart des nouveaux événements. La vague dorée pèse seulement 0,25. À partir de la vague 7, hors boss et mutation déjà active, elle représente environ 0,60 % des vagues.

Ouvrir les `.tres` du dossier `scenes/modes/zombie/equilibrage/compositions` dans l'Inspecteur pour modifier leur première vague, leur poids et leur durée. Les nouveaux types réutilisent la composition classique et ses limites par ennemi.

| Vague | Dès la vague | Poids | Effet |
| --- | ---: | ---: | --- |
| Blackout | 3 | 1 | Soleil et appliques à 12 % pendant 20 s ; lumière de secours autour du pompier. Les feux restent lumineux. |
| Double Horde | 5 | 1 | Budget mobile ×2, sans dépasser les limites par type ni les emplacements disponibles. Les tourelles restent limitées à deux. |
| Brouillard | 4 | 1 | Brouillard jusqu'à la fin de la vague. |
| Chaleur extrême | 5 | 1 | Consommation de mousse ×1,5 jusqu'à la fin de la vague. |
| Panne de mousse | 5 | 0,7 | Jet interrompu et inutilisable pendant 6 s. La charge reste conservée et peut se recharger. |
| Vague dorée | 4 | 0,25 | Tous les ennemis apparus ont un matériau doré et donnent ×5 leur butin habituel. |
| Mutation générale | 7 | 0,7 | Même trait d'élite pour tous les mobiles pendant 60 s de jeu, y compris ceux qui apparaissent ensuite. |

Double Horde double un **budget**, pas nécessairement le nombre exact de corps : les ennemis n'ont pas tous le même coût, et les limites habituelles restent appliquées.

## Déroulement

`vagues_zombie.gd` tire la composition au démarrage puis appelle `EvenementsVague.commencer()`. Le gestionnaire applique son effet et affiche une grande annonce avec la police du jeu. Le texte apparaît, reste 2,8 s puis disparaît en fondu. Meute, Siège, Embuscade et le mini-boss profitent aussi de l'annonce.

`scenes/modes/zombie/evenements/evenements_vague.tscn` est ajouté uniquement par `mode_zombie.gd`. Son script sauvegarde les réglages lumineux avant de les modifier, puis les rétablit à la fin de l'effet. Les paramètres de mousse temporaires sont séparés des améliorations.

La pause suspend les durées. Une mutation ne s'arrête pas simplement parce que la vague est terminée : elle peut couvrir le début de la suivante. Aucun nouvel événement aléatoire ne s'y superpose ; les vagues de boss restent possibles. Au bout de 60 s, chaque survivant retrouve son trait initial et conserve sa proportion de PV. Les tourelles et les flaques ne sont pas des zombies mobiles : leurs traits de vitesse n'auraient aucun effet, elles ne mutent donc pas.

Le signal `CatalogueEnnemis.ennemi_enregistre` applique la version dorée ou la mutation aux nouveaux ennemis après leur préparation et leur éventuel tirage d'élite. Les figurants d'arrivée sont dorés eux aussi.

## Versions dorées et pièces

`scenes/systemes/ennemis/ennemi_dore.gd` remplace les matériaux des modèles par le shader métallique `ennemi_dore.gdshader`, et colore leurs particules de feu en or. Les flaques conservent leur shader et leur transparence, avec des couleurs dorées.

La version dorée est indépendante du trait d'élite. Un ennemi normal qui vaut 3 points lâche 15 pièces ; une élite dorée de ce même type lâche 30 pièces (3 ×2 ×5). `monnaie.gd` utilise le composant `Dore` pour ce calcul au moment de la mort.

Le glossaire propose une version **Dorée** pour chacun des huit types. Elle reste masquée tant qu'elle n'a pas été rencontrée ; le bouton de debug « Tout débloquer » l'inclut également.

Pour tester un type de vague sans attendre son tirage : appuyer sur **I**, puis **Choisir une vague…**, et cliquer sur le type souhaité. Le menu se ferme et remplace la vague actuelle par cette composition. Si elle n'est pas encore disponible au numéro actuel, le debug avance à sa première vague autorisée. Le joueur, ses améliorations et le refuge restent conservés ; les ennemis, captives et apparitions de la vague précédente sont remplacés.

`debug_zombie.gd` construit la liste depuis les ressources de difficulté, y compris la classique et le mini-boss. `aller_vague_debug(numero, composition_forcee)` impose ce choix uniquement pour ce lancement : les probabilités habituelles restent intactes pour les vagues suivantes. Le sous-menu `choix_vagues.tscn` reprend les couleurs du debug et permet de revenir avec Échap ou le bouton Retour.
