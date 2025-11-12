# Sistema Automatizado de Captura de Direcciones SEPOMEX

**Autores:** Herrera Moreno Sayuri y Jiménez Balderas Evelyn Monserrat
**Fecha:** 31 de octubre de 2025

---

## 1. Introducción

El proyecto surge de la problemática observada en distintos formularios utilizados en plataformas internas donde los usuarios debían capturar manualmente información como Estado, Municipio/Alcaldía y Colonia. 

Este documento presenta el desarrollo e implementación del sistema automatizado de captura de direcciones basado en el catálogo oficial de códigos postales del Servicio Postal Mexicano (SEPOMEX). 

### 1.1 Objetivo

Construir una base relacional que estandarice la captura de direcciones y
reduzca errores de tecleo, usando el catálogo oficial de SEPOMEX como base para el autollenado.



## 2. Metodología

El desarrollo del sistema se llevó a cabo siguiendo un enfoque centrado en la obtención, limpieza y estructuración de datos oficiales, así como en el diseño de un modelo lógico que permitiera la autocompletación de direcciones mediante el Código Postal.


## 3.Creación de tablas

### Tabla `cat_estados`
```sql
DROP TABLE IF EXISTS cat_estados CASCADE;

CREATE TABLE cat_estados (
  estado_id INTEGER PRIMARY KEY,
  estado TEXT NOT NULL
);
```

### Tabla `cat_municipios`
```sql
DROP TABLE IF EXISTS cat_municipios CASCADE;

CREATE TABLE cat_municipios (
  municipio_id INTEGER PRIMARY KEY,
  estado_id INTEGER NOT NULL,
  municipio TEXT NOT NULL,
  FOREIGN KEY (estado_id) REFERENCES cat_estados(estado_id)
);
```

### Tabla `cat_asentamientos`
```sql
DROP TABLE IF EXISTS cat_asentamientos CASCADE;

CREATE TABLE cat_asentamientos (
  asentamiento_id INTEGER PRIMARY KEY,
  municipio_id INTEGER NOT NULL,
  asentamiento TEXT NOT NULL,
  FOREIGN KEY (municipio_id) REFERENCES cat_municipios(municipio_id)
);
```

### Tabla `sepomex`
```sql
DROP TABLE IF EXISTS sepomex CASCADE;

CREATE TABLE sepomex (
  id SERIAL PRIMARY KEY,
  codigo_postal TEXT NOT NULL,
  estado_id INTEGER,
  estado TEXT,
  municipio_id INTEGER,
  municipio TEXT,
  asentamiento_id INTEGER,
  asentamiento TEXT,
  tipo_asentamiento TEXT,
  ciudad TEXT
);
```

---

## 3.2. Importación de datos

### En Linux

Conectar a PostgreSQL:
```bash
psql -U tu_usuario -d fundacion
```

Importar los archivos CSV:
```sql
\COPY cat_estados FROM '/home/usuario/ruta/cat_estados.csv' WITH (FORMAT csv, HEADER true);
\COPY cat_municipios FROM '/home/usuario/ruta/cat_municipios.csv' WITH (FORMAT csv, HEADER true);
\COPY cat_asentamientos FROM '/home/usuario/ruta/cat_asentamientos.csv' WITH (FORMAT csv, HEADER true);
\COPY sepomex FROM '/home/usuario/ruta/sepomex_base.csv' WITH (FORMAT csv, HEADER true);
```

### En macOS

Conectar a PostgreSQL:
```bash
psql -U tu_usuario -d sepomex
```

Importar los archivos CSV:
```sql
\COPY cat_estados FROM '/ruta/archivos/cat_estados.csv' WITH (FORMAT csv, HEADER true);
\COPY cat_municipios FROM '/ruta/archivos/cat_municipios.csv' WITH (FORMAT csv, HEADER true);
\COPY cat_asentamientos FROM '/ruta/archivos/cat_asentamientos.csv' WITH (FORMAT csv, HEADER true);
\COPY sepomex FROM '/ruta/archivos/sepomex.csv' WITH (FORMAT csv, HEADER true);
```

**Ejemplos de rutas:**
- Linux: `/home/usuario/proyecto/cat_estados.csv`
- macOS: `/Users/usuario/Documents/proyecto/cat_estados.csv`

---

## 4. Validación de datos cargados

Verificar el número de registros en cada tabla:
```sql
SELECT COUNT(*) FROM cat_estados;
SELECT COUNT(*) FROM cat_municipios;
SELECT COUNT(*) FROM cat_asentamientos;
SELECT COUNT(*) FROM sepomex;
```

Ver los primeros registros:
```sql
SELECT * FROM cat_estados LIMIT 5;
SELECT * FROM cat_municipios LIMIT 5;
SELECT * FROM cat_asentamientos LIMIT 5;
SELECT * FROM sepomex LIMIT 5;
```

---





