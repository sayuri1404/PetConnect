from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime, date
from ..database import get_db_conn
from ..config import PAW_SCHEMA
from .auth import require_role, get_current_user

router = APIRouter(tags=["donaciones"])

class DonationIn(BaseModel):
    id_fundacion: int
    amount: float
    message: Optional[str] = None
    donor_name: Optional[str] = None
    donor_email: Optional[EmailStr] = None

@router.get("/api/fundaciones")
async def fundaciones(conn=Depends(get_db_conn)):
    rows = await conn.fetch(
        f"SELECT * FROM {PAW_SCHEMA}.fundacion ORDER BY 1"
    )
    # Convertimos los valores a dict
    return {"fundaciones": [dict(r) for r in rows]}

@router.post("/api/donaciones")
async def crear_donacion(payload: DonationIn, user=Depends(get_current_user), conn=Depends(get_db_conn)):
    if payload.amount <= 0:
        raise HTTPException(status_code=400, detail="Monto inválido")

    id_adoptante = None
    if user and user.get("rol") == "adoptante":
        id_adoptante = int(user["id_adoptante"])

    # Insert flexible
    cols = await conn.fetch(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema=$1 AND table_name='donacion'
        """,
        PAW_SCHEMA
    )
    allowed = {r["column_name"] for r in cols}

    data = {
        "id_fundacion": payload.id_fundacion,
        "monto": payload.amount,
        "mensaje": payload.message,
        "donador_nombre": payload.donor_name,
        "donador_email": str(payload.donor_email) if payload.donor_email else None,
        "id_donador": id_adoptante, # mapeo id_adoptante -> id_donador si tabla lo usa así
        "created_at": datetime.now(),
    }

    # Filtramos solo columnas que existen en la tabla real
    clean = {k: v for k, v in data.items() if k in allowed and v is not None}

    if not clean:
        raise HTTPException(status_code=500, detail="Error mapeando columnas de donacion")

    keys = list(clean.keys())
    vals = [clean[k] for k in keys]
    params = ",".join([f"${i+1}" for i in range(len(vals))])
    cols_sql = ",".join(keys)

    await conn.execute(
        f"INSERT INTO {PAW_SCHEMA}.donacion ({cols_sql}) VALUES ({params})",
        *vals
    )
    return {"ok": True}

@router.get("/api/fundacion/donaciones")
async def ver_donaciones_fundacion(user=Depends(require_role("fundacion")), conn=Depends(get_db_conn)):
    id_f = int(user["id_fundacion"])
    rows = await conn.fetch(
        f"SELECT * FROM {PAW_SCHEMA}.donacion WHERE id_fundacion=$1 ORDER BY 1 DESC",
        id_f
    )
    return {"donaciones": [dict(r) for r in rows]}

@router.get("/api/donaciones/mis")
async def mis_donaciones(user=Depends(require_role("adoptante")), conn=Depends(get_db_conn)):
    # Si la tabla donacion tiene id_donador apuntando a adoptante, usamos eso
    id_ad = int(user["id_adoptante"])
    
    # Revisamos si existe columna id_donador
    cols = await conn.fetch(
        f"SELECT column_name FROM information_schema.columns WHERE table_schema='{PAW_SCHEMA}' AND table_name='donacion'"
    )
    col_names = [c["column_name"] for c in cols]
    
    where_col = "id_donador" if "id_donador" in col_names else "id_adoptante"
    
    if where_col not in col_names:
         return {"donaciones": []}

    rows = await conn.fetch(
        f"SELECT * FROM {PAW_SCHEMA}.donacion WHERE {where_col}=$1 ORDER BY 1 DESC",
        id_ad
    )
    return {"donaciones": [dict(r) for r in rows]}
