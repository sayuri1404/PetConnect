import asyncpg
from fastapi import HTTPException
from .config import DATABASE_URL, PAW_SCHEMA, SEPOMEX_SCHEMA

pool: asyncpg.Pool | None = None

async def init_db():
    global pool
    # fijamos search_path a paw,sepomex para no escribir schema todo el tiempo si se desea,
    # aunque en los queries usaremos explicitamente los nombres para claridad.
    pool = await asyncpg.create_pool(
        DATABASE_URL,
        server_settings={"search_path": f"{PAW_SCHEMA},{SEPOMEX_SCHEMA},public"}
    )

async def close_db():
    global pool
    if pool:
        await pool.close()

async def get_db_conn():
    if not pool:
        raise HTTPException(status_code=500, detail="DB pool not ready")
    async with pool.acquire() as conn:
        yield conn
