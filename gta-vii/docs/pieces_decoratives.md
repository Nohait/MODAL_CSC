# Variantes des pièces décoratives

Les scènes sont dans scenes/decors/interieurs/pieces. Chaque étage possède trois variantes :

| Étage | Petite pièce | Pièce allongée | Pièce en L |
| --- | --- | --- | --- |
| 1 | appartement_incendie : salon | cuisine_incendie : cuisine et repas | appartement_en_l : repas et salon |
| 2 | reserve_incendie : stockage | atelier_entretien_incendie : entretien et stockage | reserve_en_l : rayonnages et outillage |
| 3 | atelier_incendie : électricité | local_installations_incendie : installations et entretien | atelier_en_l : électricité et rangement |

Les petites pièces mesurent 4,6 × 4,7 m. Les pièces allongées font environ 4,6 × 8,4 m et les pièces en L environ 8,6 × 7,4 m, murs compris. Les modèles PBR existants sont réutilisés. Les incendies sont décoratifs et les scènes n'ont pas de plafond.

## Placement

habillage_salle.gd, fonction _installer_piece(), essaie une variante de l'étage. plan_espaces_decoratifs.gd calcule les rectangles des sols et des murs après rotation. Le coin vide d'une pièce en L reste libre : on ne réserve pas un seul grand rectangle englobant.

Chaque portion est testée contre les cases jouables, les trous du plancher, les autres pièces et les blocs de collision existants, notamment les couloirs, escaliers et paliers hors de la grille. Le seuil est exclu car il rejoint volontairement le mur existant. Si une portion rencontre un obstacle, toute la variante est refusée et une autre est essayée. Si aucune ne tient, le mur reste entier et aucune porte décorative n'est posée.

room_generator.gd, fonction ouvrir_mur_decoratif(), remplace uniquement le mesh du mur par deux panneaux latéraux et un linteau, créant une ouverture visuelle de 1,6 × 2,4 m. La collision originale reste présente : joueur, victimes, ennemis et jet sont bloqués au seuil. Les pièces sont ajoutées sous Habillage, hors de la navigation, sans points de spawn. La porte reçoit Avec piece derriere = true pour masquer son ancien fond sombre et sa lueur artificielle.

## Ajouter une variante

Dupliquer une scène et modifier ses meubles, foyers et surfaces dans Godot. Les surfaces directement sous la racine doivent commencer par Sol ou Mur : SolEntree, SolFond, MurGauche, etc. Les foyers commencent par Foyer. piece_decorative.gd hérite d'EspaceDecoratif : matériaux, collisions, aspect et préparation des foyers sont partagés avec le remplissage procédural. Le script de la pièce conserve son bagage au seuil et son profil d'incendie visible.

L'emprise provient des dimensions et positions des surfaces : aucun rectangle à renseigner manuellement. Pour une forme en L, utiliser plusieurs blocs de sol. Garder les meubles à l'intérieur de ces sols : le placement vérifie l'enveloppe bâtie, pas chaque meuble séparément.

L'ouverture reste à Z = 0, la pièce s'étend vers -Z, le sol est à Y = 0 et la génération pose la scène à Y = 0,10 m, comme le dessus du sol jouable.

Modifier les listes Pieces etage 1, Pieces etage 2 et Pieces etage 3 dans scenes/salles/habillage_classique.tres. Le hasard du décor est indépendant des combats et reste reproductible après une reprise de partie.

## Vérifications

Compilation Godot vérifiée. Audit de 120 salles avec contrôles des chemins, collisions et géométrie réelle des pièces : aucun problème détecté. Sur dix générations supplémentaires par étage, les neuf variantes ont été sélectionnées et soixante pièces placées. L'aperçu des neuf scènes a également été vérifié.


## Plan commun des annexes

`habillage_salle.gd` crée un `PlanEspacesDecoratifs` par salle, avant le placement des portes et des pièces. Le plan réserve la grille jouable, les trous et les volumes de collision. Une pièce préparée vérifie ses empreintes dans ce même plan, puis réserve toutes ses surfaces, seuil compris. Le seuil est exclu du test de raccordement uniquement, car il rejoint le mur d'origine.

`enveloppe_batiment.gd` reçoit ce plan ; il ne recalcule plus séparément les espaces occupés. Il découpe les rectangles libres, construit les pièces procédurales et les inscrit dans les mêmes réservations. Le découpage et les recettes de mobilier restent les méthodes de construction adaptées aux espaces disponibles. La métadonnée `espaces_decoratifs` de la salle permet de lire les réservations et leur origine dans l'inspecteur distant.

`espace_decoratif.gd` est la base commune : collisions désactivées, matériaux de surfaces, préparation des foyers et application de l'aspect des annexes. Les pièces préparées héritent de cette classe ; le conteneur EspacesInaccessibles du remplissage procédural l'utilise directement. Chaque branche applique l'aspect une seule fois. Les profils et les scènes existants restent utilisables.

Les anciens scripts placement_pieces_decoratives.gd et ambiance_piece_inaccessible.gd ont été remplacés par ces deux responsabilités communes. L'audit contrôle désormais aussi la géométrie réelle des sols procéduraux, sans les confondre avec les seuils des scènes préparées.

Après cette réorganisation : compilation validée, 24 générations couvrant les trois étages et quatre tailles sans problème de géométrie, de passage ou de reproductibilité. Le renfoncement d'une réservation en L et l'exclusion réciproque des deux types de pièces ont été testés. Aperçus des trois intensités d'incendie vérifiés en rendu réel.
