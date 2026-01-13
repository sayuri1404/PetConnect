# DataSphere PetConnect - Entregable Final

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
    source venv/bin/activate  # En Windows: venv\Scripts\activate
    ```

3.  **Instalar Dependencias**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configurar Variables de Entorno**:
    - El archivo `.env` ya se incluye en `paw_api/.env` para facilitar las pruebas.
    - **Importante**: Abra `paw_api/.env` y verifique que `DATABASE_URL` coincida con sus credenciales locales.
    - Ejemplo: `DATABASE_URL=postgresql://usuario:password@localhost:5432/petconnect`

### 4. Ejecución
Desde la raíz de la carpeta descomprimida (`petconnect/`):

```bash
uvicorn paw_api.main:app --reload
```

- Si el servidor arranca correctamente, verá: `Application startup complete`.
- Acceda a la documentación interactiva en: **http://127.0.0.1:8000/docs**

## Archivos Fuente CSV
Los archivos CSV originales (`perros.csv`, `gatos.csv`, etc.) se encuentran en la raíz del código fuente descomprimido, como referencia de los datos cargados.
