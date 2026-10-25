// Read-only asset checks and derived contact sheets. Original images are preserved.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),cp=require('child_process');
const sharp=require(process.argv[2]||'sharp');
const root=path.resolve(__dirname,'..'), partial=process.argv.includes('--partial');
const catalogue=JSON.parse(fs.readFileSync(path.join(root,'docs/theme-art/catalogue.json'),'utf8'));
const out=path.join(root,'build','theme-art-qa');fs.mkdirSync(out,{recursive:true});
const esc=s=>s.replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
(async()=>{
 const records=[],missing=[],seen=new Map(),duplicates=[];
 for(const a of catalogue.assets){
  const file=path.join(root,a.file);
  if(!fs.existsSync(file)){missing.push(a.id);continue;}
  const data=fs.readFileSync(file),m=await sharp(data).metadata(),digest=crypto.createHash('sha256').update(data).digest('hex');
  if(m.format!=='webp'||m.width<1280||m.height<700||Math.abs(m.width/m.height-16/9)>.04)throw Error('Invalid story artwork '+a.id);
  if(seen.has(digest))duplicates.push([seen.get(digest),a.id]);seen.set(digest,a.id);
  records.push({...a,width:m.width,height:m.height,bytes:data.length,sha256:digest});
 }
 const reference='assets/oculum/home_art/amber_shore.png';
 const original=cp.execFileSync('git',['rev-parse','HEAD:'+reference],{cwd:root,encoding:'utf8'}).trim();
 const current=cp.execFileSync('git',['hash-object',reference],{cwd:root,encoding:'utf8'}).trim();
 if(original!==current)throw Error('Original Rame fatato was modified');
 if(duplicates.length)throw Error('Duplicate story artwork: '+JSON.stringify(duplicates));
 const cols=5,w=300,h=188,per=25;
 for(let page=0;page<Math.ceil(records.length/per);page++){
  const entries=records.slice(page*per,(page+1)*per),layers=[];
  for(let i=0;i<entries.length;i++){
   const a=entries[i],x=i%cols*w,y=Math.floor(i/cols)*h;
   layers.push({input:await sharp(path.join(root,a.file)).resize(w,169,{fit:'cover'}).toBuffer(),left:x,top:y});
   const svg='<svg xmlns="http://www.w3.org/2000/svg" width="'+w+'" height="19"><rect width="100%" height="100%" fill="#101219"/><text x="6" y="14" font-size="11" font-family="sans-serif" fill="#eee">'+esc(a.id)+'</text></svg>';
   layers.push({input:Buffer.from(svg),left:x,top:y+169});
  }
  await sharp({create:{width:cols*w,height:Math.ceil(entries.length/cols)*h,channels:4,background:'#101219'}}).composite(layers).png().toFile(path.join(out,'contact-'+String(page+1).padStart(2,'0')+'.png'));
 }
 const report={expected:catalogue.assets.length,present:records.length,missing,originalReferencePreserved:true,assets:records};
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify({expected:report.expected,present:records.length,missing:missing.length,megabytes:Math.round(records.reduce((n,a)=>n+a.bytes,0)/104857.6)/10}));
 if(!partial&&missing.length)throw Error('Missing '+missing.length+' story artworks');
})().catch(e=>{console.error(e.message);process.exitCode=1});
