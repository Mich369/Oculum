// Assemble original Canva PNG material into the app's existing safe margins.
// This is deterministic export/layout, not a replacement illustration.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const packs = [
  ['canva_ice', 'ice-frame.png', 'MAHYIjPQqpM'],
  ['canva_spirit', 'spirit-frame.png', 'MAHYIrXYxZA'],
  ['canva_physical', 'physical-frame.png', 'MAHYIp4_Ams'],
];
async function frame(source, w, h) {
  const metadata=await sharp(source).metadata();
  if(!metadata.hasAlpha) throw new Error(`Missing Canva alpha: ${source}`);
  const sw=metadata.width,sh=metadata.height;
  const band=Math.min(24,Math.floor(h/4));
  const corner=256, rail=176;
  const layers=[];
  async function part(rect,width,height,left,top) {
    const input=await sharp(source).extract(rect).resize(width,height,{fit:'fill'}).png().toBuffer();
    layers.push({input,left,top});
  }
  for(const [x,y,px,py] of [[0,0,0,0],[sw-corner,0,w-band,0],[0,sh-corner,0,h-band],[sw-corner,sh-corner,w-band,h-band]]) {
    await part({left:x,top:y,width:corner,height:corner},band,band,px,py);
  }
  await part({left:corner,top:0,width:sw-2*corner,height:rail},w-2*band,band,band,0);
  await part({left:corner,top:sh-rail,width:sw-2*corner,height:rail},w-2*band,band,band,h-band);
  await part({left:0,top:corner,width:rail,height:sh-2*corner},band,h-2*band,0,band);
  await part({left:sw-rail,top:corner,width:rail,height:sh-2*corner},band,h-2*band,w-band,band);
  return sharp({create:{width:w,height:h,channels:4,background:'#00000000'}}).composite(layers).png().toBuffer();
}
async function run() {
  const manifestPath=path.join(root,'design/theme-art-manifest.json');
  const ids=new Set(packs.map(pack=>pack[0]));
  const manifest=JSON.parse(fs.readFileSync(manifestPath,'utf8')).filter(entry=>!ids.has(entry.theme));
  for(const [id,file,mediaId] of packs) {
    const source=path.join(root,'design/materials/canva-20261016',file);
    const output=path.join(root,'assets/themes',id);
    for(const folder of ['frames','decorations','overlays'])fs.mkdirSync(`${output}/${folder}`,{recursive:true});
    for(const [role,w,h] of [['panel',1024,512],['mobile',640,320],['portrait',256,256],['statistics',256,192],['separator',768,64],['scene',1024,192],['scene-mobile',640,96]]) {
      const original=await frame(source,w,h);
      for(const variant of ['', 'still','alive']) {
        const buffer=await sharp(original).modulate({brightness:variant==='alive'?1.1:1}).png().toBuffer();
        fs.writeFileSync(`${output}/${role.startsWith('scene')?'decorations':'frames'}/${role}${variant?'-'+variant:''}.png`,buffer);
      }
    }
    for(const [state,brightness] of [['normal',1],['hover',1.2],['pressed',.7],['selected',1.35],['disabled',.45]]) {
      await sharp(`${output}/frames/panel.png`).modulate({brightness}).png().toFile(`${output}/frames/button-${state}.png`);
    }
    await sharp(source).resize(512,256,{fit:'contain',background:'#00000000'}).png().toFile(`${output}/overlays/relic.png`);
    const design=path.join(root,'design/themes',id);
    fs.mkdirSync(design,{recursive:true});
    fs.writeFileSync(`${design}/source.json`,JSON.stringify({provider:'Canva',referenceDesign:'DAHX-kQUyBo',transparentMediaId:mediaId,original:source.split(path.sep).slice(-4).join('/'),originalWidth:1776,originalHeight:896,safeBand:24,exporter:'scripts/build_canva_theme_frames.cjs'},null,2)+'\n');
    for(const folder of ['frames','decorations','overlays'])for(const filename of fs.readdirSync(`${output}/${folder}`)) {
      const relative=`assets/themes/${id}/${folder}/${filename}`;
      const bytes=fs.readFileSync(path.join(root,relative));
      manifest.push({theme:id,role:filename.replace('.png',''),path:relative,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
    }
    console.log(`Exported ${id} from original Canva PNG`);
  }
  fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n');
}
run().catch(error=>{console.error(error);process.exitCode=1;});
