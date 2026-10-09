# Entrées habitées et ambiances classiques

## Décor

`scenes/decors/interieurs/porte_manteau_noir.tscn` et `porte_manteau_chapeau.tscn` contiennent un modèle importé et une collision simple. Leur hauteur est de 1,75 m. Les scènes font référence aux assets originaux, sans recopier toute la géométrie dans le texte de la scène.

`tapis_use.tscn` utilise une très fine boîte et le matériau `assets/materiaux/tapis_use.tres`. Ce matériau combine couleur, normale OpenGL pour le relief et rugosité. Le tapis n'a pas de collision. Il repose au-dessus du sol dont le dessus est à Y = 0,10 m.

Dans `habillage_salle.gd`, `_habiller_entree()` ajoute ces détails après le placement d'une porte condamnée. Les porte-manteaux alternent entre les deux modèles ; leur présence et celle des tapis sont tirées avec le hasard propre au décor. Les tapis reçoivent un petit décalage et une rotation. Aucun tapis n'est ajouté devant le buffet de la porte barricadée.

Les porte-manteaux restent dans la case déjà réservée à la porte et sont ajoutés sous `Navigation/Decor`. Ils ne deviennent pas des emplacements d'apparition de personnages.

Dans `habillage_classique.tres`, les paramètres `Porte manteaux`, `Chance porte manteau` et `Chance tapis` permettent de régler le contenu. Une chance de 0,70 signifie 70 % par porte, pas un nombre garanti par salle.

## Sons

Les listes `Sons etage 1`, `Sons etage 2` et `Sons etage 3` de la même ressource définissent les profils à installer. `_sonoriser()` crée les sources dans chaque salle et privilégie le poste électrique au dernier étage lorsqu'il existe.

- Étage 1 : communications radio déjà présentes, avec un profil indépendant, espacées de 35 à 75 secondes.
- Étage 2 : chute de débris localisée près d'un mur, espacée de 40 à 85 secondes.
- Étage 3 : trois extraits d'étincelles de 2,3 secondes, espacés de 18 à 38 secondes.

Le délai initial est également tiré dans cet intervalle. Ce ne sont pas des sons continus : traverser rapidement une salle peut donc ne déclencher aucun passage. Les volumes et portées sont réglables dans `scenes/systemes/audio/profils/*_classique.tres`.

`coordination_ambiances.gd` est un composant commun, installé ici dans le décor classique. Il utilise les enfants `AmbianceLocale` et n'autorise qu'un passage ponctuel à la fois, puis douze secondes de silence minimum. Chaque source garde ses propres délais aléatoires. Il surveille la visibilité de la salle et la pause : les sons s'éteignent en fondu, et les horloges ne progressent pas pendant la boutique ou dans les salles inactives. Il ne remplace pas le gestionnaire existant du mode zombie.

`ambiance_locale.gd` reste responsable du lecteur `AudioStreamPlayer3D`, du choix du fichier, du volume et des fondus. Les sons sont localisés : la distance et la direction du joueur comptent. Le hasard sonore ne modifie pas les graines de génération ou de combat.

Pour essayer rapidement un profil, régler temporairement ses deux délais à une ou deux secondes, puis lancer une salle du bon étage. Restaurer ensuite les délais indiqués ci-dessus.

## Vérification

120 salles sur les trois étages contrôlées sans problème de collision ou de navigation. Aperçu des deux modèles et des tapis vérifié. Contrôle de l'exclusivité sonore, de l'arrêt en fondu pendant la pause et de l'arrêt dans une salle masquée réussi. Les volumes restent à apprécier à l'oreille avec la musique en jeu.
