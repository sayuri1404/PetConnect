import asyncio
import asyncpg

# Correct URL from paw_api/.env
DATABASE_URL = "postgresql://paw_admin:paw_pass@localhost:5433/paw_rescue"

async def check_urls():
    try:
        print(f"Connecting to {DATABASE_URL}...")
        conn = await asyncpg.connect(DATABASE_URL)
        rows = await conn.fetch('SELECT id_mascota, nombre, url_foto FROM paw.mascota_rescatada ORDER BY id_mascota LIMIT 20')
        print(f"Found {len(rows)} pets.")
        for r in rows:
            print(f"ID: {r['id_mascota']} | Name: {r['nombre']} | URL: {r['url_foto']}")
        await conn.close()
    except Exception as e:
        print(f"Connection error: {e}")

if __name__ == "__main__":
    asyncio.run(check_urls())
