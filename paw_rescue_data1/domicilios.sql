--Creación de esquemas
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN ('vacunas', 'paw');


SET search_path TO vacunas;

-- tablas sepomex
CREATE SCHEMA IF NOT EXISTS sepomex;

-- Creación de tablas para sepomex

CREATE TABLE sepomex.estado (
  entidad_id INTEGER PRIMARY KEY,
  entidad_federativa VARCHAR(45) NOT NULL
);

CREATE TABLE sepomex.codigos (
  codigo_postal CHAR(5) NOT NULL,
  entidad_id INTEGER NOT NULL,
  municipio VARCHAR(150) NOT NULL,
  asentamiento VARCHAR(150) NOT NULL,
  tipo_asentamiento TEXT,
  ciudad VARCHAR(50),

  PRIMARY KEY (codigo_postal, asentamiento),
  CONSTRAINT fk_codigos_estado
    FOREIGN KEY (entidad_id) REFERENCES sepomex.estado(entidad_id)
);

CREATE TABLE sepomex.domicilio (
  id_domicilio BIGSERIAL PRIMARY KEY,
  codigo_postal CHAR(5) NOT NULL,
  asentamiento VARCHAR(150) NOT NULL,
  calle VARCHAR(150),
  num_exterior VARCHAR(150),
  num_interior VARCHAR(150),
  referencia TEXT,

  CONSTRAINT fk_domicilio_codigos
    FOREIGN KEY (codigo_postal, asentamiento)
    REFERENCES sepomex.codigos(codigo_postal, asentamiento)
);
 

BEGIN;


-- =========================================================
-- Reasignar CP + asentamiento con pares de sepomex
-- =========================================================
WITH ap AS (
  SELECT ctid, row_number() OVER (ORDER BY ctid) AS rn
  FROM paw.adoptante_perfil
),
codes AS (
  SELECT codigo_postal, asentamiento,
         row_number() OVER (ORDER BY random()) AS rn
  FROM (
    SELECT DISTINCT
      lpad(trim(codigo_postal::text),5,'0') AS codigo_postal,
      trim(asentamiento) AS asentamiento
    FROM sepomex.codigos
    WHERE entidad_id IN (9,15)
      AND codigo_postal IS NOT NULL
      AND asentamiento IS NOT NULL
      AND trim(asentamiento) <> ''
  ) t
),
cnt AS (
  SELECT COUNT(*)::int AS n FROM codes
)
UPDATE paw.adoptante_perfil apf
SET
  codigo_postal = c.codigo_postal,
  asentamiento  = c.asentamiento
FROM ap
JOIN cnt ON true
JOIN codes c
  ON c.rn = ((ap.rn - 1) % cnt.n) + 1
WHERE apf.ctid = ap.ctid;

--poblar domicilio 
DELETE FROM sepomex.domicilio;

INSERT INTO sepomex.domicilio (
  codigo_postal, asentamiento, calle, num_exterior, num_interior, referencia
)
SELECT DISTINCT
  ap.codigo_postal,
  ap.asentamiento,
  ap.calle,
  ap.num_exterior,
  ap.num_interior,
  NULL::text AS referencia
FROM paw.adoptante_perfil ap
WHERE ap.codigo_postal IS NOT NULL
  AND ap.asentamiento IS NOT NULL
  AND ap.calle IS NOT NULL
  AND ap.num_exterior IS NOT NULL;






