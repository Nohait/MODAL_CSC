# Ensembles de décoration des étages

Les cinq nouvelles scènes se trouvent dans `scenes/decors/interieurs` :

- `coin_repas.tscn` : table avec nappe et trois chaises légèrement décalées ; étage 1.
- `coin_cuisine.tscn` : réfrigérateur et cuisinière ; étage 1.
- `poste_entretien.tscn` : chariot à outils et rayonnage avec quelques cartons ; étage 2.
- `stockage_technique.tscn` : deux rayonnages et un chariot décalé devant ; étages 2 et 3.
- `poste_electrique.tscn` : boîtier mural et rayonnage ; étage 3.

Chaque scène est un corps fixe avec un nœud `Mobilier` et une collision simple par gros objet. Les cartons placés sur les étagères sont seulement visuels, puisqu'ils restent à l'intérieur de la collision du rayonnage. Aucun nouveau comportement de combat n'est ajouté.

## Matériaux partagés

L'ancien `salon.gd` est déplacé et renommé en `mobilier_incendie.gd`, dans ce dossier. Les scènes de salon utilisent maintenant ce même script : toutes les références sont mises à jour. La logique de matériaux est inchangée, et le shader existant `mobilier_appartement.gdshader` est réutilisé. Il conserve couleur, relief, rugosité et métal, puis ajoute une carbonisation locale.

Sélectionner la racine d'un ensemble pour modifier **Brulure**, **Intensite braises**, **Taille foyer** et **Point foyer**. Ce dernier indique la position locale à laquelle le générateur ajoute son foyer décoratif. Les flammes sont ajoutées lors de la génération, elles ne sont pas directement contenues dans les scènes de mobilier.

## Choix procédural

Dans `habillage_salle.gd`, le tableau **Salons** est renommé **Ensembles appartements** : il contient les trois salons, le coin repas et le coin cuisine. Les profils `ambiance_etage_2.tres` et `ambiance_etage_3.tres` utilisent les nouveaux ensembles dans leur liste **Meubles incendies**, avec les cartons existants.

Le générateur mélange la liste propre à l'étage avec son hasard local, puis prend les ensembles successivement. Il évite donc les répétitions tant que la liste contient assez de variantes. La graine du combat n'est pas utilisée pour ce mélange.

Les ensembles restent dans une case de cinq mètres et regardent vers l'intérieur de la salle. Le placement respecte les cases réservées aux portes et aux arrivées. Une case meublée est exclue des points de spawn et au moins douze cases libres sont conservées. Les collisions sont placées sous `Navigation/Decor` pour participer aux deux maillages de navigation.

Le nombre maximal est toujours réglé avec **Nombre meubles en feu** : deux à l'étage 1, trois à l'étage 2 et deux à l'étage 3. Ce sont des coins meublés, pas une conversion de toute la salle en appartement ou atelier.

## Import de la cuisine

Le pack complet comprend de nombreux accessoires. Seuls deux modèles indépendants sont exportés : `refrigerateur.glb` et `cuisiniere.glb`, dans `assets/modeles/interieurs`. Ils gardent leurs proportions avec une échelle uniforme, et leurs textures sont limitées à 1K. Chaque salle charge ces éléments utiles plutôt que le pack entier. Les fichiers de crédits indiquent les auteurs, licences et adaptations.

## Vérification

L'aperçu a permis de vérifier les proportions et d'orienter les rayonnages vers la salle. L'audit a détecté une collision du boîtier légèrement enfoncée dans le mur : son modèle et sa collision ont été déplacés ensemble de huit centimètres vers l'intérieur. Le lot corrigé contrôle 120 salles avec les trois étages, les deux navigations et la reproduction à graine identique.

Le mode zombie et ses maps ne sont pas modifiés.
