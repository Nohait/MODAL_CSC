# Intervention dans la rue du Hall

La scène `scenes/decors/ville/intervention_pompiers.tscn` est placée dans la rue au nord-ouest du Hall, dans `exterieur_ville.tscn`, à gauche du local poubelles. Elle regroupe un camion, deux pompiers, une façade, une borne incendie, des lampadaires, des barrières et des pneus. Elle remplace visuellement l'ancien immeuble Nord1. Tout cet ensemble reste décoratif et ne rejoint ni les groupes du joueur ni ceux des ennemis.

## Eau et tuyaux

`intervention_pompiers.gd` construit le jet entre la sortie réglable dans l'Inspecteur (`sortie_lance`) et le repère `Batiment/CibleLance`, placé à une fenêtre du premier étage. Sa trajectoire est une parabole : une vitesse initiale le dirige vers le haut, puis une gravité légère courbe l'eau. La vitesse est calculée pour atteindre exactement la fenêtre. Le tube transparent et les particules utilisent la même trajectoire ; `jet_intervention.gdshader` anime les stries du tube. Une seconde émission produit les éclaboussures à l'arrivée.

Le bâtiment est reculé derrière le trottoir opposé, avec sa façade vers Z = -43,5. Le repère visé et les flammes sont ses enfants : ils suivent automatiquement ce déplacement. Le camion et les pompiers restent à leur emplacement dans la rue.

`tuyau_intervention.gd` arrondit une liste de points avec une `Curve3D`, puis construit un petit tube autour du trajet. Il relie la borne au camion et le camion à la lance. Aucun corps physique n'est nécessaire pour ces tuyaux hors du niveau jouable.

## Pompiers et fenêtres

`pompier_intervention.tscn` réutilise le modèle et la pose du pompier. Son extincteur est masqué et ses animations de déplacement sont désactivées. `pompier_intervention.gd` commence par relever le modèle pour poser ses bottes au sol : son origine importée ne correspond pas à ses pieds. Ensuite, il tourne successivement les coudes et les bras pour rapprocher les mains de la lance. Les paramètres `hauteur_mains` et `avance_mains` permettent d'ajuster cette pose sans modifier le joueur.

La fenêtre arrosée émet une fumée claire ; la fenêtre voisine émet une fumée sombre et les flammes animées déjà utilisées sur la voiture. Des particules montent, grossissent puis disparaissent grâce à leur rampe de couleur et au shader `fumee_hall.gdshader` existant.

Les gyrophares alternent leur éclairage avec une sinusoïde. Les pompiers ont un très léger balancement. Les lampadaires éclairent localement la rue. Les traces sombres et les petites zones humides habillent l'asphalte sans modifier son matériau de base.

La rubalise existante bouge également légèrement grâce à `ruban_securite.gdshader`. Ses maillages dans `hall.tscn` et `annexes_hall.tscn` ont été subdivisés pour que le shader puisse faire onduler leur milieu. Cela ne change pas les collisions.

## Modèles

Les archives Blender téléchargées ont été converties en GLB dans `assets/modeles/decors/ville/intervention/`. Les textures couleur, relief et rugosité sont conservées. Les crédits et les adaptations sont répertoriés dans le `CREDITS.md` de ce dossier.
