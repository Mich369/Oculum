// Editable theme reliefs, exported into the shared Flutter art layer.
// No gameplay data or control geometry is changed by this exporter.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const read = file => JSON.parse(fs.readFileSync(path.join(root, file), 'utf8').replace(/^\uFEFF/, ''));
const bible = read('docs/design/theme-art-bible.json');
const elements = read('docs/design/element-pack-specs.json');
const P = d => `<path d="${d}"/>`;
const C = (x,y,r) => `<circle cx="${x}" cy="${y}" r="${r}"/>`;
const eye = P('M2 16Q16 1 30 16Q16 31 2 16Z')+C(16,16,5);
const moon = P('M23 2C-7 5-3 34 25 29C5 24 8 9 23 2Z');
const flower = C(16,16,3)+P('M16 12C3-5-5 16 12 16C-5 29 17 39 16 20C29 39 39 16 20 16C39 3 16-5 16 12Z');
const gear = C(16,16,10)+C(16,16,4)+P('M16 1v5m0 20v5M1 16h5m20 0h5M5 5l4 4m14 14 4 4M5 27l4-4M23 9l4-4');
const crown = P('M3 10l5 18h16l5-18-9 7-4-14-4 14Z M8 24h16');
const drop = P('M16 1C12 10 3 16 6 24C10 34 26 32 27 22C28 16 20 8 16 1Z');
const motifs = {
 classic_reliquary: eye+P('M3 3l5 3M29 3l-5 3M2 29l7-3M30 29l-7-3'),
 classic_rpg:P('M4 3h24v14L16 31 4 17Z M16 5v21M8 12h16'),
 classic_low_detail:P('M16 4L28 16 16 28 4 16Z M12 16h8'),
 blood_court:crown+drop.replaceAll('path','path transform="translate(9 9) scale(.43)"'),
 witch_glass:P('M11 1h10M13 2v8L3 25q0 6 13 6t13-6L19 10V2M6 22h20M12 15l6 5-4 5'),
 moon_iron:moon+P('M3 3v26M0 8h7M0 24h7'),
 lunar_eclipse:C(16,16,9)+P('M2 16Q16-8 30 16Q16 40 2 16M20 7Q8 15 19 25'),
 cathedral_rose:flower+P('M16 0v5M16 27v5M0 16h5M27 16h5'),
 thorn_vigil:P('M1 28Q26 35 27 3M2 25l-1-8 8 5M20 23l8 5-2-10M24 13l-9-5 9-2'),
 frost_chapel:eye+P('M16 0v8M11 3l5 5 5-5M16 24v8M10 29l6-5 6 5M0 16h4M28 16h4'),
 obsidian_sigil:P('M15 0L29 9 23 29 7 31 1 12Z M15 0l2 12-10 7 16 10M17 12l12-3M7 19l-6-7'),
 solar_reliquary:C(16,16,6)+P('M16 0v7M16 25v7M0 16h7M25 16h7M4 4l6 6M22 22l6 6M4 28l6-6M22 10l6-6'),
 storm_cathedral:P('M2 30V17l5-8 5 8v13M22 30V12l4-10 4 10v18M15 0l-5 12h8l-4 15 11-19h-8l3-8'),
 abyssal_tide:P('M16 27C-10 20 2-5 16 5C30-5 42 20 16 27ZM16 26L5 9M16 26l0-21M16 26L27 9M3 30q6-9 10 0M20 31q5-12 10-4'),
 ember_rite:P('M5 30V13h8v17M20 30V8h7v22M3 14h12M18 9h11M9 10q-8-6 0-10 7 7 0 10M24 6q-6-5 0-6 5 5 0 6'),
 ivory_archive:P('M6 1q-8 0-4 8h21V2q9-4 8 5v20q-1 6-8 3H5V9M8 13h12M8 19h12M8 25h8'),
 vervain_gothic:flower+P('M3 31Q20 21 15 1M27 30Q6 13 3 2M8 25l-7-2M23 24l7-5'),
 kingi_wrong_future:gear+P('M9 16Q16 7 23 16Q16 25 9 16Z'),
 blood_chapel:P('M3 31V14Q16-9 29 14v17M7 29V14Q16-1 25 14v15')+P('M16 10q-13 18 0 18 13 0 0-18Z'),
 null_crown:P('M1 8l7 18h7M20 26h4l7-18-9 7-5-12-4 12-4-3M9 30h15'),
 phobia_dark:eye+C(16,16,2)+P('M0 2l8 7M32 1l-8 8M0 31l8-8M32 31l-8-8'),
 whispering_reliquary:P('M2 15q14-10 28 0q-14 12-28 0ZM7 13l1 7M13 11v10M20 11v10M25 13l-1 7M3 29q16-7 26 0'),
 black_briar_kingdom:crown+P('M1 31Q20 23 29 1M6 26l-5-7M22 9l-7-4M23 25l8 3'),
 slime_prince:crown+P('M4 28q-6-12 6-13q6-6 13 0 13 1 6 13Z'),
 moon_rot:moon+P('M3 16q6-10 12 0ZM9 16v13M19 26q5-9 11 0M25 26v5'),
 obser_relic:C(16,16,12)+P('M16 5v22M5 13h22M5 13L2 22h9ZM27 13l-5 9h9Z'),
 deep_forest_demon:P('M8 31l1-13Q-2 11 3 1q0 12 9 8L16 1l4 8q9 4 9-8 5 10-6 17l1 13M10 24l6-6 6 6'),
 astral_ink:P('M9 18V8h14v10l5 6v7H4v-7ZM7 21h18M11 11h10M16 0v5M2 7l4 2M27 6l4-3'),
 bone_saint:C(16,7,6)+P('M11 14h10l3 4-3 4 3 4-3 5H11l-3-5 3-4-3-4ZM16 13v19'),
 medieval_keep:P('M2 31V5h5v5h5V5h8v5h5V5h5v26M11 31V19q5-9 10 0v12'),
 fortezza_oculum:P('M1 31V8l6-7 6 7v23M19 31V8l6-7 6 7v23M13 14h6M13 27h6')+P('M9 10Q16 0 23 10Q16 18 9 10Z'),
 hoshy_cosmic_cat:P('M4 16L2 1l11 7h7l11-7-3 15q2 16-12 15Q2 31 4 16ZM7 17h5M21 17h5M14 24l2 2 2-2M29 26q12-17-3-14'),
 ash_oracle:P('M3 4Q16-2 29 4l-4 19-9 8-9-8ZM7 10l6 3M25 10l-6 3M12 22h8M2 30l3-3M29 27l3 3'),
 void_liturgy:P('M6 6A14 14 0 1 0 27 6M4 7h24l-4 25H8ZM8 7q16 12 16 25M24 7Q8 19 8 32'),
 shadow_gate_rank:P('M1 31V9L16 0 31 9v22M6 31V12l10-6 10 6v19M11 31V16l5-3 5 3v15'),
 postea_bloom:flower+P('M3 27l6-3M23 28l6-4M3 4l4 3M27 4l4 3')+C(16,16,1),
 karma_duality:P('M16 2v28M2 9h28M2 9v9h10V9M20 9v9h10V9M7 21Q16 32 25 21')+C(7,13,2)+C(25,13,2),
 monster_lantern:P('M11 3q5-7 10 0M7 5h18l-2 23H9ZM5 5h22M6 30h20M13 23V10l6 5-4 4 5 4'),
 jrpg_legend:P('M16 0l5 7-4 15h8v4h-8v6h-3v-6H7v-4h7L11 7Z'),
 rogue_mutation:eye+P('M1 2q15 11 0 28M31 1q-15 15 0 30M12 1q9 8 7 12M10 24q-8 9 0 8'),
 cell_crimson_run:P('M4 0v11l4 4-4 5v12M14 0v32M24 0v12l-3 5 7 5v10M0 5h31M0 27h31'),
 darkest_stagecoach:C(10,22,9)+C(10,22,3)+P('M10 13v18M1 22h18M4 16l12 12M4 28l12-12M22 4h8l-1 16h-6ZM26 0v4'),
 buried_herbarium:P('M3 1h26v30H3ZM16 28V8M16 18Q4 21 6 10q10 0 10 8M17 14q11 2 10-9-9 0-10 9'),
 funeral_clockwork:gear+P('M16 7v10l6 4M2 30l8-4M30 30l-8-4'),
 tidal_stained_glass:P('M2 29V12Q16-9 30 12v17ZM16 2v27M2 15h28M2 22q7-8 14 0t14 0M6 7l20 19M26 7L6 26'),
 ashen_covenant:P('M5 0l23 7-4 25-9-4-9 4 2-20ZM9 5l13 3-2 17-8-4M1 17l5 3M27 14l5 2'),
 eclipse_bonfire:moon+P('M14 29q-10-5-1-16 0 7 4 6 0-7 5-10 11 16-8 20Z'),
 bolted_black_iron:P('M3 3h26v26H3Z M8 16h16M16 8v16')+C(6,6,1)+C(26,26,1),
 bolted_gold_plate:crown+C(5,4,2)+C(27,4,2)+P('M7 31h18'),
 bolted_copper_oxide:P('M1 6h10v20h21M1 12h5v19h26M16 1v8h14v6M17 18q-7-8 1-10')+C(23,23,4),
 bolted_silver_plate:eye+C(16,16,10)+P('M0 3h8M24 3h8M0 29h8M24 29h8'),
 meadow_sprite:P('M16 31V11M16 18Q-2 16 3 5q13 0 13 13M16 18Q34 16 29 5 16 5 16 18')+C(16,6,3),
 aurora_moth:P('M16 29V8M16 14Q-5-4 3 24l13-6q21-22 13 6l-13-6M16 8L10 1M16 8l6-7')+C(7,14,3)+C(25,14,3),
 modern_school_day:P('M5 1h24v30H5ZM9 1v30M2 7h6M2 15h6M2 23h6M15 8h9M15 13h9M16 20l6 6M22 20l-6 6'),
 vtt_arcane_table:P('M1 7l15-6 15 6v18l-15 6-15-6ZM1 7l15 6 15-6M16 13v18M8 4l16 25M24 4L8 29'),
 vtt_obsidian_grid:P('M1 1h30v30H1ZM1 11h30M1 21h30M11 1v30M21 1v30M11 11l10 10M21 11L11 21'),
 vtt_parchment_layers:P('M2 8L26 1l5 22-23 8ZM5 12l17-6 5 14-17 6ZM11 17l7-6 4 9-7-1-2 4'),
 vtt_master_overlay:C(16,16,13)+P('M16 0v8M16 24v8M0 16h8M24 16h8M10 12l6-5 6 5-6 7Z'),
 verdigris_mourning:flower+P('M1 29l8-4M23 28l8 3M4 0l2 8M28 0l-2 8M12 28h8'),
 restyle_legno:P('M1 5q14-8 30 0M1 10q14-8 30 0M1 23q14 8 30 0M1 29q14 6 30 0M6 18q10-12 20 0-10 9-20 0Z'),
 restyle_originale:eye+P('M0 4h32M0 28h32M4 1v30M28 1v30'),
 restyle_cenere:P('M3 31V6l10-5 16 6v24ZM7 13l6 4 6-6 7 8M8 25h2M17 28h3M24 24h4'),
 restyle_sangue:eye+P('M0 13l5 8M6 8l5 8M21 16l5 8M27 11l5 8M16 24q-5 8 0 8 5 0 0-8'),
 restyle_aurora:P('M1 6q9-10 15 0t15 0M1 12q9-10 15 0t15 0M1 18q9-10 15 0t15 0M1 24q9-10 15 0t15 0')+C(16,16,3),
 restyle_natura:P('M16 31V18M16 22Q-5 17 5 1q14 4 11 21M17 18Q34 17 28 3q-13 0-11 15'),
 restyle_lume:P('M11 28V12h10v16M7 31h18M8 12h16M16 9q-9-4 0-9 8 7 0 9M2 7l4 3M26 10l4-3'),
 restyle_acido:P('M7 1h18L22 27q-6 7-12 0ZM11 7q11 3 10 10M11 12l3 13M20 21v8')+C(16,19,2),
 restyle_sogno:P('M6 26q-11-9 0-15 2-13 14-7 10-3 10 9 9 11-2 13ZM5 20q8-5 15 0t12 0')+C(22,8,2),
 restyle_spiritualita:P('M9 31Q-1 3 16 1q17 2 7 30l-5-5-4 5-5-5Z M11 9q5-6 10 0M11 17q5 7 10 0'),
};
const palettes = { wood:['#513620','#dfb27d'],bark:['#2c392e','#b9c39b'],stone:['#30323b','#c8c6cf'],metal:['#313941','#bbc8d2'],charred:['#281e1c','#ed995d'],ash:['#33343b','#c8c6cc'],dream:['#363657','#dcc3ed'],spirit:['#343747','#e9e8f1'],astral:['#28283f','#bdb2df'],crystal:['#283b4b','#afdbeb'],water:['#18343c','#97d4ce'],ivory:['#423b35','#dfd2ae'],acid:['#263629','#c6df80']};
function family(theme) {
 const id=theme.id, text=theme.formsAndMaterials.toLowerCase();
 if(/cenere|ash/.test(id))return 'ash';
 if(/legno|herbarium/.test(id))return 'wood';
 if(/blood|sangue|ember|bonfire|lume|solar/.test(id))return 'charred';
 if(/spirit|bone_saint/.test(id))return 'spirit';
 if(/sogno|dream|aurora|moth/.test(id))return 'dream';
 if(/acid|witch/.test(id))return 'acid';
 if(/forest|briar|thorn|vervain|natura|meadow|bloom|rose|verdigris/.test(id))return 'bark';
 if(/frost|glass|obsidian/.test(id))return 'crystal';
 if(/iron|bolted|clock|kingi|obser|fortezza|cell|stagecoach/.test(id))return 'metal';
 if(/moon|lunar|astral|cosmic|void|karma|shadow/.test(id))return 'astral';
 if(/abyss|tide|slime|mutation|phobia/.test(id))return 'water';
 return /osso|avorio/.test(text)?'ivory':'stone';
}
function motion(theme,material) {
 const text=(theme.motion+' '+theme.id).toLowerCase();
 if(/moon|lunar/.test(theme.id))return 'orbit';
 if(/solar/.test(theme.id))return 'rays';
 if(/clock|ingran|kingi/.test(text))return 'clock';
 if(/spirit|anime/.test(text))return 'souls';
 if(/blood|sangue|essenza/.test(text))return 'blood';
 if(/sogno|aurora/.test(text))return 'clouds';
 if(/briar|thorn|root|radic/.test(text))return 'roots';
 if(/vervain|meadow|petalo|bloom/.test(text))return 'petals';
 if(/storm|elettric/.test(text))return 'lightning';
 if(/slime|ampoll/.test(text))return 'bubbles';
 return {wood:'dust',bark:'leaves',stone:'dust',metal:'glint',charred:'sparks',ash:'ash',dream:'clouds',spirit:'souls',astral:'stars',crystal:'prism',water:'waves',ivory:'halo',acid:'acid'}[material];
}
function elementMotif(spec) {
 const source=fs.readFileSync(path.join(root,`design/themes/${spec.id}/relic.svg`),'utf8');
 return source.slice(source.indexOf('>',source.indexOf('<g'))+1,source.lastIndexOf('</g>'));
}
const specs=[...bible.map(t=>({...t,material:family(t),motif:motifs[t.id]})),...elements.map(t=>({...t,formsAndMaterials:t.name,motif:elementMotif(t)})),
 {id:'canva_ice',name:'Ghiaccio · Canva',material:'crystal',formsAndMaterials:'Ghiaccio scolpito e cristalli sospesi',motion:'prism',motif:P('M16 0v32M0 16h32M4 4l24 24M4 28L28 4M10 1l6 6 6-6M1 10l6 6-6 6M31 10l-6 6 6 6')},
 {id:'canva_spirit',name:'Spirituale · Canva',material:'spirit',formsAndMaterials:'Alabastro e filamenti d’anime',motion:'souls',motif:motifs.restyle_spiritualita+P('M0 7q4-7 8 0M24 7q4-7 8 0')},
 {id:'canva_physical',name:'Fisico · Canva',material:'metal',formsAndMaterials:'Acciaio martellato e cuoio da battaglia',motion:'glint',motif:P('M4 1l25 25-4 5L1 6ZM31 1L6 26l-5-4L26 0M0 26l6 6M26 26l6-6')}
];
// Celestial enemies: silver lunar metal and burning solar bronze never share
// a material palette, a crest or a motion vocabulary.
for(const spec of specs){
 if(/moon|lunar/.test(spec.id))spec.material='astral';
 if(/solar/.test(spec.id))spec.material='charred';
 if(spec.id==='classic_low_detail')spec.motion='none';
}
const creativeSources={
 canva_ice:'canva-20261016/ice-frame.png',
 canva_spirit:'canva-20261016/spirit-frame.png',
 canva_physical:'canva-20261016/physical-frame.png',
 restyle_legno:'canva-20261017/wood-frame.png',
 buried_herbarium:'canva-20261017/wood-frame.png',
 element_pack_radice:'canva-20261017/wood-frame.png',
 restyle_cenere:'canva-20261017/ash-frame.png',
 ash_oracle:'canva-20261017/ash-frame.png',
 element_pack_cenere:'canva-20261017/ash-frame.png',
 restyle_sogno:'canva-20261017/dream-frame.png',
 element_pack_sogno:'canva-20261017/dream-frame.png',
 element_pack_fuoco:'canva-20261017/adobe-fire-frame.png',
 element_pack_lava:'canva-20261017/adobe-fire-frame.png',
 ember_rite:'canva-20261017/adobe-fire-frame.png',
};
function outline(material,w,h) {
 if(['metal','stone','crystal'].includes(material))return `M34 10H${w-34}l24 24V${h-34}l-24 24H34L10 ${h-34}V34Z`;
 if(['wood','bark','charred','ash'].includes(material))return `M34 9Q${w*.25} 17 ${w*.5} 9T${w-34} 9Q${w-5} 6 ${w-9} 34L${w-12} ${h-34}Q${w-4} ${h-7} ${w-34} ${h-10}H34Q7 ${h-4} 10 ${h-34}L9 34Q5 8 34 9Z`;
 return `M34 10H${w-34}Q${w-10} 10 ${w-10} 34V${h-34}Q${w-10} ${h-10} ${w-34} ${h-10}H34Q10 ${h-10} 10 ${h-34}V34Q10 10 34 10Z`;
}
function svg(spec,state) {
 const w=1024,h=512,[dark,light]=palettes[spec.material], d=outline(spec.material,w,h);
 const disabled=state==='disabled', selected=state==='selected', hover=state==='hover', pressed=state==='pressed';
 const crest=selected?30:26, opacity=disabled?.25:pressed?.6:hover?1:.84;
 const paths=[];
 const line=(d,width=1,alpha=.8)=>paths.push(`<path d="${d}" fill="none" stroke="${light}" stroke-width="${width}" opacity="${alpha}"/>`);
 // Deep material rails: only the margin is painted, never the reading center.
 paths.push(`<path d="${d}" fill="none" stroke="${dark}" stroke-width="18"/><path d="${d}" fill="none" stroke="${light}" stroke-width="1.2"/>`);
 for(const y of [10,h-10]) {
  if(['wood','bark'].includes(spec.material))for(let n=0;n<5;n++)line(`M42 ${y-6+n*2.5}Q${w*.3} ${y-12+n*2.5} ${w*.5} ${y-4+n*2.5}T${w-42} ${y-6+n*2.5}`,n%2?.65:1,n%2?.3:.65);
  else if(['ash','stone','charred'].includes(spec.material))for(let x=48;x<w-40;x+=23)line(`M${x} ${y-6}l6 7-4 6m5-6 9-3`,spec.material==='ash'?1.8:.7,.42);
  else if(spec.material==='metal')for(let x=48;x<w-40;x+=42)paths.push(`<circle cx="${x}" cy="${y}" r="3" fill="${dark}" stroke="${light}" stroke-width=".9"/>`);
  else if(spec.material==='crystal')for(let x=48;x<w-40;x+=31)paths.push(`<path d="M${x} ${y-7}l13 3-3 13-13-3Z" fill="${light}" fill-opacity=".23" stroke="${light}" stroke-opacity=".7"/>`);
  else for(let n=0;n<3;n++)line(`M40 ${y-4+n*4}Q${w*.25} ${y-14+n*4} ${w*.5} ${y-4+n*4}T${w-40} ${y-4+n*4}`,.8,.4);
 }
 for(const [x,y,angle] of [[32,32,0],[w-32,32,90],[w-32,h-32,180],[32,h-32,270]]) {
  paths.push(`<g transform="translate(${x} ${y}) rotate(${angle})"><path d="M-22 46v-48q0-20 20-20h48" fill="none" stroke="${dark}" stroke-width="8"/><path d="M-22 46v-48q0-20 20-20h48" fill="none" stroke="${light}" stroke-width="1"/><g transform="translate(-16 -16)" fill="${dark}" stroke="${light}" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">${spec.motif}</g></g>`);
 }
 // A central emblem belongs to the rail, with empty space below it.
 for(const [x,y,sy] of [[w/2,13,1],[w/2,h-13,-1]])paths.push(`<g transform="translate(${x-crest/2} ${y-crest/2*sy}) scale(${crest/32} ${sy*crest/32})" fill="${dark}" stroke="${light}" stroke-width="1.1" stroke-linejoin="round">${spec.motif}</g>`);
 if(selected)line(`M80 3H${w-80}M80 ${h-3}H${w-80}`,1.5,.9);
 if(pressed)line(`M42 19H${w-42}M19 42V${h-42}`,1.5,.5);
 return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}"><g opacity="${opacity}">${paths.join('')}</g></svg>`;
}
async function run(){
 const output=[], shapes=new Set();
 for(const spec of specs){
  if(!spec.motif)throw Error(`Missing authored identity: ${spec.id}`);
  const sourceDir=path.join(root,'design/themes',spec.id), target=path.join(root,'assets/themes',spec.id,'frames');
  fs.mkdirSync(target,{recursive:true});fs.mkdirSync(sourceDir,{recursive:true});
  const material=path.join(root,'assets/themes/materials',`${spec.material}.png`);
  const creativeSource=creativeSources[spec.id];
  const creativePath=creativeSource && path.join(root,'design/materials',creativeSource);
  // This UI export mask reserves the label area for every source, including
  // sources whose inner aperture is dark. Source artwork is kept unchanged.
  const safeMask=Buffer.from('<svg width="1024" height="512"><path fill="white" fill-rule="evenodd" d="M0 0H1024V512H0Z M64 48H960V464H64Z"/></svg>');
  const retained=creativePath && fs.existsSync(creativePath)
    ? await sharp(creativePath).resize(1024,512,{fit:'fill'}).png().toBuffer():null;
  for(const state of ['normal','hover','pressed','selected','disabled']){
   const source=svg(spec,state);fs.writeFileSync(path.join(sourceDir,`identity-${state}.svg`),source);
   const assembly=retained
     ? sharp(retained).modulate({brightness:state==='disabled'?.4:state==='pressed'?.72:state==='hover'?1.15:1}).composite([{input:Buffer.from(source)},{input:safeMask,blend:'dest-in'}])
     : sharp(Buffer.from(source));
   const bytes=await assembly.png({palette:true,colours:192,dither:.3}).toBuffer();
   fs.writeFileSync(path.join(target,`identity-${state}.png`),bytes);
   if(state==='normal'){
    const alpha=await sharp(bytes).extractChannel(3).raw().toBuffer();
    const hash=crypto.createHash('sha256').update(alpha).digest('hex');
    if(shapes.has(hash))throw Error(`Repeated frame shape: ${spec.id}`);shapes.add(hash);
   }
  }
  // Engraving is native vector artwork over a retained, local material source.
  const glyph=`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><g stroke="${palettes[spec.material][1]}" stroke-opacity=".22" stroke-width=".6" fill="none">${[0,1,2].map(y=>[0,1,2].map(x=>`<g transform="translate(${x*96-16} ${y*96-16}) scale(1.25)">${spec.motif}</g>`).join('')).join('')}</g></svg>`;
  fs.writeFileSync(path.join(sourceDir,'identity-surface.svg'),glyph);
  await sharp(material).resize(256,256).composite([{input:Buffer.from(glyph)}]).png({palette:true,colours:192,dither:.3}).toFile(path.join(target,'identity-surface.png'));
  output.push({id:spec.id,name:spec.name,material:spec.material,motif:spec.formsAndMaterials,motion:spec.id==='classic_low_detail'?'none':spec.id.startsWith('element_pack_')?spec.motion:motion(spec,spec.material),source:retained?creativeSource:'Authored SVG relief plus retained material',safeBand:48,opposition:/moon|lunar/.test(spec.id)?'sun':/solar/.test(spec.id)?'moon':null});
  console.log(`Identity: ${spec.id}`);
 }
 fs.writeFileSync(path.join(root,'docs/design/theme-identities.json'),JSON.stringify(output,null,2)+'\n');
 const q=s=>JSON.stringify(s);
 const entries=output.map(t=>`  ${q(t.id)}: OculumThemeIdentity(${q(t.id)}, ${q(t.material)}, ${q(t.motion)}, ${q(t.motif)}),`).join('\n');
 fs.writeFileSync(path.join(root,'lib/widgets/oculum_theme_identity.dart'),`// Generated by scripts/build_theme_identities.cjs.\nclass OculumThemeIdentity {\n  const OculumThemeIdentity(this.id, this.material, this.motion, this.motif);\n  final String id, material, motion, motif;\n  String get surface => 'assets/themes/$id/frames/identity-surface.png';\n  String frame(String state) => 'assets/themes/$id/frames/identity-$state.png';\n}\nconst oculumThemeIdentities = <String, OculumThemeIdentity>{\n${entries}\n};\n`);
 const all=read('design/theme-art-manifest.json').filter(x=>!x.role.startsWith('identity-'));
 for(const spec of specs)for(const file of fs.readdirSync(path.join(root,'assets/themes',spec.id,'frames')).filter(x=>x.startsWith('identity-'))){
  const relative=`assets/themes/${spec.id}/frames/${file}`,bytes=fs.readFileSync(path.join(root,relative));
  all.push({theme:spec.id,role:file.replace('.png',''),path:relative,bytes:bytes.length,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
 }
 fs.writeFileSync(path.join(root,'design/theme-art-manifest.json'),JSON.stringify(all,null,2)+'\n');
 console.log(`Verified ${specs.length} identities, ${shapes.size} unique alpha silhouettes.`);
}
run().catch(error=>{console.error(error);process.exitCode=1;});
