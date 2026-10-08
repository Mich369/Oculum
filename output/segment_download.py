from pathlib import Path
p=Path('output/download_current_artifacts.py');s=p.read_text(encoding='utf-8-sig');start=s.index('   with urllib.request.urlopen(url,timeout=30,context=ctx)');end=s.index('   with zipfile.ZipFile',start)
s=s[:start]+'''   offset=0
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
''' + s[end:];p.write_text(s,encoding='utf-8')
