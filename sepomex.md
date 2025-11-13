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


```sql

CREATE TABLE Estado (
  id_estado INTEGER PRIMARY KEY,
  nombre VARCHAR(45)
);


CREATE TABLE Sepomex (
  codigo_postal CHAR (5),
  id_estado INTEGER,
  municipio VARCHAR (150),
  asentamiento VARCHAR (150),
  tipo_asentamiento TEXT,
  ciudad VARCHAR (50),
  PRIMARY KEY (codigo_postal, asentamiento) 
  FOREIGN KEY (id_estado) REFERENCES Estado(id_estado)
);


CREATE TABLE Domicilio (
  id_domicilio BIGSERIAL PRIMARY KEY,  
  codigo_postal CHAR (5),
  asentamiento VARCHAR (150),
  calle VARCHAR (150),
  num_exterior VARCHAR (150),
  num_interior VARCHAR (150),
  referencia TEXT,
    FOREIGN KEY ((codigo_postal, asentamiento)
      REFERENCES sepomex(codigo_postal, asentamiento)
);
  

## 3.2. Importación de datos

### En Linux

Conectar a PostgreSQL:
```bash
psql -U tu_usuario -d fundacion
```

Importar los archivos CSV:
```sql
\COPY cat_estados FROM '/home/usuario/ruta/cat_estados.csv' WITH (FORMAT csv, HEADER true);
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
\COPY sepomex FROM '/ruta/archivos/sepomex.csv' WITH (FORMAT csv, HEADER true);
```

**Ejemplos de rutas:**
- Linux: `/home/usuario/proyecto/cat_estados.csv`
- macOS: `/Users/usuario/Documents/proyecto/cat_estados.csv`

---

## 4. Validación de datos cargados

Verificar el número de registros en cada tabla:
```sql
SELECT COUNT(*) FROM Estado;
SELECT COUNT(*) FROM Sepomex;
```

Ver los primeros registros:
```sql
SELECT * FROM Estado LIMIT 5;
SELECT * FROM Sepomex LIMIT 5;
```

---
## 5 Consultas 

```ssql
SELECT 
  D.id_domicilio,  
  S.codigo_postal,
  S.asentamiento,
  E.estado
  D.calle,
  D.num_exterior,
  D.num_interior,
  D.referencia
FROM domicilio AS D
JOIN Sepomex AS S ON S.id_codigo_postal = D.id_codigo_postal
AND S.asentamiento = D.asentamiento
JOIN Estado AS E ON E.id_estado = S.id_estado;

```
---
## 6 Consultas desde aplicaciones (Python y PHP)

Este sistema puede integrarse fácilmente en formularios web o móviles. A continuación se muestran ejemplos de cómo consultar la base de datos para autocompletar los campos de domicilio usando el código postal.

---

### Python (Flask + psycopg2)

```python
import psycopg2
from flask import Flask, request, jsonify

app = Flask(__name__)

# Conexión a PostgreSQL
conn = psycopg2.connect(
    dbname="tu_base",
    user="tu_usuario",
    password="tu_contraseña",
    host="localhost",
    port="5432"
)

@app.route('/buscar_datos', methods=['GET'])
def buscar_datos():
    cp = request.args.get('codigo_postal')
    cur = conn.cursor()
    cur.execute("""
        SELECT DISTINCT estado, municipio, asentamiento
        FROM sepomex
        WHERE codigo_postal = %s
    """, (cp,))
    resultados = cur.fetchall()
    cur.close()

    datos = [{"estado": r[0], "municipio": r[1], "asentamiento": r[2]} for r in resultados]
    return jsonify(datos)

if __name__ == '__main__':
    app.run(debug=True)


<?php
$cp = $_GET['codigo_postal'];

try {
    $pdo = new PDO("pgsql:host=localhost;dbname=tu_base", "tu_usuario", "tu_contraseña");

    $stmt = $pdo->prepare("
        SELECT DISTINCT estado, municipio, asentamiento
        FROM sepomex
        WHERE codigo_postal = :cp
    ");
    $stmt->bindParam(':cp', $cp);
    $stmt->execute();

    $resultados = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($resultados);

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>



