import json,urllib.request,zipfile,pathlib
root=pathlib.Path('build/github-artifacts-37741874069')
for a in json.loads(pathlib.Path('output/artifact-transfer.json').read_text()):
 p=root/(a['name']+'.zip')
 with urllib.request.urlopen(urllib.request.Request(a['url'],headers={'User-Agent':'Mozilla/5.0'}),timeout=30) as r,p.open('wb') as f:
  while data:=r.read(65536): f.write(data)
 with zipfile.ZipFile(p) as z:
  if z.testzip(): raise RuntimeError('corrupt')
  z.extractall(root/a['name'])
 p.unlink(); print(a['name']+' verified',flush=True)

