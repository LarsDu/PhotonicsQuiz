import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const {chromium} = await import(process.argv[3] || 'playwright');
const base = process.argv[2] || 'http://127.0.0.1:8080';
const content = JSON.parse(readFileSync('assets/curriculum.json','utf8'));
const browser = await chromium.launch({headless:true, channel:'chromium', ...(process.env.LUMEN_CHROME_PATH ? {executablePath:process.env.LUMEN_CHROME_PATH} : {})});
const context = await browser.newContext({viewport:{width:390,height:844},deviceScaleFactor:1});
const page = await context.newPage();
const errors=[];
const external=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('request',r=>{if(new URL(r.url()).origin!==new URL(base).origin)external.push(r.url());});
async function ready() {
  await page.waitForSelector('flutter-view');
  const placeholder=page.locator('flt-semantics-placeholder');
  if(await placeholder.count()) await placeholder.evaluate(el=>el.click());
  await page.getByRole('button',{name:'Progress and backups'}).waitFor();
}
async function saved() { return page.evaluate(()=>JSON.parse(JSON.parse(localStorage.getItem('lumen.study.v1')))); }
try {
 await page.goto(base);await ready();
 await page.screenshot({path:'docs/mobile-preview.png'});
 await page.getByRole('tab',{name:'Topics',exact:true}).click();
 await page.getByRole('textbox').fill('germanium');
 await page.getByRole('button',{name:/Study Detectors & receivers/}).waitFor();
 await page.getByRole('tab',{name:'Review',exact:true}).click();
 await page.getByRole('tab',{name:'Explore',exact:true}).click();
 await page.getByRole('button',{name:'Company source',exact:true}).first().waitFor();
 await page.getByRole('checkbox',{name:'Courses',exact:true}).click();
 await page.getByRole('button',{name:'Open resource',exact:true}).first().waitFor();
 await page.getByRole('checkbox',{name:'My roadmap',exact:true}).click();
 await page.getByRole('tab',{name:'Today',exact:true}).click();
 await page.getByRole('button',{name:'Start a study session',exact:true}).click();
 await page.getByRole('button',{name:'Save and close session',exact:true}).waitFor();
 await page.getByRole('button',{name:'Save and close session',exact:true}).click();
 const ids=['waveguides-12','platforms-17','platforms-07','platforms-03','platforms-02','platforms-01'];
 const seeded={version:1,records:{},bookmarks:[],projects:[],daily:{},active:{ids,index:0,title:'Browser check',good:0}};
 await page.evaluate(j=>localStorage.setItem('lumen.study.v1',JSON.stringify(JSON.stringify(j))),seeded);
 await page.reload();await ready();
 await page.evaluate(async()=>{await navigator.serviceWorker.ready;});
 await page.waitForFunction(()=>!!navigator.serviceWorker.controller);
 await context.setOffline(true);
 await page.reload();await ready();
 await page.getByRole('button',{name:'Resume session',exact:true}).click();
 for(const [i,id] of ids.entries()) {
   const q=content.questions.find(q=>q.id===id);
   await page.getByRole('heading',{name:q.prompt,exact:true}).waitFor();
   if(i===0){await page.getByRole('button',{name:'Bookmark question',exact:true}).click();await page.screenshot({path:'docs/question-preview.png'});}
   if(q.kind==='recall') {
     await page.getByRole('button',{name:'Reveal answer',exact:true}).click();
     await page.getByRole('button',{name:'Got it',exact:true}).click();
   }else{
     for(const answer of q.answers) await page.getByRole('button',{name:answer,exact:true}).click();
     await page.getByRole('button',{name:'Check answer',exact:true}).click();
   }
   await page.getByRole('button',{name:i===ids.length-1?'Finish session':'Next question',exact:true}).click();
 }
 await page.getByRole('button',{name:'Back to my study',exact:true}).click();
 await page.waitForFunction(()=>JSON.parse(JSON.parse(localStorage.getItem('lumen.study.v1'))).active===null);
 const progress=await saved();
 assert.equal(Object.keys(progress.records).length,6);
 assert.deepEqual(progress.bookmarks,['waveguides-12']);
 for(const r of Object.values(progress.records)){assert.equal(r.attempts,1);assert.equal(r.correct,1);}
 await page.reload();await ready();
 assert.equal(Object.keys((await saved()).records).length,6);
 await context.setOffline(false);
 await page.setViewportSize({width:1280,height:900});
 await page.waitForTimeout(300);
 await page.screenshot({path:'docs/desktop-preview.png'});
 assert.deepEqual(errors,[]);
 assert.deepEqual(external,[], 'Study should use bundled assets, including renderer and scientific fonts');
 console.log('Browser checks passed: mobile navigation/search/resources, six formats, offline reload, persistence, bookmark, and desktop rendering.');
} finally { await browser.close(); }
