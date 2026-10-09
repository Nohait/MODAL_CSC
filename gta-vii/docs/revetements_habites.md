# Habillage des appartements

Les textures se trouvent dans `assets/textures/decors/appartements` et les matériaux dans `assets/materiaux/appartements`. Les cartes EXR ont été converties en PNG, car leur compression n'était pas reconnue par Godot. Les sources EXR et Blender restent dans `assets/sources/appartements`, ignoré par l'import grâce à `.gdignore`. Les modèles de cadres et d'horloges restent en glTF. Six livres ont été exportés en un petit ensemble GLB depuis le fichier Blender téléchargé.

Les compositions ont maintenant un champ **Sol** : parquet droit pour les chambres et bureaux, parquet à chevrons pour le salon ancien et le coin lecture, carrelage pour le coin repas et la réserve. Les cadres et livres sont ajoutés aux listes de modèles existantes, avec leurs positions et hauteurs. Les sols conservent le traitement sombre des pièces inaccessibles.

`finitions_habitees.gd` construit les cloisons peintes ou tapissées, leurs plinthes et quelques horloges. Ses paramètres sont dans `scenes/salles/finitions_habitees.tres`, accessible depuis **RoomGenerator → Habillage → Bâtiment → Finitions**. Les trois teintes d'étage distinguent une peinture chaude, une peinture plus froide et une peinture grisée. Les papiers peints sont des motifs mats sans faux relief prononcé.

Les foyers existants conservent leur limite par salle. Une petite trace de suie est placée au sol près de chacun, avec une orientation et une taille variables ; les incendies ne recouvrent pas toutes les surfaces. La sélection aléatoire utilise toujours le générateur de décor indépendant du combat et reste reproductible à graine identique.

Dans `ville_etage.gd`, certains matériaux `MI_FakeInterior` des modèles d'immeubles deviennent émissifs. L'émission reprend leur texture pour conserver les détails des fenêtres. Au maximum deux petits foyers occupent de véritables surfaces de fenêtre du modèle ; ils n'ajoutent aucune lumière locale ni son audible. Les réglages **Intensité fenêtres éclairées** et **Incendies extérieurs** figurent dans `exterieur_etage_1.tres`, profil commun de la ville. Le déplacement vertical de cette ville entre étages reste inchangé.
