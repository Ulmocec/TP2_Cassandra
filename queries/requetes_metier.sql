-- ====================== REQUÊTES MÉTIER ======================

-- ---------------------------------------------------------------
-- REQ-01
-- Besoin métier : Connaitre le détail (nom, capacité, position) d'une station.
-- Requête CQL   : SELECT ... WHERE station_id = ...
-- Clé de partition : station_id
-- Justification : la table stations est partitionnée par station_id, requête directe sans ALLOW FILTERING.
-- ---------------------------------------------------------------
SELECT * FROM stations WHERE station_id = '1117';

-- ---------------------------------------------------------------
-- REQ-02
-- Besoin métier : Connaitre la disponibilité (vélos, docks, e-bikes) d'une station.
-- Requête CQL   : SELECT ... FROM stations_dispo WHERE station_id = ... [AND duedate = ...]
-- Clé de partition : station_id ; clé de clustering : duedate
-- Justification : stations_dispo est partitionnée par station et clustering sur la date
-- (composée de la snapshot), ce qui permet l'historique et la dernière mesure.
-- ---------------------------------------------------------------
SELECT * FROM stations_dispo WHERE station_id = '1117';

-- ---------------------------------------------------------------
-- REQ-03
-- Besoin métier : Lister les stations d'un arrondissement, triées par capacité décroissante.
-- Requête CQL   : SELECT ... FROM stations_by_arrondissement WHERE arrondissement = ...
-- Clé de partition : arrondissement ; clé de clustering : (capacity DESC, station_id)
-- Justification : la table est dédiée à cette requête, le tri est intégré au clustering
-- (ORDER BY inutile), aucun ALLOW FILTERING.
-- ---------------------------------------------------------------
SELECT arrondissement, capacity, station_id, name
FROM stations_by_arrondissement
WHERE arrondissement = 'Montrouge';

-- ---------------------------------------------------------------
-- REQ-04
-- Besoin métier : Classement des plus grandes stations d'un arrondissement (top 5).
-- Requête CQL   : idem REQ-03 avec LIMIT 5.
-- Clé de partition : arrondissement (clustering capacity DESC)
-- Justification : le tri décroissant par capacité est déjà dans le clustering, LIMIT suffit.
-- ---------------------------------------------------------------
SELECT arrondissement, capacity, station_id, name
FROM stations_by_arrondissement
WHERE arrondissement = 'Montrouge'
LIMIT 5;

-- ---------------------------------------------------------------
-- REQ-05
-- Besoin métier : Nombre total de stations du service.
-- Requête CQL   : SELECT COUNT(*) FROM stations;
-- Clé de partition : aucune (agrégation sur toute la table, warning normal Cassandra)
-- Justification : agrégation globale acceptée par Cassandra sans ALLOW FILTERING.
-- ---------------------------------------------------------------
SELECT COUNT(*) FROM stations;

-- ---------------------------------------------------------------
-- REQ-06
-- Besoin métier : Stations d'un arrondissement offrant le plus de vélos disponibles.
-- Requête CQL   : SELECT ... avec numbikesavailable dénormalisé dans la table par arrondissement.
-- Clé de partition : arrondissement
-- Justification : la colonne numbikesavailable est dénormalisée dans stations_by_arrondissement
-- pour répondre à cette requête sans jointure ni ALLOW FILTERING.
-- ---------------------------------------------------------------
SELECT arrondissement, capacity, station_id, name, numbikesavailable
FROM stations_by_arrondissement
WHERE arrondissement = 'Montrouge'
LIMIT 5;

-- ====================== VÉRIFICATION DES DONNÉES ======================

SELECT COUNT(*) FROM stations;
SELECT COUNT(*) FROM stations_dispo;
SELECT COUNT(*) FROM stations_by_arrondissement;

SELECT * FROM stations LIMIT 5;