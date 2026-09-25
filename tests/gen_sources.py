# Met le code du jeu (src/) dans un fichier Luau lisible par le simulateur
import json, os, sys
root, target = sys.argv[1], sys.argv[2]
out = ['return {']
for folder, _, files in os.walk(os.path.join(root, 'src')):
    for f in files:
        if f.endswith('.lua'):
            path = os.path.join(folder, f)
            key = os.path.relpath(path, root)
            out.append('[%s] = %s,' % (json.dumps(key), json.dumps(open(path, encoding='utf-8').read(), ensure_ascii=False)))
out.append('}')
open(target, 'w', encoding='utf-8').write('\n'.join(out))
