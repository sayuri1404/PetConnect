import asyncio
from paw_api.database import init_db, close_db, get_db_conn
from paw_api.config import PAW_SCHEMA
import os
from dotenv import load_dotenv

load_dotenv("paw_api/.env")

async def inspect():
    await init_db()
    conn_gen = get_db_conn()
    conn = await anext(conn_gen)
    try:
        # Check vacunas.vacuna
        print("Checking vacunas.vacuna...")
        rows = await conn.fetch(
            """
            SELECT column_name, data_type
            FROM information_schema.columns
            WHERE table_schema = 'vacunas' AND table_name = 'vacuna'
            """
        )
        if not rows:
            print("Table vacunas.vacuna NOT FOUND")
        else:
            for r in rows:
                print(f" - {r['column_name']} ({r['data_type']})")
                
    finally:
        await close_db()

if __name__ == "__main__":
    asyncio.run(inspect())
