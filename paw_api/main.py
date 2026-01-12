from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import init_db, close_db
from .routers import auth, mascotas, solicitudes, donaciones, perfil, sepomex, citas, lista_negra, rescates, fundacion

# =====================
# APP
# =====================
app = FastAPI(title="Paw Rescue API", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Startup / Shutdown
@app.on_event("startup")
async def startup():
    await init_db()

@app.on_event("shutdown")
async def shutdown():
    await close_db()

# Include Routers
app.include_router(auth.router)
app.include_router(mascotas.router)
app.include_router(solicitudes.router)
app.include_router(donaciones.router)
app.include_router(perfil.router)
app.include_router(sepomex.router)
app.include_router(citas.router)
app.include_router(lista_negra.router)
app.include_router(rescates.router)
app.include_router(fundacion.router)

@app.get("/")
def root():
    return {"message": "Paw Rescue API is running"}
# touched to force reload