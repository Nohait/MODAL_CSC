# Nouvelles cartes et combos

31 cartes rejoignent le catalogue existant. Elles ont pour cette première version un effet fixe, une rareté propre et une seule acquisition possible par partie. Les boosters conservent leurs probabilités de rareté. Les 24 premières sont disponibles dans les deux modes ; les 7 cartes d'équipement sont réservées au zombie.

## Où modifier les cartes

Dans Godot, ouvrir `scenes/systemes/ameliorations/cartes/<identifiant>.tres`. L'Inspecteur permet de modifier le titre, la description, le pictogramme, la rareté, la valeur, les modes et les prérequis. `catalogue_ameliorations.tres` contient la liste commune.

Les descriptions restent courtes. Le champ Texte effet affiche la valeur avec son unité ; `%s` reçoit la valeur et `%%` affiche un pourcentage. Un texte sans `%s` fonctionne aussi, par exemple « Deux jets ».

Pour créer une variante sans nouveau code, dupliquer une ressource, changer son identifiant mais garder son champ Effet, puis l'ajouter au catalogue. Les comportements lisent les valeurs regroupées par effet : deux cartes différentes peuvent donc partager un comportement. Les prérequis et l'obtention unique continuent d'utiliser l'identifiant propre de chaque carte.

Un prérequis contient l'identifiant d'une autre carte, par exemple `jet_givre` pour `gel_profond`. Tous les prérequis doivent avoir été achetés avant que la carte puisse sortir d'un booster. L'historique reste valable après l'expiration d'un bouclier. Le catalogue debug montre les cartes verrouillées et les prérequis manquants ; acheter ceux-ci, puis rouvrir le catalogue pour choisir la suite.

## Ce qui a été raccordé

- `upgrade_manager.gd` garde les acquisitions et les tirages. Il filtre les prérequis, recalcule les statistiques et reçoit les débuts/fins de salle ou de vague.
- `effets_cartes.gd`, ajouté comme enfant du joueur, réagit au dash, aux sauvetages et aux équipements. Ses délais utilisent le temps du jeu : une pause les suspend.
- `etat_mousse.gd` est ajouté à un ennemi lorsqu'une amélioration l'affecte. Il mémorise l'enrobage, le gel profond et le recul, et écoute son signal `died` pour les effets de mort.
- `zone_mousse.gd` représente une plaque au sol. Son Area3D détecte les ennemis et les victimes. Les effets sont appliqués toutes les 0,25 seconde et ne traversent pas les murs. Le dessin et la collision grandissent ensemble. Les plaques appartiennent à la salle et sont retirées à la fin de l'étape.
- `zone_mousse.gdshader` donne au plan une bordure irrégulière et de petites bulles. La couleur devient bleue pour la glace ; le script réduit l'opacité avant la disparition. Ce shader ne calcule aucun dégât.

L'extincteur transmet aussi la durée de contact avec une cible. Les ennemis acceptent une source de dégâts facultative : `mousse`, `eau` ou `feu`. Le joueur et les victimes passent par les protections avant de perdre leurs PV. Les sprinklers et l'extincteur mural préviennent le gestionnaire quand ils sont utilisés.

## Jet et mousse

| Carte | Rareté | Effet initial | Prérequis |
|---|---|---|---|
| Choc thermique | Légendaire | Un ennemi refroidi qui meurt provoque une explosion de 25 dégâts dans 2,5 m, réservée aux ennemis proches. | Jet givré |
| Verglas | Rare | Plaques froides de 4 s ; ralentissement de 20 %. | Jet givré |
| Gel profond | Épique | Après 1,2 s de jet continu, immobilisation de 0,6 s ; délai de 5 s entre deux gels. | Jet givré |
| Éclats de glace | Épique | Mort pendant le gel profond : explosion de 25 dégâts dans 2,5 m. | Gel profond |
| Brise-glace | Rare | Un dash au contact d'un ennemi refroidi inflige 30 dégâts et retire son ralentissement. | Jet givré |
| Mousse persistante | Rare | Plaques de 4 s, 8 dégâts/s. | — |
| Mousse expansive | Rare | Le rayon des plaques double progressivement en 2 s. | Mousse persistante |
| Enrobage | Rare | Après 0,8 s de jet continu, la cible reçoit 25 % de dégâts supplémentaires pendant 3 s. | — |
| Réaction en chaîne | Légendaire | Une cible enrobée qui meurt enrobe les ennemis visibles dans 3 m. | Enrobage |
| Jet pulsé | Rare | Impulsions de 0,22 s toutes les 0,6 s, avec 80 % de dégâts supplémentaires par impact. | — |
| Double lance | Épique | Deux jets étroits autour de la visée, avec un espace central. | — |
| Surpression | Rare | Jusqu'à 30 % de dégâts supplémentaires selon la proportion de mousse restante. | — |

Le jet pulsé maintient `is_attacking` tant que le bouton est tenu. `emission_effective` distingue une impulsion du creux qui suit : la charge n'est consommée que pendant l'émission, mais la recharge reste bloquée pendant le tir maintenu. Chaque impulsion a sa portion de jet, qui continue d'avancer après son émission.

Double lance duplique seulement les particules. Les deux directions et les deux secteurs de dégâts utilisent le même angle. L'indicateur de debug montre aussi l'espace central ; une cible suffisamment large peut toucher le bord d'un jet.

## Dash et victimes

| Carte | Rareté | Effet initial | Prérequis |
|---|---|---|---|
| Sillage de secours | Rare | Le dash laisse des plaques de 3 s, 8 dégâts/s. | — |
| Départ sous pression | Rare | +40 % de dégâts du jet pendant 1,5 s après le début du dash. | — |
| Freinage d'urgence | Rare | Une onde repousse les ennemis dans 2,8 m à la fin du dash. | — |
| Deuxième souffle | Rare | Un ennemi tué dans les 1,5 s après le dash retire 30 % du délai de recharge du dash. | — |
| Intervention éclair | Épique | Le trajet du dash libère les victimes à moins de 1,6 m. | — |
| Retour de pression | Rare | Quand le dernier PV du bouclier du joueur disparaît, une onde repousse les ennemis dans 3 m. | Mousse protectrice |
| Formation serrée | Rare | Une victime escortée près d'une autre victime escortée reçoit 20 % de dégâts en moins. | — |
| Passage sécurisé | Rare | Traverser la mousse donne un bouclier de 10 PV, prolongé jusqu'à 3 s après la sortie. Délai de 5 s avant un nouveau bouclier. | Mousse persistante |
| Priorité aux blessés | Rare | Redistribue les soins réels à la victime avec le moins de PV, puis aux suivantes. | — |
| Courage contagieux | Commun | Une libération donne +20 % de vitesse au joueur et à son escorte pendant 3 s. | — |
| Équipe de soutien | Rare | +3 % de recharge par victime protégée, plafonné à +30 %. Le zombie compte aussi les occupants du camion. | — |
| Extraction d'urgence | Légendaire | Une victime escortée qui recevrait un coup fatal revient à la position du joueur avec 1 PV, une fois par victime. | — |

Le combo **Jet givré + Sillage de secours** se déclenche automatiquement : la traînée devient bleue et ralentit les ennemis de 20 %. Il n'existe pas de carte Percée glaciale, et la boutique ne décrit pas ce combo.

Le recul passe par `move_and_collide`, donc les ennemis ne sont pas téléportés à travers les murs. Intervention éclair vérifie le segment parcouru entre deux images : un dash rapide ne saute pas la détection d'une victime.

### Exemple de Priorité aux blessés

Trois victimes ont 10, 80 et 100 PV sur 100. Un soin de 25 PV aurait réellement donné 25 + 20 + 0 = **45 PV**. La carte donne ces 45 PV à la première victime : elles terminent à **55, 80 et 100 PV**.

Si cette première victime atteint son maximum, le surplus va à la prochaine la plus faible. Le calcul trie une copie de la liste : il conserve l'ordre de suivi et, surtout, la dernière victime attaquable du camion. La carte ne crée pas de soin supplémentaire et ne ressuscite pas les victimes.

## Équipements du mode zombie

| Carte | Rareté | Effet initial | Prérequis |
|---|---|---|---|
| Circuit de secours | Rare | Deux déclenchements par activation en boutique, séparés par 5 s de réarmement. | — |
| Eau glacée | Rare | L'eau ralentit de 20 % les ennemis touchés pendant 1 s. | Jet givré |
| Réseau interconnecté | Rare | Un sprinkler déclenché donne +30 % de dégâts aux autres pendant 5 s. | — |
| Réserve collective | Rare | Un plein mural soigne les occupants du camion de 10 PV chacun ; compatible avec Priorité aux blessés. | — |
| Zone de repli | Rare | Rupture du bouclier du camion : un cercle protecteur de 5 m pendant 3 s, −30 % de dégâts pour le camion et le joueur dans ce cercle. | Protection d'urgence |
| Gyrophare d'intervention | Rare | Les ennemis attirés par la sirène reçoivent 25 % de dégâts supplémentaires. | Sirène de diversion |
| Maintenance préventive | Épique | À la fin d'une vague, recharge gratuitement un équipement utilisé et inactif, choisi au hasard. | — |

Les équipements ne changent pas de prix. Maintenance ne paie rien, ne recharge qu'un objet, et n'arme pas un sprinkler jamais utilisé. Le deuxième déclenchement de Circuit reste réservé pendant son réarmement : la boutique ne le revend pas entre les deux jets.

Les valeurs chiffrées des cartes sont dans leurs ressources. Les rayons, seuils de contact et délais communs de cette première version sont dans les trois scripts d'effets. Ils pourront être exposés dans les ressources si les tests montrent le besoin de les régler souvent.


## Choc thermique et légendaires

Choc thermique fonctionne avec le ralentissement de Jet givré : Gel profond n'est pas nécessaire. Il n'a plus de lien avec les flaques de feu. Éclats de glace ajoute ses 25 dégâts si l'ennemi meurt pendant son immobilisation : les deux cartes produisent une seule explosion de 50 dégâts. Le joueur, les victimes et le camion sont exclus des cibles. Un kamikaze refroidi déclenche cependant aussi son explosion habituelle, dangereuse pour les alliés, une seule fois.

Le booster légendaire coûte 5 points : ses poids sont 20 % rares, 50 % épiques et 30 % légendaires avant redistribution selon le pool disponible. Les trois premières légendaires sont Choc thermique, Réaction en chaîne et Extraction d'urgence. Elles sont dorées, fixes, uniques et disponibles dans les deux modes. Le booster est grisé et l'achat est refusé sans paiement si aucune légendaire n'est disponible.
