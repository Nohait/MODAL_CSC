# Vérification des salles procédurales

Cet outil est une scène de travail indépendante. Aucun menu du jeu ne l'appelle. Il ne modifie ni le générateur, ni les règles de combat, ni les sauvegardes de partie. Les portes ouvertes et les défauts volontaires de l'autocontrôle concernent uniquement ses instances temporaires.

## Les fichiers

- `outils/validation/audit_generation.tscn` : scène à ouvrir puis lancer avec F6. Sélectionner sa racine pour régler le nombre de salles, les tailles, la première graine et le gabarit de personnage dans l'Inspector.
- `audit_generation.gd` : organise les essais, appelle le véritable générateur, cuit les deux navigations et écrit le rapport. Il détruit chaque salle avant de passer à la suivante.
- `controle_geometrie.gd` : compare les volumes de collision des meubles aux murs et aux autres meubles. Il tient compte des rotations et vérifie que les meubles restent sur le sol de la grille.
- `controle_passages.gd` : place une capsule virtuelle aux points d'arrivée, aux points de spawn et dans les passages des portes. Il demande aussi des chemins sur les navigations des victimes et des ennemis.

## Comment les essais fonctionnent

Chaque cas possède une graine, une taille, un étage, un nombre d'arrivants et les indicateurs de début/fin d'étage. Le test alterne de petites et grandes salles, les trois étages et des escortes de 10 ou 62 arrivants avec les réglages par défaut.

La même salle est générée une seconde fois à graine identique. Le test compare la grille, les points d'arrivée et de spawn, ainsi que les scènes et transformations du décor et des portes. Il ignore les noms automatiques de Godot, qui changent entre instances.

Après cuisson, Godot doit synchroniser la navigation avant que les chemins puissent être interrogés. L'outil attend cette synchronisation et utilise deux cartes indépendantes par essai, alimentées par les vrais maillages cuits. Cela évite qu'une ancienne salle ou une interrogation prématurée produise de fausses alertes.

Un chemin non vide ne suffit pas : ses extrémités doivent réellement atteindre le départ et la cible, avec une tolérance horizontale de 70 cm. Le test vérifie également la présence de sorties, le nombre de points d'arrivée et l'absence de collisions sur les petits gravats.

## Rapport et reproduction

Par défaut, le rapport JSON est écrit dans `user://audit_generation/rapport.json`, séparément des sauvegardes. Godot permet d'ouvrir ce dossier via son menu « Ouvrir le dossier des données utilisateur ». Chaque cas conserve ses paramètres et les éventuelles alertes avec leur position.

Pour rejouer un cas, renseigner **Fichier reproduction** et **Indice cas** dans la racine de la scène, puis lancer F6. L'indice commence à zéro. Le rapport de ce nouvel essai remplace le précédent dans le dossier de sortie : conserver une copie du rapport initial si nécessaire.

En ligne de commande, les arguments après `--` permettent aussi de régler `--nombre=300`, `--graine=810300`, `--rapport=chemin`, ou de rejouer `--reproduire=rapport.json --cas=49`.

L'option `--autocontrole` ajoute volontairement des meubles superposés dans un mur, un obstacle sur un point de spawn et un mur fermant l'entrée. Le test doit détecter ces quatre défauts. Ils ne sont jamais enregistrés dans une scène du jeu.

## Résultats du 8 octobre 2026

- Premier lot : graines 810000 à 810299, 300 salles, aucune alerte géométrique ou de navigation.
- Lot final : graines 810300 à 810599, 300 salles, aucune alerte ; contrôle supplémentaire de tous les chemins d'arrivée et comparaison de chaque salle avec sa régénération à graine identique.
- Autocontrôle : les quatre défauts volontairement introduits sont détectés.
- Reproduction du cas 49 du lot final : aucune alerte.
- Import et analyse du projet par Godot 4.7.2 : terminés sans erreur.

Ces résultats n'ont nécessité aucune modification du code de génération utilisé en partie.

## Limites des contrôles

Ce contrôle porte sur la géométrie statique générée et les chemins disponibles. Il ne simule pas les combats, la fuite des victimes, les foules, ni l'ajout ultérieur de tourelles et de flaques. Il compare des volumes de collision, pas les détails visuels des modèles. Il ne garantit donc pas qu'aucun bug ne puisse exister avec une autre graine ou pendant une partie.
