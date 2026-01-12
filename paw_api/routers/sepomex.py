from fastapi import APIRouter, Depends, HTTPException
from ..database import get_db_conn
from ..config import SEPOMEX_SCHEMA

router = APIRouter(prefix="/api/sepomex", tags=["sepomex"])

@router.get("/cp/{cp}")
async def sepomex_cp(cp: str, conn=Depends(get_db_conn)):
    cp = cp.strip()
    if len(cp) != 5:
        raise HTTPException(status_code=400, detail="CP inválido")

    rows = await conn.fetch(
        f"""
        SELECT
          c.codigo_postal,
          c.asentamiento,
          c.tipo_asentamiento,
          c.municipio,
          c.ciudad,
          e.entidad_federativa AS estado
        FROM {SEPOMEX_SCHEMA}.codigos c
        JOIN {SEPOMEX_SCHEMA}.estado e
          ON e.entidad_id = c.entidad_id
        WHERE c.codigo_postal = $1
        ORDER BY c.asentamiento
        """,
        cp
    )

    if not rows:
        return {"found": False, "cp": cp, "items": []}

    items = [dict(r) for r in rows]
    return {
        "found": True,
        "cp": cp,
        "estado": items[0]["estado"],
        "municipio": items[0]["municipio"],
        "items": items
    }
