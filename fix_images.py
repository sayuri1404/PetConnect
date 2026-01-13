import asyncio
import asyncpg
import random

# Correct URL from paw_api/.env
DATABASE_URL = "postgresql://paw_admin:paw_pass@localhost:5433/paw_rescue"

async def fix_images():
    try:
        print(f"Connecting to {DATABASE_URL}...")
        conn = await asyncpg.connect(DATABASE_URL)
        
        # Get all pets
        rows = await conn.fetch('SELECT id_mascota, especie_id FROM paw.mascota_rescatada')
        print(f"Updating {len(rows)} pets...")
        
        for r in rows:
            mid = r['id_mascota']
            eid = r['especie_id']
            
            # Generate new URL
            if eid == 1: # Dog
                # Use placedog.net with ID for consistency
                # Use a random ID between 1 and 200 to get variety
                rand_id = random.randint(1, 200)
                new_url = f"https://placedog.net/400/225?id={rand_id}"
            elif eid == 2: # Cat
                # Use loremflickr for cats (placekitten is sometimes down)
                # Add a random param to avoid browser caching same image
                new_url = f"https://loremflickr.com/400/225/cat?lock={mid}"
            else:
                new_url = f"https://loremflickr.com/400/225/animal?lock={mid}"
                
            await conn.execute("UPDATE paw.mascota_rescatada SET url_foto = $1 WHERE id_mascota = $2", new_url, mid)
            
        print("All pet images updated to valid placeholders.")
        await conn.close()
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    asyncio.run(fix_images())
