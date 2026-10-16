// Original editable vector motifs + local raster materials. No recolored copies.
const fs=require('fs');
const path=require('path');
const crypto=require('crypto');
const sharp=require(process.argv[2]||'sharp');
const root=path.resolve(__dirname,'..');
const specs=JSON.parse(fs.readFileSync(path.join(root,'docs/design/element-pack-specs.json'),'utf8'));
function syncRegistries() {
  const mappingPath=path.join(root,'docs/design/element-theme-packs.json');
  const mapping=JSON.parse(fs.readFileSync(mappingPath,'utf8'));
  for(const spec of specs) mapping[spec.element]=spec.id;
  fs.writeFileSync(mappingPath,JSON.stringify(mapping,null,2)+'\n');
  const quote=value=>`'${value.replaceAll("'",'’')}'`;
  const materialNames={metal:'metallo inciso',stone:'pietra stratificata',charred:'roccia carbonizzata',astral:'polvere astrale',water:'vetro e acqua',acid:'vetro corroso',ash:'cenere e fuliggine',crystal:'cristallo',dream:'veli di nubi',ivory:'osso scolpito',wood:'legno inciso',bark:'corteccia',spirit:'veli perlacei'};
  fs.writeFileSync(path.join(root,'lib/widgets/oculum_generated_element_packs.dart'),
    "part of 'oculum_theme_asset_packs.dart';\n\nconst oculumAdditionalElementArtPacks = <String, OculumThemeAssetPack>{\n"+
    specs.map(s=>`  ${quote(s.id)}: OculumThemeAssetPack(${quote(s.id)}, ${quote(s.name)}, ${quote(materialNames[s.material])}, ${quote(s.motion)}),`).join('\n')+'\n};\n');
  let registry='// Generated from docs/design/element-pack-specs.json.\nconst oculumElementThemePackIds = <String, String>{\n'+Object.entries(mapping).map(([e,id])=>`  ${quote(e)}: ${quote(id)},`).join('\n')+'\n};\n';
  const extra={fisico:{style:'bolted_metal',motion:'glint',material:'metal',accent:'C0C8D0'},gelo:{style:'frost',motion:'frost',material:'crystal',accent:'B9DAEC'},spirituale:{style:'spirit',motion:'souls',material:'spirit',accent:'F0EFF5'}};
  const all=[...specs,...Object.entries(extra).map(([element,s])=>({element,...s}))];
  for(const [name,field] of [['Styles','style'],['Motions','motion'],['Materials','material']]) registry+=`\nconst oculumElementTheme${name} = <String, String>{\n`+all.map(s=>`  ${quote(s.element)}: ${quote(s.element==='cenere'&&field==='material'?'canva-ash':s[field])},`).join('\n')+'\n};\n';
  registry+='\nconst oculumElementThemeAccents = <String, int>{\n'+all.map(s=>`  ${quote(s.element)}: 0xFF${s.accent},`).join('\n')+'\n};\n';
  fs.writeFileSync(path.join(root,'lib/widgets/oculum_element_theme_registry.dart'),registry);
}
// Each element has its own silhouette, not a generic symbol with another tint.
function glyph(id,alive=false) {
  const p=d=>`<path d="${d}"/>`;
  const c=(x,y,r)=>`<circle cx="${x}" cy="${y}" r="${r}"/>`;
  switch(id) {
    case 'taglio': return p('M3 27Q5 7 28 3L13 20Z M7 24L22 9 M2 18l6-6M19 30l8-8');
    case 'perforante': return p('M16 1l5 18-5 11-5-11Z M16 5v22M3 25l6-5M29 25l-6-5');
    case 'contundente': return p('M8 3h16l6 8-4 10H6L2 11Z M11 21v9h10v-9M18 3l-4 8 7 3-5 7');
    case 'fuoco': return p(`M16 30C-1 26 5 15 10 11q-1 7 3 6C14 8 ${alive?'26 1':'21 4'} 20 1c19 19 8 31-4 29Z M16 28q-7-5 0-13q7 8 0 13Z`);
    case 'vento': return p('M1 10h20c13 0 9-13 2-8M2 17h25c6 0 5 10-1 10M3 24h12c8 0 6 9 0 7');
    case 'acqua': return p('M16 1C14 8 3 14 5 22c2 12 21 11 23 0C29 14 19 7 16 1Z M8 21q4-6 9 0t9 0M9 25q8 6 14-1');
    case 'terra': return p('M1 26l6-11 8-3 8-11 7 25Z M5 20l9-3 10 2M5 26l9-4 14 2M15 12l4 7');
    case 'sonoro': return p('M11 2v13q5 7 10 0V2M16 20v11M5 6q-6 8 0 16M27 6q6 8 0 16M1 3q-7 13 0 25');
    case 'psichico': return p('M5 26V13C5-2 27-2 27 12l4 8h-6v10M10 23V9h11v9h-6v-5M8 27h10');
    case 'lava': return p('M1 26l7-17 8 4 8-11 7 26Z M16 12l-4 8 8-2-3 13M5 25l6-3M24 18l5 6');
    case 'fulmine': return p('M20 1L5 18h10l-4 13L29 12H18Z M4 3l3 4M28 25l-3-3');
    case 'veleno': return p('M6 8C6-3 30 0 27 10C24 20 4 11 5 24c2 9 22 9 23-1M8 8l5-2 4 3-4 3Z M23 15l-3 8h7Z');
    case 'cenere': return p('M1 26q7-7 14 0t16 0M3 21q5-6 12-2t14-3M10 7l3 4M23 2l-2 5')+c(6,13,1)+c(19,11,1.5)+c(27,23,.8);
    case 'sangue': return p('M16 1Q4 15 6 23C10 35 27 31 27 20Q25 12 16 1Z M16 8v20M16 17l-6-4M16 21l6-4M16 25l-5-2');
    case 'cristallo': return p('M16 1L29 10l-4 16-9 5-9-5L3 10Z M16 1l-5 11 5 19 5-19Z M3 10l8 2 10 0 8-2');
    case 'oscuro': return p('M3 2Q17 7 29 2L27 27l-5-7-6 10-6-8-5 7Z M9 5q10 10 0 17M24 5q-9 7-4 13');
    case 'lunare': return p('M24 3C-1-4-6 33 21 31C4 22 8 7 24 3Z M25 12v8M21 16h8')+c(17,2,1);
    case 'solare': return c(16,16,7)+p('M16 1v6M16 25v6M1 16h6M25 16h6M5 5l5 5M22 22l5 5M5 27l5-5M22 10l5-5');
    case 'vapium': return p('M2 29V13h8v10h12V8h8M2 18h8M22 14h8M13 13q-5-5 0-9M18 17q-5-6 0-13')+c(5,27,2);
    case 'osso': return p('M9 7C-4 5 2-5 11 3l10 20c13 0 11 13 3 7C19 37 14 28 18 24Z M10 9l9 16');
    case 'gravita': return '<ellipse cx="16" cy="16" rx="15" ry="6" transform="rotate(-25 16 16)"/>'+c(16,16,5)+p('M8 1l3 6M24 25l3 6M7 30l4-4');
    case 'vuoto': return p('M11 2A15 15 0 0 0 2 22M7 29a15 15 0 0 0 23-12M29 9l-3-4M16 7a9 9 0 0 0-9 12M17 25a9 9 0 0 0 8-10M16 1v3');
    case 'sogno': return '<path d="M7 26C-3 26 0 13 9 15C4 1 25-3 24 13c13-4 12 15-1 13Z" fill="#9EACD7" fill-opacity=".28" stroke="#C2B4E6"/><path d="M6 21q5-4 10 0t12-1M14 2v5M11 5h6" fill="none" stroke="#E5BDD9"/>';
    case 'metallo': return p('M2 7l8-5h18v20l-8 8H2Z M7 7h16v14H7Z M2 25h15l11-11')+c(5,5,1)+c(25,5,1)+c(5,24,1);
    case 'postea': return p('M16 2l8 5v9l-8 5-8-5V7Z M16 8l3 3-3 4-3-4Z M2 12v13h9M30 12v13h-9M16 22v9')+c(4,29,2)+c(28,29,2);
    case 'radice': return p('M16 1v10L8 18l-7 6M16 8l8 6 7 1M16 12l2 11-5 8M10 17l1 8-5 5M22 13l-1 8 8 7M18 23l5 8');
    case 'slime': return p('M1 26C-1 16 8 11 10 5c4-10 10 3 13 7 8 3 12 12 6 16C20 35 5 33 1 26Z M4 25q10 7 24 0')+c(12,15,3)+c(23,22,2);
    case 'oculum': return p('M1 16Q16-1 31 16Q16 33 1 16Z M5 7l3 3M24 22l4 4M16 0v4M16 28v4')+c(16,16,8)+c(16,16,3);
    case 'stella': return p('M16 1l4 10 11 5-11 4-4 11-4-11-11-4 11-5Z M16 6v20M6 16h20')+c(4,4,1)+c(29,28,1);
    case 'corrotto': return p('M2 10Q8-3 16 4q8-8 14 4l-5 8 7 10-15 4-7-5-8 6 4-15Z M9 9l4 6-3 7M23 6l-4 8 5 8')+c(17,23,2);
    case 'nonmorto': return p('M4 29V9l5-7h14l5 7v20Z M8 29V10h16v19M10 15h12M12 12v6M19 12v6M10 23l12 3M13 21v6M20 22v7');
    case 'acido': return p('M5 2h22l-3 18-4 2v9h-5V20l-7-4Z M9 5l3 9M23 5l-3 11M2 23l3 6M29 19l-2 7')+c(14,10,2);
    case 'sacro': return p('M4 30V15Q4 5 16 1q12 4 12 14v15M9 29V16q0-7 7-10 7 3 7 10v13M16 10v15M11 16h10');
    case 'diabolico': return p('M13 27C-2 22-4 5 8 0C1 13 10 15 13 10M19 27C34 22 36 5 24 0c7 13-2 15-5 10M12 19l4 12 4-12M5 28l5-5M27 28l-5-5');
    case 'angelico': return p('M15 28C1 23-4 8 1 3q5 16 13 12M17 28C31 23 36 8 31 3q-5 16-13 12M1 8l8 9M2 16l9 5M31 8l-8 9M30 16l-9 5')+'<ellipse cx="16" cy="4" rx="6" ry="2"/>';
    case 'necrotico': return p('M5 29l10-16M8 24Q-1 14 9 6q1 11 5 8M16 18q10-4 14-1-3 12-15 12M9 11l2 8')+c(23,6,3)+c(28,1,1)+c(18,2,1.5);
    case 'magia': return p('M16 1l13 23H3Z M16 31L3 8h26Z M9 16h14M16 9v14')+c(16,16,13);
    case 'energia': return p('M16 1C-3 5 0 27 16 31C35 26 32 5 16 1Z M16 5c-9 10 9 12 0 22M5 16q11-9 22 0')+c(16,16,4);
    case 'esplosivo': return p('M15 1l5 9 10-6-4 12 6 4-11 3-1 9-7-9-11 7 4-12-6-5 12-2Z M11 15l8 6M19 13l-4 8');
    case 'radiazione': return c(16,16,3)+c(16,16,15)+p('M13 11L8 3l-5 8 8 3ZM21 14l10-3-5-8-7 8ZM14 21l-3 9h10l-3-9Z');
    case 'plasma': return p('M16 1C7 5 24 10 8 14S4 30 17 31M16 1c15 6-3 10 12 18s-1 16-11 12M5 2l4 4M26 2l-3 4M16 9l-5 12 9-4-4 11');
    case 'tecnologia': return p('M8 8h16v16H8Z M12 1v7M20 1v7M12 24v7M20 24v7M1 12h7M1 20h7M24 12h7M24 20h7M12 12h8v8h-8Z');
    case 'proiettile': return p('M6 30V9q3-12 6 0v21ZM19 30V9q3-12 6 0v21ZM6 22h6M19 22h6M4 27h10M17 27h10');
    case 'laser': return p('M1 15h8M23 15h8M1 18h8M23 18h8M10 5q-5 11 0 22M22 5q5 11 0 22M10 5h12M10 27h12')+'<ellipse cx="16" cy="16" rx="4" ry="11"/>';
    case 'tempo': return p('M5 2h22M5 30h22M8 3q0 9 8 13-8 4-8 13M24 3q0 9-8 13 8 4 8 13M12 9h8l-4 5ZM11 27l5-6 5 6Z');
    case 'spazio': return '<ellipse cx="16" cy="16" rx="8" ry="15"/><ellipse cx="16" cy="16" rx="15" ry="8" transform="rotate(-35 16 16)"/>'+p('M16 1v5M16 26v5M4 26l4-3')+c(27,6,2);
    case 'caos': return p('M3 1l9 9-7 6 9 1-3 14 10-10 9 8-3-15 5-8-13 2-3-8-3 11ZM6 26l4-3M25 2l-3 4');
    case 'natura': return alive
      ? p('M16 31V13M16 20Q0 22 2 7q14 0 14 13ZM16 17Q28 19 30 3q-14 0-14 14Z M6 10l9 9')+'<g fill="#BE98D6" fill-opacity=".7" stroke="#DFC3ED">'+c(16,7,3)+c(12,3,3)+c(20,3,3)+'</g>'
      : p('M16 31V7M16 22L6 15l-4-9M16 16l9-8 5-7M9 17l-7 3M23 10l6 4M15 11l-4-8');
    case 'pianta': return p(`M15 31Q5 11 23 2M15 25Q1 25 1 15q10-1 13 8M13 18Q0 16 5 6q9 2 9 10M16 15q14 4 15-7-10-3-15 7M20 7q${alive?'9-9 10-2':'4-4 8-2'}`);
    case 'bestiale': return p('M3 24l4-15 4-6-2 22ZM13 28l3-22 4-5-1 28ZM24 25l3-15 4-4-1 20Z M3 29q12-4 25 1');
    case 'maledizione': return p('M16 1l10 7-3 15-7 8-7-8L6 8Z M2 9l8 7-7 8M30 9l-8 7 7 8M9 12l14 9M12 9l9 14')+c(16,16,5);
    case 'benedizione': return '<ellipse cx="16" cy="7" rx="11" ry="5"/>'+p('M8 11L5 31l8-7 3 7 3-7 8 7-3-20M16 1v12M11 6h10');
    case 'cura': return p('M5 17h22q-2 12-11 13Q7 29 5 17ZM2 17h28M16 16V6M16 10Q6 10 8 2q9 0 8 8ZM17 12q10 1 11-8-10-1-11 8');
    case 'vero': return p('M16 1L29 16 16 31 3 16Z M16 6l8 10-8 10-8-10Z M10 16l4 4 8-9M3 3l4 4M25 25l4 4');
    case 'sconosciuto': return p('M3 1h12v7l-7 3 8 5-5 5 12 4-2 6M27 1l-6 8 9 4-6 8M1 28l4-3M16 2v3')+c(25,29,2);
    default: throw new Error(`No authored motif for ${id}`);
  }
}
function vector(spec,w,h,alive) {
  const color=`#${spec.accent}`, angular=['metal','stone','crystal'].includes(spec.material);
  const outer=angular?`M26 8H${w-26}l18 18V${h-26}l-18 18H26L8 ${h-26}V26Z`:`M28 8H${w-28}q20 0 20 20V${h-28}q0 20-20 20H28Q8 ${h-8} 8 ${h-28}V28Q8 8 28 8Z`;
  const parts=[`<path d="${outer}" fill="none" stroke="#101116" stroke-width="1.4"/><path d="${outer}" fill="none" stroke="${color}" stroke-opacity=".42" stroke-width="1.6"/>`];
  const motif=glyph(spec.element,alive);
  // A narrow reading-safe band, including distinct small central crests.
  for(const [x,y,sx,sy] of [[1,1,1,1],[w-1,1,-1,1],[1,h-1,1,-1],[w-1,h-1,-1,-1]]) {
    parts.push(`<g transform="translate(${x} ${y}) scale(${sx*.68} ${sy*.68})" fill="${color}" fill-opacity=".13" stroke="${color}" stroke-width="1.35" stroke-linecap="round" stroke-linejoin="round">${motif}</g>`);
  }
  const count=alive?5:3;
  for(let n=1;n<=count;n++) {
    const x=Math.round(w*n/(count+1));
    parts.push(`<g transform="translate(${x-8} 0) scale(.5)" fill="none" stroke="${color}" stroke-opacity=".68" stroke-width="1.2">${motif}</g>`);
    if(n%2===1)parts.push(`<g transform="translate(${x+8} ${h}) scale(-.5)" fill="none" stroke="${color}" stroke-opacity=".48" stroke-width="1.2">${motif}</g>`);
  }
  // Material grooves differ from the symbol and do not enter the reading area.
  if(['wood','bark'].includes(spec.material)) for(let n=0;n<5;n++)parts.push(`<path d="M32 ${8+n*1.5}Q${w*.35} ${4+n} ${w*.5} ${11+n}T${w-32} ${8+n*1.5}" fill="none" stroke="${color}" stroke-opacity=".24" stroke-width=".6"/>`);
  if(spec.material==='charred')parts.push(`<path d="M30 6l35 5 22-7 17 8M${w-32} ${h-7}l-43-5-19 7-26-8" fill="none" stroke="${color}" stroke-width="1.7" opacity=".7"/>`);
  if(spec.material==='metal')for(let x=40;x<w-35;x+=53)parts.push(`<circle cx="${x}" cy="${h-8}" r="1.2" fill="${color}" opacity=".5"/>`);
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${parts.join('')}</svg>`;
}
async function run() {
  syncRegistries();
  const manifestPath=path.join(root,'design/theme-art-manifest.json');
  const ids=new Set(specs.map(spec=>spec.id));
  const manifest=JSON.parse(fs.readFileSync(manifestPath,'utf8')).filter(entry=>!ids.has(entry.theme));
  const alphaSignatures=new Set();
  for(const spec of specs) {
    const sourceDir=path.join(root,'design/themes',spec.id),output=path.join(root,'assets/themes',spec.id);
    for(const directory of [sourceDir,`${output}/frames`,`${output}/decorations`,`${output}/overlays`])fs.mkdirSync(directory,{recursive:true});
    const ash=path.join(root,'design/materials/canva-20261016/ash-material.png');
    const material=spec.element==='cenere'&&fs.existsSync(ash)?ash:path.join(root,`assets/themes/materials/${spec.material}.png`);
    if(!fs.existsSync(material))throw new Error(`Missing material ${material}`);
    if (!process.argv.includes('--finalize-only')) {
    for(const [role,w,h] of [['panel',1024,512],['mobile',640,320],['portrait',256,256],['statistics',256,192],['separator',768,64],['scene',1024,192],['scene-mobile',640,96]]) {
      const mask=Buffer.from(`<svg width="${w}" height="${h}"><rect x="9" y="9" width="${w-18}" height="${h-18}" rx="9" fill="none" stroke="white" stroke-width="15"/></svg>`);
      const texture=await sharp(material).resize(w,h).modulate({brightness:1.05}).ensureAlpha().composite([{input:mask,blend:'dest-in'}]).png().toBuffer();
      for(const variant of ['', 'still','alive']) {
        const svg=vector(spec,w,h,variant==='alive');
        const filename=`${role}${variant?'-'+variant:''}`;
        fs.writeFileSync(`${sourceDir}/${filename}.svg`,svg);
        const bytes=await sharp(texture).composite([{input:Buffer.from(svg)}]).png({compressionLevel:9}).toBuffer();
        fs.writeFileSync(`${output}/${role.startsWith('scene')?'decorations':'frames'}/${filename}.png`,bytes);
        if(role==='panel'&&variant==='alive') {
          const alpha=await sharp(bytes).extractChannel('alpha').raw().toBuffer();
          const signature=crypto.createHash('sha256').update(alpha).digest('hex');
          if(alphaSignatures.has(signature))throw new Error(`Repeated silhouette: ${spec.element}`);
          alphaSignatures.add(signature);
        }
      }
    }
    const panel=`${output}/frames/panel.png`;
    for(const [state,brightness] of [['normal',1],['hover',1.2],['pressed',.65],['selected',1.4],['disabled',.4]])await sharp(panel).modulate({brightness}).png().toFile(`${output}/frames/button-${state}.png`);
    const relic=`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><g transform="translate(32 32) scale(6)" fill="#${spec.accent}" fill-opacity=".16" stroke="#${spec.accent}" stroke-width=".7" stroke-linecap="round" stroke-linejoin="round">${glyph(spec.element,true)}</g></svg>`;
    fs.writeFileSync(`${sourceDir}/relic.svg`,relic);
    await sharp(Buffer.from(relic)).png().toFile(`${output}/overlays/relic.png`);
    fs.writeFileSync(`${sourceDir}/composition.json`,JSON.stringify({...spec,materialSource:path.relative(root,material).replaceAll('\\','/'),readingCenter:'transparent',safeBand:24,motionScope:'outer edges only',generator:'scripts/build_element_theme_packs.cjs'},null,2)+'\n');
    }
    for(const directory of ['frames','decorations','overlays'])for(const filename of fs.readdirSync(`${output}/${directory}`)) {
      const relative=`assets/themes/${spec.id}/${directory}/${filename}`,bytes=fs.readFileSync(path.join(root,relative));
      manifest.push({theme:spec.id,role:filename.replace('.png',''),path:relative,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
    }
    console.log(`Exported ${spec.element}: ${spec.name}`);
  }
  const pendingManifest=manifestPath+'.pending';
  fs.writeFileSync(pendingManifest,JSON.stringify(manifest,null,2)+'\n');
  for(let attempt=0;;attempt++) {
    try { fs.renameSync(pendingManifest,manifestPath); break; }
    catch(error) { if(attempt===7)throw error; await new Promise(resolve=>setTimeout(resolve,250)); }
  }
  console.log(`Verified ${alphaSignatures.size} distinct silhouettes.`);
  const tileW=220,tileH=140,columns=5,rows=Math.ceil(specs.length/columns),tiles=[];
  for(const [index,spec] of specs.entries()) {
    const x=index%columns*tileW,y=Math.floor(index/columns)*tileH;
    const panel=await sharp(path.join(root,`assets/themes/${spec.id}/frames/panel-alive.png`)).resize(tileW,110).png().toBuffer();
    const emblem=await sharp(path.join(root,`assets/themes/${spec.id}/overlays/relic.png`)).resize(78,78).png().toBuffer();
    const title=Buffer.from(`<svg width="220" height="140"><text x="110" y="130" text-anchor="middle" font-family="serif" font-size="14" fill="#${spec.accent}">${spec.name}</text></svg>`);
    tiles.push({input:panel,left:x,top:y},{input:emblem,left:x+71,top:y+16},{input:title,left:x,top:y});
  }
  await sharp({create:{width:columns*tileW,height:rows*tileH,channels:4,background:'#121118'}}).composite(tiles).png().toFile(path.join(root,'design/element-pack-overview.png'));
}
run().catch(error=>{console.error(error);process.exitCode=1;});
