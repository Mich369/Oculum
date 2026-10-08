import urllib.request,json,urllib.error
u=json.load(open('output/artifact-transfer.json'))[0]['url']
try:
 r=urllib.request.urlopen(u); print(r.status)
except urllib.error.HTTPError as e: print(e.read().decode()[:1200])
