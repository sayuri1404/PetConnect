import asyncio
from paw_api.database import init_db, close_db, get_db_conn
# from paw_api.utils import hash_password 

from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

async def reset():
    await init_db()
    conn_gen = get_db_conn()
    conn = await anext(conn_gen)
    
    email = "fundacion1@pawrescue.com"
    new_pass = "1234"
    hashed = pwd_context.hash(new_pass)
    
    try:
        await conn.execute(
            "UPDATE paw.usuario_auth SET password_hash = $1 WHERE email = $2",
            hashed, email
        )
        print(f"Password for {email} reset to '{new_pass}'")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await close_db()

if __name__ == "__main__":
    asyncio.run(reset())
