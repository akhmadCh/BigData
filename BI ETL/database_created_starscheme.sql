-- BUAT DATABASE (HANYA CONTOH UNTUK STAR SCHEME)
CREATE DATABASE superhero_dw;
USE superhero_dw;

-- DIMENSIONS
CREATE TABLE DimDate (
   DateKey INT PRIMARY KEY,
   FullDate DATE,
   Day VARCHAR(10),
   Month VARCHAR(15),
   MonthOfYear INT,
   DayOfMonth INT,
   IsWeekend CHAR(1),
   Quarter VARCHAR(2),
   Year INT
);

CREATE TABLE DimHero (
   HeroKey INT PRIMARY KEY,
   HeroID_OLTP INT,
   Codename VARCHAR(50),
   PrimaryTerritory VARCHAR(50),
   RowIsCurrent CHAR(1),
   RowStartDate DATE,
   RowEndDate DATE
);

CREATE TABLE DimCase (
   CaseKey INT PRIMARY KEY,
   CaseID_OLTP INT,
   CaseName VARCHAR(100),
   Priority VARCHAR(20),
   Status VARCHAR(20)
);

CREATE TABLE DimEntity (
   EntityKey INT PRIMARY KEY,
   EntityID_OLTP INT,
   KnownAlias VARCHAR(100),
   EntityType VARCHAR(30),
   ThreatLevel VARCHAR(20)
);

CREATE TABLE DimInformant (
   InformantKey INT PRIMARY KEY,
   InformantID_OLTP INT,
   Codename VARCHAR(50),
   Specialization VARCHAR(50),
   ReliabilityTier VARCHAR(5)
);

-- FACTS
CREATE TABLE factIntelGathering (
   DateKey INT,
   HeroKey INT,
   CaseKey INT,
   EntityKey_Suspect INT,
   InformantKey INT,
   IntelCount INT,
   CredibilityRating INT,
   FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
   FOREIGN KEY (HeroKey) REFERENCES DimHero(HeroKey),
   FOREIGN KEY (CaseKey) REFERENCES DimCase(CaseKey),
   FOREIGN KEY (EntityKey_Suspect) REFERENCES DimEntity(EntityKey),
   FOREIGN KEY (InformantKey) REFERENCES DimInformant(InformantKey)
);

CREATE TABLE factCasePerformance (
   DateOpenedKey INT,
   DateClosedKey INT,
   CaseKey INT,
   LeadHeroKey INT,
   CaseResolvedCount INT,
   DaysToSolved INT,
   TotalHeroesAssigned INT,
   FOREIGN KEY (DateOpenedKey) REFERENCES DimDate(DateKey),
   FOREIGN KEY (DateClosedKey) REFERENCES DimDate(DateKey),
   FOREIGN KEY (CaseKey) REFERENCES DimCase(CaseKey),
   FOREIGN KEY (LeadHeroKey) REFERENCES DimHero(HeroKey)
);

CREATE TABLE factPatrols (
   DateKey INT,
   HeroKey INT,
   PatrolCount INT,
   IncidentsReported INT,
   PatrolDurationMinutes INT,
   FOREIGN KEY (DateKey) REFERENCES DimDate(DateKey),
   FOREIGN KEY (HeroKey) REFERENCES DimHero(HeroKey)
);
