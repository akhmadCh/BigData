require('dotenv').config();
const mysql = require("mysql2/promise");

// menangani format ke yyy-mm-dd
function formatDate(date) {
   const d = new Date(date);
   const year = d.getFullYear();
   const month = String(d.getMonth() + 1).padStart(2, '0');
   const day = String(d.getDate()).padStart(2, '0');
   return `${year}-${month}-${day}`;
}

// format untuk DateKey
function formatDateKey(date) {
   const d = new Date(date);
   const year = d.getFullYear();
   const month = String(d.getMonth() + 1).padStart(2, '0');
   const day = String(d.getDate()).padStart(2, '0');
   return parseInt(`${year}${month}${day}`);
}

function getDayName(date) {
   const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
   return days[new Date(date).getDay()];
}

function getMonthName(date) {
   const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
   return months[new Date(date).getMonth()];
}

function getQuarter(date) {
   const month = new Date(date).getMonth() + 1;
   return 'Q' + Math.ceil(month / 3);
}

// selisih hari
function daysDifference(date1, date2) {
   const diff = new Date(date2) - new Date(date1);
   return Math.round(diff / (1000 * 60 * 60 * 24));
}

// database config for oltp and dw
const oltpConfig = {
   host: process.env.DB_HOST,
   user: process.env.DB_USER,
   password: process.env.DB_PASSWORD,
   database: process.env.DB_NAME1,
   port: process.env.DB_PORT
};

const dwConfig = {
   host: process.env.DB_HOST,
   user: process.env.DB_USER,
   password: process.env.DB_PASSWORD,
   database: process.env.DB_NAME2,
   port: process.env.DB_PORT
};

// 1. EXTRACT
async function extract(connOLTP) {
   console.log("\nEXTRACT");
   
   const [superheroes] = await connOLTP.execute("SELECT * FROM superhero");
   const [cases] = await connOLTP.execute("SELECT * FROM cases");
   const [entities] = await connOLTP.execute("SELECT * FROM entities_of_interest");
   const [informants] = await connOLTP.execute("SELECT * FROM informants");
   const [intelEntries] = await connOLTP.execute("SELECT * FROM intel_entries");
   const [patrols] = await connOLTP.execute("SELECT * FROM patrols");
   const [heroCases] = await connOLTP.execute("SELECT * FROM hero_case");
   const [caseEntities] = await connOLTP.execute("SELECT * FROM bridge_case_entities");
   
   console.log(`Extract ${superheroes.length} records from table 'superheroes'`);
   console.log(`Extract ${cases.length} records from table 'cases'`);
   console.log(`Extract ${entities.length} records from table 'entities'`);
   console.log(`Extract ${informants.length} records from table 'informants'`);
   console.log(`Extract ${intelEntries.length} records from table 'intel' entries`);
   console.log(`Extracted ${patrols.length} records from table 'patrols'`);
   
   return { superheroes, cases, entities, informants, intelEntries, patrols, heroCases, caseEntities };
}

// 2. TRANSFORM
function transformDimHero(superheroes) {
   return superheroes.map((hero, index) => ({
      HeroKey: index + 1,
      HeroID_OLTP: hero.id,
      Codename: hero.codename,
      PrimaryTerritory: hero.primary_territory,
      RowIsCurrent: 'Y',
      RowStartDate: new Date(),
      RowEndDate: null
   }));
}

function transformDimCase(cases) {
   const priorityMap = {1: 'Low', 2: 'Medium', 3: 'High', 4: 'Very High', 5: 'Critical'};
   
   return cases.map((c, index) => ({
      CaseKey: index + 1,
      CaseID_OLTP: c.id,
      CaseName: c.case_name,
      Priority: priorityMap[c.priority] || 'Unknown',
      Status: c.status.replace('_', '-')
   }));
}

function transformDimEntity(entities) {
   const threatLevelMap = {1: 'Low', 2: 'Medium', 3: 'High', 4: 'Very High', 5: 'Critical'};
   
   return entities.map((e, index) => ({
      EntityKey: index + 1,
      EntityID_OLTP: e.id,
      KnownAlias: e.known_alias,
      EntityType: e.entity_type,
      ThreatLevel: threatLevelMap[e.threat_level] || 'Unknown'
   }));
}

function transformDimInformant(informants) {
   const reliabilityMap = {1: 'D', 2: 'C', 3: 'B', 4: 'A', 5: 'S'};
   
   return informants.map((i, index) => ({
      InformantKey: index + 1,
      InformantID_OLTP: i.id,
      Codename: i.codename,
      Specialization: i.specialization,
      ReliabilityTier: reliabilityMap[i.reliability_score] || 'N/A'
   }));
}

function transformDimDate(cases, patrols) {
   const dateSet = new Set();
   
   // tanggal unik untuk setiap case
   cases.forEach(c => {
      if (c.date_opened) dateSet.add(formatDate(c.date_opened));
      if (c.date_closed) dateSet.add(formatDate(c.date_closed));
   });
   
   patrols.forEach(p => {
      if (p.date) dateSet.add(formatDate(p.date));
   });
   
   // transform ke dimension date
   return Array.from(dateSet).map(dateStr => {
      const date = new Date(dateStr);
      const dayName = getDayName(date);
      
      return {
         DateKey: formatDateKey(date),
         FullDate: date,
         Day: dayName,
         Month: getMonthName(date),
         MonthOfYear: date.getMonth() + 1,
         DayOfMonth: date.getDate(),
         IsWeekend: (dayName === 'Saturday' || dayName === 'Sunday') ? 'Y' : 'N',
         Quarter: getQuarter(date),
         Year: date.getFullYear()
      };
   });
}

// TRANSFORM FACT TABLES
function transformFactIntelGathering(intelEntries, keyMaps) {
   return intelEntries.map(intel => {
      const dateKey = keyMaps.date.get(formatDate(intel.timestamp));
      
      return {
         DateKey: dateKey,
         HeroKey: keyMaps.hero.get(intel.hero_id),
         CaseKey: keyMaps.case.get(intel.case_id),
         EntityKey_Suspect: null,
         InformantKey: keyMaps.informant.get(intel.informant_id),
         IntelCount: 1,
         CredibilityRating: intel.credibility_rating
      };
   }).filter(row => row.DateKey !== undefined);
}

function transformFactCasePerformance(cases, heroCases, keyMaps) {
   // jumlah hero per case
   const heroesPerCase = {};
   heroCases.forEach(hc => {
      heroesPerCase[hc.case_id] = (heroesPerCase[hc.case_id] || 0) + 1;
   });
   
   // mengambil lead hero tiap cases
   const leadHeroMap = new Map();
   heroCases.forEach(hc => {
      if (hc.role.includes('lead')) {
         leadHeroMap.set(hc.case_id, hc.hero_id);
      }
   });
   
   // transform case yang sudah 'closed'
   return cases
      .filter(c => c.status.startsWith('closed'))
      .map(c => {
         return {
            DateOpenedKey: keyMaps.date.get(formatDate(c.date_opened)),
            DateClosedKey: keyMaps.date.get(formatDate(c.date_closed)),
            CaseKey: keyMaps.case.get(c.id),
            LeadHeroKey: keyMaps.hero.get(leadHeroMap.get(c.id)),
            CaseResolvedCount: 1,
            DaysToSolved: daysDifference(c.date_opened, c.date_closed),
            TotalHeroesAssigned: heroesPerCase[c.id] || 0
         };
      });
}

function transformFactPatrols(patrols, keyMaps) {
   return patrols.map(p => ({
      DateKey: keyMaps.date.get(formatDate(p.date)),
      HeroKey: keyMaps.hero.get(p.hero_id),
      PatrolCount: 1,
      IncidentsReported: p.incidents_reported,
      PatrolDurationMinutes: 180
   }));
}

// 3. LOAD
async function loadDimension(connDW, tableName, data, columns) {
   if (data.length === 0) return;
   
   const sql = `INSERT INTO ${tableName} (${columns.join(',')}) VALUES (${columns.map(() => '?').join(',')})`;
   
   for (const row of data) {
      const values = columns.map(col => row[col] ?? null);
      await connDW.execute(sql, values);
   }
   
   console.log(`Load ${data.length} records into ${tableName}`);
}

async function loadFact(connDW, tableName, data, columns) {
   if (data.length === 0) return;
   
   const sql = `INSERT INTO ${tableName} (${columns.join(',')}) VALUES (${columns.map(() => '?').join(',')})`;
   
   for (const row of data) {
      const values = columns.map(col => row[col] ?? null);
      await connDW.execute(sql, values);
   }
   
   console.log(`Load ${data.length} records into ${tableName}`);
}

// MAIN PROCESS
// ETL 
async function main() {
   let oltpConn, dwConn;
   
   try {
      console.log("Connecting to databases...");
      oltpConn = await mysql.createConnection(oltpConfig);
      dwConn = await mysql.createConnection(dwConfig);
      console.log("Connected successfully!");
      
      // Clear DW tables
      console.log("\nDW TABLES");
      await dwConn.execute('SET FOREIGN_KEY_CHECKS = 0');
      await dwConn.execute('TRUNCATE TABLE factIntelGathering');
      await dwConn.execute('TRUNCATE TABLE factCasePerformance');
      await dwConn.execute('TRUNCATE TABLE factPatrols');
      await dwConn.execute('TRUNCATE TABLE DimDate');
      await dwConn.execute('TRUNCATE TABLE DimHero');
      await dwConn.execute('TRUNCATE TABLE DimCase');
      await dwConn.execute('TRUNCATE TABLE DimEntity');
      await dwConn.execute('TRUNCATE TABLE DimInformant');
      await dwConn.execute('SET FOREIGN_KEY_CHECKS = 1');
      console.log("All tables cleared");
      
      // 1. EXTRACT
      const extractedData = await extract(oltpConn);
      
      // 2. TRANSFORM
      console.log("\nTRANSFORM");
      const dimHero = transformDimHero(extractedData.superheroes);
      const dimCase = transformDimCase(extractedData.cases);
      const dimEntity = transformDimEntity(extractedData.entities);
      const dimInformant = transformDimInformant(extractedData.informants);
      const dimDate = transformDimDate(extractedData.cases, extractedData.patrols);
      
      // lookup maps untuk foreign keys
      const keyMaps = {
         hero: new Map(dimHero.map(h => [h.HeroID_OLTP, h.HeroKey])),
         case: new Map(dimCase.map(c => [c.CaseID_OLTP, c.CaseKey])),
         entity: new Map(dimEntity.map(e => [e.EntityID_OLTP, e.EntityKey])),
         informant: new Map(dimInformant.map(i => [i.InformantID_OLTP, i.InformantKey])),
         date: new Map(dimDate.map(d => [formatDate(d.FullDate), d.DateKey]))
      };
      
      const factIntel = transformFactIntelGathering(extractedData.intelEntries, keyMaps);
      const factCase = transformFactCasePerformance(extractedData.cases, extractedData.heroCases, keyMaps);
      const factPatrol = transformFactPatrols(extractedData.patrols, keyMaps);
      
      console.log(`Transform ${dimHero.length} records table heroes`);
      console.log(`Transform ${dimCase.length} records table cases`);
      console.log(`Transform ${dimEntity.length} records table entities`);
      console.log(`Transform ${dimInformant.length} records table informants`);
      console.log(`Transform ${dimDate.length} records table dates`);
      console.log(`Transform ${factIntel.length} records table intel records`);
      console.log(`Transform ${factCase.length} records table case records`);
      console.log(`Transform ${factPatrol.length} records table patrol records`);
      
      // 3. LOAD
      console.log("\nLOAD");
      
      await loadDimension(dwConn, 'DimHero', dimHero, 
         ['HeroKey', 'HeroID_OLTP', 'Codename', 'PrimaryTerritory', 'RowIsCurrent', 'RowStartDate', 'RowEndDate']);
      
      await loadDimension(dwConn, 'DimCase', dimCase,
         ['CaseKey', 'CaseID_OLTP', 'CaseName', 'Priority', 'Status']);
      
      await loadDimension(dwConn, 'DimEntity', dimEntity,
         ['EntityKey', 'EntityID_OLTP', 'KnownAlias', 'EntityType', 'ThreatLevel']);
      
      await loadDimension(dwConn, 'DimInformant', dimInformant,
         ['InformantKey', 'InformantID_OLTP', 'Codename', 'Specialization', 'ReliabilityTier']);
      
      await loadDimension(dwConn, 'DimDate', dimDate,
         ['DateKey', 'FullDate', 'Day', 'Month', 'MonthOfYear', 'DayOfMonth', 'IsWeekend', 'Quarter', 'Year']);
      
      await loadFact(dwConn, 'factIntelGathering', factIntel,
         ['DateKey', 'HeroKey', 'CaseKey', 'EntityKey_Suspect', 'InformantKey', 'IntelCount', 'CredibilityRating']);
      
      await loadFact(dwConn, 'factCasePerformance', factCase,
         ['DateOpenedKey', 'DateClosedKey', 'CaseKey', 'LeadHeroKey', 'CaseResolvedCount', 'DaysToSolved', 'TotalHeroesAssigned']);
      
      await loadFact(dwConn, 'factPatrols', factPatrol,
         ['DateKey', 'HeroKey', 'PatrolCount', 'IncidentsReported', 'PatrolDurationMinutes']);
      
      console.log("\n(: ETL SELESAI :)");

      // setelah load selesai
      // laporan intel gathering yang lengkap
      console.log("\nValidating data...");
      [rows] = await dwConn.query(`
         SELECT fi.DateKey, dd.FullDate, dd.Day, dh.Codename AS HeroName, 
            dc.CaseName, 
            di.Codename AS InformantName, 
            fi.IntelCount, 
            fi.CredibilityRating 
         FROM factIntelGathering fi 
         JOIN DimDate dd ON fi.DateKey = dd.DateKey 
         JOIN DimHero dh ON fi.HeroKey = dh.HeroKey 
         JOIN DimCase dc ON fi.CaseKey = dc.CaseKey 
         JOIN DimInformant di ON fi.InformantKey = di.InformantKey 
         ORDER BY dd.FullDate DESC
      `);
      console.table(rows);

      // laporan case performance
      [rows] = await dwConn.query(`
         SELECT 
            fcp.CaseKey,
            dc.CaseName,
            dc.Priority,
            dc.Status,
            dh.Codename AS LeadHero,
            dd_open.FullDate AS DateOpened,
            dd_close.FullDate AS DateClosed,
            fcp.DaysToSolved,
            fcp.TotalHeroesAssigned,
            fcp.CaseResolvedCount
         FROM factCasePerformance fcp
         JOIN DimCase dc ON fcp.CaseKey = dc.CaseKey
         JOIN DimHero dh ON fcp.LeadHeroKey = dh.HeroKey
         JOIN DimDate dd_open ON fcp.DateOpenedKey = dd_open.DateKey
         JOIN DimDate dd_close ON fcp.DateClosedKey = dd_close.DateKey
         ORDER BY fcp.DaysToSolved ASC;
      `);
      console.table(rows);

      // laporan patrol tiap hero
      [rows] = await dwConn.query(`
         SELECT 
            fp.DateKey,
            dd.FullDate,
            dd.Day,
            dd.IsWeekend,
            dh.Codename AS HeroName,
            dh.PrimaryTerritory,
            fp.PatrolCount,
            fp.IncidentsReported,
            fp.PatrolDurationMinutes
         FROM factPatrols fp
         JOIN DimDate dd ON fp.DateKey = dd.DateKey
         JOIN DimHero dh ON fp.HeroKey = dh.HeroKey
         ORDER BY dd.FullDate DESC;
      `);
      console.table(rows);

   } catch (err) {
      console.error("\nETL GAGAL: ", err.message);
   } finally {
      if (oltpConn) await oltpConn.end();
      if (dwConn) await dwConn.end();
      console.log("\nConnection closed");
   }
}

main();
