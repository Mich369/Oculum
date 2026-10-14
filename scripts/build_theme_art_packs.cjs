// Reproducible original vector compositions. Original theme illustrations are
// retained unchanged; runtime PNGs are rendered from these editable SVG sources.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const themes = JSON.parse(fs.readFileSync(path.join(root, 'docs/design/theme-art-bible.json'), 'utf8').replace(/^\uFEFF/, ''));
const familyOf = id => {
  if (/legno|wood/.test(id)) return 'wood';
  if (/restyle_acido|acid/.test(id)) return 'acid';
  if (/spiritual|spirit/.test(id)) return 'spirit';
  if (/restyle_cenere/.test(id)) return 'ash';
  if (/dream|sogno/.test(id)) return 'dream';
  if (/forest|briar|thorn|vervain|natura|meadow|bloom|rose|verdigris/.test(id)) return 'botanical';
  if (/frost|glass|obsidian|aurora/.test(id)) return 'crystal';
  if (/bolted|iron|keep|fortezza|obser|school|stagecoach|cell/.test(id)) return 'forged';
  if (/moon|lunar|astral|cosmic|karma|void/.test(id)) return 'astral';
  if (/abyss|slime|mutation|phobia/.test(id)) return 'tide';
  if (/ember|ash|cenere|bonfire|lume|solar|storm/.test(id)) return 'ember';
  return 'cathedral';
};
const palettes = {botanical:['#493f54','#a98bc1','#68765b'],crystal:['#506374','#b7d1dc','#786891'],forged:['#544d48','#c4ae86','#857469'],astral:['#554f78','#c7bde4','#8584a1'],tide:['#344c58','#91bcc1','#627380'],ember:['#67422e','#d7ad70','#a25a40'],cathedral:['#5c4d4a','#cfbba0','#897276'],dream:['#435477','#dcc3ef','#a595d8']};
palettes.wood=['#322014','#dbb579','#8c6240'];
palettes.ash=['#37383d','#cbcbd1','#777b82'];
palettes.acid=['#17211a','#c4e66d','#8d78b0'];
palettes.spirit=['#191b21','#eceef3','#b8bdc8'];
const materialOf = id => /ivory|bone/.test(id)?'ivory':({botanical:'bark',crystal:'crystal',forged:'metal',astral:'astral',tide:'water',ember:'charred',cathedral:'stone',dream:'dream',wood:'wood',ash:'ash',acid:'acid',spirit:'spirit'}[familyOf(id)]);
const hash = s => crypto.createHash('sha256').update(s).digest();
async function writePng(file, buffer) {
  const temporary=`${file}.tmp-${process.pid}`;
  fs.writeFileSync(temporary,buffer);
  for(let attempt=0;attempt<8;attempt++) {
    try { fs.renameSync(temporary,file); return; }
    catch(error) { if(attempt===7) throw error; await new Promise(resolve=>setTimeout(resolve,350)); }
  }
}
const paletteSources=new Map();
function paletteOf(theme) {
  if(!paletteSources.has(theme.source)) paletteSources.set(theme.source,fs.readFileSync(path.join(root,theme.source),'utf8'));
  const text=paletteSources.get(theme.source), start=text.indexOf(`id: '${theme.id}'`);
  const next=text.indexOf('OculumColorPreset(',start+1), block=text.slice(start,next<0?undefined:next);
  const color=key=>{const m=block.match(new RegExp(`${key}:\\s*Color\\(0x[0-9a-fA-F]{2}([0-9a-fA-F]{6})\\)`));return m?`#${m[1]}`:null;};
  const fallback=palettes[familyOf(theme.id)];
  return [color('secondary')||fallback[0],color('tertiary')||fallback[1],color('utility')||fallback[2]];
}
function frame(theme, w, h, role, variant = '') {
  const bytes=hash(theme.id), family=familyOf(theme.id), [dark,light,mid]=paletteOf(theme);
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
      } else if(family==='dream') {
        line(`M ${x+sx*a} ${y+sy*13} C ${x+sx*(a-6)} ${y+sy*4} ${x+sx*(a+5)} ${y+sy*3} ${x+sx*(a+10)} ${y+sy*11} C ${x+sx*(a+16)} ${y+sy*5} ${x+sx*(a+25)} ${y+sy*7} ${x+sx*(a+27)} ${y+sy*14}`,i%2===0?'#8aa8df':'#d7a7df',2,.76);
        if(i%2===0)ellipse(x+sx*(a+18),y+sy*17,2,1.4,'#efbedb','#d7a7df');
      } else if(family==='wood') {
        for(let grain=0;grain<3;grain++) line(`M ${x+sx*(a-4)} ${y+sy*(2+grain*4)} Q ${x+sx*(a+7)} ${y+sy*(8+grain*3)} ${x+sx*(a+18)} ${y+sy*(2+grain*4)}`,mid,.8,.8);
      } else if(family==='ash') {
        for(let dust=0;dust<8;dust++)ellipse(x+sx*(a+dust*2),y+sy*(2+(dust*7%11)),dust%3===0?1.2:.5,dust%3===0?.7:.4,light,mid);
      } else if(family==='acid') {
        line(`M ${x+sx*a} ${y+sy*2} Q ${x+sx*(a+5)} ${y+sy*11} ${x+sx*(a+10)} ${y+sy*7} T ${x+sx*(a+20)} ${y+sy*12}`,light,2,.92);
        ellipse(x+sx*(a+8),y+sy*8,2,3,mid,light);
        line(`M ${x+sx*(a+8)} ${y+sy*4} L ${x+sx*(a+8)} ${y+sy*9}`,'#eef9c9',.65,.8);
      } else if(family==='spirit') {
        line(`M ${x+sx*a} ${y+sy*13} Q ${x+sx*(a-4)} ${y+sy*7} ${x+sx*(a+3)} ${y+sy*3} Q ${x+sx*(a+9)} ${y-sy*2} ${x+sx*(a+13)} ${y+sy*4} Q ${x+sx*(a+17)} ${y+sy*10} ${x+sx*(a+12)} ${y+sy*14}`,light,1.35,.72);
        ellipse(x+sx*(a+7),y+sy*7,1.3,1.3,light,light);
        line(`M ${x+sx*(a+1)} ${y+sy*16} Q ${x+sx*(a+10)} ${y+sy*19} ${x+sx*(a+18)} ${y+sy*15}`,mid,.6,.48);
      } else {
        line(`M ${x+sx*a} ${y+sy*3} L ${x+sx*a} ${y+sy*14} Q ${x+sx*(a+5)} ${y+sy*8} ${x+sx*(a+10)} ${y+sy*14} L ${x+sx*(a+10)} ${y+sy*3}`,mid,1.8,.8);
        polygon(`${x+sx*(a+5)},${y+sy*2} ${x+sx*(a+8)},${y+sy*6} ${x+sx*(a+5)},${y+sy*10} ${x+sx*(a+2)},${y+sy*6}`);
      }
    }
  }
  // Give each sheet a clear, symmetric material rail. Repeated family marks
  // fill the side gutters while the entire reading area stays transparent.
  const railStep=62+bytes[14]%16;
  for(const [rail,sx] of [[inset+5,1],[w-inset-5,-1]]) {
    line(`M ${rail} ${inset+30} L ${rail} ${h-inset-30}`,dark,5,.44);
    line(`M ${rail} ${inset+30} L ${rail} ${h-inset-30}`,light,.75,.64);
    for(let y=inset+42,index=0;y<h-inset-35;y+=railStep,index++) {
      const length=5+(bytes[(index+20)%32]%5);
      line(`M ${rail-sx*3} ${y-12} L ${rail} ${y-12} L ${rail+sx*length} ${y-3} L ${rail+sx*length} ${y+7}`,mid,1,.8);
      if(family==='botanical') {
        line(`M ${rail} ${y-14} Q ${rail+sx*9} ${y} ${rail} ${y+14}`,variant==='alive'?'#91ad72':'#77716f',1.5,.92);
        for(const dy of [-7,1,9]) {
          const leaf=variant==='alive'?'#91ad72':'#77716f', bloom=variant==='alive'?'#d4a0df':'#8a777b';
          shapes.push(`<path d="M ${rail} ${y+dy} q ${sx*8} ${-sx*4} ${sx*8} ${sx*2} q ${-sx*5} ${sx*5} ${-sx*8} ${-sx*2}Z" fill="${leaf}" opacity=".88"/>`);
          if(variant==='alive'&&dy===1) for(let p=0;p<5;p++) { const a=p*Math.PI*2/5, px=rail+sx*10+Math.cos(a)*2.2, py=y+dy+Math.sin(a)*2.2; shapes.push(`<ellipse cx="${px}" cy="${py}" rx="1.7" ry="2.6" transform="rotate(${p*72} ${px} ${py})" fill="${bloom}"/>`); }
        }
      } else if(family==='crystal') {
        polygon(`${rail+sx*8},${y-14} ${rail+sx*15},${y-3} ${rail+sx*8},${y+13} ${rail+sx*2},${y-1}`,dark);
        line(`M ${rail+sx*8} ${y-13} L ${rail+sx*8} ${y+12} M ${rail+sx*3} ${y-1} L ${rail+sx*14} ${y-3}`,light,.8,.95);
      } else if(family==='forged') {
        shapes.push(`<path d="M ${rail+sx*2} ${y-13} h ${sx*13} v 25 h ${-sx*13}Z" fill="${dark}" fill-opacity=".52" stroke="${light}" stroke-width=".8"/>`);
        ellipse(rail+sx*8.5,y-8,1.5,1.5,light,dark); ellipse(rail+sx*8.5,y+7,1.5,1.5,light,dark);
      } else if(family==='astral') {
        ellipse(rail+sx*9,y,6,6,dark,light);
        line(`M ${rail+sx*9} ${y-11} L ${rail+sx*9} ${y+11} M ${rail+sx*1} ${y} L ${rail+sx*17} ${y}`,mid,.7,.8);
        ellipse(rail+sx*9,y,1.7,1.7,light,light);
      } else if(family==='tide') {
        for(let wave=0;wave<3;wave++) line(`M ${rail+sx*(wave*3)} ${y-11+wave*8} C ${rail+sx*10} ${y-4+wave*8} ${rail+sx*5} ${y+wave*8} ${rail+sx*17} ${y-4+wave*8}`,wave===1?'#91bcc1':mid,1.25,.82);
      } else if(family==='ember') {
        const color=variant==='alive'?'#ed9a60':mid;
        shapes.push(`<path d="M ${rail+sx*9} ${y-14} Q ${rail+sx*1} ${y-4} ${rail+sx*6} ${y+1} Q ${rail+sx*2} ${y+9} ${rail+sx*9} ${y+13} Q ${rail+sx*17} ${y+8} ${rail+sx*12} ${y+1} Q ${rail+sx*17} ${y-6} ${rail+sx*9} ${y-14}Z" fill="${color}" fill-opacity=".48" stroke="${light}" stroke-width=".9"/>`);
        line(`M ${rail+sx*9} ${y-5} Q ${rail+sx*5} ${y+1} ${rail+sx*9} ${y+8}`,light,.8,.9);
      } else if(family==='dream') {
        const cloudColor=variant==='alive'?'#efbddb':'#a48a9f';
        line(`M ${rail+sx*1} ${y+3} C ${rail-sx*2} ${y-5} ${rail+sx*5} ${y-10} ${rail+sx*9} ${y-4} C ${rail+sx*15} ${y-11} ${rail+sx*21} ${y-4} ${rail+sx*19} ${y+2} C ${rail+sx*22} ${y+9} ${rail+sx*14} ${y+12} ${rail+sx*8} ${y+8} C ${rail+sx*2} ${y+13} ${rail-sx*2} ${y+9} ${rail+sx*1} ${y+3}`,cloudColor,1.5,.92);
        if(variant==='alive') { ellipse(rail+sx*8,y+16,1.2,1.2,'#86aee8','#86aee8'); ellipse(rail+sx*15,y+18,1,1,'#b79ce7','#b79ce7'); }
      } else if(family==='acid') {
        for(let drop=0;drop<3;drop++) {
          const dx=rail+sx*(5+drop*5), dy=y-10+drop*3;
          shapes.push(`<path d="M ${dx} ${dy-4} C ${dx-3} ${dy} ${dx-2} ${dy+5} ${dx} ${dy+6} C ${dx+3} ${dy+5} ${dx+3} ${dy} ${dx} ${dy-4}Z" fill="${drop===1?'#c7e774':mid}" stroke="${light}" stroke-width=".6" opacity=".9"/>`);
          line(`M ${dx} ${dy-2} L ${dx} ${dy+2}`,'#eff9d4',.45,.85);
        }
      } else if(family==='spirit') {
        for(let mote=0;mote<4;mote++) {
          const dx=rail+sx*(4+mote*4), dy=y-6+(mote%2)*8;
          ellipse(dx,dy,mote%2?1.2:1.8,mote%2?2:2.6,'#e7eaf0','#f7f8fb');
          ellipse(dx-.4,dy-.5,.35,.35,'#ffffff','#ffffff');
        }
        line(`M ${rail+sx*2} ${y+12} Q ${rail+sx*10} ${y+7} ${rail+sx*18} ${y+12}`,'#b8bdc8',.6,.42);
      } else {
        const arch=`M ${rail+sx*2} ${y+12} L ${rail+sx*2} ${y-1} Q ${rail+sx*2} ${y-12} ${rail+sx*9} ${y-12} Q ${rail+sx*16} ${y-12} ${rail+sx*16} ${y-1} L ${rail+sx*16} ${y+12}`;
        line(arch,light,1.1,.86); polygon(`${rail+sx*9},${y-5} ${rail+sx*13},${y} ${rail+sx*9},${y+5} ${rail+sx*5},${y}`);
      }
      if(variant==='alive'&&family!=='botanical'&&family!=='dream') ellipse(rail+sx*20,y,1.6,1.6,light,light);
    }
  }
  // A centered crest anchors the composition instead of drifting off-axis.
  const center=w*.5, cy=inset;
  line(`M ${center-32} ${cy} L ${center-12} ${cy} M ${center+12} ${cy} L ${center+32} ${cy}`,mid,1.25,.86);
  polygon(`${center},${cy-11} ${center+11},${cy} ${center},${cy+11} ${center-11},${cy}`);
  polygon(`${center},${cy-6} ${center+6},${cy} ${center},${cy+6} ${center-6},${cy}`,mid);
  for(let i=0;i<4;i++)if(bytes[9]&(1<<i))line(`M ${center-4+i*2.5} ${cy-4} L ${center+1+i} ${cy+4}`,light,.8,.96);
  if(variant==='alive') { ellipse(center-16,cy,1.8,1.8,light,light); ellipse(center+16,cy,1.8,1.8,light,light); }
  if (variant) {
    const alive = variant === 'alive';
    const reach = Math.max(8, Math.min(76, Math.min(w, h) * .17));
    const corners = [[inset,inset,1,1],[w-inset,inset,-1,1],[inset,h-inset,1,-1],[w-inset,h-inset,-1,-1]];
    for(const [x,y,sx,sy] of corners) {
      if(family==='botanical') {
        if(alive) {
          const green='#91ad72', bloom='#d4a0df';
          line(`M ${x} ${y+sy*4} C ${x+sx*reach*.12} ${y+sy*reach*.2} ${x+sx*reach*.65} ${y+sy*reach*.22} ${x+sx*reach*.82} ${y+sy*reach*.64}`,green,2.1,.95);
          line(`M ${x+sx*reach*.33} ${y+sy*reach*.2} Q ${x+sx*reach*.52} ${y+sy*reach*.04} ${x+sx*reach*.62} ${y+sy*reach*.31} Q ${x+sx*reach*.42} ${y+sy*reach*.32} ${x+sx*reach*.33} ${y+sy*reach*.2}`,green,1,.9);
          for(let p=0;p<5;p++){const a=p*Math.PI*2/5, px=x+sx*reach*.82+Math.cos(a)*reach*.055, py=y+sy*reach*.64+Math.sin(a)*reach*.055; shapes.push(`<ellipse cx="${px}" cy="${py}" rx="${reach*.035}" ry="${reach*.06}" transform="rotate(${p*72} ${px} ${py})" fill="${bloom}" opacity=".9"/>`)}
          ellipse(x+sx*reach*.82,y+sy*reach*.64,reach*.025,reach*.025,'#e6c98e','#e6c98e');
        } else {
          line(`M ${x} ${y+sy*4} C ${x+sx*reach*.2} ${y+sy*reach*.18} ${x+sx*reach*.58} ${y+sy*reach*.16} ${x+sx*reach*.78} ${y+sy*reach*.58}`, '#77716f',1,.86);
          line(`M ${x+sx*reach*.35} ${y+sy*reach*.24} Q ${x+sx*reach*.26} ${y+sy*reach*.04} ${x+sx*reach*.17} ${y+sy*reach*.27}`, '#77716f',.8,.7);
          shapes.push(`<path d="M ${x+sx*reach*.73} ${y+sy*reach*.52} q ${sx*reach*.15} ${sy*reach*.08} ${sx*reach*.04} ${sy*reach*.22} q ${-sx*reach*.12} ${-sy*reach*.03} ${-sx*reach*.04} ${-sy*reach*.22}" fill="#8a777b" opacity=".72"/>`);
        }
      } else if(family==='dream') {
        const c1=alive?'#86aee8':'#7183a5', c2=alive?'#b79ce7':'#8a7e9d', c3=alive?'#efbddb':'#a48a9f';
        for(let cloud=0;cloud<(alive?3:2);cloud++) {
          const yy=y+sy*(reach*(.24+cloud*.22)), xx=x+sx*(cloud*reach*.08);
          line(`M ${xx} ${yy} C ${xx-sx*reach*.08} ${yy-sy*reach*.12} ${xx+sx*reach*.04} ${yy-sy*reach*.18} ${xx+sx*reach*.17} ${yy-sy*reach*.11} C ${xx+sx*reach*.19} ${yy-sy*reach*.24} ${xx+sx*reach*.39} ${yy-sy*reach*.25} ${xx+sx*reach*.42} ${yy-sy*reach*.1} C ${xx+sx*reach*.57} ${yy-sy*reach*.16} ${xx+sx*reach*.64} ${yy-sy*reach*.04} ${xx+sx*reach*.58} ${yy+sy*reach*.04}`,[c1,c2,c3][cloud%3],alive?2.1:1.2,alive?.9:.62);
        }
        if(alive) for(let s=0;s<3;s++) { const px=x+sx*reach*(.2+s*.2), py=y+sy*reach*(.69+(s%2)*.07); line(`M ${px} ${py-reach*.025} L ${px} ${py+reach*.025} M ${px-reach*.025} ${py} L ${px+reach*.025} ${py}`,c3,.8,.9); }
      } else if(family==='acid') {
        for(let drop=0;drop<4;drop++) {
          const dx=x+sx*reach*(.24+drop*.12), dy=y+sy*reach*(.28+(drop%2)*.18);
          const length=reach*(.12+(drop%2)*.05);
          line(`M ${dx} ${dy} C ${dx-sx*reach*.035} ${dy+sy*length*.42} ${dx+sx*reach*.025} ${dy+sy*length*.78} ${dx} ${dy+sy*length}`,alive?'#c7e774':'#7b8b55',alive?2:1,.88);
          ellipse(dx,dy+sy*length,reach*.018,reach*.024,alive?'#d9f39a':'#7b8b55',alive?'#eff9d4':'#7b8b55');
        }
        line(`M ${x+sx*reach*.18} ${y+sy*reach*.19} L ${x+sx*reach*.3} ${y+sy*reach*.11} L ${x+sx*reach*.39} ${y+sy*reach*.2}`,alive?'#d9c8ee':'#807b7b',1,.8);
      } else if(family==='spirit') {
        const ghost=alive?'#f0f2f7':'#838792';
        for(let mote=0;mote<(alive?6:3);mote++) {
          const px=x+sx*reach*(.2+(mote%3)*.22), py=y+sy*reach*(.2+Math.floor(mote/3)*.28);
          const r=reach*(mote%2?.025:.038);
          ellipse(px,py,r,r,ghost,ghost);
          line(`M ${px-sx*r*2} ${py+sy*r*3} Q ${px} ${py+sy*r*5} ${px+sx*r*2} ${py+sy*r*3}`,ghost,.7,alive?.5:.3);
        }
        line(`M ${x+sx*reach*.12} ${y+sy*reach*.62} Q ${x+sx*reach*.5} ${y+sy*reach*.48} ${x+sx*reach*.88} ${y+sy*reach*.62}`,ghost,alive?1.6:1,.54);
      } else if(alive) {
        // Each remaining theme family gets a distinct inlaid glyph, not a tint.
        const color=family==='crystal'?'#d5e6ee':family==='forged'?'#d5bd8c':family==='tide'?'#a0d5d6':family==='ember'?'#e8b36c':family==='astral'?'#cfc4f1':'#d9c7ad';
        line(`M ${x} ${y+sy*reach*.12} Q ${x+sx*reach*.08} ${y} ${x+sx*reach*.16} ${y+sy*reach*.12} Q ${x+sx*reach*.24} ${y+sy*reach*.25} ${x+sx*reach*.32} ${y+sy*reach*.08}`,color,1.7,.88);
        ellipse(x+sx*reach*.16,y+sy*reach*.2,reach*.035,reach*.035,color,color);
      } else {
        line(`M ${x} ${y+sy*reach*.14} L ${x+sx*reach*.12} ${y+sy*reach*.05} M ${x+sx*reach*.18} ${y+sy*reach*.24} L ${x+sx*reach*.31} ${y+sy*reach*.13}`, '#807b7b',.8,.7);
        ellipse(x+sx*reach*.17,y+sy*reach*.19,reach*.018,reach*.018,'#807b7b','#807b7b');
      }
    }
  }
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${shapes.join('')}</svg>`;
}
async function run() {
  const inventory=[];
  for(const theme of themes) {
    const dir=path.join(root,'design/themes',theme.id), output=path.join(root,'assets/themes',theme.id);
    fs.mkdirSync(dir,{recursive:true});
    const comp={id:theme.id,name:theme.name,materials:theme.formsAndMaterials,family:familyOf(theme.id),signature:hash(theme.id).toString('hex'),motion:theme.motion,figmaFile:'Dw1F8sR6bzTCuGkaH2CEeS',safeCenter:'Artwork only in outer 28 pixels; alpha=0 in reading area',desktop:'extended scene and split edge',tablet:'compact edge and side ornament',mobile:'dedicated shallow scene and narrow frame'};
    if(theme.id==='classic_reliquary'||theme.id==='classic_low_detail')comp.materials='sigillo inciso in rame e montatura d osso; nessun occhio in reliquiario';
    await writePng(path.join(dir,'composition.json'),JSON.stringify(comp,null,2)+'\n');
    for(const [role,w,h] of [['panel',1024,512],['mobile',640,320],['portrait',256,256],['statistics',256,192],['separator',768,64]]) {
      fs.mkdirSync(path.join(output,'frames'),{recursive:true});
      for (const variant of ['', 'still', 'alive']) {
        const svg=frame(theme,w,h,role,variant);
        const suffix=variant?`-${variant}`:'';
        if (!variant) await writePng(path.join(dir,`${role}.svg`),svg);
        else await writePng(path.join(dir,`${role}-${variant}.svg`),svg);
        const png=path.join(output,'frames',`${role}${suffix}.png`);
        const figmaExport = path.join(dir, 'figma-panel.png');
        if (!variant && role === 'panel' && fs.existsSync(figmaExport)) {
          // Preserve the existing hand-refined panel export and alpha mask.
          const mask = await sharp(Buffer.from(svg)).png().toBuffer();
          await writePng(png,await sharp(figmaExport).ensureAlpha().composite([{input:mask,blend:'dest-in'}]).png({compressionLevel:9}).toBuffer());
        } else {
          const material=path.join(root,`assets/themes/materials/${materialOf(theme.id)}.png`);
          if(fs.existsSync(material)) {
            // Actual raster material in the existing outer frame; the center
            // stays alpha=0 and nine-slice keeps the border width constant.
            const mask=Buffer.from(`<svg width="${w}" height="${h}"><rect x="8" y="8" width="${w-16}" height="${h-16}" rx="9" fill="none" stroke="white" stroke-width="14"/></svg>`);
            const textured=await sharp(material).resize(w,h).ensureAlpha().composite([{input:mask,blend:'dest-in'}]).png().toBuffer();
            await writePng(png,await sharp(textured).composite([{input:Buffer.from(svg)}]).png({compressionLevel:9}).toBuffer());
          } else {
            await writePng(png,await sharp(Buffer.from(svg)).png({compressionLevel:9}).toBuffer());
          }
        }
        inventory.push({theme:theme.id,role:variant?`${role}-${variant}`:role,path:path.relative(root,png).replace(/\\/g,'/'),bytes:fs.statSync(png).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(png)).digest('hex')});
      }
    }
    // Scenes assemble original artwork in reserved empty space. Classic uses
    // only engraved geometry, respecting the removed eye-in-reliquary request.
    for(const [role,w,h] of [['scene',1024,192],['scene-mobile',640,96]]) {
      const layers=[];
      if(theme.id!=='classic_reliquary'&&theme.id!=='classic_low_detail'&&theme.signaturePng&&fs.existsSync(path.join(root,theme.signaturePng))) {
        // Crop a large part of the illustration into the scene, rather than
        // shrinking a tall creature into a tiny icon. Center remains empty.
        const image=await sharp(path.join(root,theme.signaturePng)).resize({height:h,width:Math.round(w*.28),fit:'cover',position:'centre'}).png().toBuffer();
        const meta=await sharp(image).metadata();
        const right=hash(theme.id)[10]%2===0;
        layers.push({input:image,left:right?w-meta.width-18:18,top:Math.floor((h-meta.height)/2)});
      }
      fs.mkdirSync(path.join(output,'decorations'),{recursive:true});
      for (const variant of ['', 'still', 'alive']) {
        const lines=Buffer.from(frame(theme,w,h,'mobile',variant));
        const suffix=variant?`-${variant}`:'';
        const png=path.join(output,'decorations',`${role}${suffix}.png`);
        await writePng(path.join(dir,`${role}${suffix}.json`),JSON.stringify({width:w,height:h,source:theme.signaturePng,layers:layers.length,variant:variant||'default',placement:hash(theme.id)[10]%2===0?'right':'left',alphaCenter:0},null,2)+'\n');
        await writePng(png,await sharp({create:{width:w,height:h,channels:4,background:'#00000000'}}).composite([{input:lines},...layers]).png({compressionLevel:9}).toBuffer());
        inventory.push({theme:theme.id,role:variant?`${role}-${variant}`:role,path:path.relative(root,png).replace(/\\/g,'/'),bytes:fs.statSync(png).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(png)).digest('hex')});
      }
    }
    if (theme.id === 'restyle_sogno') {
      const relicSvg=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><g fill="none" stroke-linecap="round" stroke-linejoin="round"><path d="M38 151c-15-27 9-47 34-39 7-38 58-45 74-7 31-15 66 14 53 42 13 23-6 47-33 43H69c-18 0-31-16-31-39Z" fill="#435477" fill-opacity=".42" stroke="#dcc3ef" stroke-width="5"/><path d="M51 158c22-12 39 6 57-2 18-8 31-3 49 3 17 6 28-2 41-8M67 171c17-7 27 4 42 0 15-4 25 4 37 7 12 3 24-2 34-7" stroke="#8aa8df" stroke-width="3"/><path d="M84 126c11-12 27-8 33 3 12-18 39-14 43 4 15-8 29 7 23 18" stroke="#efbedb" stroke-width="3"/><path d="m116 80 0-17m-8 8h16m52 95 0-13m-6 6h12m-105 35 0-12m-6 6h12" stroke="#efbedb" stroke-width="2"/></g></svg>`);
      const relic=path.join(output,'overlays','relic.png');
      fs.mkdirSync(path.dirname(relic),{recursive:true});
      await writePng(relic,await sharp(relicSvg).png({compressionLevel:9}).toBuffer());
      inventory.push({theme:theme.id,role:'relic',path:path.relative(root,relic).replace(/\\/g,'/'),bytes:fs.statSync(relic).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(relic)).digest('hex')});
    }
    if (theme.id === 'restyle_acido' || theme.id === 'restyle_spiritualita') {
      const acid = theme.id === 'restyle_acido';
      const acidSvg=`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><defs><linearGradient id="glass" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#29372e"/><stop offset=".55" stop-color="#a7cc5d" stop-opacity=".55"/><stop offset="1" stop-color="#382d49"/></linearGradient></defs><path d="M72 35Q128 20 184 35L173 183Q128 210 83 183Z" fill="url(#glass)" fill-opacity=".62" stroke="#d5eb9b" stroke-width="5"/><path d="M91 51Q112 98 96 137T101 176M164 52Q144 98 162 132T151 185" fill="none" stroke="#c7e774" stroke-width="5" stroke-linecap="round"/><path d="M117 66q12 14 2 33t2 26M139 109q10 13 1 25" fill="none" stroke="#f0f8d2" stroke-width="2.5" stroke-linecap="round"/><path d="M104 49l10-12m33 14 9-10" stroke="#d9c8ee" stroke-width="2"/><circle cx="98" cy="172" r="4" fill="#c7e774"/><circle cx="160" cy="185" r="3" fill="#c7e774"/></svg>`;
      const spiritSvg=`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256"><path d="M73 40Q128 19 183 40L173 181Q128 208 83 181Z" fill="#dfe3eb" fill-opacity=".08" stroke="#eef0f5" stroke-opacity=".86" stroke-width="4"/><path d="M93 53Q120 79 97 103T102 157M161 54Q137 82 160 107T151 174" fill="none" stroke="#e9ecf3" stroke-opacity=".48" stroke-width="2"/><g fill="#f5f6f9"><circle cx="69" cy="88" r="4" opacity=".46"/><circle cx="190" cy="120" r="3" opacity=".3"/><circle cx="75" cy="157" r="2.5" opacity=".4"/><circle cx="179" cy="69" r="3.5" opacity=".34"/></g><path d="M100 71q10-11 20 0t20 0m-37 59q13-13 26 0t26 0" fill="none" stroke="#c5cbd6" stroke-opacity=".52" stroke-width="2"/></svg>`;
      const relicSvg=Buffer.from(acid?acidSvg:spiritSvg);
      const relic=path.join(output,'overlays','relic.png');
      fs.mkdirSync(path.dirname(relic),{recursive:true});
      await writePng(relic,await sharp(relicSvg).png({compressionLevel:9}).toBuffer());
      inventory.push({theme:theme.id,role:'relic',path:path.relative(root,relic).replace(/\\/g,'/'),bytes:fs.statSync(relic).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(relic)).digest('hex')});
    }
  }
  await writePng(path.join(root,'design/theme-art-manifest.json'),JSON.stringify(inventory,null,2)+'\n');
  for (const id of ['vervain_gothic','abyssal_tide','bone_saint','frost_chapel','restyle_sogno','restyle_acido','restyle_spiritualita']) {
    const t=themes.find(x=>x.id===id), [dark,light]=paletteOf(t);
    const escape=s=>s.replace(/&/g,'&amp;').replace(/</g,'&lt;');
    const lettering=Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="640"><rect width="1024" height="640" fill="#100e16"/><text x="62" y="80" fill="${light}" font-family="serif" font-size="32">OCULUM · ${escape(t.name)}</text><text x="62" y="118" fill="#c5b9ad" font-size="17">${escape(t.formsAndMaterials)}</text><text x="64" y="350" fill="${light}" font-family="serif" font-size="25">Rose | Tutto pur di Salvarla</text><text x="64" y="390" fill="#ded3c6" font-size="18">Vita e scudo     30 / 30          Oculum     6 / 6</text><text x="64" y="435" fill="#ded3c6" font-size="18">Resilienza 3   ·   Volontà 3   ·   Materia 5   ·   Oculum 6</text><text x="64" y="488" fill="#ded3c6" font-size="18">Attacco · Difesa · Iniziativa · Aiuta compagno</text><text x="64" y="604" fill="${light}" font-size="13">Tavola degli asset · centro leggibile · cornici e scene in layer separati</text></svg>`);
    const framePng=await sharp(path.join(root,`assets/themes/${id}/frames/panel.png`)).resize(1024,512).png().toBuffer();
    const scene=fs.readFileSync(path.join(root,`assets/themes/${id}/decorations/scene.png`));
    await writePng(path.join(root,`design/theme-art-preview-${id}.png`),await sharp(lettering).composite([{input:framePng,top:128,left:0},{input:scene,top:134,left:0}]).png().toBuffer());
  }
  console.log(`Created ${inventory.length} transparent PNGs for ${themes.length} themes (${(inventory.reduce((a,b)=>a+b.bytes,0)/1048576).toFixed(2)} MiB).`);
}
run().catch(e=>{console.error(e);process.exitCode=1;});
