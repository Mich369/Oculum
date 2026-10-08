import json, subprocess, urllib.request, urllib.error, zipfile, pathlib, time, ssl
root=pathlib.Path('build/github-artifacts-37741874069'); root.mkdir(exist_ok=True)
arts=json.loads(subprocess.check_output(['gh','api','repos/Mich369/Oculum/actions/runs/37741874069/artifacts']))['artifacts']
token=subprocess.check_output(['gh','auth','token'],text=True).strip()
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs): return None
opener=urllib.request.build_opener(NoRedirect)
for a in arts:
 dest=root/a['name']; dest.mkdir(exist_ok=True)
 for attempt in range(3):
  try:
   req=urllib.request.Request(a['archive_download_url'],headers={'Authorization':'Bearer '+token,'User-Agent':'Oculum'})
   try: r=opener.open(req)
   except urllib.error.HTTPError as e:
    if e.code != 302: raise
    url=e.headers['Location']
   archive=root/(a['name']+'.zip')
   ctx=ssl.create_default_context(); ctx.minimum_version=ssl.TLSVersion.TLSv1_2; ctx.maximum_version=ssl.TLSVersion.TLSv1_2
   offset=0
   with archive.open('wb') as f:
    while True:
     for chunk_attempt in range(5):
      try:
       req=urllib.request.Request(url,headers={'Range':f'bytes={offset}-{offset+1048575}'})
       with urllib.request.urlopen(req,timeout=20,context=ctx) as r:
        data=r.read(); cr=r.headers.get('Content-Range'); total=int(cr.split('/')[-1]) if cr else len(data)
       break
      except Exception:
       if chunk_attempt==4: raise
     f.write(data); offset+=len(data)
     if offset>=total: break
   with zipfile.ZipFile(archive) as z:
    if z.testzip(): raise RuntimeError('ZIP corrupt')
    z.extractall(dest)
   archive.unlink(); print(a['name']+' verified',flush=True); break
  except Exception:
   if attempt==2: raise
   time.sleep(2)



