// Reproducible Senka UI identity: authored vector motifs over retained material.
// Generates six NEW assets only; never rewrites existing themes or gameplay.
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');
const sharpPath = process.argv[2] || 'sharp';
const sharp = require(sharpPath);
const root = path.resolve(__dirname, '..');
const base = fs.readFileSync(path.join(root, 'scripts/build_theme_identities.cjs'), 'utf8');
const renderer = { exports: {}, require, __dirname, process: { argv: ['', '', sharpPath] } };
vm.runInNewContext(base.slice(0, base.indexOf('async function run()')) + '\nexports.svg=svg;', renderer);
const mask = '<path d="M8 3Q16 0 24 3L26 17Q24 28 16 32Q8 28 6 17Z"/>' +
  '<path d="M8 13Q12 8 15 13Q12 18 8 13ZM17 13Q21 8 24 13Q21 18 17 13Z"/>' +
  '<circle cx="11.5" cy="13" r="4.5"/><circle cx="20.5" cy="13" r="4.5"/>' +
  '<path d="M5 4Q-3 15 3 26M27 4Q35 15 29 26M12 21Q16 24 20 21"/>';
const crescent = '<path d="M24 2C1 3-2 27 22 29C7 21 8 8 24 2Z"/>';
const spec = { id: 'senka_kamaria', material: 'astral', motif: mask + crescent,
  formsAndMaterials: 'Maschera nera a due fori/circoli, filamenti d’ombra, spicchio lunare buono' };
const out = path.join(root, 'assets/themes/moon_iron/frames');
const sources = path.join(root, 'design/themes/senka_kamaria');
fs.mkdirSync(sources, {recursive: true});
async function run() {
 const manifest = [];
 for (const state of ['normal','hover','pressed','selected','disabled']) {
  const svg = renderer.exports.svg(spec,state);
  const filename = 'senka-identity-' + state + '.png';
  const target = path.join(out,filename);
  if (fs.existsSync(target)) throw Error('Versioned identity already exists: ' + target);
  fs.writeFileSync(path.join(sources,'identity-' + state + '.svg'),svg);
  const bytes = await sharp(Buffer.from(svg)).png({palette:true,colours:192,dither:.3}).toBuffer();
  fs.writeFileSync(target,bytes);
  manifest.push({state,asset:path.relative(root,target).split(path.sep).join('/'),sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
 }
 const surfaceSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><g stroke="#bdb2df" stroke-opacity=".22" stroke-width=".6" fill="none">' +
  [0,1,2].map(y=>[0,1,2].map(x=>'<g transform="translate(' + (x*96-16) + ' ' + (y*96-16) + ') scale(1.25)">' + spec.motif + '</g>').join('')).join('') + '</g></svg>';
 fs.writeFileSync(path.join(sources,'identity-surface.svg'),surfaceSvg);
 const target = path.join(out,'senka-identity-surface.png');
 if (fs.existsSync(target)) throw Error('Versioned surface already exists');
 await sharp(path.join(root,'assets/themes/materials/astral.png')).resize(256,256)
  .composite([{input:Buffer.from(surfaceSvg)}]).png({palette:true,colours:192,dither:.3}).toFile(target);
 const bytes = fs.readFileSync(target);
 manifest.push({state:'surface',asset:path.relative(root,target).split(path.sep).join('/'),sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
 fs.writeFileSync(path.join(root,'docs/ART_SENKA_UI_IDENTITY_2026-10-28.json'),JSON.stringify({
  date:'2026-10-28',kind:'code-native authored SVG UI identity',sourceRenderer:'scripts/build_theme_identities.cjs (bounded reuse of SVG renderer only)',
  motif:spec.formsAndMaterials,material:'astral',readingCenter:'transparent, same safe UI rail as existing theme',
  existingAssetsOverwritten:false,gameplayChanged:false,assets:manifest
 },null,2)+'\n');
 console.log('Generated six unique Senka identity assets only.');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
