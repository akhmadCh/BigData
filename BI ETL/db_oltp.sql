-- Buat database
CREATE DATABASE superhero_oltp;
USE superhero_oltp;

-- ENUM di MySQL bisa pakai tipe ENUM langsung
CREATE TABLE superhero (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codename VARCHAR(100) NOT NULL,
    primary_territory VARCHAR(100),
    status ENUM('active','inactive','compromised') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE cases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    case_name VARCHAR(200),
    status ENUM('active','cold','closed_success','closed_failed'),
    description TEXT,
    priority TINYINT,
    date_opened DATETIME,
    date_closed DATETIME
);

CREATE TABLE entities_of_interest (
    id INT AUTO_INCREMENT PRIMARY KEY,
    known_alias VARCHAR(200),
    real_name VARCHAR(200),
    entity_type ENUM('person','gang','corporation'),
    threat_level TINYINT,
    biography TEXT
);

CREATE TABLE informants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codename VARCHAR(100),
    reliability_score TINYINT,
    specialization VARCHAR(100),
    status ENUM('active','compromised','retired','deceased'),
    last_contact_date DATETIME
);

CREATE TABLE intel_entries (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    case_id INT,
    informant_id INT,
    hero_id INT,
    credibility_rating TINYINT,
    timestamp DATETIME,
    content TEXT,
    source_type ENUM('observation','informant','interrogation','digital'),
    FOREIGN KEY (case_id) REFERENCES cases(id),
    FOREIGN KEY (informant_id) REFERENCES informants(id),
    FOREIGN KEY (hero_id) REFERENCES superhero(id)
);

CREATE TABLE bridge_case_entities (
    case_id INT,
    entity_id INT,
    role VARCHAR(100),
    PRIMARY KEY (case_id, entity_id),
    FOREIGN KEY (case_id) REFERENCES cases(id),
    FOREIGN KEY (entity_id) REFERENCES entities_of_interest(id)
);

CREATE TABLE bridge_entity_relationships (
    entity_id_A INT,
    entity_id_B INT,
    relationship_type VARCHAR(100),
    PRIMARY KEY (entity_id_A, entity_id_B),
    FOREIGN KEY (entity_id_A) REFERENCES entities_of_interest(id),
    FOREIGN KEY (entity_id_B) REFERENCES entities_of_interest(id)
);

CREATE TABLE patrols (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hero_id INT,
    territory VARCHAR(100),
    date DATETIME,
    incidents_reported INT,
    notes TEXT,
    FOREIGN KEY (hero_id) REFERENCES superhero(id)
);

CREATE TABLE hero_case (
    id INT AUTO_INCREMENT PRIMARY KEY,
    hero_id INT,
    case_id INT,
    role VARCHAR(100),
    FOREIGN KEY (hero_id) REFERENCES superhero(id),
    FOREIGN KEY (case_id) REFERENCES cases(id)
);

-- =========================================================
-- INSERT DATA SUPERHEROES
-- =========================================================
INSERT INTO superhero (codename, primary_territory, status) VALUES
('Batman', 'Gotham', 'active'),
('Daredevil', 'Hell''s Kitchen', 'active'),
('Punisher', 'New York', 'active'),
('Spider-Man', 'New York', 'active'),
('Nightwing', 'Blüdhaven', 'active'),
('Red Hood', 'Gotham', 'inactive'),
('Robin (Damian Wayne)', 'Gotham', 'active');

-- =========================================================
-- INSERT DATA CASES
-- =========================================================
INSERT INTO cases (case_name, status, description, priority, date_opened, date_closed) VALUES
('Joker''s Bank Heist', 'closed_success', 'Joker attempted a massive heist in Gotham.', 5, '2025-01-10', '2025-01-12'),
('Kingpin Drug Operations', 'active', 'Massive drug trafficking ring in Hell''s Kitchen.', 4, '2025-02-15', NULL),
('Punisher Vigilante Crackdown', 'cold', 'Punisher targeted several mob bosses.', 3, '2025-03-01', NULL),
('Spider-Man vs Green Goblin', 'closed_failed', 'Green Goblin escaped after major battle.', 5, '2025-04-20', '2025-04-21');

-- =========================================================
-- INSERT DATA ENTITIES
-- =========================================================
INSERT INTO entities_of_interest (known_alias, real_name, entity_type, threat_level, biography) VALUES
('Joker', 'Unknown', 'person', 5, 'Psychopathic clown criminal mastermind.'),
('Kingpin', 'Wilson Fisk', 'person', 4, 'Crime lord of Hell''s Kitchen.'),
('Green Goblin', 'Norman Osborn', 'person', 5, 'Industrialist turned supervillain.'),
('Gotham Mob', 'Multiple', 'gang', 3, 'Organized crime families in Gotham.');

-- =========================================================
-- INSERT DATA INFORMANTS
-- =========================================================
INSERT INTO informants (codename, reliability_score, specialization, status, last_contact_date) VALUES
('Oracle', 5, 'Hacking and surveillance', 'active', '2025-09-20'),
('Ben Urich', 4, 'Journalism', 'active', '2025-09-25'),
('Underworld Snitch', 2, 'Street intel', 'compromised', '2025-08-30');

-- =========================================================
-- INSERT DATA INTEL
-- =========================================================
INSERT INTO intel_entries (case_id, informant_id, hero_id, credibility_rating, timestamp, content, source_type) VALUES
(1, 1, 1, 5, '2025-01-10 14:00:00', 'Joker spotted near Gotham bank.', 'observation'),
(2, 2, 2, 4, '2025-02-16 10:30:00', 'Kingpin''s men moving crates.', 'informant'),
(3, 3, 3, 3, '2025-03-02 19:00:00', 'Punisher tracked mob meeting.', 'informant'),
(4, NULL, 4, 5, '2025-04-20 21:00:00', 'Green Goblin attacked Oscorp tower.', 'observation');

-- =========================================================
-- BRIDGE CASE - ENTITIES
-- =========================================================
INSERT INTO bridge_case_entities (case_id, entity_id, role) VALUES
(1, 1, 'main villain'),
(2, 2, 'crime boss'),
(3, 4, 'target gang'),
(4, 3, 'archenemy');

-- =========================================================
-- BRIDGE ENTITY RELATIONSHIPS
-- =========================================================
INSERT INTO bridge_entity_relationships (entity_id_A, entity_id_B, relationship_type) VALUES
(1, 4, 'manipulates'),
(2, 4, 'supplies'),
(3, 2, 'rivals');

-- =========================================================
-- PATROLS
-- =========================================================
INSERT INTO patrols (hero_id, territory, date, incidents_reported, notes) VALUES
(1, 'Gotham', '2025-09-20', 3, 'Stopped armed robbery.'),
(2, 'Hell''s Kitchen', '2025-09-21', 2, 'Drug bust.'),
(4, 'New York', '2025-09-22', 4, 'Green Goblin sighting.');

-- =========================================================
-- HERO - CASE RELATIONSHIPS
-- =========================================================
INSERT INTO hero_case (hero_id, case_id, role) VALUES
(1, 1, 'lead investigator'),
(2, 2, 'lead investigator'),
(3, 3, 'solo vigilante'),
(4, 4, 'main hero');
