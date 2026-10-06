# TP Exploitation des données avec Apache Cassandra — Vélib'

## Sujet

Étude des stations de vélos en libre-service **Vélib'** de la métropole du Grand Paris : données statiques
des stations et disponibilité en temps réel.

## API utilisées

- `velib-emplacement-des-stations` — localisation et capacité des stations
- `velib-disponibilite-en-temps-reel` — disponibilité (vélos, docks, e-bikes) par arrondissement

## Données récupérées

- 1519 stations récupérées
- Champs emplacement : `stationcode`, `name`, `capacity`, `coordonnees_geo`, `station_opening_hours`
- Champs disponibilité : `numbikesavailable`, `numdocksavailable`, `mechanical`, `ebike`,
  `nom_arrondissement_communes`, `is_installed`, `is_renting`, `is_returning`, `duedate`

## Modèle Cassandra

Keyspace `velib` — 3 tables pensées pour les requêtes métier (query-driven design) :

| Table | Partition Key | Clustering Key | Rôle |
|---|---|---|---|
| `stations` | `station_id` | — | infos statiques (nom, capacité, position) |
| `stations_dispo` | `station_id` | `duedate` | disponibilité (historique par date) |
| `stations_by_arrondissement` | `arrondissement` | `capacity DESC, station_id` | stations par quartier triées par capacité |

Voir `documentation/modelisation.md` pour les justifications et les 6 requêtes métier.

## Installation et exécution

Prérequis : Docker, Cassandra dans Docker (`docker compose up -d`), venv avec `requests` et `cassandra-driver`.

```bash
source venv/bin/activate
python script/getapi.py   # 1. récupération des 2 API -> data/*.json
python script/init.py     # 2. création du schéma + import des données
python script/requetes.py queries/requetes_metier.sql   # 3. requêtes métier
python script/requetes.py queries/crud.sql              # 4. démonstration CRUD
```

## Requêtes métier principales

| Réf | Besoin | Table |
|---|---|---|
| REQ-01 | Détail d'une station | `stations` |
| REQ-02 | Disponibilité d'une station | `stations_dispo` |
| REQ-03 | Stations d'un arrondissement triées par capacité | `stations_by_arrondissement` |
| REQ-04 | Top 5 des plus grandes stations d'un arrondissement | `stations_by_arrondissement` |
| REQ-05 | Nombre total de stations | `stations` |
| REQ-06 | Stations d'un arrondissement avec le plus de vélos | `stations_by_arrondissement` |

## Captures de résultats

- `documentation/captures/crud.txt`
- `documentation/captures/requetes_metier.txt`