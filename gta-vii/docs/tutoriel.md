# Tutoriel — première intervention

Le parcours est fixe. Il réutilise le joueur et les systèmes communs du jeu avec `session_tutoriel`, qui le distingue de la progression classique. Les transitions entre salles utilisent l’écran de chargement partagé.

Tous les chemins ci-dessous sont relatifs à `scenes/modes/tutoriel/`.

## Salles et fichiers à modifier

| Dossier | Scène | Responsabilités |
|---|---|---|
| `00_03_parvis/` | `00_parvis.tscn` | `00_parvis.gd` coordonne l’introduction ; `progression_parvis.gd` vérifie les actions. |
| `04_premier_sauvetage/` | `04_premier_sauvetage.tscn` | `04_premier_sauvetage.gd` coordonne libération, extinction et escorte ; `progression_sauvetage.gd` valide les objectifs. |
| `05_06_combat/` | `05_premier_combat.tscn`, `06_combat_autonome.tscn` | `salle_combat.gd` coordonne les salles intérieures ; `progression_combat.gd` suit les rencontres. |
| `07_ravitaillement/` | `07_ravitaillement.tscn` | `poste_ravitaillement.gd` gère le pompier, le ravitaillement et la carte ; `progression_ravitaillement.gd` valide le choix et la sortie. |
| `08_sauvetage_sous_menace/` | `08_sauvetage_sous_menace.tscn` | `08_sauvetage_sous_menace.gd` gère victime, porte et ennemi ; `progression_sauvetage_sous_menace.gd` valide le sauvetage. |

Les scènes de combat autonome, de ravitaillement et de sauvetage sous menace héritent de `05_06_05_06_combat/05_premier_combat.tscn`. Elles utilisent donc également `05_06_05_06_combat/salle_combat.gd`, avec leurs paramètres de départ respectifs. Modifier cette base peut affecter plusieurs étapes.

## Dialogues et objectifs

Les ressources `00_03_00_03_parvis/etapes/00_contact.tres`, `01_mousse.tres`, `02_reserve.tres`, `03_dash.tres` et `03b_entree.tres` définissent titres, consignes, répliques et objectifs du parvis via `etape_tutoriel.gd`. Leur état de progression appartient au script, pas aux Resources partagées.

Les répliques des salles intérieures se trouvent dans leurs appels à `parler()`. Les paroles des pompiers doivent être compréhensibles indépendamment des indications du HUD : victimes, dangers et matériel dans les dialogues ; commandes dans les consignes.

`commun/dialogues/` contient la bulle et sa révélation progressive. `commun/figurants/` contient le pompier et les animations des figurants. À proximité, E termine la phrase en cours puis passe à la suivante ; s’éloigner masque la conversation sans effacer son avancement.

## Décor et navigation

Chaque salle regroupe son `decor_*.gd` et son `plan_*.tres` lorsque son plan est défini par une Resource. Le premier sauvetage conserve sa géométrie principale dans la scène, complétée par `appartements_mitoyens.gd` et `habillage_sauvetage.gd`.

`commun/decors/construction_interieur.gd` construit sols, murs, finitions, éclairages et accès décoratifs. `plan_appartement.gd` définit les données d’un plan fixe. `profil_decor.tres` et son script définissent les matériaux et les paramètres visuels communs. Ce dossier contient aussi la double porte, la zone sécurisée et l’effet de brasier.

Certaines positions de validation et de navigation restent inscrites dans les scripts. Après déplacement d’une porte ou d’une zone d’arrivée, vérifier aussi la progression, les points de navigation, l’ennemi et l’escorte.

## Transitions et reprise

`reprise/reprise_tutoriel.gd` conserve le matériel au passage vers la salle suivante et enregistre un point au début de chaque salle dans `user://partie_tutoriel.save`. Une reprise restaure les cartes, la vie, la réserve, la surchauffe et l’état du renfort de formation ; objectifs et rencontres recommencent au début de la salle.

`reprise/catalogue.gd` référence les six définitions de salles. Leurs identifiants (`parvis`, `sauvetage`, `combat`, `pratique`, `poste`, `menace`) sont indépendants des noms de fichiers : les conserver pour ne pas invalider les reprises. Les définitions `.tres` donnent les chemins des scènes.

`commun/interface/echec_tutoriel.gd` présente la reprise après échec. L’intégration à l’écran titre se trouve dans `scenes/interfaces/menus/titre/ecran_titre.gd`.

## Debug et vérification

En version debug, I ouvre les outils de `debug/` : accès aux étapes, commandes de test et état des objectifs. Les départs de debug n’écrivent pas les points de reprise normaux.

Pour vérifier une évolution, parcourir la salle concernée puis contrôler sa sortie, un échec et une reprise. Une analyse des chemins ne valide ni le rendu, ni les collisions, ni les déplacements des victimes.

La numérotation reprend les étapes du HUD : 00 à 03 sur le parvis, 04 premier sauvetage, 05 premier combat, 06 combat autonome, 07 ravitaillement et 08 sauvetage sous menace. `03b_entree.tres` est la transition après l’esquive, avant le premier sauvetage. Les préfixes des définitions de reprise servent au rangement ; leurs identifiants de sauvegarde restent inchangés.
