from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from datetime import date
from ..database import get_db_conn

router = APIRouter(prefix="/api/lista-negra", tags=["lista-negra"])

# --- Models ---
class ListaNegraCreate(BaseModel):
    nombre_duenio: str
    motivo: str
    fecha_inicio: date
    tipo: str # temporal / definitiva (frontend) -> mapped to es_permanente

class ListaNegraOut(BaseModel):
    id_lista: int
    nombre_duenio: str
    motivo: str
    inicio: date
    es_permanente: bool

# --- Endpoints ---

@router.post("/", response_model=ListaNegraOut)
async def add_to_blacklist(entry: ListaNegraCreate, conn=Depends(get_db_conn)):
    # 1. Buscar o crear dueño (paw.duenio)
    # Intentamos buscar exact match por nombre para simplificar
    row_duenio = await conn.fetchrow("SELECT id_duenio FROM paw.duenio WHERE nombre = $1", entry.nombre_duenio)
    
    if row_duenio:
        id_duenio = row_duenio['id_duenio']
    else:
        # Crear dummy duenio si no existe (solo nombre)
        id_duenio = await conn.fetchval(
            "INSERT INTO paw.duenio (nombre, identificacion) VALUES ($1, 'SIN-ID') RETURNING id_duenio",
            entry.nombre_duenio
        )

    # 2. Insertar en lista negra
    es_permanente = (entry.tipo == 'definitiva')
    
    row = await conn.fetchrow("""
        INSERT INTO paw.lista_negra (id_duenio, motivo, inicio, es_permanente)
        VALUES ($1, $2, $3, $4)
        RETURNING id_lista, id_duenio, motivo, inicio, es_permanente
    """, id_duenio, entry.motivo, entry.fecha_inicio, es_permanente)
    
    # Construir respuesta
    return ListaNegraOut(
        id_lista=row['id_lista'],
        nombre_duenio=entry.nombre_duenio,
        motivo=row['motivo'],
        inicio=row['inicio'],
        es_permanente=row['es_permanente']
    )

@router.get("/", response_model=List[ListaNegraOut])
async def get_blacklist(conn=Depends(get_db_conn)):
    rows = await conn.fetch("""
        SELECT l.id_lista, d.nombre as nombre_duenio, l.motivo, l.inicio, l.es_permanente
        FROM paw.lista_negra l
        JOIN paw.duenio d ON l.id_duenio = d.id_duenio
        ORDER BY l.inicio DESC
    """)
    return [
        ListaNegraOut(
            id_lista=r['id_lista'],
            nombre_duenio=r['nombre_duenio'],
            motivo=r['motivo'],
            inicio=r['inicio'],
            es_permanente=r['es_permanente']
        ) for r in rows
    ]
