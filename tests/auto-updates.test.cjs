const assert=require('node:assert/strict'),{create}=require('../portable-practice-updates');
function setup(changes={}){const stats={reloads:0,saves:0};const o={version:'2026-11-16.3',available:()=>true,release:async()=>({version:'2026-11-16.4'}),verify:async()=>true,safe:()=>true,save:async()=>{stats.saves++},saved:()=>true,reload:v=>{stats.reloads++;stats.version=v},...changes};return {o,stats,updater:create(o)}}
(async()=>{
let t=setup();await t.updater.check();await t.updater.check();assert.equal(t.stats.reloads,1);assert.equal(t.stats.saves,1);
for(const changes of [{available:()=>false},{safe:()=>false},{saved:()=>false},{verify:async()=>false},{release:async()=>{throw Error('Offline')}},{release:async()=>({version:'2026-11-16.2'})}]){t=setup(changes);await t.updater.check();assert.equal(t.stats.reloads,0)}
t=setup();t.o.save=async()=>{t.o.safe=()=>false};await t.updater.check();assert.equal(t.stats.reloads,0,'Do not interrupt an activity started during saving');
t=setup({safe:()=>false});await t.updater.check();t.o.safe=()=>true;await t.updater.check();assert.equal(t.stats.reloads,1,'Deferred update applies when Home is safe');
t=setup({release:async()=>({version:'2026-11-16.10'})});await t.updater.check();assert.equal(t.stats.reloads,1);
let release; t=setup({verify:()=>new Promise(r=>release=r)});const first=t.updater.check();await new Promise(r=>setImmediate(r));await t.updater.check();release(true);await first;assert.equal(t.stats.reloads,1,'Concurrent resume events do not reload twice');
console.log('PASS automatic updates: resume, deferred busy/recording state, unsynced/conflicting saves, offline, partial releases, races and one reload.');
})().catch(e=>{console.error(e);process.exitCode=1});
