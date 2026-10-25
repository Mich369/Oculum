// Format export only. Every generated PNG remains untouched in its source path.
const fs = require('fs');
const path = require('path');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const sourceDir = path.join(root, 'assets', 'oculum', 'theme_stories');
const outputDir = path.join(sourceDir, 'webp');
(async () => {
  fs.mkdirSync(outputDir, {recursive: true});
  let originalBytes = 0, finalBytes = 0, count = 0;
  for (const name of fs.readdirSync(sourceDir).filter(n => n.endsWith('.png'))) {
    const source = path.resolve(sourceDir, name);
    const destination = path.join(outputDir, name.replace(/\.png$/, '.webp'));
    if (fs.existsSync(destination) && fs.statSync(destination).mtimeMs >= fs.statSync(source).mtimeMs) continue;
    const input = fs.readFileSync(source);
    const before = await sharp(input).metadata();
    const output = await sharp(input).webp({quality: 91, effort: 5}).toBuffer();
    const after = await sharp(output).metadata();
    if (after.width !== before.width || after.height !== before.height || after.format !== 'webp') {
      throw Error('Invalid export: ' + name);
    }
    fs.writeFileSync(destination, output);
    originalBytes += input.length; finalBytes += output.length; count++;
  }
  console.log(JSON.stringify({count, originalBytes, finalBytes}));
})().catch(error => {console.error(error.message); process.exitCode = 1;});
