#!/usr/bin/env node
// Agent Web 0.1: offline, read-only static ASH extractor; not an ASH compiler.
import fs from "node:fs";
import path from "node:path";
function esc(x){return String(x).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#39;");}

function parseAsh(text,slug,number){
 const masked=text.replace(/\/\*[\s\S]*?\*\/|\/\/[^\n]*|"(?:\\.|[^"\\])*"/g,m=>m.replace(/[^\n]/g," "));
 const decl=/\b(void|boolean|int|float|string|item|location|familiar|buffer|monster|effect|slot|skill|stat|element|matcher)\s+([A-Za-z_]\w*)\s*\([^;{}]*\)\s*\{/g;
 const out=[]; let depth=0,cursor=0,m;
 while((m=decl.exec(masked))!==null){
   for(let p=cursor;p<m.index;p++){if(masked[p]==="{")depth++;else if(masked[p]==="}")depth--;}
   cursor=m.index;
   if(depth!==0)continue;
   const open=m.index+m[0].lastIndexOf("{");let end=open+1,n=1;
   while(end<masked.length&&n>0){if(masked[end]==="{")n++;if(masked[end]==="}")n--;end++;}
   if(n!==0)break;
   const idx=out.length+1,code=text.slice(m.index,end);
   const calls=[...new Set([...masked.slice(open+1,end-1).matchAll(/\b([A-Za-z_]\w*)\s*\(/g)].map(x=>x[1]).filter(x=>!["if","for","while","foreach","switch","return"].includes(x)))];
   const sig=text.slice(m.index,open).replace(/\s+/g," ").trim();
   const keywords=[...new Set((m[2].replace(/([a-z])([A-Z])/g,"$1 $2")+" "+sig+" "+calls.join(" ")).toLowerCase().replace(/[^a-z0-9_ ]/g," ").split(/[\s_]+/).filter(x=>x.length>2))].slice(0,32);
   out.push({id:number+"."+idx,script:slug,name:m[2],signature:sig,code,line_start:text.slice(0,m.index).split("\n").length,line_end:text.slice(0,end).split("\n").length,keywords,calls});
   decl.lastIndex=end;cursor=end;depth=0;
 }
 return out;
}

function graphFor(custom,master){
 const scripts=[{slug:"don_custom_functions",number:11,path:"scripts/don_custom_functions.ash",functions:parseAsh(custom,"don_custom_functions",11)},{slug:"don_master_lib",number:12,path:"don-master-ash-lib/scripts/don_master_lib.ash",functions:parseAsh(master,"don_master_lib",12)}];
 const all=scripts.flatMap(s=>s.functions), byName=new Map();
 for(const fn of all){const list=byName.get(fn.name)||[];list.push(fn);byName.set(fn.name,list);}
 const edges=[];
 for(const fn of all){
   for(const name of fn.calls){
     const choices=byName.get(name)||[],same=choices.filter(v=>v.script===fn.script),targets=same.length?same:choices;
     for(const to of targets){
       const cross=to.script!==fn.script;
       edges.push({from:fn.id,to:to.id,kind:"call",state:"strong",position:"frame",capability:cross?"bridge_thread":"bearing_guy",filament:"agent_filament_strong_frame_"+(cross?"bridge_thread":"bearing_guy"),cross_ladder:cross});
     }
   }
 }
 edges.push({from:"11",to:"12",kind:"import",state:"strong",position:"anchor",capability:"attachment_bond",filament:"agent_filament_strong_anchor_attachment_bond",cross_ladder:true});
 const ladder_metrics=scripts.map(s=>{
   const outgoing=edges.filter(e=>e.kind==="call"&&e.from.startsWith(s.number+"."));
   const ropes=outgoing.filter(e=>e.cross_ladder);
   const pct=outgoing.length?Math.round(10000*ropes.length/outgoing.length)/100:0;
   return {script:s.slug,resolved_outgoing:outgoing.length,cross_ladder_outgoing:ropes.length,percent:pct,tier:pct<25?"sparse":pct<35?"agent-web-weak":pct<50?"agent-web-medium":pct<75?"agent-web-strong":"agent-web-review-for-merge"};
 });
 return {schema:"agent-web/0.1",scripts,edges,ladder_metrics,embeddings:"not_computed",evidence:"lexical static call scan; no runtime proof"};
}

function htmlPage(title,body){
 const css="body{max-width:1050px;margin:20px auto;padding:18px;font:15px/1.5 system-ui;color:#000;background:#fcfcff}header{background:#abd1f3;border:2px solid black;padding:15px}article{padding:14px;border:1px solid #444;background:white;margin:12px 0;overflow-wrap:anywhere}article:target{outline:3px solid #4a94c6}a{color:#14537a}code,pre{font-family:monospace}pre{padding:12px;background:#dff7fa;white-space:pre-wrap;overflow-wrap:anywhere;max-height:600px;overflow:auto}input{box-sizing:border-box;width:100%;padding:10px;border:2px solid #000}details{padding:5px}small{color:#444}";
 return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+esc(title)+'</title><style>'+css+'</style></head><body><header><h1>'+esc(title)+'</h1><p>Agent Web v0.1 — read-only static source index, no model embeddings or executable functions</p></header>'+body+'</body></html>\n';
}

function buildAgentWeb(custom,master){
 const graph=graphFor(custom,master),all=graph.scripts.flatMap(s=>s.functions),byId=new Map(all.map(f=>[f.id,f])),pages={};
 for(const script of graph.scripts){
   const slug=script.slug,metric=graph.ladder_metrics.find(x=>x.script===slug);
   const entries=script.functions.map(f=>{
     const key=f.id.replace(".","-"),anchor="fn-"+key,actual="actual-"+key,idx="index-"+key;
     const references=graph.edges.filter(e=>e.from===f.id).map(e=>{
       const to=byId.get(e.to);
       return to?'<a href="'+(to.script===slug?"#fn-"+to.id.replace(".","-"):to.script+"_micro_agent.html#fn-"+to.id.replace(".","-"))+'">'+esc(to.name)+'</a> <small>('+esc(e.filament)+')</small>':"";
     }).join(" · ")||"No resolved project calls";
     const prefix='<h2>'+esc(f.name)+' <small>['+f.id+']</small></h2><p><code>'+esc(f.signature)+'</code></p><p>'+esc(script.path)+':'+f.line_start+'–'+f.line_end+'</p>';
     const index='<article id="'+idx+'">'+prefix+'<p>function_index'+f.id+'.1 · <a href="../'+slug+'_micro_agent.html#'+anchor+'">micro</a> · <a href="../agent_web_actual/'+slug+'.html5#'+actual+'">actual</a></p><p>Keywords: '+esc(f.keywords.join(", "))+'</p></article>';
     const body='<article id="'+actual+'">'+prefix+'<p>function_actual'+f.id+'.2</p><pre><code>'+esc(f.code)+'</code></pre></article>';
     const search=esc((f.name+" "+f.signature+" "+f.keywords.join(" ")+" "+references.replace(/<[^>]+>/g," ")).toLowerCase());
     const micro='<article class="entry" id="'+anchor+'" data-search="'+search+'">'+prefix+'<p><a href="agent_web_index/'+slug+'.html5#'+idx+'">function_index'+f.id+'.1</a> · <a href="agent_web_actual/'+slug+'.html5#'+actual+'">function_actual'+f.id+'.2</a></p><p><strong>Keywords:</strong> '+esc(f.keywords.join(", "))+'</p><p><strong>Filaments:</strong> '+references+'</p><details><summary>Actual ASH source (read only)</summary><pre><code>'+esc(f.code)+'</code></pre></details></article>';
     return {index,body,micro};
   });
   pages["agent_web_index/"+slug+".html5"]=htmlPage(slug+" · index",entries.map(x=>x.index).join("\n"));
   pages["agent_web_actual/"+slug+".html5"]=htmlPage(slug+" · actual",entries.map(x=>x.body).join("\n"));
   const scriptFilter='const q=document.getElementById("search"),items=[...document.querySelectorAll(".entry")],counter=document.getElementById("count");q.addEventListener("input",()=>{const tokens=q.value.toLowerCase().trim().split(/\\s+/).filter(Boolean);let count=0;for(const item of items){const visible=tokens.every(t=>item.dataset.search.includes(t));item.hidden=!visible;if(visible)count++;}counter.textContent=count+" matching functions";});';
   const top='<p>'+script.functions.length+' function definitions, '+metric.cross_ladder_outgoing+'/'+metric.resolved_outgoing+' resolved outgoing calls crossing ladders ('+metric.percent+'%, '+metric.tier+'). Static lexical estimate; import link not included in percentage.</p><p><a href="agent_web_index/'+slug+'.html5">Index</a> · <a href="agent_web_actual/'+slug+'.html5">Actual</a> · <a href="'+(slug==="don_custom_functions"?"don_master_lib":"don_custom_functions")+'_micro_agent.html">Other ladder</a></p><label for="search">Search by name, signature, keyword or link</label><input id="search" type="search" placeholder="item, familiar, consume, quest"><p id="count">'+script.functions.length+' matching functions</p>';
   pages[slug+"_micro_agent.html"]=htmlPage(slug+" · micro-agent",top+entries.map(x=>x.micro).join("\n")+'<script>'+scriptFilter+'</script>');
 }
 pages["agent_web_graph.json"]=JSON.stringify({schema:graph.schema,embeddings:graph.embeddings,evidence:graph.evidence,scripts:graph.scripts.map(s=>({slug:s.slug,path:s.path,number:s.number,functions:s.functions.map(({code,calls,...rest})=>rest)})),edges:graph.edges,ladder_metrics:graph.ladder_metrics},null,2)+"\n";
 return {graph,pages};
}
const args=process.argv.slice(2);
const option=(flag,fallback)=>{const i=args.indexOf(flag);return i<0?fallback:args[i+1];};
if(args.includes("--help")){console.log("node tools/build-agent-web.mjs --custom PATH --master PATH --out DIR");process.exit(0);}
const a=option("--custom","scripts/don_custom_functions.ash"),b=option("--master","../don-ash-lib/don-master-ash-lib/scripts/don_master_lib.ash"),dir=option("--out","data/agentWeb");
for(const file of [a,b])if(!fs.existsSync(file)){console.error("Missing ASH source: "+file);process.exit(2);}
const result=buildAgentWeb(fs.readFileSync(a,"utf8"),fs.readFileSync(b,"utf8"));
for(const [relative,body] of Object.entries(result.pages)){const file=path.join(dir,relative);fs.mkdirSync(path.dirname(file),{recursive:true});fs.writeFileSync(file,body,"utf8");console.log(file);}
console.log(JSON.stringify(result.graph.ladder_metrics));
