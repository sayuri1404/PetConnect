/* =========================================================
   1) CREAR ESQUEMA PAW
   ========================================================= */
CREATE SCHEMA IF NOT EXISTS paw;

/* =========================================================
   2) 1FN - ATOMICIDAD
   - Se crea una tabla “staging” (stg_mascota)
     donde llega el CSV “tal cual”.
   ========================================================= */

DROP TABLE IF EXISTS paw.stg_mascota;

CREATE TABLE paw.stg_mascota (
  id_mascota INT,
  nombre TEXT,
  especie TEXT,
  edad INT,
  raza TEXT,
  "tamaño" TEXT,
  color_pelo TEXT,
  color_pelo_secundario TEXT,
  tipo_pelo TEXT,
  comportamiento TEXT,
  convive_con_otros_animales TEXT,
  padecimientos TEXT,
  tratamiento_padecimiento TEXT,
  vacunas TEXT,
  sexo TEXT,
  senias_particulares TEXT,
  url_foto TEXT
);


/* =========================================================
   3) 2FN - ELIMINAR DEPENDENCIAS PARCIALES
   - 2FN: quitar dependencias parciales (cuando la PK es compuesta)
   - Aquí, entidad principal “mascota_rescatada” usa PK simple
     (id_mascota), así 2FN se resuelve diseñando una tabla 
     principal con PK simple y catálogos aparte.
   ========================================================= */
/* =========================================================
   4) 3FN / BCNF - ELIMINAR DEPENDENCIAS TRANSITIVAS
   - 3FN: evitar dependencias transitivas.
   - BCNF: toda dependencia funcional debe depender de una clave.
   - Solución: separar catálogos (raza/color/padecimiento) para evitar
     repetir texto y mantener consistencia.
   ========================================================= */

-- Catálogos
-- RAZA
CREATE TABLE IF NOT EXISTS paw.raza (
  id_raza SERIAL PRIMARY KEY,
  especie_id INT NOT NULL REFERENCES vacunas.mascota(id_mascotamasc),
  nombre TEXT NOT NULL,
  UNIQUE (especie_id, nombre)
);

--COLOR
CREATE TABLE IF NOT EXISTS paw.color (
  id_color SERIAL PRIMARY KEY,
  nombre TEXT UNIQUE NOT NULL
);

-- PADECIMIENTO
CREATE TABLE IF NOT EXISTS paw.padecimiento (
  id_padecimiento SERIAL PRIMARY KEY,
  nombre TEXT UNIQUE NOT NULL
);

-- Tabla principal
CREATE TABLE IF NOT EXISTS paw.mascota_rescatada (
  id_mascota INT PRIMARY KEY,
  nombre TEXT NOT NULL,
  especie_id INT NOT NULL REFERENCES vacunas.mascota(id_mascotamasc),
  edad INT,
  id_raza INT REFERENCES paw.raza(id_raza),
  tamanio TEXT,
  tipo_pelo TEXT,
  comportamiento TEXT,
  convive_con_otros_animales BOOLEAN,
  sexo TEXT,
  senias_particulares TEXT,
  url_foto TEXT
);


/* =========================================================
   5) 4FN - INDEPENDENCIA DE MULTIVALUADOS
   - 4FN: separar atributos multivaluados independientes.
   - Una mascota puede tener varios colores y varios
     padecimientos.
   ========================================================= */

-- Colores (principal/secundario)
CREATE TABLE IF NOT EXISTS paw.mascota_color (
  id_mascota INT REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  id_color INT REFERENCES paw.color(id_color),
  es_principal BOOLEAN NOT NULL,
  PRIMARY KEY (id_mascota, id_color, es_principal)
);

-- Padecimientos
CREATE TABLE IF NOT EXISTS paw.mascota_padecimiento (
  id_mascota INT REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  id_padecimiento INT REFERENCES paw.padecimiento(id_padecimiento),
  tratamiento TEXT,
  PRIMARY KEY (id_mascota, id_padecimiento)
);


/* =========================================================
   6) 5FN - PROYECCIÓN Y UNIÓN 
   - 5FN: eliminar dependencias de unión
   - Se aplica en:
       - historial dueños (mascota_duenio_hist)
       - lista negra (duenio -> lista_negra)
       - eventos médicos (mascota -> evento_medico)
       - vacunas aplicadas (mascota -> vacuna_aplicada -> vacuna)
   ========================================================= */

-- Rescate (1:1 con mascota)
CREATE TABLE IF NOT EXISTS paw.rescate (
  id_rescate SERIAL PRIMARY KEY,
  id_mascota INT UNIQUE NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  alcaldia TEXT NOT NULL,
  situacion TEXT NOT NULL,
  necesidades_especiales TEXT
);

-- Dueños anteriores
CREATE TABLE IF NOT EXISTS paw.duenio (
  id_duenio SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  identificacion TEXT
);

-- Historial de dueños anteriores (N:M)
CREATE TABLE IF NOT EXISTS paw.mascota_duenio_hist (
  id_mascota INT REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  id_duenio INT REFERENCES paw.duenio(id_duenio),
  desde DATE,
  hasta DATE,
  motivo TEXT,
  PRIMARY KEY (id_mascota, id_duenio, desde)
);

-- Lista negra (1:N)
CREATE TABLE IF NOT EXISTS paw.lista_negra (
  id_lista SERIAL PRIMARY KEY,
  id_duenio INT NOT NULL REFERENCES paw.duenio(id_duenio),
  motivo TEXT NOT NULL,
  inicio DATE NOT NULL,
  fin DATE,
  es_permanente BOOLEAN NOT NULL DEFAULT false
);

-- Expediente médico general (1:N)
CREATE TABLE IF NOT EXISTS paw.evento_medico (
  id_evento SERIAL PRIMARY KEY,
  id_mascota INT NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  tipo TEXT NOT NULL,    
  fecha DATE,
  detalle TEXT
);

-- Vacunas aplicadas (1:N)
CREATE TABLE IF NOT EXISTS paw.vacuna_aplicada (
  id_aplicacion SERIAL PRIMARY KEY,
  id_mascota INT NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  id_vacuna INT NOT NULL REFERENCES vacunas.vacuna(id_vacunavac),
  fecha_aplicacion DATE,
  proxima_dosis DATE,
  observaciones TEXT
);

/* =========================================================
   Poblar catálogos desde stg_mascota (3FN)
   ========================================================= */

-- Raza (depende de especie)
INSERT INTO paw.raza (especie_id, nombre)
SELECT DISTINCT
  CASE
    WHEN LOWER(especie) = 'perro' THEN 1
    WHEN LOWER(especie) = 'gato'  THEN 2
  END AS especie_id,
  TRIM(raza) AS nombre
FROM paw.stg_mascota
WHERE raza IS NOT NULL AND TRIM(raza) <> ''
  AND LOWER(especie) IN ('perro','gato')
ON CONFLICT DO NOTHING;

-- Colores (principal)
INSERT INTO paw.color (nombre)
SELECT DISTINCT TRIM(color_pelo)
FROM paw.stg_mascota
WHERE color_pelo IS NOT NULL AND TRIM(color_pelo) <> ''
ON CONFLICT DO NOTHING;

-- Colores (secundario)
INSERT INTO paw.color (nombre)
SELECT DISTINCT TRIM(color_pelo_secundario)
FROM paw.stg_mascota
WHERE color_pelo_secundario IS NOT NULL AND TRIM(color_pelo_secundario) <> ''
ON CONFLICT DO NOTHING;

-- Padecimientos
INSERT INTO paw.padecimiento (nombre)
SELECT DISTINCT TRIM(padecimientos)
FROM paw.stg_mascota
WHERE padecimientos IS NOT NULL AND TRIM(padecimientos) <> ''
ON CONFLICT DO NOTHING;


/* =========================================================
 Poblar tabla principal (mascota_rescatada)
   ========================================================= */

INSERT INTO paw.mascota_rescatada (
  id_mascota, nombre, especie_id, edad, id_raza,
  tamanio, tipo_pelo, comportamiento, convive_con_otros_animales,
  sexo, senias_particulares, url_foto
)
SELECT
  s.id_mascota,
  COALESCE(NULLIF(TRIM(s.nombre), ''), 'Sin nombre') AS nombre,
  CASE
    WHEN LOWER(s.especie) = 'perro' THEN 1
    WHEN LOWER(s.especie) = 'gato'  THEN 2
    ELSE 1
  END AS especie_id,
  s.edad,
  r.id_raza,
  s."tamaño",
  s.tipo_pelo,
  s.comportamiento,
  CASE
    WHEN LOWER(s.convive_con_otros_animales) IN ('si','sí','true','1') THEN TRUE
    WHEN LOWER(s.convive_con_otros_animales) IN ('no','false','0') THEN FALSE
    ELSE NULL
  END,
  s.sexo,
  s.senias_particulares,
  s.url_foto
FROM paw.stg_mascota s
LEFT JOIN paw.raza r
  ON r.nombre = TRIM(s.raza)
 AND r.especie_id = CASE
    WHEN LOWER(s.especie) = 'perro' THEN 1
    WHEN LOWER(s.especie) = 'gato'  THEN 2
    ELSE NULL
 END
ON CONFLICT (id_mascota) DO NOTHING;


/* =========================================================
  Poblar tablas en (4FN)
   ========================================================= */

-- mascota_color principal
INSERT INTO paw.mascota_color (id_mascota, id_color, es_principal)
SELECT s.id_mascota, c.id_color, TRUE
FROM paw.stg_mascota s
JOIN paw.color c ON c.nombre = TRIM(s.color_pelo)
WHERE s.color_pelo IS NOT NULL AND TRIM(s.color_pelo) <> ''
ON CONFLICT DO NOTHING;

-- mascota_color secundario
INSERT INTO paw.mascota_color (id_mascota, id_color, es_principal)
SELECT s.id_mascota, c.id_color, FALSE
FROM paw.stg_mascota s
JOIN paw.color c ON c.nombre = TRIM(s.color_pelo_secundario)
WHERE s.color_pelo_secundario IS NOT NULL AND TRIM(s.color_pelo_secundario) <> ''
ON CONFLICT DO NOTHING;

-- mascota_padecimiento
INSERT INTO paw.mascota_padecimiento (id_mascota, id_padecimiento, tratamiento)
SELECT
  s.id_mascota,
  p.id_padecimiento,
  s.tratamiento_padecimiento
FROM paw.stg_mascota s
JOIN paw.padecimiento p ON p.nombre = TRIM(s.padecimientos)
WHERE s.padecimientos IS NOT NULL AND TRIM(s.padecimientos) <> ''
ON CONFLICT DO NOTHING;


/* =========================================================
   Poblar tablas faltantes
   ========================================================= */

-- Rescate (usa municipio)
INSERT INTO paw.rescate (id_mascota, fecha, alcaldia, situacion, necesidades_especiales)
SELECT
  m.id_mascota,
  (CURRENT_DATE - (trunc(random()*180))::int)::date AS fecha,

  a.municipio AS alcaldia,

  (ARRAY[
    'Abandono en vía pública','Rescate por maltrato','Hallado herido',
    'Rescate por denuncia vecinal','Rescatado de azotea','Rescate por acumulación',
    'En situación de calle','Entrega voluntaria'
  ])[1 + floor(random()*8)::int] AS situacion,

  CASE
    WHEN random() < 0.35 THEN (ARRAY[
      'Requiere curaciones por heridas','Bajo peso','Ansiedad por trauma',
      'Tratamiento antipulgas intensivo','Dieta especial','Seguimiento veterinario semanal'
    ])[1 + floor(random()*6)::int]
    ELSE NULL
  END AS necesidades_especiales
FROM paw.mascota_rescatada m
CROSS JOIN LATERAL (
  SELECT municipio
  FROM (
    SELECT DISTINCT municipio
    FROM sepomex.codigos
    WHERE entidad_id IN (9, 15)
      AND municipio IS NOT NULL
      AND TRIM(municipio) <> ''
  ) t
  ORDER BY random()
  LIMIT 1
) a
ON CONFLICT (id_mascota) DO NOTHING;

UPDATE paw.rescate
SET fecha = CURRENT_DATE
WHERE id_mascota IN (
  SELECT id_mascota FROM paw.rescate ORDER BY random() LIMIT 3
);

UPDATE paw.rescate
SET alcaldia = 'Gustavo A. Madero',
    fecha = DATE '2025-06-15'
WHERE id_mascota IN (
  SELECT id_mascota FROM paw.rescate ORDER BY random() LIMIT 3
);

-- Dueño 
INSERT INTO paw.duenio (nombre, identificacion)
SELECT
  (ARRAY['Ana','Luis','Carlos','María','José','Fernanda','Jorge','Sofía','Miguel','Valeria','Daniel','Camila','Eduardo','Paola','Ricardo','Andrea'])
    [1 + floor(random()*16)::int]
  || ' ' ||
  (ARRAY['García','Hernández','López','Martínez','González','Pérez','Sánchez','Ramírez','Cruz','Flores','Gómez','Vargas','Morales','Castillo','Torres','Rivera'])
    [1 + floor(random()*16)::int] AS nombre,
  'INE-' || lpad((100000 + floor(random()*900000)::int)::text, 6, '0') AS identificacion
FROM generate_series(1,25);


-- Historial de dueños anteriores
WITH m AS (
  SELECT id_mascota, row_number() OVER (ORDER BY id_mascota) AS rn
  FROM paw.mascota_rescatada
),
d AS (
  SELECT id_duenio, row_number() OVER (ORDER BY id_duenio) AS rn
  FROM paw.duenio
),
cnt AS (
  SELECT COUNT(*)::int AS n FROM paw.duenio
)
INSERT INTO paw.mascota_duenio_hist (id_mascota, id_duenio, desde, hasta, motivo)
SELECT
  m.id_mascota,
  d.id_duenio,
  (CURRENT_DATE - (300 + floor(random()*900)::int))::date AS desde,
  (CURRENT_DATE - (10  + floor(random()*250)::int))::date AS hasta,
  (ARRAY[
    'Abandono','Maltrato confirmado','Fallecimiento del dueño',
    'Mudanza','Entrega por falta de recursos','Rescate por denuncia'
  ])[1 + floor(random()*6)::int] AS motivo
FROM m
JOIN cnt ON true
JOIN d
  ON d.rn = ((m.rn - 1) % cnt.n) + 1
WHERE random() < 0.60;


-- Lista negra
TRUNCATE TABLE paw.lista_negra RESTART IDENTITY;

INSERT INTO paw.lista_negra (id_duenio, motivo, inicio, fin, es_permanente)
SELECT
  d.id_duenio,
  (ARRAY[
    'Maltrato confirmado','Abandono reiterado','Fraude en adopción',
    'Incumplimiento de contrato','Negligencia médica'
  ])[1 + floor(random()*5)::int] AS motivo,
  (CURRENT_DATE - floor(random()*900)::int)::date AS inicio,
  CASE WHEN random() < 0.60 THEN NULL
       ELSE (CURRENT_DATE - floor(random()*60)::int)::date
  END AS fin,
  (random() < 0.30) AS es_permanente
FROM paw.duenio d
WHERE random() < 0.35;


-- Evento médico
INSERT INTO paw.evento_medico (id_mascota, tipo, fecha, detalle)
SELECT
  m.id_mascota,
  (ARRAY['desparasitacion','curacion','alergia','enfermedad','esterilizacion'])
    [1 + floor(random()*5)::int] AS tipo,
  (CURRENT_DATE - floor(random()*365)::int)::date AS fecha,
  (ARRAY[
    'Tratamiento general','Seguimiento clínico','Aplicación tópica',
    'Control de infección','Observación y reposo','Medicamento antiinflamatorio',
    'Limpieza de herida','Control de pulgas y garrapatas'
  ])[1 + floor(random()*8)::int] AS detalle
FROM paw.mascota_rescatada m
CROSS JOIN LATERAL generate_series(1, (1 + floor(random()*3))::int) gs(n);


-- Vacuna aplicada (1 o 2 vacunas aleatorias por mascota)
INSERT INTO paw.vacuna_aplicada (id_mascota, id_vacuna, fecha_aplicacion, proxima_dosis, observaciones)
SELECT
  m.id_mascota,
  v.id_vacunavac,
  (CURRENT_DATE - ((random()*500)::int))::date AS fecha_aplicacion,
  (CURRENT_DATE + ((30 + random()*240)::int))::date AS proxima_dosis,
  CASE WHEN random() < 0.3 THEN 'Aplicada en campaña / Refuerzo programado' ELSE NULL END AS observaciones
FROM paw.mascota_rescatada m
JOIN LATERAL (
  SELECT id_vacunavac
  FROM vacunas.vacuna
  ORDER BY random()
  LIMIT (1 + (random()*2)::int)
) v ON true
WHERE random() < 0.90;