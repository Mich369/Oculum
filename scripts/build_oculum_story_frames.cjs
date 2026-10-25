// Native UI ornaments, exported without altering any existing artwork.
const fs=require('fs'),path=require('path');
const sharp=require(process.argv[2]||'sharp');
const root=path.resolve(__dirname,'..');
const ids=["hidenas","plane_demoniaco","plane_diabolico","dedicated_indigo","dedicated_cloud_sea","dedicated_aurora","plane_nuvole_rocciose","plane_mezzano","plane_sacro","plane_angelico","plane_oblio","plane_isole","plane_affogato","plane_sotterraneo","plane_sotterraneo_maggiore","plane_shadow_hell","plane_vero_inferno","plane_postea","plane_caramella","plane_foresta_elementale","plane_morti","plane_ghiaccio","benedict"];
const seed=id=>Array.from(id).reduce((n,c)=>(n*31+c.charCodeAt(0))&0x7fffffff,17);
const tint=id=>/demoniaco|hidenas|vero_inferno/.test(id)?'#c58265':/diabolico|shadow_hell|oblio/.test(id)?'#a496cf':/dedicated|nuvole|isole/.test(id)?'#99b4e2':/caramella/.test(id)?'#d0a3bb':/morti|affogato/.test(id)?'#92c3bd':/angelico|sacro/.test(id)?'#c4b17b':'#b0a8a1';
function frame(id,w,h,state,variant){
 const n=seed(id),color=tint(id),alpha=state==='disabled'?.22:state==='pressed'?.92:state==='hover'?.8:state==='selected'?1:.58;
 let strokes='';
 for(const sx of [1,-1]) for(const sy of [1,-1]){
  const x=sx===1?8:w-8,y=sy===1?8:h-8;
  let d='M0 29L0 0L29 0';
  for(let i=0;i<9;i++){const length=3+((n>>(i*2))&3)*2;d+='M'+(7+i*2.7)+' 3L'+(7+i*2.7)+' '+length;}
  d+='M4 19Q'+(8+n%7)+' '+(11+n%5)+' 20 4';
  if(variant==='alive')d+='M4 30Q12 13 30 4';
  strokes+='<path d="'+d+'" transform="translate('+x+' '+y+') scale('+sx+' '+sy+')" fill="none" stroke="'+color+'" stroke-width="'+(state==='pressed'?1.8:1.1)+'" opacity="'+alpha+'"/>';
 }
 const anchor=110+ids.indexOf(id)*35;
 strokes+='<path d="M'+anchor+' 6l8 10-8 10-8-10Z" fill="none" stroke="'+color+'" stroke-width="2.6" opacity="'+alpha+'"/>';
 return '<svg xmlns="http://www.w3.org/2000/svg" width="'+w+'" height="'+h+'">'+strokes+'</svg>';
}
function relic(id){
 const c=tint(id),n=seed(id);
 let symbol;
 if(id==='benedict') symbol='<circle cx="126" cy="68" r="19"/><path d="M113 88 91 112l-13 58 21 9 9-34-8 65h60l-13-65 15 24 20-14-28-45-15-22Z"/><path d="M124 95l-7 26 16 17-9 27m-12 16 9 16m24-85 5 28"/>';
 else if(id==='hidenas') symbol='<path d="M51 196V96l19-29 9 45 13-73 15 64 19-35 9 128M147 196V91l12-34 13 39v100"/><path d="M91 190c-24-28 19-40 9-67 39 35 41 47 15 67Z"/>';
 else if(/cloud|nuvole|dedicated|isole/.test(id))symbol='<path d="M40 129c-13-26 9-50 31-41 0-42 64-49 74-10 40-14 61 42 27 53ZM40 151c45 30 82-22 134 0M59 173c35 19 62-15 99-4"/>';
 else if(/demoniaco|inferno/.test(id))symbol='<ellipse cx="128" cy="73" rx="72" ry="25"/><path d="M56 75v74c12 66 132 66 144 0V75M64 94c105 57 154 6 61-3s-84 59 5 52 31 44-8 35"/>';
 else if(/diabolico|shadow_hell/.test(id))symbol='<path d="M57 195V88l18-31 18 31v32h22V72l14-31 14 31v48h24V88l17-31 16 31v107ZM135 89c-22 22-22 47 0 57-41 5-47-50 0-57Z"/>';
 else if(/sacro|angelico/.test(id))symbol='<path d="M126 172C47 153 47 70 42 48c47 10 67 68 84 94 20-50 48-82 88-94-6 48-12 101-84 124ZM82 190h92"/><circle cx="128" cy="57" r="14"/>';
 else if(/morti/.test(id))symbol='<path d="M75 154c-51-88 150-114 109 0l-20 39H93Z"/><ellipse cx="105" cy="123" rx="13" ry="18"/><ellipse cx="152" cy="123" rx="13" ry="18"/><path d="M110 170v21m20-21v21m20-21v21"/>';
 else if(/caramella/.test(id))symbol='<path d="M70 190V79c0-67 108-67 108 0v21h-26V80c0-32-55-32-55 0v110ZM70 107l26-17m-26 49 26-17m-26 49 26-17"/>';
 else if(/postea/.test(id))symbol='<path d="M70 72h115v116H70Z"/><circle cx="99" cy="119" r="15"/><circle cx="157" cy="119" r="15"/><path d="M92 158h73m-37-87V45m-22 0h44m-80 61H48v49h22m115-49h24v49h-24"/>';
 else symbol='<path d="M128 43 63 90l13 101h104l13-101ZM93 164v-53l35-23 35 23v53Z"/>';
 let marks='';for(let i=0;i<10;i++)marks+='<path d="M'+(69+i*12)+' 218v'+(3+((n>>(i*2))&3)*2)+'"/>';
 return '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><g fill="#13141f" stroke="'+c+'" stroke-width="3.1" stroke-linecap="round" stroke-linejoin="round">'+symbol+marks+'</g></svg>';
}
(async()=>{
for(const id of ids){
 const dir=path.join(root,'assets','themes',id);fs.mkdirSync(path.join(dir,'frames'),{recursive:true});fs.mkdirSync(path.join(dir,'overlays'),{recursive:true});
 for(const state of ['normal','hover','pressed','selected','disabled'])await sharp(Buffer.from(frame(id,1024,512,state,''))).png().toFile(path.join(dir,'frames','identity-'+state+'.png'));
 await sharp({create:{width:256,height:256,channels:4,background:'#101219'}}).png().toFile(path.join(dir,'frames','identity-surface.png'));
 for(const role of ['panel','mobile','portrait','statistics','separator'])for(const variant of ['','still','alive'])await sharp(Buffer.from(frame(id,1024,512,'normal',variant))).png().toFile(path.join(dir,'frames',role+(variant?'-'+variant:'')+'.png'));
 await sharp(Buffer.from(relic(id))).png().toFile(path.join(dir,'overlays','relic.png'));
}
console.log(ids.length+' story frame packs exported.');
})().catch(e=>{console.error(e);process.exitCode=1});
