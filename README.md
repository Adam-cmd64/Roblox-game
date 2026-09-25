# ⛏️ Mine Brainrot (Roblox)

## Le but du jeu

1. **Tu mines des rochers** avec ta pioche. Chaque clic enlève des PV au rocher.
2. Quand le rocher casse, **tu obtiens une carte brainrot au hasard** (Tralalero, Bombardiro, **Tung Tung Tung Sahur**, Patapim, Chimpanzini...). Plus elle est rare, plus elle rapporte.
3. Les cartes vont dans **ta base** (en bas de l'écran) et **rapportent du Cash chaque seconde**.
4. Avec le Cash, tu **achètes une meilleure pioche** (Bois → Pierre → Fer → Or → Diamant). Chaque pioche fait plus de dégâts.
5. Mais chaque nouvelle pioche est **verrouillée derrière un Rebirth**.
6. **Rebirth = 1000 Cash + 1 carte Tung Tung Tung Sahur** (consommée). Ton Cash repart à 0, mais tu gagnes **+50 % de revenu pour toujours** et tu débloques la pioche suivante.

| Carte | Rareté | $/s | Chance |
|---|---|---|---|
| 🦈 Tralalero Tralala | Commune | 1 | 50 % |
| 🐊 Bombardiro Crocodilo | Rare | 3 | 30 % |
| 🪵 Tung Tung Tung Sahur | Épique | 8 | 15 % |
| 🌳 Brr Brr Patapim | Légendaire | 20 | 4 % |
| 🍌 Chimpanzini Bananini | Mythique | 60 | 1 % |

| Pioche | Dégâts | Prix | Rebirths requis |
|---|---|---|---|
| Bois | 1 | gratuit | 0 |
| Pierre | 3 | 250 | 1 |
| Fer | 8 | 1000 | 2 |
| Or | 20 | 5000 | 3 |
| Diamant | 50 | 20000 | 4 |

Tous ces chiffres se modifient dans un seul fichier : `src/ReplicatedStorage/GameConfig.lua`.

## Installation dans Roblox Studio (copier-coller)

Supprime d'abord les anciens scripts (`BrainrotServer`, `BrainrotClient`, le ScreenGui `BrainrotUI` et le dossier `RemoteEvents`) — les RemoteEvents sont maintenant **créés automatiquement** par le script serveur.

| Fichier du repo | Où le créer dans Studio | Type d'objet |
|---|---|---|
| `src/ReplicatedStorage/GameConfig.lua` | `ReplicatedStorage` → nommé `GameConfig` | **ModuleScript** |
| `src/ServerScriptService/BrainrotServer.server.lua` | `ServerScriptService` → nommé `BrainrotServer` | **Script** |
| `src/StarterPlayer/StarterPlayerScripts/BrainrotClient.client.lua` | `StarterPlayer > StarterPlayerScripts` → nommé `BrainrotClient` | **LocalScript** |

Puis clique sur **Play**.

### Avec Rojo (optionnel)

Le fichier `default.project.json` est prêt : `rojo serve` puis connecte-toi depuis le plugin Rojo dans Studio.

## Visuels

- Les rochers ont des pépites de minerai colorées et explosent en débris.
- Tu tiens une vraie pioche (Tool) dont la tête change de couleur selon ton niveau.
- Chaque carte a son propre visuel (couleur, emoji, rareté, revenu) ; une popup animée s'affiche quand tu en trouves une.
- Pour des modèles 3D plus fidèles (ex. un vrai Tung Tung Tung Sahur), on peut brancher des modèles de la Boîte à outils à la place des rochers/cartes.
