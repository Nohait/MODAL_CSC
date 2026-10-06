# Retours visuels et sonores

- `scenes/systemes/monnaie/monnaie.gd` : rebond doré du compteur à la collecte. Les pièces rapprochées font légèrement monter la hauteur du son existant (plafonnée à 1,25) et son volume (maximum +2 dB). Une pause de 0,3 s remet la série à zéro.
- `scenes/modes/zombie/equipements/extincteur_mural.gd` et `sprinkler.gd` : voyant vert pulsant lorsque disponible, bleu pendant le jet du sprinkler, couleur chaude lorsque vide. Une onde accompagne l'utilisation.
- `scenes/modes/zombie/victimes/refuge_zombie.gd` : lumière verte de 0,8 s et de portée 6,5 m lors du dépôt. Les gyrophares existants restent animés.
- `scenes/modes/zombie/evenements/evenements_vague.gd` et `titre_incandescent.gdshader` : titre teinté par une chaleur mouvante et légère réduction de taille à l'arrivée. `SonsInterface.annoncer_vague()` réutilise un souffle déjà présent avec des hauteurs différentes selon l'événement.

`scenes/effets/retours/impulsion_visuelle.gd` centralise les ondes. Un TorusMesh grandit et devient transparent pendant 0,45 s, puis son nœud est supprimé. Aucun dégât, collision ou changement des bonus n'est géré par cet effet.

Les animations des équipements et du combat s'arrêtent avec le jeu. Aucun nouvel asset téléchargé n'est nécessaire pour cette première version.

Les combos conservent leurs visuels de combat existants, sans ondes ajoutées. Les achats gardent uniquement les animations d’ouverture des boosters.
