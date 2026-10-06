import re
import sys

from cassandra.cluster import Cluster


def run_sql_file(session, path):
    with open(path) as f:
        content = f.read()
    content = re.sub(r"/\*.*?\*/", "", content, flags=re.DOTALL)
    content = re.sub(r"^\s*--.*$", "", content, flags=re.MULTILINE)
    statements = [stmt.strip() for stmt in content.split(";") if stmt.strip()]
    for stmt in statements:
        print(f"\n>>> {stmt}")
        result = session.execute(stmt)
        for row in result or []:
            print("   ", row)


def main():
    if len(sys.argv) < 2:
        print("Usage: python script/requetes.py queries/fichier.sql [fichier2.sql ...]")
        sys.exit(1)

    cluster = Cluster(["127.0.0.1"], port=9042)
    session = cluster.connect("velib")

    for path in sys.argv[1:]:
        print(f"\n========== {path} ==========")
        run_sql_file(session, path)

    cluster.shutdown()


if __name__ == "__main__":
    main()