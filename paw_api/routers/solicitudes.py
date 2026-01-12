from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import date
from ..database import get_db_conn
from ..config import PAW_SCHEMA
from .auth import require_role

router = APIRouter(tags=["solicitudes"])

class SolicitudIn(BaseModel):
    id_mascota: int
    message: Optional[str] = None

class RechazoIn(BaseModel):
    motivo: str

@router.post("/api/solicitudes")
async def crear_solicitud(payload: SolicitudIn, user=Depends(require_role("adoptante")), conn=Depends(get_db_conn)):
    id_ad = int(user["id_adoptante"])
    id_mascota = payload.id_mascota

    # Verificar mascota a veces necesitamos asignar fundacion tambien si la tabla lo requiere
    pet = await conn.fetchrow(
        f"SELECT * FROM {PAW_SCHEMA}.mascota_rescatada WHERE id_mascota=$1",
        id_mascota
    )
    if not pet:
        raise HTTPException(status_code=404, detail="Mascota no encontrada")

    # En el SQL paw_adopciones.sql la tabla solicitud_adopcion tiene id_fundacion
    # Intentamos deducir si existe en mascota o asignar NULL
    id_fundacion = pet.get("id_fundacion") # Puede ser None si mascota no tiene columna

    # Evita duplicadas activas
    dup = await conn.fetchrow(
        f"""
        SELECT 1 FROM {PAW_SCHEMA}.solicitud_adopcion
        WHERE id_adoptante=$1 AND id_mascota=$2 AND estado IN ('pendiente','aprobada','en_revision')
        """,
        id_ad, id_mascota
    )
    if dup:
        raise HTTPException(status_code=400, detail="Ya tienes una solicitud activa para esta mascota")

    row = await conn.fetchrow(
        f"""
        INSERT INTO {PAW_SCHEMA}.solicitud_adopcion
        (id_adoptante, id_mascota, fecha_solicitud, estado, motivo_rechazo, id_fundacion)
        VALUES ($1,$2,$3,'pendiente', NULL, $4)
        RETURNING id_solicitud
        """,
        id_ad, id_mascota, date.today(), id_fundacion
    )
    return {"ok": True, "id_solicitud": int(row["id_solicitud"])}

@router.get("/api/solicitudes/mis")
async def mis_solicitudes(user=Depends(require_role("adoptante")), conn=Depends(get_db_conn)):
    id_ad = int(user["id_adoptante"])
    rows = await conn.fetch(
        f"SELECT * FROM {PAW_SCHEMA}.solicitud_adopcion WHERE id_adoptante=$1 ORDER BY id_solicitud DESC",
        id_ad
    )
    return {"solicitudes": [dict(r) for r in rows]}

@router.get("/api/fundacion/solicitudes")
async def fundacion_solicitudes(user=Depends(require_role("fundacion")), conn=Depends(get_db_conn)):
    id_f = int(user["id_fundacion"])
    rows = await conn.fetch(
        f"""
        SELECT * FROM {PAW_SCHEMA}.solicitud_adopcion
        WHERE id_fundacion=$1
        ORDER BY id_solicitud DESC
        """,
        id_f
    )
    return {"solicitudes": [dict(r) for r in rows]}

@router.post("/api/fundacion/solicitudes/{id_solicitud}/aprobar")
async def aprobar_solicitud(id_solicitud: int, user=Depends(require_role("fundacion")), conn=Depends(get_db_conn)):
    id_f = int(user["id_fundacion"])
    req = await conn.fetchrow(
        f"SELECT * FROM {PAW_SCHEMA}.solicitud_adopcion WHERE id_solicitud=$1 AND id_fundacion=$2",
        id_solicitud, id_f
    )
    if not req:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    await conn.execute(
        f"UPDATE {PAW_SCHEMA}.solicitud_adopcion SET estado='aprobada' WHERE id_solicitud=$1",
        id_solicitud
    )
    return {"ok": True}

@router.post("/api/fundacion/solicitudes/{id_solicitud}/rechazar")
async def rechazar_solicitud(id_solicitud: int, payload: RechazoIn, user=Depends(require_role("fundacion")), conn=Depends(get_db_conn)):
    id_f = int(user["id_fundacion"])
    req = await conn.fetchrow(
        f"SELECT * FROM {PAW_SCHEMA}.solicitud_adopcion WHERE id_solicitud=$1 AND id_fundacion=$2",
        id_solicitud, id_f
    )
    if not req:
        raise HTTPException(status_code=404, detail="Solicitud no encontrada")

    await conn.execute(
        f"UPDATE {PAW_SCHEMA}.solicitud_adopcion SET estado='rechazada', motivo_rechazo=$2 WHERE id_solicitud=$1",
        id_solicitud, payload.motivo
    )
    return {"ok": True}
