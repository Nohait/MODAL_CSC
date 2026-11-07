# Playlist adaptative du classique et du zombie

Dans mode_zombie.gd, Playlist musicale contient les Resources de audio/morceaux. Chaque morceau contient des CoucheMusicaleZombie : fichier audio, volume, nombre minimum d’ennemis, vague minimum, activation élite/boss et filtres éventuels. Ajouter un morceau consiste à créer une Resource MorceauMusicalZombie et à l’ajouter à cette liste. La durée vaut par défaut la longueur de sa piste la plus longue.

Le lecteur commun `scenes/systemes/audio/playlist_adaptative.gd` mélange la liste une fois au lancement avec son propre générateur aléatoire, sans modifier la génération du gameplay. Les cycles suivants répètent ce même ordre. Deux lecteurs permettent un fondu entre morceaux. Chaque lecteur contient un AudioStreamSynchronized : tous ses instruments partagent la même position, même s’ils sont inaudibles. Les Resources historiques gardent leurs noms et chemins pour préserver les références existantes.

À la fin de vague, le volume principal descend, puis stream_paused fige tous les instruments exactement à la fin du fondu. Ils reprennent ensemble au retour au combat. Le morceau suivant démarre avant la fin du précédent pour assurer la transition. Cette progression musicale est conservée pendant la partie ouverte, pas dans la sauvegarde de partie sur disque. Les stems ne bouclent plus individuellement.

`musique_zombie.gd` continue à gérer la boutique et son fondu. L’adaptateur `couches_dynamiques.gd` transmet au lecteur partagé la vague, les ennemis et l’événement. L’introduction du Hall démarre le socle du morceau choisi, sans attendre la première vague.

## Mode classique et tutoriel

Dans `main.tscn`, le nœud `MusiqueClassique` utilise la même playlist. Son script `scenes/systemes/audio/musique_classique.gd` remplace les changements de volume autrefois placés dans RoomManager. Les volumes passent tous par le bus Musique.

L’Inspector expose `intensite_par_etage` (par défaut 0, 4, 8) : un plancher de nombre d’ennemis équivalent, comparé au nombre d’ennemis réellement vivants. Ainsi les étages avancés gardent davantage d’instruments même quand la salle se vide. Les flaques ne comptent pas. Le palier musical vaut 1 + (étage - 1) × `paliers_par_etage` (5 par défaut), soit 1, 6 et 11 ; il sert aux conditions historiquement nommées `vague_minimum`. Élites et boss activent toujours les couches prévues par les Resources. Une reprise à l’étage 2 ou 3 utilise directement le bon étage.

À la libération d’une salle, le combat s’efface en fondu, sa position est conservée et Cipher accompagne l’accalmie et la boutique. La salle suivante reprend le morceau de combat à cette position. Une pause ordinaire atténue puis suspend le combat. L’ordre et la position restent en mémoire pendant la partie ouverte ; ils ne sont pas enregistrés sur disque.

Pour le tutoriel, `scenes/modes/tutoriel/commun/musique_tutoriel.gd` joue uniquement les percussions d’Assault, en boucle. Ce lecteur survit aux changements de salles, continue pendant les dialogues et boutiques, puis disparaît au retour au titre ou au départ en classique. Le contrôleur classique reste inactif en zombie : aucun double lecteur de combat.

## Ordre des couches
Les nombres indiquent les ennemis vivants nécessaires. Une baisse du danger retire les couches progressivement. Un boss active toutes les couches ; une élite active les couches marquées ci-dessous.

- Assault : guitares dès le départ, cordes à 4, percussions à 7, synthés à la vague 8 ou avec une élite.
- Unfed : guitare principale et basse dès le départ, batterie à 4, seconde guitare à 9 ou avec une élite.
- Sin Town : guitare métal et basse dès le départ ; batterie et guitare claire à 4 ; guitare Crunchy à 7 ; Mesa Boogie à 9 ; solo et synthé à 12. Les trois dernières couches peuvent aussi être activées par une élite.
- Rescue Mission : cordes, piano et nappes/synthés dès le départ ; bois et percussions à 4 ; percussions mélodiques à 7 ; cuivres à 9 ; orchestre synthétique et montées à 12 ; impacts et sound design à 15. À partir des cuivres, une élite peut aussi activer les couches.

Ces seuils commandent le volume, pas les notes jouées : si l’instrument a un silence écrit dans son fichier, il conserve ce silence. Les arrangements restent ceux des compositeurs. Les volumes et seuils restent ajustables dans l’Inspector.

Voir assets/sounds/musique/zombie/credits.md pour les licences.

## Points de départ
Les stems contiennent des silences prévus par leur arrangement. Pour entendre le socle dès le début du combat, Début lecture démarre Unfed à 16,5 s, Sin Town à 16,1 s et Rescue Mission à 8,8 s. Assault commence à 0. Tous les instruments reçoivent le même décalage ; leur synchronisation reste intacte. Ces positions sont réglables dans chaque Resource de morceau.
