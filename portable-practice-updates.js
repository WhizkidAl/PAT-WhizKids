'use strict';
// No participant data is fetched or stored by this release checker.
(function(root){
function create(options){
 let checking=false,stopped=false,readyVersion=null;
 async function check(){
  if(checking||stopped||!options.available())return;
  checking=true;
  try{
   const release=await options.release();
   if(!release||typeof release.version!=='string'||release.version.localeCompare(options.version,undefined,{numeric:true})<=0)return;
   if(readyVersion!==release.version){if(!await options.verify(release))return;readyVersion=release.version;}
   if(!options.safe())return;
   await options.save();
   // A new activity, recording or save can start while the network is busy.
   if(!options.available()||!options.safe()||!options.saved())return;
   stopped=true;options.reload(release.version);
  }catch{/* Offline or incomplete deployment: retain the working app and retry. */}
  finally{checking=false;}
 }
 return {check,stop(){stopped=true}};
}
root.PATUpdates={create};
if(typeof module!=='undefined')module.exports=root.PATUpdates;
})(typeof window!=='undefined'?window:globalThis);
