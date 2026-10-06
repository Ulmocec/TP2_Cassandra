-- ============ CRUD : consultation, insertion, modification, suppression ============

-- Consultation
SELECT * FROM stations WHERE station_id = '1117';

-- Insertion d'une station de démonstration
INSERT INTO stations (station_id, name, capacity, latitude, longitude, opening_hours)
VALUES ('99999', 'Station Démo', 10, 48.85, 2.35, null);

SELECT * FROM stations WHERE station_id = '99999';

-- Modification
UPDATE stations SET capacity = 15 WHERE station_id = '99999';

SELECT * FROM stations WHERE station_id = '99999';

-- Suppression
DELETE FROM stations WHERE station_id = '99999';

SELECT * FROM stations WHERE station_id = '99999';