# Explosion de la voiture du Hall

Cet événement est propre au mode zombie et à la map Hall. Il n'inflige pas de dégâts.

## Déclenchement

`scenes/modes/zombie/evenements/paliers/hall_explosion_voiture.tres` est un palier de l'ArenaEventManager : à la vague 10, il appelle `declencher()` sur le nœud `ExplosionVoiture` du Hall. Le mini-boss conserve son fonctionnement habituel.

`scenes/modes/zombie/evenements/explosion_voiture.gd` installe d'abord une berline sous les flammes de la voiture extérieure. Il duplique ses matériaux pour ne pas modifier les voitures du Parking. Lors de l'événement, il lance l'effet puis remplace la berline par la carcasse pendant l'explosion. Un garde-fou empêche de déclencher l'événement deux fois. Le signal `remplacement_demande` de l'effet déclenche simultanément le changement de modèle et le retour des flammes persistantes. Il utilise la même horloge que le volume, même si une image prend plus de temps à calculer.

La sauvegarde conserve les paliers réalisés. Lors d'une reprise après cet événement, `restaurer_palier()` montre directement la carcasse, sans explosion ni son. Reprendre au début de la vague 10 rejoue normalement l'événement si le point de reprise précède son déclenchement.

## Effet et son

`scenes/effets/combat/explosion_essence.gd` combine la simulation volumétrique CC0 de JangaFX, des débris, une lumière orange et un son local. La version détaillée conserve 48 textures 3D de 128 × 128 × 128 voxels, dans `assets/textures/effets/explosion_essence/volumes_hd/`. Les 32 volumes de 64³ du dossier `volumes/` restent utilisés avec le profil graphique économique. Le canal rouge conserve la densité de fumée et le vert les flammes. En HD, les valeurs sont encodées en racine carrée puis décodées dans le shader pour préserver les nuances de faible densité. Le cadrage est constant entre les instants et plus serré que dans la version légère. Ce sont des volumes, pas des images de l'explosion.

`assets/shaders/effets/explosion_volume.gdshader` traverse ces volumes selon la direction de vue : il additionne la lumière des flammes et l'opacité de la fumée le long de chaque rayon. Il s'arrête lorsqu'un objet du décor masque le volume. Un cube invisible délimite la simulation ; aucun plan ne tourne vers la caméra. Le script interpole deux instants de la simulation pour adoucir l'animation.

Les volumes sont chargés au démarrage du Hall et partagés entre les effets. La version détaillée occupe environ 192 Mio de textures en mémoire graphique, la version légère environ 32 Mio. Les textures HD utilisent seulement deux canaux, sans les canaux inutiles de la première conversion. Le nombre de pas du shader règle le compromis entre précision et coût du rendu. La densité, la luminosité et les ombres internes sont également exportées dans le script de l'effet. La fumée atténue la lumière ; les zones les plus chaudes deviennent jaune clair. La dispersion initiale utilise une copie élargie et raccourcie des mêmes volutes, plutôt qu'une sphère artificielle.

Le son est la première explosion du fichier « Beefy explosions » de SamsterBirdies, raccourcie à 3,5 secondes et convertie en mono pour la spatialisation. Les crédits et licences sont rangés avec les assets.

Le joueur reçoit une secousse via sa fonction partagée `secouer_camera(force, duree)`. L'amplitude décroît et la caméra revient à sa position initiale. Son hasard utilise un générateur séparé de celui des vagues.

## Réglages et test

Dans `hall.tscn`, sélectionner `ExplosionVoiture` pour régler la taille de l'effet, le volume, la portée sonore, l'instant du remplacement et la secousse. La haute définition, la précision du rendu, la densité et la luminosité de l'explosion y sont également réglables. Le profil économique impose les volumes légers et au plus 40 pas par rayon. Le numéro de vague se règle dans la ressource du palier.

Pour tester : lancer le Hall, ouvrir le debug avec I puis choisir « Vague 10 ». Le Parking et le mode classique ne déclenchent pas cet événement.




