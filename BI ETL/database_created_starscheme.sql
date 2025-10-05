-- BUAT DATABASE
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

-- =====================================
-- DUMMY DATA
-- =====================================

-- DimDate
INSERT INTO DimDate VALUES 
(1, '2025-09-20', 'Saturday', 'September', 9, 20, 'Y', 'Q3', 2025),
(2, '2025-09-21', 'Sunday', 'September', 9, 21, 'Y', 'Q3', 2025),
(3, '2025-09-22', 'Monday', 'September', 9, 22, 'N', 'Q3', 2025);

-- DimHero (7 Heroes)
INSERT INTO DimHero VALUES
(1, 101, 'Batman', 'Gotham', 'Y', '2025-01-01', NULL),
(2, 102, 'Daredevil', 'Hell''s Kitchen', 'Y', '2025-01-01', NULL),
(3, 103, 'Punisher', 'New York', 'Y', '2025-01-01', NULL),
(4, 104, 'Spider-Man', 'New York', 'Y', '2025-01-01', NULL),
(5, 105, 'Nightwing', 'Blüdhaven', 'Y', '2025-01-01', NULL),
(6, 106, 'Red Hood', 'Gotham', 'Y', '2025-01-01', NULL),
(7, 107, 'Robin (Damian Wayne)', 'Gotham', 'Y', '2025-01-01', NULL);

-- DimCase
INSERT INTO DimCase VALUES
(1, 201, 'Bank Robbery Gotham', 'High', 'Open'),
(2, 202, 'Harbor Smuggling NYC', 'Medium', 'Closed'),
(3, 203, 'Cyber Attack NYC Grid', 'Critical', 'Open'),
(4, 204, 'Blüdhaven Gang War', 'High', 'Open'),
(5, 205, 'Gotham Underground Arms Deal', 'Critical', 'Closed');

-- DimEntity
INSERT INTO DimEntity VALUES
(1, 301, 'Joker', 'Crime Lord', 'Critical'),
(2, 302, 'Wilson Fisk', 'Crime Lord', 'High'),
(3, 303, 'Hydra Agent', 'Terrorist', 'Critical'),
(4, 304, 'Penguin', 'Crime Boss', 'High'),
(5, 305, 'Random Thief', 'Street Criminal', 'Low');

-- DimInformant
INSERT INTO DimInformant VALUES
(1, 401, 'Oracle', 'Tech Surveillance', 'A'),
(2, 402, 'ShadowFox', 'Street Ops', 'B'),
(3, 403, 'NightOwl', 'Hacking', 'B'),
(4, 404, 'StreetRat', 'Street Level', 'C');

-- factIntelGathering
INSERT INTO factIntelGathering VALUES
(1, 1, 1, 1, 1, 10, 9),  -- Batman vs Joker
(2, 2, 2, 2, 2, 5, 8),   -- Daredevil vs Fisk
(3, 3, 2, 3, 3, 8, 7),   -- Punisher vs Hydra
(2, 4, 3, 3, 2, 7, 9),   -- Spider-Man vs Hydra
(3, 5, 4, 4, 4, 6, 6),   -- Nightwing vs Penguin
(1, 6, 5, 4, 2, 4, 8),   -- Red Hood vs Penguin
(3, 7, 1, 5, 1, 3, 7);   -- Robin vs Thief

-- factCasePerformance
INSERT INTO factCasePerformance VALUES
(1, 2, 1, 1, 1, 2, 3),   -- Batman leads Gotham robbery
(2, 3, 2, 2, 1, 5, 2),   -- Daredevil leads harbor smuggling
(3, NULL, 3, 4, 0, NULL, 2), -- Spider-Man cyber attack (ongoing)
(1, 3, 4, 5, 1, 7, 2),   -- Nightwing gang war
(2, 3, 5, 6, 1, 6, 2);   -- Red Hood arms deal

-- factPatrols
INSERT INTO factPatrols VALUES
(1, 1, 3, 2, 240),   -- Batman patrol
(2, 2, 2, 1, 180),   -- Daredevil patrol
(3, 3, 1, 1, 150),   -- Punisher patrol
(2, 4, 2, 0, 200),   -- Spider-Man patrol
(3, 5, 3, 2, 220),   -- Nightwing patrol
(1, 6, 1, 1, 160),   -- Red Hood patrol
(3, 7, 2, 1, 140);   -- Robin patrol