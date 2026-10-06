import json

from cassandra.cluster import Cluster

cluster = Cluster(["127.0.0.1"], port=9042)
session = cluster.connect()

# création du schéma depuis queries/schema.sql
with open("queries/schema.sql") as f:
    sql = "\n".join(l for l in f if not l.strip().startswith("--"))
for stmt in sql.split(";"):
    if stmt.strip():
        session.execute(stmt)

# chargement des données
with open("data/stations_emplacement.json") as f:
    stations = json.load(f)
with open("data/stations_disponibilite.json") as f:
    dispo = json.load(f)
dispo_by_code = {r["stationcode"]: r for r in dispo}

session.set_keyspace("velib")

for s in stations:
    code = s["stationcode"]
    coords = s.get("coordonnees_geo") or {}
    d = dispo_by_code.get(code, {})

    session.execute(
        "INSERT INTO stations (station_id, name, capacity, latitude, longitude, opening_hours)"
        " VALUES (%s, %s, %s, %s, %s, %s)",
        (code, s.get("name"), s.get("capacity"), coords.get("lat"), coords.get("lon"),
         s.get("station_opening_hours")),
    )

    if d.get("duedate"):
        session.execute(
            "INSERT INTO stations_dispo (station_id, duedate, numbikesavailable, numdocksavailable,"
            " mechanical, ebike, is_installed, is_renting, is_returning)"
            " VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
            (code, d.get("duedate"), d.get("numbikesavailable"), d.get("numdocksavailable"),
             d.get("mechanical"), d.get("ebike"), d.get("is_installed"), d.get("is_renting"),
             d.get("is_returning")),
        )

    session.execute(
        "INSERT INTO stations_by_arrondissement (arrondissement, capacity, station_id, name,"
        " latitude, longitude, numbikesavailable, ebike, numdocksavailable)"
        " VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
        (d.get("nom_arrondissement_communes") or "Inconnu", s.get("capacity"), code, s.get("name"),
         coords.get("lat"), coords.get("lon"), d.get("numbikesavailable"), d.get("ebike"),
         d.get("numdocksavailable")),
    )

cluster.shutdown()
print("Import terminé.")