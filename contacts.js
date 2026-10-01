let contactToken = null, contactClient;
function getContactClient(){
 const c=window.DATABASE_CONFIG;
 if(!c?.url||!c?.key||!window.supabase)throw new Error('NOT_CONFIGURED');
 return contactClient ||= supabase.createClient(c.url,c.key,{auth:{persistSession:false}});
}
function contactLanguage(){const kk=document.documentElement.lang==='kk';
 document.getElementById('nameLabel').textContent=kk?'Тегі, аты, әкесінің аты':'ФИО';
 document.getElementById('phoneLabel').textContent=kk?'Телефон нөмірі':'Номер телефона';
 document.getElementById('consentText').textContent=kk?'Институтқа осы сауалнамадағы деректерімді қабылдау мәселелері бойынша өңдеуге және көрсетілген телефон арқылы менімен байланысуға келісім беремін.':'Даю согласие институту на обработку данных этой анкеты по вопросам поступления и на связь со мной по указанному телефону.';
}
async function saveContact(){const msg=document.getElementById('saveMessage'),btn=document.getElementById('continueButton');const kk=document.documentElement.lang==='kk';
 const phone=document.getElementById('phone').value.replace(/[^0-9]/g,'').replace(/^8(?=\d{10}$)/,'7');
 if(!/^7\d{10}$/.test(phone)){msg.textContent=kk?'Телефонды +7 және 10 цифр түрінде енгізіңіз.':'Введите номер: +7 и ещё 10 цифр.';return false;}
 btn.disabled=true;msg.textContent=kk?'Сақталуда…':'Сохраняем…';
 contactToken ||= crypto.randomUUID();
 const payload={};['fullName','city','institution','status','direction'].forEach(k=>payload[k]=document.getElementById(k).value.trim());
 payload.phone='+'+phone;payload.language=document.documentElement.lang;payload.consent=document.getElementById('consent').checked;
 try{const {error}=await getContactClient().rpc('submit_contact',{p_token:contactToken,p_data:payload});if(error)throw error;msg.textContent='';return true;}
 catch(e){msg.textContent=kk?'Сақтау мүмкін болмады. Қайталап көріңіз немесе қабылдау комиссиясына хабарласыңыз.':'Не удалось сохранить заявку. Попробуйте ещё раз или свяжитесь с приёмной комиссией.';return false;}
 finally{btn.disabled=false;}
}
async function saveQuiz(result){const note=document.getElementById('resultNote');
 try{const {error}=await getContactClient().rpc('complete_contact_quiz',{p_token:contactToken,p_result:result});if(error)throw error;}
 catch(e){const el=document.createElement('p');el.textContent=document.documentElement.lang==='kk'?'Байланыс деректеріңіз сақталды. Опрос нәтижесін сақтау мүмкін болмады.':'Контакты сохранены. Результат опроса не удалось сохранить.';const retry=document.createElement('button');retry.type='button';retry.textContent=document.documentElement.lang==='kk'?'Қайталау':'Повторить';retry.onclick=()=>{el.remove();saveQuiz(result)};el.append(retry);note.append(el);}
}
