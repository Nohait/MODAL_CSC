# Difficulté des salles

Les PV restent fixes. Le RoomManager augmente la population et la taille maximale des vagues.

Dans main, sélectionner Salles/RoomManager. « Population des salles » donne les quantités de départ. « Progression de la population » règle les ajouts par salle, le saut entre étages, les ajouts de tourelles/flaques et la limite des vagues.

Avec les valeurs actuelles, les mobiles sont 2–3 à la première salle, puis un de plus par salle. Chaque nouvel étage reprend la difficulté de la dernière salle précédente et ajoute 3 mobiles : étage 2 commence à 9–10 et étage 3 à 16–17. Les vagues passent de 1 ennemi maximum à 2 en salle 3, puis 3 en salle 5. L’étage 2 commence à 4 ; la limite est 5.

Chaque racine de scène d’ennemi expose « Apparition » : premier_etage et premiere_salle. Le numéro de salle est local à l’étage (1 à 5). Un seuil étage 1 / salle 3 autorise les salles 3 à 5 de l’étage 1, puis toutes les salles suivantes. Le sbire et la flaque commencent à 1 / 1 ; la tourelle à 1 / 3. Disponibilité ne veut pas dire apparition garantie : la quantité reste tirée aléatoirement.

RoomManager.ennemi_autorise() lit les valeurs de la scène une fois, puis conserve le seuil dans un dictionnaire. Le peuplement applique ce filtre avant de réserver les positions et de compter les ennemis. Chaque salle mémorise son numero_dans_etage, car toutes les salles sont générées au début de la partie.

Les emplacements libres limitent toujours la quantité réelle. Le timer conserve sa durée aléatoire de 15 à 30 secondes, avec la dernière vague à son terme. Les défis continuent à ajouter leurs ennemis à la population prévue. Les projectiles d’une tourelle existante continuent à produire leurs flaques : le seuil de flaque concerne la population initiale.

Pour un nouveau type, ajouter les deux paramètres d’apparition à son script et utiliser ennemi_autorise() dans son chemin de génération. Le système ne découvre pas automatiquement de nouvelles scènes d’ennemis.
