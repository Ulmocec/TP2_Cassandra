DROP KEYSPACE IF EXISTS velib;

CREATE KEYSPACE velib
WITH replication = {
    'class': 'SimpleStrategy',
    'replication_factor': 1
};

USE velib;

-- Infos statiques d'une station
CREATE TABLE stations (
    station_id text PRIMARY KEY,
    name text,
    capacity int,
    latitude double,
    longitude double,
    opening_hours text
);

-- Etat temps reel d'une station (historique par duedate)
CREATE TABLE stations_dispo (
    station_id text,
    duedate text,
    numbikesavailable int,
    numdocksavailable int,
    mechanical int,
    ebike int,
    is_installed text,
    is_renting text,
    is_returning text,
    PRIMARY KEY (station_id, duedate)
);

-- Stations par arrondissement, triees par capacite decroissante
CREATE TABLE stations_by_arrondissement (
    arrondissement text,
    capacity int,
    station_id text,
    name text,
    latitude double,
    longitude double,
    numbikesavailable int,
    ebike int,
    numdocksavailable int,
    PRIMARY KEY (arrondissement, capacity, station_id)
) WITH CLUSTERING ORDER BY (capacity DESC, station_id ASC);