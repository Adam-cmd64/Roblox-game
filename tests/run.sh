#!/bin/bash
# Lance le simulateur Roblox : il joue une partie complète (minage, base, rebirth, étages,
# boutique, boosters, échange, sauvegarde) et affiche les erreurs de script.
# Prérequis : Linux ou macOS avec curl, unzip et python3.
set -e
cd "$(dirname "$0")"
CACHE=.cache
mkdir -p "$CACHE"

if [ ! -x "$CACHE/luau" ]; then
	curl -sSLo "$CACHE/luau.zip" https://github.com/luau-lang/luau/releases/latest/download/luau-ubuntu.zip
	unzip -oq "$CACHE/luau.zip" -d "$CACHE"
fi
if [ ! -f "$CACHE/api_data.luau" ]; then
	curl -sSLo "$CACHE/api.json" https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/API-Dump.json
	python3 gen_api.py "$CACHE/api.json" "$CACHE/api_data.luau"
fi

python3 gen_sources.py .. "$CACHE/sources.luau"
cp mock.luau test.luau "$CACHE/"
cd "$CACHE" && ./luau test.luau
