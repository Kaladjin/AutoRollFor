🎰 Guide de survie : AutoRollFor v3.2
L'assistant qui roll plus vite que son ombre (Spécial Turtle WoW / RollFor)

AutoRollFor est un mini-addon conçu pour s'intégrer directement à AtlasLoot. Il permet de pré-enregistrer vos choix de loot (MS, OS ou Transmo) et d'automatiser vos jets de dés quand le Raid Leader utilise l'addon RollFor.

🛠️ Installation rapide
Installez le dossier AutoRollFor dans votre répertoire Interface\AddOns\. 

Renommez le si vous l'avez telechargez de githubs en AutoRollFor

Vérifiez bien qu'AtlasLoot est activé.

En jeu, tapez /ar pour vérifier que l'addon répond.

🖱️ Comment ça marche ? (C'est ultra simple)
Plus besoin de chercher l'objet dans une liste complexe. Tout se passe dans votre AtlasLoot habituel :

Ouvrez AtlasLoot sur le boss de votre choix.

CLIC-DROIT sur l'objet qui vous intéresse.

Choisissez votre priorité :

Main Spec (MS) : Pour un roll à 100.

Off Spec (OS) : Pour un roll à 99.

Transmog (TM) : Pour un roll à 98.

Optionnel : Cochez "Lancer le dé automatiquement" pour que l'addon s'occupe de tout sans vous poser de questions.

👀 Les indicateurs visuels
Une fois un objet réservé, un petit texte apparaît sur l'icône dans AtlasLoot :

[MS] : Réservé en Main Spec.

[OS] : Réservé en Off Spec.

[TM] : Réservé en Transmo.

* (Étoile jaune) : Le roll est en mode Automatique.

⚔️ En Raid (Master Loot)
Quand le Raid Leader lance un loot avec RollFor, l'addon scanne le chat :

Si vous êtes en mode AUTO : Le jet de dés est lancé instantanément. Vous n'avez rien à faire.

Si vous êtes en mode MANUEL : Une fenêtre surgit au milieu de l'écran avec 4 boutons clairs (MS, OS, TM, Passer). Cliquez, c'est roll !

🏰 En Donjon (Group Loot)
L'addon gère aussi le mode "Besoin ou Cupidité" classique :

Réservé MS + Auto ➡️ L'addon clique sur BESOIN.

Réservé OS/TM + Auto ➡️ L'addon clique sur CUPIDITÉ.

Si pas d'Auto, la fenêtre classique de WoW s'affiche normalement.

🧪 Tester l'addon
Vous voulez vérifier que tout est prêt avant le raid ?

Réservez un objet au pif dans AtlasLoot (Clic-droit).

Tapez /ar test dans votre barre de chat.

L'addon va simuler une annonce de Raid Leader et réagir selon vos réglages.

💡 Commandes utiles
/ar : Affiche l'aide et les commandes.

/ar test : Simule un loot pour tester la détection.

/run AutoRollPrefs = {}; ReloadUI(); : ATTENTION, ceci efface absolument toutes vos réservations d'un coup.

