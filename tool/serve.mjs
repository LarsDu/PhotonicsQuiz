import {createServer} from 'node:http';
import {readFile,stat} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
const root=resolve('build/web');
const port=Number(process.argv[2]||8080), host=process.argv[3]||'127.0.0.1';
const mount=process.argv[4]||'/';
if(!mount.startsWith('/')||!mount.endsWith('/'))throw new Error('Preview base path must start and end with /');
const types={'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.png':'image/png','.ttf':'font/ttf','.otf':'font/otf','.svg':'image/svg+xml'};
createServer(async(req,res)=>{
 try {
  const path=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
  if(mount!=='/'&&path===mount.slice(0,-1)){res.writeHead(302,{'Location':mount}).end();return;}
  if(!path.startsWith(mount)){res.writeHead(404).end('Not found');return;}
  let file=resolve(root,path.slice(mount.length));
  if(file!==root&&!file.startsWith(root+sep)){res.writeHead(403).end();return;}
  if((await stat(file)).isDirectory())file=resolve(file,'index.html');
  const data=await readFile(file);
  res.writeHead(200,{'Content-Type':types[extname(file)]||'application/octet-stream','Cache-Control':'no-cache'});
  res.end(data);
 }catch{res.writeHead(404).end('Not found');}
}).listen(port,host,()=>console.log(`Lumen preview: http://${host}:${port}${mount}`));
