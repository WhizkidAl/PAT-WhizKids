const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
const root=path.resolve(__dirname,'..'),now=new Date(),version=process.argv[2]||now.toISOString().slice(0,10)+'.'+now.toISOString().slice(11,19).replaceAll(':','');
if(!/^\d{4}-\d{2}-\d{2}\.\d+$/.test(version))throw Error('Expected YYYY-MM-DD.number');
for(const name of ['portable-practice-cloud.js','portable-practice.html','portable-practice-sw.js']){
 const file=path.join(root,name);let s=fs.readFileSync(file,'utf8');
 if(name.endsWith('cloud.js'))s=s.replace(/const PAT_BUILD='[^']+'/,`const PAT_BUILD='${version}'`);
 if(name.endsWith('.html'))s=s.replace(/(portable-practice-(?:cloud|updates)\.js\?release=)[^"]+/g,'$1'+version);
 if(name.endsWith('-sw.js'))s=s.replace(/const CACHE='[^']+'/,`const CACHE='pats-auto-shell-${version}'`);
 fs.writeFileSync(file,s);
}
const names=['portable-practice-cloud.js','portable-practice-app.html','portable-practice-updates.js'];
fs.writeFileSync(path.join(root,'portable-practice-release.json'),JSON.stringify({version,sha256:Object.fromEntries(names.map(n=>[n,crypto.createHash('sha256').update(fs.readFileSync(path.join(root,n))).digest('hex')]))},null,2)+'\n');
console.log('Prepared atomic app release '+version);
