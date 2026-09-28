-- ModuleScript : TRADUCTION ANGLAISE du jeu.
--
-- Le jeu est écrit en français. Pour les joueurs qui ne sont PAS francophones (langue Roblox ≠ fr),
-- chaque texte affiché à l'écran (menus, messages, panneaux dans le monde, boutons E...) est
-- traduit en anglais juste avant d'être montré (voir Translator.start, appelé par le client).
-- Les données du jeu (raretés, mutations, sauvegardes) ne changent pas : seul l'affichage est traduit.
--
-- Comment ça marche :
--   1. PHRASES : des morceaux de phrases français → anglais, remplacés dans le texte (les plus longs d'abord).
--      Ça marche aussi pour les textes construits avec des morceaux ("Il faut " .. 3 .. " rebirth(s)...").
--   2. MOTS : des mots seuls (raretés, mutations...), remplacés seulement s'ils sont entiers.
--   Les versions EN MAJUSCULES sont ajoutées automatiquement.
--
-- Pour ajouter une traduction : ajoute une ligne {"texte français", "english text"} dans PHRASES.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("GameConfig"))

local Translator = {}

-- ============================================================
-- 1. PHRASES (et morceaux de phrases)
-- ============================================================
local PHRASES = {
	-- ===== menu, boutons =====
	{"🎒 RANGER (G)", "🎒 STORE (G)"},
	{"⭐ ÉQUIPER LES MEILLEURS", "⭐ EQUIP BEST"},
	{"💰 VENDRE", "💰 SELL"},
	{"◆ MINERAIS", "◆ MINERALS"},
	{"💎 MINERAIS", "💎 MINERALS"},
	{"📦 BOOSTERS", "📦 BOOSTERS"},
	{"🎡 ROUE & POTION", "🎡 WHEEL & POTION"},
	{"✨ GAME PASS", "✨ GAME PASSES"},
	{"👑 VIP", "👑 VIP"},
	{"ACHETER DES TOURS", "BUY SPINS"},
	{"Acheter des tours", "Buy spins"},
	{"ACHETÉ ✓", "OWNED ✓"},
	{"RÉCUPÉRER MON CADEAU !", "CLAIM MY GIFT!"},
	{"RÉCUPÉRER !", "CLAIM!"},
	{"TOUT RÉVÉLER", "REVEAL ALL"},
	{"TOUR GRATUIT DISPO !", "FREE SPIN READY!"},
	{"TOURNER !", "SPIN!"},
	{"DEVENIR VIP", "BECOME VIP"},
	{"👑 TU ES VIP ✓", "👑 YOU ARE VIP ✓"},
	{"👑 Tu es VIP !", "👑 You are VIP!"},
	{"👑 BIENVENUE VIP !", "👑 WELCOME VIP!"},
	{"🔥 MEILLEURE OFFRE DU JEU", "🔥 BEST DEAL IN THE GAME"},
	{"Tout ça en un seul achat, pour toujours !", "All of this in one purchase, forever!"},
	{"Tu économises ", "You save "},
	{"PACK VIP", "VIP PACK"},
	{"Pack VIP", "VIP Pack"},
	{"Le pack ultime !", "The ultimate pack!"},
	{"Tag VIP + [VIP] en vert dans le chat", "VIP tag + green [VIP] in chat"},
	{"1 minerai de Diamant (", "1 Diamond ore ("},
	{"1 minerai de Netherite (", "1 Netherite ore ("},
	{"Argent x2 à vie (", "Money x2 forever ("},
	{"Tapis volant (", "Flying carpet ("},
	{"Collecte auto (", "Auto collect ("},
	{" (à vie)", " (forever)"},
	{"Argent x2", "Money x2"},
	{"Tout ton argent x2, pour toujours !", "All your money x2, forever!"},
	{"Tapis volant", "Flying carpet"},
	{"Vole partout, 2,5x plus vite !", "Fly anywhere, 2.5x faster!"},
	{"Collecte auto", "Auto collect"},
	{"L'argent de ta base arrive tout seul !", "Your base money comes in by itself!"},
	{"Achetés une fois, gardés pour toujours", "Buy once, keep forever"},
	{"Plus de tours de roue, plus de chance", "More wheel spins, more luck"},
	{"Des brainrots sans miner ! Clique sur les cartes pour les révéler", "Brainrots without mining! Click the cards to reveal them"},
	{"Donne-les à un brainrot : il gagne plus d'argent pour toujours (Sac → MINERAIS)", "Give them to a brainrot: it earns more money forever (Bag → MINERALS)"},
	{"Tente ta chance sur la roue !", "Try your luck on the wheel!"},
	{"Tours de roue", "Wheel spins"},
	{"10 tours de roue", "10 wheel spins"},
	{"3 tours de roue", "3 wheel spins"},
	{"2 tours de roue", "2 wheel spins"},
	{"1 tour de roue", "1 wheel spin"},
	{" tour(s) de roue !", " wheel spin(s)!"},
	{" tour(s) de roue", " wheel spin(s)"},
	{" tour(s)", " spin(s)"},
	{"Potion Chance x2 (20 min)", "Luck Potion x2 (20 min)"},
	{"Potion Chance x2 activée pour ", "Luck Potion x2 active for "},
	{"🍀 Potion Chance x2 : ", "🍀 Luck Potion x2: "},
	{"Potion Chance x2", "Luck Potion x2"},
	{"potion Chance x2", "Luck Potion x2"},
	{"🍀 Chance x2  ", "🍀 Luck x2  "},
	{"Chance x2 pendant ", "Luck x2 for "},
	{" min : raretés x2", " min: rarities x2"},
	{"Chance x2", "Luck x2"},
	{"JUSQU'À : ", "UP TO: "},
	{"  •  EXCLUSIF", "  •  EXCLUSIVE"},
	{" • EXCLUSIF", " • EXCLUSIVE"},
	{"1 carte ", "1 card "},
	{" cartes", " cards"},
	{" carte", " card"},
	{"Clique sur les cartes pour les révéler !", "Click the cards to reveal them!"},
	{"CLIQUE !", "CLICK!"},
	{"BOOSTER GALAXIE !", "GALAXY BOOSTER!"},
	{"Booster Commun", "Common Booster"},
	{"Booster Épique", "Epic Booster"},
	{"Booster Légendaire", "Legendary Booster"},
	{"Booster Divin", "Divine Booster"},
	{"Booster Galaxie", "Galaxy Booster"},
	{"Booster Céleste", "Celestial Booster"},
	{"Brainrot Épique", "Epic Brainrot"},
	{"Brainrot Légendaire", "Legendary Brainrot"},
	{"Mode test Studio : offert", "Studio test mode: free"},
	{"Bientôt disponible !", "Coming soon!"},
	{" activé pour toujours !", " activated forever!"},
	{"Tu l'as déjà !", "You already have it!"},

	-- ===== pioches, battes, grappins =====
	{"Pioche en Bois", "Wooden Pickaxe"},
	{"Pioche en Pierre", "Stone Pickaxe"},
	{"Pioche en Fer", "Iron Pickaxe"},
	{"Pioche en Or", "Gold Pickaxe"},
	{"Pioche en Diamant", "Diamond Pickaxe"},
	{"Pioche en Netherite", "Netherite Pickaxe"},
	{"Pioche en Émeraude", "Emerald Pickaxe"},
	{"Pioche en Rubis", "Ruby Pickaxe"},
	{"Pioche Cosmique", "Cosmic Pickaxe"},
	{"Pioche du Vide", "Void Pickaxe"},
	{"Pioche Divine", "Divine Pickaxe"},
	{"Pioche Bois", "Wooden Pickaxe"},
	{"Pioche Pierre", "Stone Pickaxe"},
	{"Pioche Fer", "Iron Pickaxe"},
	{"Pioche Or", "Gold Pickaxe"},
	{"Pioche Diamant", "Diamond Pickaxe"},
	{"Pioche Netherite", "Netherite Pickaxe"},
	{"Pioche Émeraude", "Emerald Pickaxe"},
	{"Pioche Rubis", "Ruby Pickaxe"},
	{"Batte en bois", "Wooden Bat"},
	{"Batte en métal", "Metal Bat"},
	{"Batte en or", "Golden Bat"},
	{"Batte en diamant", "Diamond Bat"},
	{"Batte cosmique", "Cosmic Bat"},
	{"Grappin renforcé", "Reinforced Grapple"},
	{"Grappin laser", "Laser Grapple"},
	{"BATTES & GRAPPINS", "BATS & GRAPPLES"},
	{"Battes & Grappins", "Bats & Grapples"},
	{"[F] BATTES & GRAPPINS", "[F] BATS & GRAPPLES"},
	{"[E] PIOCHES", "[E] PICKAXES"},
	{"⛏  BOUTIQUE  ⛏", "⛏  SHOP  ⛏"},
	{"Dégâts ", "Damage "},
	{"  •  Vitesse ", "  •  Speed "},
	{"  •  Chance x", "  •  Luck x"},
	{"Portée ", "Range "},
	{"  •  Recharge ", "  •  Cooldown "},
	{"  •  Fait tomber ", "  •  Knocks down "},
	{"  •  Vise et clique pour t'envoler", "  •  Aim and click to fly"},
	{" : fais tomber les voleurs !", ": knock thieves down!"},
	{" : vise et clique pour t'envoler (portée ", ": aim and click to fly (range "},
	{"ÉQUIPÉE", "EQUIPPED"},
	{"ÉQUIPÉ", "EQUIPPED"},
	{"POSSÉDÉE", "OWNED"},
	{"POSSÉDÉ", "OWNED"},
	{"BLOQUÉE", "LOCKED"},
	{"BLOQUÉ", "LOCKED"},
	{"Achète d'abord la pioche précédente", "Buy the previous pickaxe first"},
	{"Achète d'abord la batte précédente", "Buy the previous bat first"},
	{"Achète d'abord le grappin précédent", "Buy the previous grapple first"},
	{"Va à la BOUTIQUE (touche E au comptoir) pour acheter une pioche", "Go to the SHOP (press E at the counter) to buy a pickaxe"},
	{"Va à la BOUTIQUE (touche F au comptoir) pour acheter un grappin", "Go to the SHOP (press F at the counter) to buy a grapple"},
	{"Va à la BOUTIQUE (touche F au comptoir) pour acheter une batte", "Go to the SHOP (press F at the counter) to buy a bat"},
	{"Pas assez d'argent ($", "Not enough money ($"},
	{"⛏️ Nouvelle pioche : ", "⛏️ New pickaxe: "},
	{"Nouvelle arme : ", "New weapon: "},
	{"🪝 Nouveau grappin : ", "🪝 New grapple: "},
	{" dispo à la boutique", " available at the shop"},
	{"Il te faut au moins une ", "You need at least a "},
	{" pour casser : ", " to break: "},
	{"🔒 Il faut ", "🔒 You need "},
	{" rebirth(s) pour la ", " rebirth(s) for the "},
	{" rebirth(s) pour le ", " rebirth(s) for the "},
	{"Prends-le en main pour voler ! (Espace = monter, Ctrl = descendre)", "Hold it to fly! (Space = up, Ctrl = down)"},
	{"🧞 Tapis volant !", "🧞 Flying carpet!"},
	{"✨ PIOCHE DIVINE : casse tout en 1 coup (même les futures couches)", "✨ DIVINE PICKAXE: breaks everything in 1 hit (even future layers)"},
	{" : tout casse en 1 coup !", ": everything breaks in 1 hit!"},
	{"Plus d'argent", "More money"},

	-- ===== mine =====
	{"⛏ MINE ⛏", "⛏ MINE ⛏"},
	{"⛏️ Va à la MINE et casse des blocs pour trouver des cartes !", "⛏️ Go to the MINE and break blocks to find cards!"},
	{"🏠 Pose ta carte dans ta BASE : Sac → PRENDRE → touche E sur un podium", "🏠 Place your card in your BASE: Bag → TAKE → press E on a podium"},
	{"💰 Ta carte gagne de l'argent : touche les boutons COLLECTER dans ta base !", "💰 Your card earns money: touch the COLLECT buttons in your base!"},
	{"🛒 Achète une meilleure pioche à la BOUTIQUE (touche E au comptoir)", "🛒 Buy a better pickaxe at the SHOP (press E at the counter)"},
	{"⚠️ La mine se régénère dans 15 secondes !", "⚠️ The mine resets in 15 seconds!"},
	{"⛏️ La mine est régénérée", "⛏️ The mine has been reset"},
	{"✦ Mine plus profond ✦", "✦ Mine deeper ✦"},
	{"Profondeur ", "Depth "},
	{"Roche profonde", "Deep Rock"},
	{"Débris antiques", "Ancient Debris"},
	{"Cœur cosmique", "Cosmic Core"},
	{" : casse des COFFRES dans la mine !", ": break CHESTS in the mine!"},

	-- ===== sac, index, vente =====
	{"Ton sac (clique pour ajouter / retirer)", "Your bag (click to add / remove)"},
	{"Ton sac est vide... va miner !", "Your bag is empty... go mine!"},
	{"Vends toutes les cartes du sac d'une rareté (celles posées dans ta base ne sont pas vendues)", "Sell all bag cards of a rarity (cards placed in your base are not sold)"},
	{" carte(s) vendue(s) pour $", " card(s) sold for $"},
	{" vendu pour $", " sold for $"},
	{"⭐ Tes meilleurs brainrots sont équipés dans ta base !", "⭐ Your best brainrots are equipped in your base!"},
	{"Tes meilleurs brainrots sont déjà équipés", "Your best brainrots are already equipped"},
	{" est rangé dans ton sac", " was put back in your bag"},
	{" est retourné dans ton sac", " went back to your bag"},
	{"Prends d'abord une carte dans ton sac", "Take a card from your bag first"},
	{"Prends d'abord une carte en main (Sac → PRENDRE)", "Hold a card first (Bag → TAKE)"},
	{"Pose-la sur un emplacement de ta base (touche E)", "Place it on a spot in your base (press E)"},
	{"Poser un brainrot", "Place a brainrot"},
	{" posé !", " placed!"},
	{"Emplacement ", "Spot "},
	{"📖 INDEX : ", "📖 INDEX: "},
	{" brainrots découverts ! +", " brainrots discovered! +"},
	{"📖 Tout l'Index est débloqué !", "📖 The whole Index is unlocked!"},
	{"Prochaine mise à jour", "Next update"},
	{"COMING SOON", "COMING SOON"},
	{"BIENTÔT", "SOON"},
	{"Bientôt...", "Coming soon..."},
	{"✨ Mutation ", "✨ Mutation "},
	{"Revenu x", "Income x"},
	{"Brainrot introuvable", "Brainrot not found"},

	-- ===== minerais =====
	{"Choisis un minerai, puis le brainrot qui va le recevoir", "Pick a mineral, then the brainrot that gets it"},
	{"Donne-le à un brainrot : Sac → MINERAIS", "Give it to a brainrot: Bag → MINERALS"},
	{" % pour toujours) : à qui le donner ?", " % forever): who gets it?"},
	{" % d'argent pour toujours sur 1 brainrot", " % money forever on 1 brainrot"},
	{" % d'argent pour toujours !", " % money forever!"},
	{" a déjà un minerai aussi fort (ou plus fort)", " already has an ore this strong (or stronger)"},
	{"Tu n'as pas de minerai ", "You don't have any "},
	{"Impossible : ce brainrot est en train d'être volé !", "Impossible: this brainrot is being stolen!"},
	{"Minerais : argent, or, emeraude, diamant, netherite", "Minerals: silver, gold, emerald, diamond, netherite"},
	{"MINERAI DE DIAMANT", "DIAMOND ORE"},
	{"Minerai de Diamant", "Diamond Ore"},
	{"Minerai de Netherite", "Netherite Ore"},
	{"Minerai d'argent", "Silver Ore"},
	{"Minerai d'or", "Gold Ore"},
	{"◆ Minerai Argent", "◆ Silver Ore"},
	{"◆ Minerai ", "◆ Ore: "},
	{" minerai(s) ", " ore(s) "},
	{"◆ Argent", "◆ Silver"},
	{"◆Argent", "◆Silver"},
	{"+ Argent :", "+ Silver:"},
	{"minerai Argent", "Silver ore"},
	{"sans minerai", "no mineral"},

	-- ===== base, verrou, vol =====
	{"Base de ", "Base of "},
	{"Base libre", "Free base"},
	{"Base au max", "Base maxed"},
	{"Base verrouillée pendant ", "Base locked for "},
	{"🔒 Base verrouillée ! Impossible de passer les lasers", "🔒 Base locked! You can't pass the lasers"},
	{"Base verrouillée", "Base locked"},
	{"Ta base est déjà verrouillée", "Your base is already locked"},
	{"Marche sur le bouton pour verrouiller", "Step on the button to lock"},
	{"Verrouiller la base", "Lock the base"},
	{"🔓 OUVERTE", "🔓 OPEN"},
	{"Cette base est déjà ouverte !", "This base is already open!"},
	{"Cette base est verrouillée !", "This base is locked!"},
	{"REZ-DE-CHAUSSÉE", "GROUND FLOOR"},
	{"ÉTAGE ", "FLOOR "},
	{"Nouvel étage construit dans ta base !", "New floor built in your base!"},
	{"Nouvel étage !", "New floor!"},
	{" emplacements débloqués dans ta base", " spots unlocked in your base"},
	{"Débloqué au rebirth ", "Unlocked at rebirth "},
	{" secondes", " seconds"},
	{"🚨 VOLEUR 🚨", "🚨 THIEF 🚨"},
	{"🚨 ALARME : ", "🚨 ALARM: "},
	{" a essayé de pirater ta base !", " tried to hack your base!"},
	{" pirate ta base !", " is hacking your base!"},
	{" a piraté tes lasers : plus que ", " hacked your lasers: only "},
	{" de verrouillage !", " of lock left!"},
	{" t'a volé ", " stole your "},
	{" VOLE TON ", " IS STEALING YOUR "},
	{" A RAMASSÉ TON ", " PICKED UP YOUR "},
	{"Tu as volé ", "You stole "},
	{" ! Ramène-le dans ta base !", "! Bring it back to your base!"},
	{"Tu portes déjà un brainrot !", "You're already carrying a brainrot!"},
	{"Tu as lâché ", "You dropped "},
	{" ! Il est par terre, vite !", "! It's on the ground, hurry!"},
	{" est tombé par terre ! Va le ramasser !", " fell on the ground! Go pick it up!"},
	{"Tu as ramassé ", "You picked up "},
	{"Ramasse-le ! ", "Pick it up! "},
	{" est revenu dans ta base !", " is back in your base!"},
	{"Trop tard ! Le brainrot est reparti", "Too late! The brainrot went back"},
	{" t'a mis un coup de batte !", " hit you with a bat!"},
	{"Ramène ", "Bring "},
	{" dans ta base !", " to your base!"},
	{"🚫 Pas de téléportation avec un brainrot volé : ramène-le à pied !", "🚫 No teleporting with a stolen brainrot: bring it back on foot!"},
	{"AU SOL", "ON THE GROUND"},
	{" n'a pas de base", " has no base"},

	-- ===== piratage =====
	{"🔓 PIRATAGE DES LASERS", "🔓 LASER HACK"},
	{"Pirater les lasers", "Hack the lasers"},
	{"SYSTÈME LASER", "LASER SYSTEM"},
	{"Coupe dans l'ordre : ", "Cut in order: "},
	{"Tu as mémorisé l'ordre ? Vas-y !", "Did you remember the order? Go!"},
	{"Mauvais fil ! L'alarme sonne !", "Wrong wire! The alarm is ringing!"},
	{"Trop lent !", "Too slow!"},
	{"Trop loin du panneau", "Too far from the panel"},
	{"Piratage annulé", "Hack cancelled"},
	{"Piratage réussi ! Les lasers s'éteignent dans ", "Hack successful! The lasers turn off in "},
	{", tiens-toi prêt !", ", get ready!"},
	{"LASERS AFFAIBLIS ! Encore ", "LASERS WEAKENED! Still "},
	{"LASERS AFFAIBLIS !", "LASERS WEAKENED!"},
	{"Système bloqué ! Réessaie dans ", "System locked! Try again in "},
	{"Mini-jeu", "Mini-game"},
	{"ÉCHEC", "FAILED"},

	-- ===== rebirth =====
	{"Rebirth 0", "Rebirth 0"},
	{"TU DÉBLOQUES", "YOU UNLOCK"},
	{"Tu perds ton argent et les brainrots demandés !", "You lose your money and the required brainrots!"},
	{"Il te manque : ", "You're missing: "},
	{"Il te faut $", "You need $"},
	{" pour rebirth", " to rebirth"},
	{"PAS ENCORE...", "NOT YET..."},
	{"SÛR ?", "SURE?"},

	-- ===== échanges, cadeaux entre joueurs =====
	{"📨 Demande d'échange envoyée à ", "📨 Trade request sent to "},
	{" veut échanger !", " wants to trade!"},
	{"Échange réussi avec ", "Trade completed with "},
	{"Échange annulé : ", "Trade cancelled: "},
	{" a annulé l'échange", " cancelled the trade"},
	{" a refusé l'échange", " declined the trade"},
	{" a quitté le jeu", " left the game"},
	{"Un joueur a quitté", "A player left"},
	{"Ce joueur est déjà en échange", "This player is already trading"},
	{"Personne d'autre sur le serveur", "Nobody else on the server"},
	{"Une carte n'est plus disponible", "A card is no longer available"},
	{"Échange dans ", "Trade in "},
	{"On attend ", "Waiting for "},
	{"Ajoute des cartes", "Add cards"},
	{"🔒 Trop d'écart de rebirths avec ", "🔒 Rebirth gap too big with "},
	{"🔒 Trop d'écart de rebirths (max ", "🔒 Rebirth gap too big (max "},
	{"Trop d'écart de rebirths", "Rebirth gap too big"},
	{"TROP D'ÉCART", "GAP TOO BIG"},
	{" rebirths d'écart", " rebirths apart"},
	{"Donner la carte", "Give the card"},
	{"🎁 Tu as donné ", "🎁 You gave "},
	{" t'a donné ", " gave you "},

	-- ===== récompenses, coffre de départ, VIP =====
	{"Récompenses du jour", "Daily rewards"},
	{"🎁 Ta récompense quotidienne est prête !", "🎁 Your daily reward is ready!"},
	{"✅ Ta récompense est prête !", "✅ Your reward is ready!"},
	{"🎁 Toutes les récompenses obtenues !", "🎁 All rewards claimed!"},
	{"Reviens chaque jour ! Si tu attends plus de 48 h, ta série repart au jour 1.", "Come back every day! If you wait more than 48 h, your streak goes back to day 1."},
	{"Prochaine récompense dans ", "Next reward in "},
	{"⏳ Prochaine dans ", "⏳ Next in "},
	{"🔥 Série : ", "🔥 Streak: "},
	{"🎁 Jour ", "🎁 Day "},
	{"JOUR ", "DAY "},
	{"AUJOURD'HUI", "TODAY"},
	{"DEMAIN", "TOMORROW"},
	{"✔ PRIS", "✔ CLAIMED"},
	{"🎁 CADEAU DE DÉPART", "🎁 STARTER GIFT"},
	{"Cadeau de départ", "Starter gift"},
	{"🎁 Ton cadeau de bienvenue !", "🎁 Your welcome gift!"},
	{"⭐ Favori + 👍 Like = cadeau !", "⭐ Favorite + 👍 Like = gift!"},
	{"⭐ 1. METTRE EN FAVORI", "⭐ 1. ADD TO FAVORITES"},
	{"⭐ FAVORI ✔", "⭐ FAVORITE ✔"},
	{"👍 2. J'AI MIS UN LIKE", "👍 2. I LIKED THE GAME"},
	{"👍 LIKE ✔", "👍 LIKE ✔"},
	{"Le like : clique sur 👍 sur la page du jeu Roblox (sous le bouton Jouer), puis sur ce bouton.", "The like: click 👍 on the Roblox game page (under the Play button), then click this button."},
	{"Mets le jeu en favori ⭐ et un like 👍 pour ouvrir le coffre !", "Favorite ⭐ and like 👍 the game to open the chest!"},
	{"Va au COFFRE DORÉ à côté de la roue", "Go to the GOLDEN CHEST next to the wheel"},
	{"Tu as déjà ouvert ton cadeau de départ !", "You already opened your starter gift!"},
	{"🎁 Cadeau de départ : +$", "🎁 Starter gift: +$"},
	{"✔ DÉJÀ OUVERT", "✔ ALREADY OPENED"},
	{"✔ Déjà ouvert", "✔ Already opened"},
	{"Entre dans la zone jaune !", "Step into the yellow zone!"},
	{"📦 COFFRE OUVERT !", "📦 CHEST OPENED!"},
	{"pour bien commencer", "to get started"},
	{"🎁 CADEAU !", "🎁 GIFT!"},
	{"🌙 BON RETOUR !", "🌙 WELCOME BACK!"},
	{"Pendant ton absence (", "While you were away ("},
	{"), ta base t'a rapporté :", "), your base earned:"},
	{"SUPER !", "GREAT!"},
	{"au hasard !", "at random!"},
	{"🎁 Cadeau d'un admin : ", "🎁 Gift from an admin: "},
	{"🎁 Tu peux reprendre le cadeau de départ", "🎁 You can claim the starter gift again"},

	-- ===== roue =====
	{"✦ ROUE DE LA FORTUNE ✦", "✦ WHEEL OF FORTUNE ✦"},
	{"Roue de la fortune", "Wheel of fortune"},
	{"[E] Tourner   •   [F] Acheter des tours", "[E] Spin   •   [F] Buy spins"},
	{"Tourner la roue", "Spin the wheel"},
	{"Gratuit dans ", "Free in "},
	{"   •   Tes tours : ", "   •   Your spins: "},
	{"Tes tours : ", "Your spins: "},
	{"La roue tourne déjà, attends un peu !", "The wheel is already spinning, wait a bit!"},
	{"Plus de tours ! Reviens plus tard ou achète des tours (touche F)", "No spins left! Come back later or buy spins (press F)"},
	{"Va à la ROUE DE LA FORTUNE pour tourner (touche E)", "Go to the WHEEL OF FORTUNE to spin (press E)"},

	-- ===== classements, monde =====
	{"💰 LES PLUS RICHES", "💰 RICHEST PLAYERS"},
	{"⚡ MEILLEURE BASE", "⚡ BEST BASE"},
	{"Top 10 de tous les serveurs  •  mis à jour chaque minute", "Top 10 of all servers  •  updated every minute"},
	{"Top 10 de tous les serveurs", "Top 10 of all servers"},
	{"Top 10 du serveur", "Top 10 of this server"},
	{"meilleure base", "best base"},
	{"✦ PORTAIL MYSTÈRE ✦", "✦ MYSTERY PORTAL ✦"},

	-- ===== paramètres, admin =====
	{"Paramètres", "Settings"},
	{"La musique de fond du jeu", "The game's background music"},
	{"Graphismes allégés", "Low graphics"},
	{"Moins d'effets : le jeu est plus fluide sur les petits PC et les téléphones", "Fewer effects: smoother on small PCs and phones"},
	{"Mes amis passent mes lasers", "My friends can pass my lasers"},
	{"Quand ta base est verrouillée, tes amis Roblox peuvent entrer (pas les inconnus)", "When your base is locked, your Roblox friends can enter (not strangers)"},
	{"Commandes admin", "Admin commands"},
	{"🛡️ Tu as les commandes admin ! Tape /aide pour la liste", "🛡️ You have admin commands! Type /aide for the list"},
	{"Joueur introuvable : ", "Player not found: "},
	{"Il faut viser un joueur : /", "You must target a player: /"},
	{"Expulsé par un admin", "Kicked by an admin"},
	{"💰 Ton argent : $", "💰 Your money: $"},
	{"💰 Argent x2 pour toujours !", "💰 Money x2 forever!"},
	{"🤖 Collecte auto : l'argent de ta base arrive tout seul !", "🤖 Auto collect: your base money comes in by itself!"},
	{"👑 TOUT débloqué : argent, rebirths max, meilleurs outils, tapis volant, VIP et toutes les cartes !", "👑 EVERYTHING unlocked: money, max rebirths, best tools, flying carpet, VIP and all cards!"},
	{"🔁 Rebirths : ", "🔁 Rebirths: "},

	-- ===== annonces (chat) =====
	{" a miné un ", " mined a "},
	{" a pack un ", " pulled a "},
	{" a obtenu un ", " got a "},
	{" a gagné à la roue un ", " won on the wheel a "},
	{" a reçu en cadeau un ", " received a "},
	{" a ouvert son cadeau de départ un ", " opened the starter gift: a "},

	-- ===== descriptions des cartes =====
	{"Il frappe trois fois à ta porte avant le lever du soleil.", "He knocks on your door three times before sunrise."},
	{"Le lucky block le plus mystérieux du jeu.", "The most mysterious lucky block in the game."},
	{"Le roi des tigres, avec sa couronne en or.", "The king of tigers, with his golden crown."},
	{"La légende absolue. Presque introuvable dans la mine.", "The absolute legend. Almost impossible to find in the mine."},
	{"Un café ninja armé de deux katanas. Serré, sans sucre.", "A ninja coffee armed with two katanas. Strong, no sugar."},
	{"Un caillou en short léopard. Très à la mode.", "A pebble in leopard shorts. Very trendy."},
	{"Un carton en baskets. Il déménage tout le temps.", "A cardboard box in sneakers. Always moving house."},
	{"Un dragon d'or à plusieurs têtes. Il crache du feu éternel.", "A golden many-headed dragon. It breathes eternal fire."},
	{"Un grand costaud en chaussures neuves. Ne marche pas dessus.", "A big guy in brand new shoes. Don't step on them."},
	{"Un hibou qui vit dans un sapin. Il ne dort jamais.", "An owl living in a pine tree. It never sleeps."},
	{"Un hérisson tout rond. Il pique un tout petit peu.", "A round hedgehog. It's just a tiny bit spiky."},
	{"Un kangourou tout doux. Il saute plus haut que les nuages.", "A soft kangaroo. It jumps higher than the clouds."},
	{"Un lion-cactus. Sa crinière pique.", "A cactus lion. Its mane is prickly."},
	{"Un lucky block avec des ailes d'ange. Que va-t-il en sortir ?", "A lucky block with angel wings. What will come out?"},
	{"Un oiseau-citron. Il répète tout, en plus acide.", "A lemon bird. It repeats everything, but sourer."},
	{"Un orang-outan déguisé en ananas.", "An orangutan dressed as a pineapple."},
	{"Un panda avec des ailes en banane.", "A panda with banana wings."},
	{"Un pigeon pilote avec ses lunettes d'aviateur.", "A pilot pigeon with aviator goggles."},
	{"Un poisson avec un gros ventre. Il a trop mangé.", "A fish with a big belly. It ate too much."},
	{"Un requin en forme de cube. Il nage de travers.", "A cube-shaped shark. It swims sideways."},
	{"Un requin sur pattes en baskets. Il court très vite.", "A shark on legs in sneakers. It runs very fast."},
	{"Un squelette qui partage sa connexion avec tout le monde.", "A skeleton that shares its connection with everyone."},
	{"Un tigre-pastèque. Il rugit en pépins.", "A watermelon tiger. It roars seeds."},
	{"Une araignée rouge qui sourit. C'est pire.", "A smiling red spider. That's worse."},
	{"Une bouteille qui porte toujours sa soupe.", "A bottle that always carries its soup."},
	{"Une citrouille géante en baskets de luxe.", "A giant pumpkin in luxury sneakers."},
	{"Une fraise carrée. Personne ne sait pourquoi.", "A square strawberry. Nobody knows why."},
	{"Une pastèque en colère. Elle crache des pépins.", "An angry watermelon. It spits seeds."},
	{"Une pieuvre-myrtille venue du fond des abysses.", "A blueberry octopus from the depths of the abyss."},
	{"Une souris à lunettes. Elle a tout lu.", "A mouse with glasses. It has read everything."},
	{"Une tasse de café qui prend feu. Serré et brûlant.", "A coffee cup on fire. Strong and burning hot."},
	{"Une théière qui se promène. Attention, elle est brûlante.", "A walking teapot. Careful, it's hot."},
	{"Une tortue divine couverte de pousses magiques.", "A divine turtle covered in magic sprouts."},
	{"Une tortue-pastèque. Lente mais délicieuse.", "A watermelon turtle. Slow but delicious."},
	{"Une vache-planète entourée d'anneaux. Meuh cosmique.", "A planet cow surrounded by rings. Cosmic moo."},

	-- ===== aide admin (/aide) =====
	{"Vise un joueur avec son pseudo (ex : /vip Bob ou /vip @Bob) • @all = tout le serveur • montants : 1k, 1m, 1b, 1t", "Target a player with their name (ex: /vip Bob or /vip @Bob) • @all = whole server • amounts: 1k, 1m, 1b, 1t"},
	{"affiche cette liste", "shows this list"},
	{"TOUT : argent, rebirths max, meilleurs outils, tapis, VIP, toutes les cartes", "EVERYTHING: money, max rebirths, best tools, carpet, VIP, all cards"},
	{"donne une carte (ex : /give @Bob sahur galaxie 3)", "gives a card (ex: /give @Bob sahur galaxie 3)"},
	{"ajoute de l'argent (ex : /cash 10m)", "adds money (ex: /cash 10m)"},
	{"met l'argent à ce montant", "sets money to this amount"},
	{"change les rebirths (0 = les enlever)", "changes rebirths (0 = remove them)"},
	{"change la pioche", "changes the pickaxe"},
	{"enlève la Pioche Divine (retour à la pioche normale)", "removes the Divine Pickaxe (back to the normal pickaxe)"},
	{"change la batte", "changes the bat"},
	{"change le grappin (0 = aucun)", "changes the grapple (0 = none)"},
	{"met une mutation sur la carte tenue en main", "puts a mutation on the card in hand"},
	{"donne des minerais", "gives minerals"},
	{"ajoute des tours de roue", "adds wheel spins"},
	{"donne le Pack VIP (tag, chat vert, tapis, x2, minerais)", "gives the VIP Pack (tag, green chat, carpet, x2, minerals)"},
	{"enlève le VIP", "removes VIP"},
	{"donne le tapis volant", "gives the flying carpet"},
	{"donne l'argent x2", "gives money x2"},
	{"donne la collecte auto (l'argent de la base arrive tout seul)", "gives auto collect (base money comes in by itself)"},
	{"débloque tout l'Index (toutes les cartes et mutations)", "unlocks the whole Index (all cards and mutations)"},
	{"récompense quotidienne disponible tout de suite", "daily reward available right now"},
	{"le cadeau de départ peut être repris", "the starter gift can be claimed again"},
	{"vitesse de marche (16 = normal)", "walk speed (16 = normal)"},
	{"te téléporte sur ce joueur", "teleports you to this player"},
	{"téléporte ce joueur sur toi", "teleports this player to you"},
	{"verrouille la base (lasers)", "locks the base (lasers)"},
	{"ouvre la base (coupe les lasers)", "opens the base (turns off the lasers)"},
	{"régénère la mine maintenant", "resets the mine now"},
	{"message pour tout le serveur", "message for the whole server"},
	{"expulse un joueur", "kicks a player"},
	{"donne les commandes admin à ce joueur (jusqu'à la fin du serveur)", "gives admin commands to this player (until the server closes)"},
	{"enlève les commandes admin", "removes admin commands"},
	{"Écris un montant, ex : /cash 10m", "Type an amount, ex: /cash 10m"},
	{"Écris un montant, ex : /setcash 0", "Type an amount, ex: /setcash 0"},
	{"Il faut tenir une carte en main, et écrire /mutation <nom>", "Hold a card and type /mutation <name>"},
	{"Seul le créateur du jeu peut donner les commandes admin", "Only the game creator can give admin commands"},
	{"Seul le créateur du jeu peut enlever les commandes admin", "Only the game creator can remove admin commands"},
	{"Impossible d'expulser ce joueur", "Can't kick this player"},
	{"Écris /bring @joueur", "Type /bring @player"},
	{"Écris /tp @joueur", "Type /tp @player"},

	-- ===== divers =====
	{"Pour le récupérer :", "To get it back:"},

	-- ===== petits morceaux (en dernier) =====
	{"Tu as déjà", "You already have"},
	{"Rebirth ", "Rebirth "},
	{"🔒 Rebirth ", "🔒 Rebirth "},
	{"DÉJÀ", "ALREADY"},
	{"PAS PRÊT", "NOT READY"},
	{"PRÊT", "READY"},
	{"MANQUANT", "MISSING"},
	{" joueurs", " players"},
	{"Joueur ", "Player "},
	{" jour", " day"},
	{" à ", " to "}, -- "Tu as donné X à Bob" (tout le reste est déjà traduit avant)
}

-- ============================================================
-- 2. MOTS SEULS (remplacés seulement quand le mot est entier)
-- ============================================================
local WORDS = {
	-- raretés
	{"Très Rare", "Very Rare"}, {"Commun", "Common"}, {"Épique", "Epic"}, {"Légendaire", "Legendary"},
	{"Mythique", "Mythic"}, {"Enfer", "Infernal"}, {"Cosmique", "Cosmic"},
	-- mutations / minerais
	{"Arc-en-ciel", "Rainbow"}, {"Radioactif", "Radioactive"}, {"Galaxie", "Galaxy"}, {"Lave", "Lava"},
	{"Diamant", "Diamond"}, {"Émeraude", "Emerald"}, {"Or", "Gold"}, {"Argent", "Cash"},
	-- couches de la mine
	{"Herbe", "Grass"}, {"Terre", "Dirt"}, {"Pierre", "Stone"}, {"Obsidienne", "Obsidian"},
	{"Cristal", "Crystal"}, {"Néant", "Void"}, {"Noyau", "Core"},
	-- menus
	{"Sac", "Bag"}, {"Cadeaux", "Gifts"}, {"Échange", "Trade"}, {"Boutique", "Shop"}, {"Pioches", "Pickaxes"},
	{"Pioche", "Pickaxe"}, {"Batte", "Bat"}, {"Grappin", "Grapple"}, {"Musique", "Music"},
	-- boutons E (ProximityPrompt)
	{"Vendre", "Sell"}, {"Voler", "Steal"}, {"Ramasser", "Pick up"}, {"Reprendre", "Take back"},
	{"Ouvrir", "Open"}, {"Toi", "You"},
	-- boutons
	{"PRENDRE", "TAKE"}, {"DONNER", "GIVE"}, {"VENDRE", "SELL"}, {"COLLECTER", "COLLECT"},
	{"ANNULER", "CANCEL"}, {"ABANDONNER", "GIVE UP"}, {"ÉCHANGER", "TRADE"}, {"OUI", "YES"}, {"NON", "NO"},
	{"CONDITIONS", "CONDITIONS"},
	-- couleurs des fils (piratage)
	{"ROUGE", "RED"}, {"BLEU", "BLUE"}, {"JAUNE", "YELLOW"}, {"VERT", "GREEN"}, {"VIOLET", "PURPLE"},
	{"ROSE", "PINK"}, {"BLANC", "WHITE"},
	-- petits mots
	{"secondes", "seconds"},
}

-- ============================================================
-- MOTEUR
-- ============================================================
local phraseList = {} -- {fr, en}, les plus longs d'abord
local wordList = {}
local seen = {}

local function addPhrase(list, fr, en)
	if fr == "" or seen[list] and seen[list][fr] then return end
	seen[list] = seen[list] or {}
	seen[list][fr] = true
	table.insert(list, {fr, en})
end

-- chaque texte, en minuscules/majuscules normales, en MAJUSCULES (avec accents : GameConfig.upper)
-- et en MAJUSCULES « simples » (string.upper laisse les lettres accentuées en minuscules)
for _, entry in ipairs(PHRASES) do
	addPhrase(phraseList, entry[1], entry[2])
	addPhrase(phraseList, GameConfig.upper(entry[1]), GameConfig.upper(entry[2]))
	addPhrase(phraseList, string.upper(entry[1]), string.upper(entry[2]))
end
for _, entry in ipairs(WORDS) do
	addPhrase(wordList, entry[1], entry[2])
	addPhrase(wordList, GameConfig.upper(entry[1]), GameConfig.upper(entry[2]))
	addPhrase(wordList, string.upper(entry[1]), string.upper(entry[2]))
end
table.sort(phraseList, function(a, b) return #a[1] > #b[1] end)
table.sort(wordList, function(a, b) return #a[1] > #b[1] end)

-- une lettre (ASCII ou accentuée) ? (pour savoir si un mot est entier)
local function isLetter(byte)
	return byte ~= nil and ((byte >= 65 and byte <= 90) or (byte >= 97 and byte <= 122) or byte >= 128)
end

local function replaceAll(text, from, to, wholeWord)
	local start = 1
	local out = {}
	while true do
		local i, j = string.find(text, from, start, true)
		if not i then break end
		local ok = true
		if wholeWord then
			ok = not isLetter(string.byte(text, i - 1)) and not isLetter(string.byte(text, j + 1))
		end
		if ok then
			table.insert(out, string.sub(text, start, i - 1))
			table.insert(out, to)
		else
			table.insert(out, string.sub(text, start, j))
		end
		start = j + 1
	end
	if #out == 0 then
		return text
	end
	table.insert(out, string.sub(text, start))
	return table.concat(out)
end

local cache = {}
local cacheSize = 0

-- Traduit un texte français en anglais (renvoie le texte tel quel s'il n'y a rien à traduire)
function Translator.translate(text)
	if type(text) ~= "string" or text == "" or not string.find(text, "%a") then
		return text
	end
	local cached = cache[text]
	if cached then
		return cached
	end
	local result = text
	for _, entry in ipairs(phraseList) do
		if string.find(result, entry[1], 1, true) then
			result = replaceAll(result, entry[1], entry[2], false)
		end
	end
	for _, entry in ipairs(wordList) do
		if string.find(result, entry[1], 1, true) then
			result = replaceAll(result, entry[1], entry[2], true)
		end
	end
	if cacheSize > 4000 then
		table.clear(cache)
		cacheSize = 0
	end
	cache[text] = result
	cache[result] = result -- le texte anglais ne se retraduit pas
	cacheSize += 2
	return result
end

-- Le joueur doit-il avoir le jeu en anglais ? (tout le monde sauf les francophones)
function Translator.isEnglish(player)
	player = player or Players.LocalPlayer
	local ok, locale = pcall(function()
		return player.LocaleId
	end)
	if not ok or type(locale) ~= "string" or locale == "" then
		return false -- langue inconnue : on garde le français
	end
	return string.sub(string.lower(locale), 1, 2) ~= "fr"
end

-- ============================================================
-- CÔTÉ CLIENT : traduit tout ce qui s'affiche (écran + monde)
-- ============================================================
local watched = setmetatable({}, {__mode = "k"})

local function watchText(object, property)
	local function apply()
		local current = object[property]
		local translated = Translator.translate(current)
		if translated ~= current then
			object[property] = translated
		end
	end
	apply()
	object:GetPropertyChangedSignal(property):Connect(apply)
end

local function watch(object)
	if watched[object] then return end
	if object:IsA("TextLabel") or object:IsA("TextButton") then
		watched[object] = true
		watchText(object, "Text")
	elseif object:IsA("ProximityPrompt") then
		watched[object] = true
		watchText(object, "ActionText")
		watchText(object, "ObjectText")
	end
end

function Translator.start(force)
	if not force and not Translator.isEnglish() then
		return false
	end
	Translator.active = true
	local player = Players.LocalPlayer
	local roots = {player:WaitForChild("PlayerGui"), workspace}
	for _, root in ipairs(roots) do
		for _, object in ipairs(root:GetDescendants()) do
			watch(object)
		end
		root.DescendantAdded:Connect(watch)
	end
	return true
end

-- Pour les textes qui ne passent pas par l'écran (ex : messages dans le chat)
function Translator.chat(text)
	if Translator.active then
		return Translator.translate(text)
	end
	return text
end

return Translator
