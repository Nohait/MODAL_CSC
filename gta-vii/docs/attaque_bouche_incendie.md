# Attaque secondaire : bouche à incendie

La scène `scenes/armes/bouche_incendie/attaque_bouche.tscn` est instanciée sous `player/SecondaryAttack`, dans le joueur commun aux deux modes. Elle ne dépend pas de la scène de l'extincteur. Le chemin vers le joueur est exporté pour pouvoir déplacer cette scène si nécessaire.

Maintenir `attaque_bouche` (clic droit) affiche le disque ; relâcher confirme si le placement est valide. La direction vient de l'intersection du rayon caméra avec un plan horizontal, puis sa longueur est limitée à la portée. Un rayon vertical récupère le dessus réel du sol. Le trajet et le volume de la bouche sont vérifiés contre les collisions du décor : un disque rouge signale un emplacement refusé.

La chute dure 1,4 seconde. Son accélération vient de `p * p`. La collision n'est activée qu'au contact du sol. Les dégâts et le recul sont appliqués à tout le disque dès l'atterrissage, une seule fois. L'onde s'étend ensuite pendant 0,55 seconde pour représenter l'impact, sans infliger de nouvelles touches. Les murs bloquent les dégâts. Les dégâts et le recul utilisent `effets_cartes`, donc l'affichage existant et la protection des tourelles contre le déplacement sont conservés.

La bouche reste 5 secondes, clignote la dernière seconde, puis disparaît. Le pictogramme Tabler du HUD conserve ses contours blancs ; son intérieur se remplit de rouge de bas en haut pendant la chute et la présence. Il est entièrement rempli lorsque l’attaque est disponible. La pause suspend le cycle ; changer de salle le nettoie. L'état transitoire de la bouche n'est pas ajouté aux sauvegardes de début de salle/vague.

Réglages : sélectionner `AttaqueBouche` dans `player.tscn`. Portée, rayon, dégâts, recul, durées, dimensions et nombre de gouttes sont exportés. `disque_eau.gdshader` dessine le disque et l'onde sur un plan transparent. Le modèle est redimensionné à partir de ses bornes, sans changer ses proportions.

Modèle : Tiko, Fire Hydrant (Low Poly Style), CC BY 4.0 selon la licence fournie. Le crédit est conservé avec le modèle. Aucun nouveau son n'a été ajouté à cette première version.
