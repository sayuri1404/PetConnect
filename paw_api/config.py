import os
from dotenv import load_dotenv

# Cargar .env explícitamente desde la carpeta actual o paw_api/
load_dotenv(dotenv_path="paw_api/.env")
# Fallback si se corre desde dentro de paw_api
load_dotenv()

# =====================
# CONFIG
# =====================
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://paw_admin:tu_password@localhost:5433/paw_rescue"
)

PAW_SCHEMA = "paw"
SEPOMEX_SCHEMA = "sepomex"
