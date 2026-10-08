import pathlib,zipfile,json,subprocess,hashlib
root=pathlib.Path('build/github-artifacts-37741874069')
arts=json.loads(subprocess.check_output(['gh','api','repos/Mich369/Oculum/actions/runs/37741874069/artifacts']))['artifacts']
for a in arts:
 p=root/(a['name']+'.zip'); assert p.stat().st_size==a['size_in_bytes']
 assert 'sha256:'+hashlib.file_digest(p.open('rb'),'sha256').hexdigest()==a['digest'],a['name']
 with zipfile.ZipFile(p) as z:
  assert z.testzip() is None
  z.extractall(root/a['name'])
 print(a['name']+' SHA256 and ZIP verified',flush=True)
