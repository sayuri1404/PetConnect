from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from ..database import get_db_conn

router = APIRouter(prefix="/api/fundacion", tags=["fundacion"])

# --- Models ---
class EmpleadoCreate(BaseModel):
    nombre: str
    puesto: str
    area: Optional[str] = None # Para cuidadores
    turno: Optional[str] = None # Para cuidadores

class EmpleadoOut(BaseModel):
    id_empleado: int
    nombre: str
    puesto: str
    is_cuidador: bool
    area: Optional[str]
    turno: Optional[str]

# --- Endpoints ---

@router.post("/empleados", response_model=EmpleadoOut)
async def register_empleado(empleado: EmpleadoCreate, conn=Depends(get_db_conn)):
    # 1. Insertar en tabla empleados
    row_emp = await conn.fetchrow("""
        INSERT INTO paw.empleados (nombre, puesto)
        VALUES ($1, $2)
        RETURNING id_empleado, nombre, puesto
    """, empleado.nombre, empleado.puesto)
    
    id_emp = row_emp['id_empleado']
    is_cuidador = False
    area = None
    turno = None

    # 2. Si es cuidador (check puesto), insertar en cuidadores
    # Asumimos que si el puesto contiene "Cuidador", lo agregamos a la tabla especializada
    if "cuidador" in empleado.puesto.lower():
        if not empleado.area or not empleado.turno:
                # Default values if missing suitable for logic
                empleado.area = empleado.area or "General"
                empleado.turno = empleado.turno or "Matutino"
        
        await conn.execute("""
            INSERT INTO paw.cuidadores (id_empleado, area, turno)
            VALUES ($1, $2, $3)
        """, id_emp, empleado.area, empleado.turno)
        is_cuidador = True
        area = empleado.area
        turno = empleado.turno

    return EmpleadoOut(
        id_empleado=id_emp,
        nombre=row_emp['nombre'],
        puesto=row_emp['puesto'],
        is_cuidador=is_cuidador,
        area=area,
        turno=turno
    )

@router.get("/empleados", response_model=List[EmpleadoOut])
async def list_empleados(conn=Depends(get_db_conn)):
    # Left join para traer info de cuidador si existe
    rows = await conn.fetch("""
        SELECT e.id_empleado, e.nombre, e.puesto, c.area, c.turno
        FROM paw.empleados e
        LEFT JOIN paw.cuidadores c ON e.id_empleado = c.id_empleado
        ORDER BY e.id_empleado DESC
    """)
    
    results = []
    for r in rows:
        results.append(EmpleadoOut(
            id_empleado=r['id_empleado'],
            nombre=r['nombre'],
            puesto=r['puesto'],
            is_cuidador=(r['area'] is not None),
            area=r['area'],
            turno=r['turno']
        ))
    return results
