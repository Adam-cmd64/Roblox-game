# ⛏️ Mine Brainrot (Roblox)

## Le but du jeu

1. **Mine** dans la grande mine au centre : tu casses les blocs et tu descends couche par couche (38 couches).
2. Les blocs avec des **cristaux brillants** contiennent un **brainrot**. Il va dans ton **🎒 inventaire**.
3. Va dans **ta base**, ouvre l'inventaire, clique **✋ Prendre** : la carte est dans ta main. Appuie sur **E** devant un emplacement libre pour la **poser**.
4. Chaque brainrot posé **produit de l'argent** qui s'accumule sur son bouton **COLLECTER** : marche dessus pour récupérer.
5. Achète de meilleures pioches à la **⛏️ BOUTIQUE** (le chalet à l'ouest de la mine) : Bois → Pierre → Fer → Or → Diamant → Netherite.
6. **Rebirth** (menu 🔄) : de l'argent + un brainrot précis. Tu gagnes +50 % de revenu, +1 emplacement, et la pioche suivante se débloque à la boutique.
7. **Échange** tes brainrots avec les autres joueurs (3 rebirths d'écart max).
8. **Boosters** (Robux) : des paquets de 3 cartes sans miner.

## Raretés et chances

11 raretés : Commun, Rare, Très Rare, Épique, Légendaire, Mythique, Abyssal, Enfer, God, Eternal, Angel (22 brainrots).

La chance dépend de ta **pioche** et de la **profondeur** :

| Situation | Commun | Rare | Très Rare | Épique | Légendaire+ |
|---|---|---|---|---|---|
| Pioche en bois, surface | 91 % | 7,3 % | 1,3 % | 0,27 % | ~0,08 % |
| Pioche en fer, couche 20 | 84 % | 11 % | 3 % | 1 % | ~0,6 % |
| Netherite, tout au fond | 66 % | 15 % | 7 % | 4 % | ~8 % |

Mutations (rares, affichées au-dessus des cartes avec des effets) : Or x1.5, Diamant x2, Arc-en-ciel x3, Lave x4, Galaxie x6 et Radioactif x8 (ces deux dernières : admin seulement).

## Commandes admin (dans le chat)

Dans Roblox Studio tout le monde est admin. En jeu, ajoute ton UserId dans `GameConfig.ADMINS`.

- `/give sahur` ou `/give graipuss arc-en-ciel` : donne un brainrot (avec mutation optionnelle)
- `/cash 1000000` : ajoute de l'argent
- `/rebirths 3` : change le nombre de rebirths
- `/pickaxe 6` : donne la pioche n°6 (Netherite)
- `/mutation lave` : met une mutation sur la carte que tu tiens en main

## Mettre les vraies images des brainrots

1. Dans Studio : **Fenêtre → Gestionnaire de ressources (Asset Manager) → Images → Importer**, choisis l'image du brainrot.
2. Clic droit sur l'image importée → **Copier l'ID**.
3. Dans `src/ReplicatedStorage/GameConfig.lua`, mets l'ID dans le champ `Image` du brainrot : `Image = "rbxassetid://123456789"`.

Tant que `Image` est vide, la carte affiche le modèle 3D du brainrot.

## Activer les boosters Robux

1. Sur le **Creator Dashboard** : ton jeu → **Monétisation → Produits développeur** → crée un produit par booster (149, 399, 999, 2499 Robux).
2. Copie chaque ID dans `GameConfig.BOOSTERS` (`ProductId = ...`).

Tant que `ProductId = 0`, le booster est **gratuit dans Studio** (pour tester l'animation) et **désactivé en jeu**.

## Sauvegarde

L'argent, les rebirths, la pioche et tous les brainrots sont sauvegardés (DataStore).
Pour tester la sauvegarde dans Studio : **Paramètres du jeu → Sécurité → Enable Studio Access to API Services**.

## Installation avec Rojo

1. `git pull`, puis `.\rojo.exe serve`
2. Studio : **Plugins → Rojo → Connect**
3. **Supprime les anciens objets** qui ne servent plus :
   - `StarterGui > ScreenGui` / `BrainrotUI` (ancienne interface)
   - dans `ServerScriptService` : les anciens `MineManager`, `BaseManager`, `PickaxeBuilder` qui sont **à la racine** (les nouveaux sont DANS `BrainrotServer`)
   - `ReplicatedStorage > RemoteEvents` (recréé automatiquement)
4. **Play**. Toute la map est construite automatiquement au lancement.

## Organisation du code

- `src/ReplicatedStorage/GameConfig.lua` : **tous les réglages** (raretés, brainrots, pioches, couches, rebirths, boosters, admins)
- `src/ReplicatedStorage/CardRenderer.lua` : le design des cartes (style carte à collectionner)
- `src/ReplicatedStorage/BrainrotModels.lua` : les brainrots en 3D
- `src/ServerScriptService/BrainrotServer/` : le serveur (mine, bases, boutique, boosters, échanges, sauvegarde, admin)
- `src/StarterPlayer/StarterPlayerScripts/BrainrotClient/` : l'interface (HUD, fenêtres, échanges, minage, effets)
