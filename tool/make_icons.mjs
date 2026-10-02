import {readFileSync, readdirSync, writeFileSync} from 'node:fs';
const {default: sharp} = await import(process.argv[2] || 'sharp');
const svg = readFileSync('assets/branding/lumen.svg','utf8');
const jobs = [['web/favicon.png',32],['web/icons/Icon-192.png',192],['web/icons/Icon-512.png',512],['web/icons/Icon-maskable-192.png',192],['web/icons/Icon-maskable-512.png',512]];
for (const [density,size] of Object.entries({mdpi:48,hdpi:72,xhdpi:96,xxhdpi:144,xxxhdpi:192})) jobs.push([`android/app/src/main/res/mipmap-${density}/ic_launcher.png`,size]);
const dir='ios/Runner/Assets.xcassets/AppIcon.appiconset';
for(const file of readdirSync(dir).filter(file=>file.endsWith('.png'))){const match=file.match(/-([\d.]+)x[\d.]+@(\d+)x/);jobs.push([`${dir}/${file}`,Number(match[1])*Number(match[2])]);}
for (const [path,size] of jobs) {
 writeFileSync(path, await sharp(Buffer.from(svg)).resize(size,size).flatten({background:'#182d35'}).png().toBuffer());
}
console.log(`Rendered ${jobs.length} app icons from the original SVG.`);
