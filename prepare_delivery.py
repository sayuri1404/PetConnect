
import os
import re
import tarfile
import shutil

# Config
SOURCE_DIR = os.path.dirname(os.path.abspath(__file__))
SQL_FILES = [
    "paw_rescue_data1/Vacunas_editado1.sql",
    "paw_api/create_auth_tables.sql",
    "paw_rescue_data1/domicilios.sql",
    "paw_rescue_data1/paw.sql",
    "paw_rescue_data1/paw_fundacion.sql",
    "paw_rescue_data1/paw_adopciones.sql"
]

OUTPUT_DIR = os.path.join(SOURCE_DIR, "Entregables")
DB_DIR = os.path.join(OUTPUT_DIR, "Base de Datos")
SYSTEM_DIR = os.path.join(OUTPUT_DIR, "Sistema")
ENV_DIR = os.path.join(OUTPUT_DIR, "Entorno de desarrollo y producción")

# Regex to detect command type in a clean statement (no comments)
DDL_REGEX = re.compile(r'^\s*(CREATE|ALTER|DROP|COMMENT|DO|DECLARE|BEGIN|COMMIT|ROLLBACK|SET|TRUNCATE)', re.IGNORECASE)
DML_REGEX = re.compile(r'^\s*(INSERT|UPDATE|DELETE|COPY|WITH)', re.IGNORECASE)

def get_sql_chunks(content):
    """
    Splits SQL content by semicolon, respecting quotes and comments.
    Preserves the comments and whitespace within the chunk.
    """
    chunks = []
    chunk = []
    in_quote = False
    quote_char = ''
    in_comment_line = False
    in_comment_block = False
    
    i = 0
    n = len(content)
    while i < n:
        char = content[i]
        next_char = content[i+1] if i+1 < n else ''
        
        chunk.append(char)
        
        if in_comment_line:
            if char == '\n':
                in_comment_line = False
        elif in_comment_block:
            if char == '*' and next_char == '/':
                in_comment_block = False
                chunk.append('/') # Complete the delimiter
                i += 1 
        elif in_quote:
            if char == quote_char:
                # Check for escape (doubling)
                if next_char == quote_char:
                    chunk.append(quote_char)
                    i += 1
                else:
                    in_quote = False
        else:
            # Check delimiters
            if char == '-' and next_char == '-':
                in_comment_line = True
                chunk.append('-') # Consume next
                i += 1
            elif char == '/' and next_char == '*':
                in_comment_block = True
                chunk.append('*') # Consume next
                i += 1
            elif char == "'" or char == '"':
                in_quote = True
                quote_char = char
            elif char == ';':
                # End of statement
                chunks.append("".join(chunk))
                chunk = []
        
        i += 1
    
    if chunk:
        remaining = "".join(chunk).strip()
        if remaining:
            chunks.append("".join(chunk))
            
    return chunks

def split_sqls():
    # if os.path.exists(OUTPUT_DIR):
    #     shutil.rmtree(OUTPUT_DIR)
    
    os.makedirs(DB_DIR, exist_ok=True)
    os.makedirs(SYSTEM_DIR, exist_ok=True)
    os.makedirs(ENV_DIR, exist_ok=True)
    os.makedirs(SYSTEM_DIR, exist_ok=True)
    os.makedirs(ENV_DIR, exist_ok=True)

    ddl_path = os.path.join(DB_DIR, "basededatos.sql")
    dml_path = os.path.join(DB_DIR, "datos.sql")

    print(f"Generating {ddl_path} and {dml_path}...")

    with open(ddl_path, 'w', encoding='utf-8') as f_ddl, \
         open(dml_path, 'w', encoding='utf-8') as f_dml:
        
        f_dml.write("SET search_path TO paw, vacunas, sepomex, public;\n\n")

        for relative_path in SQL_FILES:
            full_path = os.path.join(SOURCE_DIR, relative_path)
            print(f"Processing {relative_path}...")
            
            # Simple header
            header = f"\n-- =============================================\n-- SOURCE: {os.path.basename(relative_path)}\n-- =============================================\n\n"
            f_ddl.write(header)
            f_dml.write(header)

            try:
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                chunks = get_sql_chunks(content)
                
                for chunk in chunks:
                    # Logic to identify if it is DDL or DML
                    clean = chunk
                    clean = re.sub(r'--.*', '', clean)
                    clean = re.sub(r'/\*.*?\*/', '', clean, flags=re.DOTALL)
                    clean = clean.strip()
                    
                    if not clean:
                         # Comment only or empty
                         # We default to DDL to preserve documentation flow in basededatos.sql
                         # But if the comment belongs to an INSERT section...
                         # Usually 1FN/2FN comments are creates.
                         f_ddl.write(chunk)
                         continue
                    
                    if DML_REGEX.match(clean):
                        f_dml.write(chunk)
                    else:
                        f_ddl.write(chunk)
                        
            except Exception as e:
                print(f"Error reading {full_path}: {e}")

def create_readme():
    readme_path = os.path.join(ENV_DIR, "DataSphere_petconnect.md")
    content = """# DataSphere PetConnect - Entregable Final

## Descripción del Proyecto
Sistema de gestión para la adopción y rescate de mascotas (PetConnect). Incluye API REST (FastAPI), Base de Datos (PostgreSQL) y documentación técnica.

## Estructura del Entregable
1.  **Base de Datos/**
    - `basededatos.sql`: Script DDL. Crea esquemas (`paw`, `vacunas`, `sepomex`), tablas y restricciones. Incluye documentación de normalización.
    - `datos.sql`: Script DML. Carga masiva de datos de prueba y catálogos.
2.  **Sistema/**
    - `sistema.tgz`: Código fuente completo del proyecto, incluyendo archivos CSV de datos fuente.

---

## Guía de Instalación y Ejecución

### 1. Requisitos Previos
- **Python**: Versión 3.9 o superior.
- **PostgreSQL**: Versión 14 o superior.
- **Terminal/Consola**: Bash o PowerShell.

### 2. Configuración de Base de Datos
1.  Abra su herramienta de administración de PostgreSQL (pgAdmin, DBeaver o psql).
2.  Cree una nueva base de datos llamada `petconnect` (u otro nombre de su preferencia).
3.  **Restaurar Estructura**: Ejecute el script `basededatos.sql`.
    ```bash
    psql -U su_usuario -d petconnect -f "Entregables/Base de Datos/basededatos.sql"
    ```
4.  **Cargar Datos**: Ejecute el script `datos.sql`.
    ```bash
    psql -U su_usuario -d petconnect -f "Entregables/Base de Datos/datos.sql"
    ```

### 3. Configuración del Sistema (Backend)
1.  **Descomprimir**: Extraiga el archivo `sistema.tgz` en una carpeta de trabajo.
    ```bash
    tar -xzAOf "Entregables/Sistema/sistema.tgz" | tar -x
    # O simplemente descomprimir con su herramienta favorita
    cd petconnect
    ```

2.  **Entorno Virtual** (Recomendado):
    ```bash
    python3 -m venv venv
    source venv/bin/activate  # En Windows: venv\\Scripts\\activate
    ```

3.  **Instalar Dependencias**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configurar Variables de Entorno**:
    - El archivo `.env` ya se incluye en `paw_api/.env` para facilitar las pruebas.
    - **Importante**: Abra `paw_api/.env` y verifique que `DATABASE_URL` coincida con sus credenciales locales.
    - Ejemplo: `DATABASE_URL=postgresql://usuario:password@localhost:5432/petconnect`

### 4. Ejecución del Backend
Desde la raíz de la carpeta descomprimida (`petconnect/`):

```bash
uvicorn paw_api.main:app --reload
```

- Si el servidor arranca correctamente, verá: `Application startup complete`.
- Acceda a la documentación interactiva en: **http://127.0.0.1:8000/docs**

### 5. Ejecución del Frontend
1.  Asegúrese de que el Backend esté ejecutándose en el puerto 8000.
2.  Busque el archivo `pet1.html` en la carpeta raíz.
3.  Simplemente haga doble clic en `pet1.html` para abrirlo en su navegador web favorito (Chrome, Firefox, Safari).
    - La interfaz web se conectará automáticamente con la API local (vía `pet3.js`).

## Archivos Fuente CSV
Los archivos CSV originales (`perros.csv`, `gatos.csv`, etc.) se encuentran en la raíz del código fuente descomprimido, como referencia de los datos cargados.
"""
    with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(content)

def package_system():
    tgz_path = os.path.join(SYSTEM_DIR, "sistema.tgz")
    def filter_files(tarinfo):
        exclude = ['.git', '__pycache__', 'node_modules', '.DS_Store', 'venv', 'Entregables']
        for exc in exclude:
            if exc in tarinfo.name:
                return None
        return tarinfo
    
    csv_additions = ["perros.csv", "gatos.csv", "cat_entidad_federativa.csv", "sepomex_base.csv"]
    
    with tarfile.open(tgz_path, "w:gz") as tar:
        # 1. Add project source
        tar.add(SOURCE_DIR, arcname="petconnect", filter=filter_files)
        
        # 2. Add requested CSVs (look in SYSTEM_DIR or SOURCE_DIR)
        print("Adding CSVs to archive...")
        for csv in csv_additions:
            # Check in Entregables/Sistema (likely location)
            sys_csv = os.path.join(SYSTEM_DIR, csv)
            src_csv = os.path.join(SOURCE_DIR, csv)
            
            target_path = None
            if os.path.exists(sys_csv):
                target_path = sys_csv
            elif os.path.exists(src_csv):
                target_path = src_csv
            
            if target_path:
                print(f"  Adding {csv}")
                tar.add(target_path, arcname=f"petconnect/{csv}")
            else:
                print(f"  Warning: {csv} not found.")

if __name__ == "__main__":
    split_sqls()
    create_readme()
    package_system()
    print("Done.")
