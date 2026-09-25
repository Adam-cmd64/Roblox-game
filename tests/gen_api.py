# Convertit le dump de l'API Roblox en table Luau (classes, propriétés, enums)
import json, sys
d = json.load(open(sys.argv[1]))
q = lambda s: json.dumps(s, ensure_ascii=False)
out = ['return {', 'classes = {']
for c in d['Classes']:
    tags = c.get('Tags') or []
    members = []
    for m in c.get('Members', []):
        kind, name, mtags = m['MemberType'], m['Name'], m.get('Tags') or []
        if kind == 'Property':
            vt = m['ValueType']
            members.append('[%s]={k="P",c=%s,t=%s,ro=%s}' % (q(name), q(vt['Category']), q(vt['Name']), 'true' if 'ReadOnly' in mtags else 'false'))
        elif kind in ('Function', 'Event', 'Callback'):
            members.append('[%s]={k="%s"}' % (q(name), kind[0]))
    creatable = 'false' if ('NotCreatable' in tags or 'Service' in tags) else 'true'
    out.append('[%s]={super=%s,creatable=%s,members={%s}},' % (q(c['Name']), q(c['Superclass']), creatable, ','.join(members)))
out.append('},')
out.append('enums = {')
for e in d['Enums']:
    out.append('[%s]={%s},' % (q(e['Name']), ','.join('[%s]=%d' % (q(i['Name']), i['Value']) for i in e['Items'])))
out.append('},')
out.append('}')
open(sys.argv[2], 'w').write('\n'.join(out))
