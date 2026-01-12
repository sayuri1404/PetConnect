from fastapi import APIRouter, HTTPException, Depends, Header
from pydantic import BaseModel, EmailStr
from typing import Optional, Dict, Any
import secrets
from passlib.context import CryptContext
from ..database import get_db_conn
from ..config import PAW_SCHEMA

router = APIRouter(prefix="/api/auth", tags=["auth"])

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# token -> payload
# En prod usar Redis o JWT stateless
TOKENS: Dict[str, Dict[str, Any]] = {}

# =====================
# MODELS
# =====================
class RegisterFundacionIn(BaseModel):
    nombre: str
    email: EmailStr
    telefono: Optional[str] = None
    rfc: Optional[str] = None
    password: str

class RegisterAdoptanteIn(BaseModel):
    nombre: str
    email: EmailStr
    telefono: Optional[str] = None
    password: str

class LoginIn(BaseModel):
    email: EmailStr
    password: str

# =====================
# HELPERS
# =====================
def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

async def require_user(authorization: Optional[str] = Header(None)):
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Token")
    token = authorization.split(" ", 1)[1].strip() if " " in authorization else authorization
    if token not in TOKENS:
        raise HTTPException(status_code=401, detail="Invalid Token")
    return TOKENS[token]

def require_role(role: str):
    async def dependency(user=Depends(require_user)):
        if user["rol"] != role:
            raise HTTPException(status_code=403, detail="Permisos insuficientes")
        return user
    return dependency

# Alias para compatibilidad
get_current_user = require_user

# ... (Previous models)

# ... (Previous helpers)

# =====================
# ROUTES
# =====================
@router.post("/register-adoptante")
async def register_adoptante(payload: RegisterAdoptanteIn, conn=Depends(get_db_conn)):
    # 1) email único en usuario_auth
    exists = await conn.fetchrow(
        f"SELECT 1 FROM {PAW_SCHEMA}.usuario_auth WHERE email=$1",
        payload.email.lower()
    )
    if exists:
        raise HTTPException(status_code=400, detail="Email ya registrado")

    # 2) crear adoptante
    row_ad = await conn.fetchrow(
        f"INSERT INTO {PAW_SCHEMA}.adoptante (nombre, telefono, email) "
        "VALUES ($1,$2,$3) RETURNING id_adoptante",
        payload.nombre,
        payload.telefono,
        payload.email.lower()
    )
    if not row_ad:
        raise HTTPException(status_code=500, detail="No se pudo crear adoptante")

    id_adoptante = int(row_ad["id_adoptante"])

    # 3) crear usuario_auth con rol adoptante
    pw_hash = hash_password(payload.password)

    row_u = await conn.fetchrow(
        f"INSERT INTO {PAW_SCHEMA}.usuario_auth (email, password_hash, rol, id_adoptante, created_at) "
        "VALUES ($1,$2,'adoptante',$3, now()) RETURNING id_usuario, rol, id_adoptante, id_fundacion",
        payload.email.lower(), pw_hash, id_adoptante
    )

    token = secrets.token_urlsafe(32)
    TOKENS[token] = {
        "id_usuario": int(row_u["id_usuario"]),
        "email": payload.email.lower(),
        "rol": row_u["rol"],
        "id_adoptante": row_u["id_adoptante"],
        "id_fundacion": row_u["id_fundacion"],
    }

    return {"token": token, "user": TOKENS[token]}

@router.post("/register-fundacion")
async def register_fundacion(payload: RegisterFundacionIn, conn=Depends(get_db_conn)):
    # 1) email único
    exists = await conn.fetchrow(
        f"SELECT 1 FROM {PAW_SCHEMA}.usuario_auth WHERE email=$1",
        payload.email.lower()
    )
    if exists:
        raise HTTPException(status_code=400, detail="Email ya registrado")

    # 2) crear fundacion
    # La tabla paw.fundacion tiene: id_fundacion, nombre, email, telefono, rfc
    row_fun = await conn.fetchrow(
        f"INSERT INTO {PAW_SCHEMA}.fundacion (nombre, email, telefono, rfc) "
        "VALUES ($1,$2,$3,$4) RETURNING id_fundacion",
        payload.nombre,
        payload.email.lower(),
        payload.telefono,
        payload.rfc
    )
    if not row_fun:
        raise HTTPException(status_code=500, detail="No se pudo crear fundación")

    id_fundacion = int(row_fun["id_fundacion"])

    # 3) crear usuario_auth con rol fundacion
    pw_hash = hash_password(payload.password)

    row_u = await conn.fetchrow(
        f"INSERT INTO {PAW_SCHEMA}.usuario_auth (email, password_hash, rol, id_fundacion, created_at) "
        "VALUES ($1,$2,'fundacion',$3, now()) RETURNING id_usuario, rol, id_adoptante, id_fundacion",
        payload.email.lower(), pw_hash, id_fundacion
    )

    token = secrets.token_urlsafe(32)
    TOKENS[token] = {
        "id_usuario": int(row_u["id_usuario"]),
        "email": payload.email.lower(),
        "rol": row_u["rol"],
        "id_adoptante": row_u["id_adoptante"],
        "id_fundacion": row_u["id_fundacion"],
    }

    return {"token": token, "user": TOKENS[token]}

@router.post("/login")
async def login(payload: LoginIn, conn=Depends(get_db_conn)):
    row = await conn.fetchrow(
        f"SELECT id_usuario, email, password_hash, rol, id_adoptante, id_fundacion "
        f"FROM {PAW_SCHEMA}.usuario_auth WHERE email=$1",
        payload.email.lower()
    )
    if not row or not verify_password(payload.password, row["password_hash"]):
        raise HTTPException(status_code=401, detail="Credenciales inválidas")

    token = secrets.token_urlsafe(32)
    TOKENS[token] = {
        "id_usuario": int(row["id_usuario"]),
        "email": row["email"],
        "rol": row["rol"],
        "id_adoptante": row["id_adoptante"],
        "id_fundacion": row["id_fundacion"],
    }
    return {"token": token, "user": TOKENS[token]}

@router.get("/me")
async def me(user=Depends(require_user)):
    return {"user": user}

@router.post("/logout")
async def logout(user=Depends(require_user), authorization: Optional[str] = Header(None)):
    token = authorization.split(" ", 1)[1].strip()
    TOKENS.pop(token, None)
    return {"ok": True}
