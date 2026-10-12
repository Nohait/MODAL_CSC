# Tutoriel — première intervention

Le bouton **Tutoriel** charge `scenes/modes/tutoriel/tutoriel.tscn` avec l'écran de chargement partagé. Le décor est fixe, éditable dans la scène : parvis, façade, fenêtres en feu, véhicules d'intervention, deux foyers de pratique et repère de dash.

Le joueur conserve le déplacement, la visée, le jet et le carnet. Le supérieur le rejoint en utilisant les animations existantes. **E**, à proximité, commence ou poursuit la conversation. S'éloigner cache le dialogue sans perdre son avancement. Aucun dialogue ne met le jeu en pause. La bulle suit le supérieur à l'écran et révèle progressivement ses caractères, avec de courtes pauses de ponctuation. E termine d'abord la phrase si elle est en cours, puis passe à la suivante. S'éloigner suspend sa révélation. Les conseils utilisent le parchemin classique.

## Responsabilités

- `introduction_tutoriel.gd` : mise en scène, supérieur, proximité, affichage et entrée dans le bâtiment.
- `progression_tutoriel.gd` : validation des actions, séparée des dialogues et de leur rendu.
- `bulle_dialogue.gd` : présentation et révélation des répliques, indépendamment des objectifs. Vitesse et pauses sont exposées dans l'Inspector.
- `etape_tutoriel.gd` et les cinq `.tres` : titres, consignes, répliques et type d'objectif. Les ressources sont des définitions, leur état n'est pas modifié pendant une partie.

Les étapes sont : conversation, extinction des deux foyers, utilisation puis récupération de la réserve, dash se terminant dans le repère, puis entrée volontaire. Les foyers utilisent le vrai système d'extinction partagé, pas une simulation dédiée. Un foyer éteint avant sa consigne reste comptabilisé. La réserve doit effectivement être entamée pendant son exercice et se reconstituer ; marcher dans le repère ne valide pas le dash.

Les distances de conversation, la vitesse du supérieur, le fondu, les seuils de réserve et le rayon de validation du dash sont exposés dans l'Inspector. La durée d'extinction se règle sur les composants Extinction des deux foyers.

Le briefing tease les victimes et leur escorte, les créatures, le ravitaillement et une attaque plus lourde. La bouche à incendie est désactivée uniquement pendant cette introduction pour garder une première prise en main centrée sur la mousse.

## Suite à construire

L'entrée ouvre `parcours_tutoriel.tscn`, encore hérité du parcours classique. L'intérieur prédéfini, les premiers ennemis accompagnés, les victimes, la pratique en combat et le déblocage du zombie après la première victoire restent à construire.

`session_tutoriel` empêche de créer un point de reprise classique ou de supprimer une sauvegarde classique à la mort/victoire. Une victoire de test n'est pas comptée comme victoire classique. Les systèmes communs de découvertes et de succès liés aux actions restent présents. Les modes existants restent accessibles pendant le développement.
