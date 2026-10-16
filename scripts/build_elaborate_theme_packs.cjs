// Original, editable vector artwork exported as local transparent PNGs.
const fs = require('fs');
const path = require('path');
const sharp = require(process.argv[2] || 'sharp');
const crypto = require('crypto');
const root = path.resolve(__dirname, '..');
const themes = [
  ['buried_herbarium', 'Erbario sepolto', '#bda578', '#4c674f'],
  ['funeral_clockwork', 'Orologeria funebre', '#d2b989', '#687987'],
  ['tidal_stained_glass', 'Vetrata delle maree', '#a0d9d5', '#827ba8'],
];
function artwork(id, w, h, alive) {
  const [, , light, accent] = themes.find(t => t[0] === id);
  const parts = [];
  const line = (d, color = light, width = 1, opacity = .8) => parts.push(`<path d="${d}" fill="none" stroke="${color}" stroke-width="${width}" opacity="${opacity}" stroke-linecap="round"/>`);
  // All decoration stays inside a 24px band; nine-slice never stretches motifs.
  line(`M32 10H${w - 32}M32 ${h - 10}H${w - 32}M10 32V${h - 32}M${w - 10} 32V${h - 32}`, accent, 7, .4);
  line(`M32 7H${w - 32}M32 ${h - 7}H${w - 32}M7 32V${h - 32}M${w - 7} 32V${h - 32}`, light, .8);
  if (id === 'buried_herbarium') {
    // Continuous grain, rather than a flat brown border or a central tile.
    for (const y of [h-10,10]) {
      for(let i=0;i<5;i++) {
        let d=`M32 ${y-3+i*1.4}`;
        for(let x=48;x<w-32;x+=16) d+=`Q${x-8} ${y-3+i*1.4+Math.sin(x*.021+i)*1.4} ${x} ${y-3+i*1.4}`;
        line(d,i%2?'#d0a873':'#382417',.65,.6);
      }
    }
  } else if (id === 'funeral_clockwork') {
    for(let x=112;x<w-100;x+=38) {
      for(const y of [10,h-10]) {
        parts.push(`<circle cx="${x}" cy="${y}" r="2.7" fill="#403b34" stroke="${light}" stroke-width=".6"/>`);
        line(`M${x-1} ${y-1}l2 2`,accent,.7);
      }
    }
  } else {
    for(let x=110;x<w-90;x+=29) {
      for(const y of [10,h-10]) {
        parts.push(`<path d="M${x} ${y-3}l14 1-3 6-14-2Z" fill="${x%2?accent:'#3f8088'}" fill-opacity=".65" stroke="#233940" stroke-width=".8"/>`);
        line(`M${x+1} ${y-2}l8 1`,light,.6,.55);
      }
    }
  }
  for (const [x, y, sx, sy] of [[8,8,1,1],[w-8,8,-1,1],[8,h-8,1,-1],[w-8,h-8,-1,-1]]) {
    parts.push(`<g transform="translate(${x} ${y}) scale(${sx} ${sy})">`);
    if (id === 'buried_herbarium') {
      line('M0 70C17 44 -8 23 22 0L90 0', '#5a3c27', 9);
      for (let i=0;i<6;i++) {
        const a=12+i*12;
        line(`M${a} 0q9 ${3+i%3} 17 1`, '#d4ae70', .8, .65);
        line(`M0 ${a}q${4+i%2} 7 0 16`, '#98734d', .9);
        parts.push(`<path d="M${a} 1q-3 13 8 16q5-8-8-16" fill="${accent}" opacity=".8"/>`);
        if (alive && i%2===0) parts.push(`<circle cx="${a+7}" cy="13" r="2.4" fill="#bc94ca"/>`);
      }
      line('M3 3Q18 11 2 30M9 2q22 18 45 7', light, 1.3);
    } else if (id === 'funeral_clockwork') {
      parts.push(`<circle cx="7" cy="7" r="15" fill="#24282d" stroke="${light}" stroke-width="2"/>`);
      for (let i=0;i<12;i++) {
        const a=i*Math.PI/6;
        line(`M${7+11*Math.cos(a)} ${7+11*Math.sin(a)}L${7+16*Math.cos(a)} ${7+16*Math.sin(a)}`, light, 1.4);
      }
      line(`M7 7L${alive?15:3} 0M7 7L15 12`, '#ede1c3', 1);
      line('M29 3H69l8 7h20M3 29v32l9 12v15', accent, 2);
      for(let i=0;i<5;i++) parts.push(`<circle cx="${34+i*11}" cy="4" r="1.8" fill="${light}"/>`);
    } else {
      for(let i=0;i<4;i++) {
        const a=14+i*18;
        parts.push(`<path d="M${a} 0l8 6-8 10-8-10Z" fill="${i%2?accent:'#376d78'}" fill-opacity=".7" stroke="${light}" stroke-width=".7"/>`);
      }
      line('M0 62q17-12 0-24t0-25M4 65q20-12 0-24', light, 1);
      parts.push(`<path d="M1 1Q24-5 20 14L7 22Z" fill="#254d5c" stroke="${light}"/>`);
      for(let i=0;i<4;i++) line(`M2 2L${5+i*5} ${20-i*2}`, light, .6);
      if(alive) parts.push('<circle cx="4" cy="76" r="2.2" fill="#e3f7ef"/>');
    }
    parts.push('</g>');
  }
  // Buttons use the same motifs and transparent center, without lettering.
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${parts.join('')}</svg>`;
}
async function run() {
  const manifestPath=path.join(root,'design/theme-art-manifest.json');
  const ids=new Set(themes.map(t=>t[0]));
  const manifest=fs.existsSync(manifestPath)
    ? JSON.parse(fs.readFileSync(manifestPath,'utf8')).filter(entry=>!ids.has(entry.theme)) : [];
  for (const [id,name] of themes) {
    const source = path.join(root,'design/themes',id);
    const output = path.join(root,'assets/themes',id);
    for(const dir of [source,`${output}/frames`,`${output}/decorations`,`${output}/overlays`]) fs.mkdirSync(dir,{recursive:true});
    for(const [role,w,h] of [['panel',1024,512],['mobile',640,320],['portrait',256,256],['statistics',256,192],['separator',768,64],['scene',1024,192],['scene-mobile',640,96]]) {
      for(const variant of ['', 'still','alive']) {
        const svg=artwork(id,w,h,variant==='alive');
        const filename=`${role}${variant?'-'+variant:''}`;
        fs.writeFileSync(`${source}/${filename}.svg`,svg);
        await sharp(Buffer.from(svg)).png().toFile(`${output}/${role.startsWith('scene')?'decorations':'frames'}/${filename}.png`);
      }
    }
    const frame=await sharp(Buffer.from(artwork(id,1024,512,true))).png().toBuffer();
    for(const [state,brightness] of [['normal',1],['hover',1.2],['pressed',.7],['selected',1.35],['disabled',.45]]) {
      await sharp(frame).modulate({brightness}).png().toFile(`${output}/frames/button-${state}.png`);
    }
    await sharp(Buffer.from(artwork(id,256,256,true))).png().toFile(`${output}/overlays/relic.png`);
    fs.writeFileSync(`${source}/README.md`, `# ${name}\n\nSorgenti SVG originali; PNG RGBA senza testo. Motivi confinati ai margini, centro trasparente. Varianti still/alive e cinque stati dei pulsanti.\n`);
    for(const directory of ['frames','decorations','overlays']) {
      for(const file of fs.readdirSync(`${output}/${directory}`).filter(file=>file.endsWith('.png'))) {
        const relative=`assets/themes/${id}/${directory}/${file}`;
        const bytes=fs.readFileSync(path.join(root,relative));
        manifest.push({theme:id,role:file.replace('.png',''),path:relative,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
      }
    }
    console.log(`Exported ${name}`);
  }
  fs.writeFileSync(manifestPath,JSON.stringify(manifest,null,2)+'\n');
}
run().catch(error=>{console.error(error);process.exitCode=1;});
