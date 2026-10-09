# Mobilier des pièces inaccessibles

Les dix meubles Poly Haven sont dans `assets/modeles/appartements`. Leurs sources et leur licence CC0 sont conservées dans `CREDITS_nouveaux_meubles.md`.

Les huit compositions sont des Resources dans `scenes/decors/interieurs/compositions` : chambre, chambre avec fauteuil de lecture, salon ancien, salon avec fauteuils, bureau, bureau partagé, coin repas et réserve.

Pour modifier une composition, ouvrir son `.tres` dans l'Inspector. Chaque indice correspond au même meuble dans les listes Modèles, Positions, Hauteurs et Orientations. La hauteur est en mètres, l'orientation en degrés. Les positions sont relatives à la composition : un appareil posé sur un buffet possède donc une hauteur positive. Le modèle conserve ses proportions.

`composition_mobilier.gd` construit les meubles et mesure leur volume réel. `amenagement_piece.gd` choisit une composition, la tourne d'un quart de tour aléatoire, puis vérifie son encombrement. Il autorise une réduction uniforme de 20 % au maximum et essaie d'autres compositions si nécessaire. Les espaces trop petits pour tous les ensembles restent sans grand mobilier. Les grands espaces peuvent accueillir deux ensembles. Une marge évite de coller les meubles aux limites de la pièce ; le jeu restant permet de décaler leur position.

La liste utilisée est exposée dans `scenes/salles/amenagement_pieces.tres`. Dupliquer une composition puis l'ajouter à cette liste permet d'étendre le catalogue sans modifier la logique. Les objets abandonnés et la marge de placement sont également réglables.

Ce mobilier concerne uniquement les espaces inaccessibles du mode classique. Il ne possède pas de collisions actives et conserve le traitement visuel sombre commun à ces espaces. `ensemble_mobilier.gd` indique un point d'incendie sur le premier meuble, en respectant le budget de foyers existant de l'enveloppe du bâtiment.

Les passages des cloisons reçoivent une `porte_cloison.tscn`, dérivée de la porte décorative existante. Le fond noir, les braises, la fumée, la lumière et la collision y sont désactivés : on voit les véritables pièces de part et d'autre. Le générateur réserve une ouverture de 1,8 m, place la porte sur la cloison et complète le mur au-dessus. L'ouverture du battant varie de zéro à `ouverture_portes_max`, réglable dans l'enveloppe du bâtiment. Les espaces volontairement ouverts restent sans cloison ni porte.
