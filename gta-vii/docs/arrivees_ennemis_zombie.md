# Arrivées des ennemis du mode zombie

MapTest possède cinq accès sous `Navigation/Decor/EntreesEnnemis` : une porte au nord, une brèche dans le mur gauche, deux fenêtres et un ascenseur au bord gauche. Les murs et leurs habillages ont été découpés pour laisser les passages visibles. Les boîtes aux lettres ont été déplacées pour dégager l'ascenseur. Le petit ascenseur condamné du mur droit reste un élément de décor distinct.

Les quatre scènes réutilisables sont dans `scenes/modes/zombie/apparitions/` : `porte_arrivee.tscn`, `breche_arrivee.tscn`, `fenetre_arrivee.tscn`, `ascenseur_arrivee.tscn`. Elles utilisent les textures et matériaux existants ; les fenêtres sont les modèles déjà installés dans le hall. La cabine et la cage sont construites avec des formes simples, sans nouvel asset externe.

## Fonctionnement d'une vague

La difficulté continue de choisir les types et quantités. Les tourelles restent fixes et apparaissent au début. Les victimes continuent d'utiliser les marqueurs de la map. Un premier mobile se trouve déjà au seuil d'une porte ou d'une brèche quand la vague démarre ; le mini-boss conserve donc son arrivée immédiate lors de sa vague.

Les autres mobiles sont répartis en groupes sur le timer habituel de 15 à 30 secondes. `creer_vague()` choisit les accès compatibles, remplit leur capacité et démarre une lueur orange avec des braises. Les volants utilisent les fenêtres ; les autres utilisent les portes, brèches et ascenseur. Le calendrier commence l'annonce avant l'échéance, et conserve la création du dernier groupe exactement à la fin du timer. Lorsque les groupes sont rapprochés, l'animation est raccourcie pour éviter de chevaucher deux arrivées sur le même accès.

Pendant cette préparation, il n'y a que des figurants visuels. `_visuel_type()` prépare une instance inerte du modèle pour récupérer son échelle et ses matériaux, copie sa partie visuelle puis supprime l'instance temporaire. La copie n'a ni script d'ennemi, ni collision, ni groupe de combat. Les présentations sont conservées en cache et libérées en quittant le mode.

À l'échéance, `creer_mobile()` remplace les figurants par les ennemis réels à leur destination. Leurs comportements, navigation, dégâts et signaux de mort restent ceux du jeu. Le compteur inclut toujours les ennemis à venir : une vague ne peut pas se terminer pendant une arrivée.

`_destination_libre()` cherche une position dégagée près du seuil, avec la collision du type concerné et un espacement entre les destinations réservées. Cela tient compte des obstacles, captives et ennemis déjà présents. Si les positions voisines sont toutes occupées, le seuil prévu reste la solution de secours pour ne pas bloquer la vague.

## Animation de l'ascenseur

`entree_ennemis.gd` est commun aux quatre accès. Il anime directement les positions à partir du temps écoulé : le calendrier, plutôt qu'un signal de fin de Tween, décide quand les ennemis deviennent actifs.

La cabine descend pendant les premiers 65 % de l'annonce. La courbe `smoothstep` accélère puis freine doucement, pour garder la descente lisible. La cage mesure 11,5 m : son fond est en béton, les deux côtés sont vitrés et la façade reste ouverte. Un bandeau lumineux rend la cabine visible. Son annonce dure jusqu’à 3,6 s. Les deux portes coulissent pendant les 15 % suivants, puis les figurants sortent pendant les derniers 20 %. Ils se resserrent dans l'ouverture avant de s'écarter dans la pièce. Après la sortie, les portes se referment et la cabine vide remonte progressivement. Le gestionnaire attend la fin de ce retour pour sélectionner de nouveau l'ascenseur.

Les volumes fixes des petits accès sont intégrés aux deux navigations, car ils sont sous `Navigation/Decor`. Les parties animées sont uniquement visuelles et ne demandent pas une nouvelle cuisson à chaque mouvement. Les fenêtres conservent une barrière invisible pour empêcher le joueur de sortir dans le vide. Les attaques ne peuvent pas viser les figurants pendant leur présentation. Ces arrivées ne sont pas installées dans le mode classique.

## Réglages dans Godot

Sélectionner une entrée dans MapTest pour modifier :

- Type entrée : porte, brèche, fenêtre ou ascenseur.
- Capacité : nombre de figurants qui peuvent emprunter cet accès dans un groupe.
- Durée arrivée : durée maximale de l'annonce ; le calendrier peut la raccourcir pour respecter le rythme de la vague.
- Distance sortie : distance dans la pièce à laquelle le mobile devient actif.
- Hauteur départ cabine : hauteur de départ de l'ascenseur.

Dans une composition de vague, déplier la ressource d'un ennemi et cocher **Volant** pour autoriser son arrivée par fenêtre. C'est activé pour le kamikaze dans les compositions Classique et Embuscade.

Pour une nouvelle map, instancier ces accès sous `Navigation/Decor/EntreesEnnemis`, orienter leur axe local +Z vers la pièce et prévoir une ouverture ainsi qu'un espace libre devant eux. Une map sans accès compatible conserve les anciennes annonces d'apparition.

## Vérification

Chargement et navigation de MapTest, ascenseur et groupe de deux sbires, présentation des six types mobiles, filtrage des fenêtres, annulation par le debug et vagues complètes 5, 7, 10 et 15. Les compteurs et la fin du sauvetage sont synchronisés avec les créations. Le rendu de la descente et de la sortie a été inspecté ; l'aperçu du catalogue des maps est actualisé.
