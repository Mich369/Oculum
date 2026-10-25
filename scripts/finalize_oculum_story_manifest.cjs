const fs=require('fs'),path=require('path');
const root=path.resolve(__dirname,'..'),dir=path.join(root,'docs','theme-art');
const catalogue=JSON.parse(fs.readFileSync(path.join(dir,'catalogue.json'),'utf8'));
const prompts=new Map();
function normalizeFile(file){return typeof file==='string'&&file.startsWith('assets/oculum/theme_stories/')&&!file.includes('/webp/')?file.replace('/theme_stories/','/theme_stories/webp/').replace(/\.png$/,'.webp'):file;}
for(const name of fs.readdirSync(dir).filter(n=>/^batch-.*\.json$/.test(n)).sort()){
 const file=path.join(dir,name),data=JSON.parse(fs.readFileSync(file,'utf8'));
 data.status='Historical generation batch. Final assets and latest prompts are indexed in catalogue.json and latest-prompts.json.';
 for(const a of data.images??[]){a.file=normalizeFile(a.file);if(a.prompt)prompts.set(a.id,a.prompt);delete a.source;}
 fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n');
}
const individual=path.join(dir,'individual');
for(const name of fs.readdirSync(individual).filter(n=>n.endsWith('.json'))){
 const file=path.join(individual,name),data=JSON.parse(fs.readFileSync(file,'utf8'));
 data.file=normalizeFile(data.file);delete data.source;
 if(data.prompt)prompts.set(data.id,data.prompt);
 fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n');
}
catalogue.referenceSun='assets/oculum/theme_stories/webp/benedict.webp';
catalogue.canonicalLore.underground='Closed continuous rock ceilings; no sky, sun, moon, clouds or surface openings.';
catalogue.canonicalLore.obser='Cracked grey stone disc with engraved central almond eye; not generic decoration.';
catalogue.canonicalLore.elementalForest='Fire trees, living green trees, frozen trees, crystals, earth and streams share a coherent forest.';
const registry=fs.readFileSync(path.join(root,'lib/widgets/oculum_element_theme_registry.dart'),'utf8').split('const oculumElementThemeStyles')[0];
catalogue.elementThemes=Object.fromEntries([...registry.matchAll(/'([^']+)': '([^']+)'/g)].map(m=>[m[1],m[2]]));
for(const a of catalogue.assets)a.file=normalizeFile(a.file);
fs.writeFileSync(path.join(dir,'catalogue.json'),JSON.stringify(catalogue,null,2)+'\n');
const latest=catalogue.assets.map(a=>({id:a.id,name:a.name,file:a.file,prompt:prompts.get(a.id)??null}));
if(latest.some(a=>!a.prompt))throw Error('Missing final prompt: '+latest.filter(a=>!a.prompt).map(a=>a.id));
fs.writeFileSync(path.join(dir,'latest-prompts.json'),JSON.stringify({provider:'built-in imagegen',canonicalLore:catalogue.canonicalLore,images:latest},null,2)+'\n');
fs.writeFileSync(path.join(dir,'scene-briefs.json'),JSON.stringify({status:'Final illustration index; canonical constraints apply to every scene.',reference:catalogue.reference,referenceSun:catalogue.referenceSun,canonicalLore:catalogue.canonicalLore,scenes:latest.map(({prompt,...a})=>a)},null,2)+'\n');
console.log(JSON.stringify({illustrations:latest.length,elementThemes:Object.keys(catalogue.elementThemes).length,prompts:latest.length}));
