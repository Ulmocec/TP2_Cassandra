# Modélisation Cassandra — Vélib'

## Tables

### `stations`

Infos statiques d'une station.

| Colonne | Type | Rôle |
|---|---|---|
| `station_id` | text | **Partition key** (anciennement `stationcode`) |
| `name` | text | nom de la station |
| `capacity` | int | nombre de places |
| `latitude` / `longitude` | double | position |
| `opening_hours` | text | horaires d'ouverture |

### `stations_dispo`

Disponibilité temps réel d'une station, avec historique par date de mesure.

| Colonne | Type | Rôle |
|---|---|---|
| `station_id` | text | **Partition key** |
| `duedate` | text | **Clustering key** (date de la mesure) |
| `numbikesavailable` | int | vélos disponibles |
| `numdocksavailable` | int | docks libres |
| `mechanical` / `ebike` | int | vélos mécaniques / électriques |
| `is_installed` / `is_renting` / `is_returning` | text | état de service |

La clé de clustering `duedate` est **nécessaire** : elle permet de conserver plusieurs mesures
dans le temps pour une même station (un ré-import n'écrase pas l'historique).

### `stations_by_arrondissement`

Dénormalisation de l'état temps réel dans une table organisée par arrondissement.

| Colonne | Type | Rôle |
|---|---|---|
| `arrondissement` | text | **Partition key** |
| `capacity` | int | **Clustering key (DESC)** — tri décroissant intégré au clustering |
| `station_id` | text | **Clustering key** (2e colonne, constance) |
| `name`, `latitude`, `longitude` | | informations station |
| `numbikesavailable`, `ebike`, `numdocksavailable` | | état temps réel dénormalisé |

Les données de la disponibilité sont **dénormalisées** ici pour répondre à la requête
« stations d'un arrondissement triées / meilleures » **sans jointure ni ALLOW FILTERING**.

## Justification des clés

- **`stations.station_id`** : toute requête sur une station précise est une recherche directe par partition key.
- **`stations_dispo.(station_id, duedate)`** : la clustering key est indispensable pour l'historique
  des disponibilités ; la requête « dispo actuelle » filtre par `station_id` (et éventuellement `duedate`).
- **`stations_by_arrondissement.(arrondissement, capacity DESC, station_id)`** : le partitionnement par
  arrondissement et le tri par capacité dans le clustering donnent directement les stations les plus
  grandes d'un quartier, sans tri applicatif.

## Besoins métier et requêtes associées

### REQ-01 — Détail d'une station
```sql
SELECT * FROM stations WHERE station_id = '1117';
```
Partition key : `station_id`. Accès direct, aucune recherche multi-partition.

### REQ-02 — Disponibilité d'une station
```sql
SELECT * FROM stations_dispo WHERE station_id = '1117';
```
Partition key : `station_id`, clustering `duedate`. Retourne la mesure (éventuellement l'historique).

### REQ-03 — Stations d'un arrondissement, triées par capacité décroissante
```sql
SELECT arrondissement, capacity, station_id, name
FROM stations_by_arrondissement
WHERE arrondissement = 'Montrouge';
```
Partition key : `arrondissement`. Le tri est déjà dans `CLUSTERING ORDER BY (capacity DESC, ...)`.

### REQ-04 — Top 5 des plus grandes stations d'un arrondissement
```sql
SELECT arrondissement, capacity, station_id, name
FROM stations_by_arrondissement
WHERE arrondissement = 'Montrouge'
LIMIT 5;
```
Même partition key ; le `LIMIT` suffit grâce au tri du clustering.

### REQ-05 — Nombre total de stations
```sql
SELECT COUNT(*) FROM stations;
```
Agrégation globale, autorisée par Cassandra (warning « aggregation without partition key » normal).

### REQ-06 — Stations d'un arrondissement offrant le plus de vélos
```sql
SELECT arrondissement, capacity, station_id, name, numbikesavailable
FROM stations_by_arrondissement
WHERE arrondissement = 'Montrouge'
LIMIT 5;
```
`numbikesavailable` est dénormalisé dans la table : requête directe par partition key, sans jointure
ni `ALLOW FILTERING`.

## Choix d'éviter ALLOW FILTERING

Aucune requête du modèle n'utilise `ALLOW FILTERING` : chaque besoin a sa propre table, organisée
autour de la partition key qu'elle interroge (approche *query-driven design* imposée par Cassandra).