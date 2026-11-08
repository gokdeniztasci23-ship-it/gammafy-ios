/* GammaFY iPhone koprusu: masaustundeki pywebview arayuzunun yerini tutar.
   Sayfa gammafy://app adresinden yuklenir; /p istekleri uygulamanin aktaricisina gider. */
window.IOS=true;
(function(){
  const M=window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.gamma;if(!M)return;
  const ist=(k,a)=>M.postMessage(Object.assign({k},a||{}));
  window.pywebview={api:{
    yukle:async()=>{try{return JSON.parse(await ist("yukle")||"{}")}catch(e){return{}}},
    kaydet:async v=>{try{await ist("kaydet",{v:JSON.stringify(v)})}catch(e){}return true},
    dosya_kaydet:async(ad,b64,mime)=>{try{return await ist("dosyaKaydet",{ad,b64,mime})}catch(e){return{ok:false,hata:String(e&&e.message||e)}}},
    dosya_eylem:async(yol)=>{try{await ist("dosyaEylem",{yol})}catch(e){}return true},
    disari_ac:async u=>{try{await ist("disariAc",{u})}catch(e){}return true},
    pano:async()=>{try{return await ist("pano")||""}catch(e){return""}},
    gelen:async()=>""}};
})();
