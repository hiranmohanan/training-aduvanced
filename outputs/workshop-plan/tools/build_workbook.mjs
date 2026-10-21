import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {Workbook,SpreadsheetFile} from '@oai/artifact-tool';
import {requirements,accounts,permissions,endpoints,schedule} from './workshop_data.mjs';

const pack=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const out=path.resolve(pack,'../01a0a8ac-ffe5-7202-b9f0-17032fb51354');
await fs.mkdir(out,{recursive:true});
await fs.mkdir(path.join(pack,'workbook-qa'),{recursive:true});
const wb=Workbook.create();
const renderNames=new Set(process.argv.slice(2));
const specs=[
 {name:'Requirements',title:'Client requirements',note:'TeamFlow / Northstar Studio. Proposed workshop scope; client acceptance is pending.',headers:['ID','Area','Requirement','Role','Priority','Acceptance criterion','Delivery'],rows:requirements,widths:[117,145,295,143,94,439,167],height:77},
 {name:'Role access',title:'Role permissions',note:'All record access uses the signed-in account. Apply rules in routes and data operations.',headers:['Operation','Employee','Admin','Super Admin'],rows:permissions,widths:[241,232,267,320],height:45},
 {name:'Demo logins',title:'Demo login accounts',note:'OTP 123456. Fictional phones; no SMS. Input normalizes spaces/hyphens. Demo date: 16 Sep 2026.',headers:['ID','Name','Role','Team','Phone login','Designation','Manager ID'],rows:accounts.map(a=>[...a.slice(0,4),`+1 202-555-${a[4].slice(-4)}`,a[5],a[6]??'None']),widths:[77,157,122,120,167,217,111],height:43},
 {name:'API catalogue',title:'Proposed API endpoints',note:'Mock contracts only. No live server exists. Session permissions constrain every authenticated result.',headers:['Method','Path','Purpose','Permission','Request / response'],rows:endpoints,widths:[83,332,184,311,430],height:56},
 {name:'Workshop schedule',title:'Two-day workshop',note:'Prepared scaffold required. Each day: 6 contact hours; breaks and lunch are excluded.',headers:['Day','Time','Minutes','Topic','Participant output'],rows:schedule,widths:[86,159,84,301,360],height:46},
];
for(const spec of specs){const sh=wb.worksheets.add(spec.name),col=String.fromCharCode(64+spec.headers.length),last=4+spec.rows.length;
 sh.showGridLines=false;
 sh.getRange(`A1:${col}${last}`).format.font={name:'Arial',size:11,color:'#233550'};
 sh.getRange('A1').values=[[spec.title]];sh.getRange('A1').format.font={name:'Arial',size:17,bold:true,color:'#152842'};
 sh.getRange(`A1:${col}1`).format.rowHeight=31;
 sh.getRange(`A1:${col}1`).format.borders={bottom:{style:'thin',color:'#C8D1DE'}};
 sh.getRange('A2').values=[[spec.note]];sh.getRange('A2').format.font={name:'Arial',size:10,color:'#66758C',italic:true};sh.getRange(`A2:${col}2`).format.rowHeight=26;
 sh.getRange(`A4:${col}4`).values=[spec.headers];sh.getRange(`A4:${col}4`).format={fill:'#203651',font:{name:'Arial',size:11,bold:true,color:'#FFFFFF'},rowHeight:30,wrapText:true,horizontalAlignment:'left',verticalAlignment:'center'};
 sh.getRange(`A5:${col}${last}`).values=spec.rows;
 sh.getRange(`A5:${col}${last}`).format.wrapText=true;sh.getRange(`A5:${col}${last}`).format.verticalAlignment='center';sh.getRange(`A5:${col}${last}`).format.rowHeight=spec.height;
 spec.widths.forEach((w,i)=>sh.getRange(`${String.fromCharCode(65+i)}1:${String.fromCharCode(65+i)}${last}`).format.columnWidthPx=w);
 for(let r=5;r<=last;r++)if(r%2===1)sh.getRange(`A${r}:${col}${r}`).format.fill='#F0F4F9';
 const t=sh.tables.add(`A4:${col}${last}`,true,spec.name.replaceAll(' ','')+'Table');t.showFilterButton=true;
 sh.freezePanes.freezeRows(4);
 if(spec.name==='Requirements')sh.getRange(`E5:E${last}`).dataValidation={rule:{type:'list',values:['Core','Later']}};
 if(spec.name==='Demo logins'){sh.getRange(`E5:E${last}`).setNumberFormat('@');sh.getRange(`A5:A${last}`).setNumberFormat('@');}
 if(spec.name==='Workshop schedule'){
  sh.getRange('C5:C16').setNumberFormat('0');sh.getRange('C5:C16').format.horizontalAlignment='right';
  sh.getRange('A19:D21').values=[['Day','Minutes','Hours',''],['Day 1',null,null,''],['Day 2',null,null,'']];
  sh.getRange('B20').formulas=[['=SUMIF(A5:A16,A20,C5:C16)']];sh.getRange('B21').formulas=[['=SUMIF(A5:A16,A21,C5:C16)']];
  sh.getRange('C20:C21').formulas=[['=B20/60'],['=B21/60']];sh.getRange('B20:C21').setNumberFormat('0');
  sh.getRange('A19:D21').format.font={name:'Arial',size:11,color:'#233550'};sh.getRange('A19:D21').format.rowHeight=27;
  sh.getRange('A19:C19').format.font={name:'Arial',size:11,bold:true,color:'#233550'};
  sh.getRange('A23').values=[['Breaks: 11:00–11:15 and 15:45–16:00. Lunch: 12:30–13:30.']];
  sh.getRange('A23').format.font={name:'Arial',size:10,color:'#66758C'};
 }
 console.log((await wb.inspect({kind:'table',range:`'${spec.name}'!A4:${col}${Math.min(last,7)}`,include:'values,formulas',tableMaxRows:4,tableMaxCols:7,maxChars:1200})).ndjson);
 if(!renderNames.size||renderNames.has(spec.name)){
  const blob=await wb.render({sheetName:spec.name,range:`A1:${col}${spec.name==='Workshop schedule'?23:last}`,scale:1,format:'png'});
  await fs.writeFile(path.join(pack,'workbook-qa',spec.name.replaceAll(' ','-')+'.png'),new Uint8Array(await blob.arrayBuffer()));
 }
}
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:30},summary:'Formula error scan',maxChars:2000})).ndjson);
console.log((await wb.inspect({kind:'table',range:"'Workshop schedule'!A19:C21",include:'values,formulas',tableMaxRows:3,tableMaxCols:3,maxChars:1200})).ndjson);
const xlsx=await SpreadsheetFile.exportXlsx(wb);await xlsx.save(path.join(out,'client-requirements.xlsx'));
console.log('EXPORTED '+path.join(out,'client-requirements.xlsx'));
