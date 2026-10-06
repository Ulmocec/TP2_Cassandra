import json
import os
import requests

DATASETS = {
    "emplacement": "velib-emplacement-des-stations",
    "disponibilite": "velib-disponibilite-en-temps-reel",
}

BASE_URL = "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/{}/records"
DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")


def fetch_all(dataset):
    results = []
    offset = 0
    limit = 100
    while True:
        response = requests.get(
            BASE_URL.format(dataset), params={"limit": limit, "offset": offset}
        )
        response.raise_for_status()
        data = response.json()
        records = data.get("results", [])
        results.extend(records)
        if not records or len(results) >= data.get("total_count", 0):
            break
        offset += limit
    return results


def main():
    print("Récupération des données Vélib'...")
    os.makedirs(DATA_DIR, exist_ok=True)
    for name, dataset in DATASETS.items():
        records = fetch_all(dataset)
        path = os.path.join(DATA_DIR, f"stations_{name}.json")
        with open(path, "w") as f:
            json.dump(records, f, ensure_ascii=False, indent=2)
        print(f"{name}: {len(records)} stations -> {path}")

    with open(os.path.join(DATA_DIR, "stations_emplacement.json")) as f:
        emplacement = json.load(f)
    print("Champs emplacement:", sorted(emplacement[0].keys()))
    with open(os.path.join(DATA_DIR, "stations_disponibilite.json")) as f:
        disponibilite = json.load(f)
    print("Champs disponibilité:", sorted(disponibilite[0].keys()))


if __name__ == "__main__":
    main()