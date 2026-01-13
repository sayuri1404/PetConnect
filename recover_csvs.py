
import asyncio
import asyncpg
import csv
import os
from dotenv import load_dotenv

load_dotenv("paw_api/.env")

DATABASE_URL = os.getenv("DATABASE_URL")

async def export_table(conn, query, filename):
    print(f"Exporting to {filename}...")
    try:
        # Fetch rows
        rows = await conn.fetch(query)
        if not rows:
            print(f"  Warning: No data for {filename}")
            return

        # Get headers
        headers = rows[0].keys()

        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            for row in rows:
                writer.writerow(row.values())
        print(f"  Done. ({len(rows)} rows)")
    except Exception as e:
        print(f"  Error exporting {filename}: {e}")

async def main():
    if not DATABASE_URL:
        print("Error: DATABASE_URL not found.")
        return

    print("Connecting to DB...")
    try:
        conn = await asyncpg.connect(DATABASE_URL)
    except Exception as e:
        print(f"Connection failed: {e}")
        return

    # 1. perros.csv
    await export_table(conn, 
        "SELECT * FROM paw.stg_mascota WHERE LOWER(especie) = 'perro'", 
        "perros.csv")

    # 2. gatos.csv
    await export_table(conn, 
        "SELECT * FROM paw.stg_mascota WHERE LOWER(especie) = 'gato'", 
        "gatos.csv")

    # 3. cat_entidad_federativa.csv
    await export_table(conn, 
        "SELECT * FROM sepomex.estado", 
        "cat_entidad_federativa.csv")
        
    # 4. sepomex_base.csv
    await export_table(conn, 
        "SELECT * FROM sepomex.codigos", 
        "sepomex_base.csv")

    await conn.close()

if __name__ == "__main__":
    asyncio.run(main())
