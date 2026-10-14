// Optimize retained raster material sources for local Flutter use.
const fs = require('fs');
const path = require('path');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'design/materials');
const target = path.join(root, 'assets/themes/materials');
async function run() {
  fs.mkdirSync(target, {recursive:true});
  const acidSource = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512"><defs><linearGradient id="glass" x2="1" y2="1"><stop stop-color="#16221b"/><stop offset=".45" stop-color="#40513b"/><stop offset=".72" stop-color="#1c2b21"/><stop offset="1" stop-color="#101813"/></linearGradient><pattern id="cells" width="46" height="42" patternUnits="userSpaceOnUse"><path d="M4 8Q14 2 23 9T42 7M0 30Q12 22 21 30T46 28" fill="none" stroke="#a8c65c" stroke-opacity=".22" stroke-width="2"/><path d="M9 7l4 9m23 11 4 8" stroke="#e5f2bd" stroke-opacity=".3" stroke-width="1.5"/><circle cx="20" cy="20" r="2" fill="#c9e879" fill-opacity=".36"/></pattern><radialGradient id="sheen"><stop stop-color="#cae985" stop-opacity=".2"/><stop offset="1" stop-color="#171c18" stop-opacity="0"/></radialGradient></defs><rect width="512" height="512" fill="url(#glass)"/><rect width="512" height="512" fill="url(#cells)"/><rect width="512" height="512" fill="url(#sheen)"/><path d="M42 0Q78 96 55 155T59 294M463 57Q414 133 447 210T424 512" fill="none" stroke="#c8e678" stroke-opacity=".16" stroke-width="8"/><path d="M46 22Q77 89 58 153m386-53q-21 63 0 116" fill="none" stroke="#f0f8d2" stroke-opacity=".23" stroke-width="2"/></svg>`);
  await sharp(acidSource).png({compressionLevel:9}).toFile(path.join(source,'acid-source.png'));
  const spiritSource = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512"><defs><radialGradient id="mist"><stop stop-color="#f1f2f6" stop-opacity=".22"/><stop offset="1" stop-color="#1a1c22" stop-opacity="0"/></radialGradient><pattern id="veil" width="64" height="64" patternUnits="userSpaceOnUse"><path d="M-8 20Q8 2 24 20T56 20T88 20M-8 52Q8 34 24 52T56 52T88 52" fill="none" stroke="#e8ebf1" stroke-opacity=".12" stroke-width="2"/><circle cx="16" cy="14" r="2" fill="#fff" fill-opacity=".3"/><circle cx="48" cy="44" r="1.5" fill="#fff" fill-opacity=".2"/></pattern></defs><rect width="512" height="512" fill="#17191f"/><rect width="512" height="512" fill="url(#veil)"/><rect width="512" height="512" fill="url(#mist)"/><path d="M44 0Q72 72 53 143T58 284M466 68Q432 126 451 204T426 512" fill="none" stroke="#e7eaf0" stroke-opacity=".19" stroke-width="5"/></svg>`);
  await sharp(spiritSource).png({compressionLevel:9}).toFile(path.join(source,'spirit-source.png'));
  for (const name of ['wood','ash','acid','spirit']) {
    await sharp(path.join(source,`${name}-source.png`)).resize(512,512).png({compressionLevel:9}).toFile(path.join(target,`${name}.png`));
  }
  const atlas = path.join(source,'material-atlas.png');
  if (fs.existsSync(atlas)) {
    const meta = await sharp(atlas).metadata();
    const tile = Math.floor(Math.min(meta.width,meta.height)/3);
    const names=['stone','metal','crystal','astral','water','charred','bark','ivory','dream'];
    for (let i=0;i<names.length;i++) {
      await sharp(atlas).extract({left:(i%3)*tile,top:Math.floor(i/3)*tile,width:tile,height:tile}).resize(512,512).png({compressionLevel:9}).toFile(path.join(target,`${names[i]}.png`));
    }
  }
  const overlay=path.join(root,'assets/themes/restyle_legno/overlays');
  fs.mkdirSync(overlay,{recursive:true});
  const mask=Buffer.from('<svg width="256" height="256"><path d="M46 48Q128 26 210 48L204 211Q128 224 52 211Z" fill="white"/></svg>');
  const wood=await sharp(path.join(target,'wood.png')).resize(256,256).composite([{input:mask,blend:'dest-in'}]).png().toBuffer();
  const carving=Buffer.from('<svg width="256" height="256"><g fill="none" stroke="#dab77a" stroke-width="3"><path d="M54 54Q128 34 202 54L196 205Q128 216 60 205Z"/><path d="M72 82Q128 62 184 82M68 170Q128 193 188 170M82 122Q128 98 174 122Q128 149 82 122Z"/><ellipse cx="128" cy="123" rx="12" ry="20"/></g></svg>');
  await sharp(wood).composite([{input:carving}]).png({compressionLevel:9}).toFile(path.join(overlay,'relic.png'));
  console.log('Local material textures and carved wood signature created.');
}
run().catch(e=>{console.error(e);process.exitCode=1;});
