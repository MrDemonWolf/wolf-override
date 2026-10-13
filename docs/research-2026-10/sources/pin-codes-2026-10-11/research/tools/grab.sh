#!/bin/zsh
# usage: grab.sh URL NAME KEYWORD...
D=${SESSION_SCRATCH:?session scratch, not kept}/pin-design/research/dl
url=$1; name=$2; shift 2
curl -sL -m 40 -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15" -H "Accept-Language: en-US" "$url" -o "$D/$name.html"
python3 -I - "$D/$name.html" "$@" <<'PY'
import re,html,sys
t=open(sys.argv[1],errors='ignore').read()
t=re.sub(r'(?is)<script.*?</script>|<style.*?</style>','',t); t=html.unescape(re.sub(r'<[^>]+>',' ',t)); t=re.sub(r'\s+',' ',t)
print('LEN',len(t), t[:150])
for k in sys.argv[2:]:
  for m in list(re.finditer(k,t,re.I))[:3]: print('>>',k,':',t[max(0,m.start()-220):m.end()+260])
PY
