// Reproducible original vector compositions. Original theme illustrations are
// retained unchanged; runtime PNGs are rendered from these editable SVG sources.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const themes = JSON.parse(fs.readFileSync(path.join(root, 'docs/design/theme-art-bible.json'), 'utf8').replace(/^\uFEFF/, ''));
const familyOf = id => {
  if (/forest|briar|thorn|vervain|natura|meadow|bloom|rose|verdigris/.test(id)) return 'botanical';
  if (/frost|glass|obsidian|aurora/.test(id)) return 'crystal';
  if (/bolted|iron|keep|fortezza|obser|school|stagecoach|cell/.test(id)) return 'forged';
  if (/moon|lunar|astral|cosmic|karma|void/.test(id)) return 'astral';
  if (/abyss|slime|mutation|phobia/.test(id)) return 'tide';
  if (/ember|ash|cenere|bonfire|lume|solar|storm/.test(id)) return 'ember';
  return 'cathedral';
};
const palettes = {botanical:['#493f54','#a98bc1','#68765b'],crystal:['#506374','#b7d1dc','#786891'],forged:['#544d48','#c4ae86','#857469'],astral:['#554f78','#c7bde4','#8584a1'],tide:['#344c58','#91bcc1','#627380'],ember:['#67422e','#d7ad70','#a25a40'],cathedral:['#5c4d4a','#cfbba0','#897276']};
const hash = s => crypto.createHash('sha256').update(s).digest();
function frame(theme, w, h, role) {
  const bytes=hash(theme.id), family=familyOf(theme.id), [dark,light,mid]=palettes[family];
  const compact=role==='mobile', inset=compact?8:12, depth=compact?18:24;
  const v=bytes[0], bend=10+bytes[1]%20, points=4+bytes[2]%5;
  const shapes=[];
  const line=(d,stroke=light,width=1,opacity=.7)=>shapes.push(`<path d="${d}" fill="none" stroke="${stroke}" stroke-width="${width}" opacity="${opacity}" stroke-linecap="round" stroke-linejoin="round"/>`);
  const ellipse=(x,y,rx,ry,fill=dark,stroke=light)=>shapes.push(`<ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="${fill}" stroke="${stroke}" stroke-width="1"/>`);
  const polygon=(p,fill=dark)=>shapes.push(`<polygon points="${p}" fill="${fill}" stroke="${light}" stroke-width="1"/>`);
  // Broken edges deliberately have different lengths and weights per identity.
  for(const [x,y,sx,sy] of [[inset,inset,1,1],[w-inset,inset,-1,1],[inset,h-inset,1,-1],[w-inset,h-inset,-1,-1]]) {
    const horizontal=45+bytes[(x+y)%32]%70, vertical=25+bytes[(x*y)%32]%45;
    line(`M ${x+sx*horizontal} ${y} L ${x+sx*bend} ${y} Q ${x} ${y} ${x} ${y+sy*bend} L ${x} ${y+sy*vertical}`,dark,5,.8);
    line(`M ${x+sx*horizontal} ${y} L ${x+sx*bend} ${y} Q ${x} ${y} ${x} ${y+sy*bend} L ${x} ${y+sy*vertical}`,light,1.1,.8);
    for(let i=0;i<points;i++) {
      const a=12+i*(8+v%5), b=2+bytes[(i+4)%32]%7;
      if(family==='botanical') {
        line(`M ${x+sx*a} ${y} Q ${x+sx*(a+10)} ${y+sy*b} ${x+sx*(a+20)} ${y- sy*4}`,mid,2,.8);
        shapes.push(`<path d="M ${x+sx*a} ${y} Q ${x+sx*(a+6)} ${y+sy*12} ${x+sx*(a+13)} ${y+sy*5} Q ${x+sx*(a+5)} ${y} ${x+sx*a} ${y}" fill="${mid}" opacity=".9"/>`);
        if(i%2===0)ellipse(x+sx*(a+6),y+sy*6,2.5,3.5,light,mid);
      } else if(family==='crystal') {
        polygon(`${x+sx*a},${y- sy*5} ${x+sx*(a+5)},${y+sy*(depth-b)} ${x+sx*(a+13)},${y+sy*2} ${x+sx*(a+7)},${y-sy*8}`);
        line(`M ${x+sx*(a+5)} ${y+sy*(depth-b)} L ${x+sx*(a+7)} ${y-sy*8}`,light,.6,.9);
      } else if(family==='forged') {
        shapes.push(`<rect x="${x+sx*a-3}" y="${y-5}" width="6" height="10" rx="1" fill="${mid}" stroke="${light}" stroke-width=".8"/>`);
        ellipse(x+sx*a,y,1.5,1.5,light,dark);
      } else if(family==='astral') {
        line(`M ${x+sx*(a-8)} ${y+sy*4} Q ${x+sx*a} ${y+sy*(b+14)} ${x+sx*(a+12)} ${y+sy*2}`,mid,.8,.8);
        ellipse(x+sx*a,y+sy*b,1.7,1.7,light,light);
        line(`M ${x+sx*a} ${y+sy*(b-5)} L ${x+sx*a} ${y+sy*(b+5)} M ${x+sx*(a-5)} ${y+sy*b} L ${x+sx*(a+5)} ${y+sy*b}`,light,.6,.9);
      } else if(family==='tide') {
        line(`M ${x+sx*(a-5)} ${y+sy*2} C ${x+sx*a} ${y+sy*18} ${x+sx*(a+15)} ${y+sy*17} ${x+sx*(a+15)} ${y+sy*5}`,mid,3,.8);
        ellipse(x+sx*(a+9),y+sy*10,2,1.5,light,dark);
      } else if(family==='ember') {
        shapes.push(`<path d="M ${x+sx*a} ${y} Q ${x+sx*(a-7)} ${y+sy*13} ${x+sx*(a+6)} ${y+sy*(b+13)} Q ${x+sx*(a+2)} ${y+sy*8} ${x+sx*(a+12)} ${y} Z" fill="${dark}" stroke="${mid}" stroke-width="1"/>`);
        line(`M ${x+sx*(a+6)} ${y+sy*4} L ${x+sx*(a+4)} ${y+sy*10}`,light,.8,.8);
      } else {
        line(`M ${x+sx*a} ${y+sy*3} L ${x+sx*a} ${y+sy*14} Q ${x+sx*(a+5)} ${y+sy*8} ${x+sx*(a+10)} ${y+sy*14} L ${x+sx*(a+10)} ${y+sy*3}`,mid,1.8,.8);
        polygon(`${x+sx*(a+5)},${y+sy*2} ${x+sx*(a+8)},${y+sy*6} ${x+sx*(a+5)},${y+sy*10} ${x+sx*(a+2)},${y+sy*6}`);
      }
    }
  }
  // Each theme's engraved rune is unique and sits entirely in the gutter.
  const center=w*(.35+(bytes[8]%30)/100), cy=inset;
  line(`M ${center-25} ${cy} L ${center-9} ${cy} M ${center+9} ${cy} L ${center+25} ${cy}`,mid,1,.8);
  polygon(`${center},${cy-7} ${center+7},${cy} ${center},${cy+7} ${center-7},${cy}`);
  for(let i=0;i<4;i++)if(bytes[9]&(1<<i))line(`M ${center-3+i*2} ${cy-3} L ${center+1+i} ${cy+3}`,light,.7,.9);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${shapes.join('')}</svg>`;
}
async function run() {
  const inventory=[];
  for(const theme of themes) {
    const dir=path.join(root,'design/themes',theme.id), output=path.join(root,'assets/themes',theme.id);
    fs.mkdirSync(dir,{recursive:true});
    const comp={id:theme.id,name:theme.name,materials:theme.formsAndMaterials,family:familyOf(theme.id),signature:hash(theme.id).toString('hex'),motion:theme.motion,figmaFile:'Dw1F8sR6bzTCuGkaH2CEeS',safeCenter:'Artwork only in outer 28 pixels; alpha=0 in reading area',desktop:'extended scene and split edge',tablet:'compact edge and side ornament',mobile:'dedicated shallow scene and narrow frame'};
    if(theme.id==='classic_reliquary'||theme.id==='classic_low_detail')comp.materials='sigillo inciso in rame e montatura d osso; nessun occhio in reliquiario';
    fs.writeFileSync(path.join(dir,'composition.json'),JSON.stringify(comp,null,2)+'\n');
    for(const [role,w,h] of [['panel',1024,512],['mobile',640,320],['portrait',256,256],['statistics',256,192],['separator',768,64]]) {
      const svg=frame(theme,w,h,role);
      fs.writeFileSync(path.join(dir,`${role}.svg`),svg);
      fs.mkdirSync(path.join(output,'frames'),{recursive:true});
      const png=path.join(output,'frames',`${role}.png`);
      const figmaExport = path.join(dir, 'figma-panel.png');
      if (role === 'panel' && fs.existsSync(figmaExport)) {
        // Figma exports may include the canvas matte even with root fills=[];
        // the original editable vector is the authoritative alpha mask.
        const mask = await sharp(Buffer.from(svg)).png().toBuffer();
        await sharp(figmaExport).ensureAlpha().composite([
          {input:mask,blend:'dest-in'},
        ]).png({compressionLevel:9}).toFile(png);
      } else {
        await sharp(Buffer.from(svg)).png({compressionLevel:9}).toFile(png);
      }
      inventory.push({theme:theme.id,role,path:path.relative(root,png).replace(/\\/g,'/'),bytes:fs.statSync(png).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(png)).digest('hex')});
    }
    // Scenes assemble original artwork in reserved empty space. Classic uses
    // only engraved geometry, respecting the removed eye-in-reliquary request.
    for(const [role,w,h] of [['scene',1024,192],['scene-mobile',640,96]]) {
      const layers=[];
      if(theme.id!=='classic_reliquary'&&theme.id!=='classic_low_detail') {
        // Crop a large part of the illustration into the scene, rather than
        // shrinking a tall creature into a tiny icon. Center remains empty.
        const image=await sharp(path.join(root,theme.signaturePng)).resize({height:h,width:Math.round(w*.28),fit:'cover',position:'centre'}).png().toBuffer();
        const meta=await sharp(image).metadata();
        const right=hash(theme.id)[10]%2===0;
        layers.push({input:image,left:right?w-meta.width-18:18,top:Math.floor((h-meta.height)/2)});
      }
      const lines=Buffer.from(frame(theme,w,h,'mobile'));
      const png=path.join(output,'decorations',`${role}.png`);
      fs.mkdirSync(path.dirname(png),{recursive:true});
      fs.writeFileSync(path.join(dir,`${role}.json`),JSON.stringify({width:w,height:h,source:theme.signaturePng,layers:layers.length,placement:hash(theme.id)[10]%2===0?'right':'left'},null,2)+'\n');
      await sharp({create:{width:w,height:h,channels:4,background:'#00000000'}}).composite([{input:lines},...layers]).png({compressionLevel:9}).toFile(png);
      inventory.push({theme:theme.id,role,path:path.relative(root,png).replace(/\\/g,'/'),bytes:fs.statSync(png).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(png)).digest('hex')});
    }
  }
  fs.writeFileSync(path.join(root,'design/theme-art-manifest.json'),JSON.stringify(inventory,null,2)+'\n');
  for (const id of ['vervain_gothic','abyssal_tide','bone_saint','frost_chapel']) {
    const t=themes.find(x=>x.id===id), [dark,light]=palettes[familyOf(id)];
    const escape=s=>s.replace(/&/g,'&amp;').replace(/</g,'&lt;');
    const lettering=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="640"><rect width="1024" height="640" fill="#100e16"/><text x="62" y="80" fill="${light}" font-family="serif" font-size="32">OCULUM · ${escape(t.name)}</text><text x="62" y="118" fill="#c5b9ad" font-size="17">${escape(t.formsAndMaterials)}</text><text x="64" y="350" fill="${light}" font-family="serif" font-size="25">Rose | Tutto pur di Salvarla</text><text x="64" y="390" fill="#ded3c6" font-size="18">Vita e scudo     30 / 30          Oculum     6 / 6</text><text x="64" y="435" fill="#ded3c6" font-size="18">Resilienza 3   ·   Volontà 3   ·   Materia 5   ·   Oculum 6</text><text x="64" y="488" fill="#ded3c6" font-size="18">Attacco · Difesa · Iniziativa · Aiuta compagno</text><text x="64" y="604" fill="${light}" font-size="13">Tavola degli asset · centro leggibile · cornici e scene in layer separati</text></svg>`);
    const framePng=await sharp(path.join(root,`assets/themes/${id}/frames/panel.png`)).resize(1024,512).png().toBuffer();
    const scene=fs.readFileSync(path.join(root,`assets/themes/${id}/decorations/scene.png`));
    await sharp(lettering).composite([{input:framePng,top:128,left:0},{input:scene,top:134,left:0}]).png().toFile(path.join(root,`design/theme-art-preview-${id}.png`));
  }
  console.log(`Created ${inventory.length} transparent PNGs for ${themes.length} themes (${(inventory.reduce((a,b)=>a+b.bytes,0)/1048576).toFixed(2)} MiB).`);
}
run().catch(e=>{console.error(e);process.exitCode=1;});
