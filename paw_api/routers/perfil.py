from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Dict, Any
from ..database import get_db_conn
from ..config import PAW_SCHEMA
from .auth import require_role

router = APIRouter(prefix="/api/adoptante/perfil", tags=["perfil"])

class PerfilIn(BaseModel):
    data: Dict[str, Any]

@router.get("")
async def get_perfil(user=Depends(require_role("adoptante")), conn=Depends(get_db_conn)):
    id_ad = int(user["id_adoptante"])
    row = await conn.fetchrow(
        f"SELECT * FROM {PAW_SCHEMA}.adoptante_perfil WHERE id_adoptante=$1",
        id_ad
    )
    return {"perfil": dict(row) if row else None}

@router.post("")
async def upsert_perfil(payload: PerfilIn, user=Depends(require_role("adoptante")), conn=Depends(get_db_conn)):
    id_ad = int(user["id_adoptante"])
    data = payload.data or {}

    cols = await conn.fetch(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema=$1 AND table_name='adoptante_perfil'
        """,
        PAW_SCHEMA
    )
    allowed = {r["column_name"] for r in cols}
    data["id_adoptante"] = id_ad

    clean = {k: v for k, v in data.items() if k in allowed}

    if "id_adoptante" not in clean:
        raise HTTPException(status_code=500, detail="Tabla adoptante_perfil no tiene id_adoptante")

    exists = await conn.fetchrow(
        f"SELECT 1 FROM {PAW_SCHEMA}.adoptante_perfil WHERE id_adoptante=$1",
        id_ad
    )

    if not exists:
        keys = list(clean.keys())
        vals = [clean[k] for k in keys]
        params = ",".join([f"${i+1}" for i in range(len(vals))])
        cols_sql = ",".join(keys)
        await conn.execute(
            f"INSERT INTO {PAW_SCHEMA}.adoptante_perfil ({cols_sql}) VALUES ({params})",
            *vals
        )
    else:
        keys = [k for k in clean.keys() if k != "id_adoptante"]
        vals = [clean[k] for k in keys]
        set_sql = ",".join([f"{k}=${i+1}" for i, k in enumerate(keys)])
        await conn.execute(
            f"UPDATE {PAW_SCHEMA}.adoptante_perfil SET {set_sql} WHERE id_adoptante=${len(vals)+1}",
            *vals, id_ad
        )

    return {"ok": True}
