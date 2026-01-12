/* ============================================================
   1) 1FN - ENTIDADES ATÓMICAS
   - Definir tablas con valores atómicos y PK única.
   ============================================================ */

CREATE TABLE IF NOT EXISTS paw.adoptante (
  id_adoptante  BIGSERIAL PRIMARY KEY,
  nombre        TEXT NOT NULL,
  email         TEXT UNIQUE,
  telefono      TEXT,
  fecha_registro DATE NOT NULL DEFAULT CURRENT_DATE,

  id_domicilio  BIGINT REFERENCES sepomex.domicilio(id_domicilio)
);

/* ============================================================
   2) 2FN / 3FN - DESCOMPOSICIÓN Y LIMPIEZA
   - Separar atributos detallados en 'ADOPTANTE_PERFIL' para 
     evitar tener una tabla masiva con muchos nulos en 'ADOPTANTE'.
   - Esto mejora la consistencia y elimina dependencias no clave.
   ============================================================ */

CREATE TABLE IF NOT EXISTS paw.adoptante_perfil (
  id_adoptante BIGINT PRIMARY KEY REFERENCES paw.adoptante(id_adoptante) ON DELETE CASCADE,

  tipo_vivienda TEXT,       
  tiene_patio   BOOLEAN,
  vive_en_renta BOOLEAN,
  tiene_otras_mascotas BOOLEAN,
  convive_con_ninos BOOLEAN,
  horas_solo_dia INT,        
  experiencia_previa BOOLEAN,
  notas TEXT
);

/* ============================================================
   3) 4FN - RELACIONES M:N (SOLICITUD)
   - 'SOLICITUD_ADOPCION' resuelve la relación Muchos-a-Muchos
     entre ADOPTANTE y MASCOTA.
   - Cada solicitud es una entidad independiente que evita
     repetición de datos en las entidades principales.
   ============================================================ */

CREATE TABLE IF NOT EXISTS paw.solicitud_adopcion (
  id_solicitud  BIGSERIAL PRIMARY KEY,
  id_adoptante  BIGINT NOT NULL REFERENCES paw.adoptante(id_adoptante) ON DELETE CASCADE,
  id_mascota    INT NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,

  fecha_solicitud DATE NOT NULL DEFAULT CURRENT_DATE,

  estado TEXT NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente','en_revision','aprobada','rechazada','cancelada','adoptada')),

  motivo_rechazo TEXT,

  UNIQUE (id_adoptante, id_mascota)
);

CREATE INDEX IF NOT EXISTS idx_solicitud_adoptante ON paw.solicitud_adopcion(id_adoptante);
CREATE INDEX IF NOT EXISTS idx_solicitud_mascota ON paw.solicitud_adopcion(id_mascota);

ALTER TABLE paw.solicitud_adopcion
  ADD COLUMN IF NOT EXISTS id_fundacion BIGINT;


/* ============================================================
   4) 5FN - FLUJOS DE PROCESO SEPARADOS 
   - Separar cada etapa del proceso (Cita, Evaluación, Adopción, Supervisión)
     en su propia tabla.
   - Esto evita anomalías de actualización y permite que cada etapa
     exista (o no) independientemente, uniéndose por la solicitud/adopción.
   ============================================================ */

-- CITAS (Independiente de la evaluación final)
CREATE TABLE IF NOT EXISTS paw.cita_visita (
  id_cita     BIGSERIAL PRIMARY KEY,
  id_solicitud BIGINT NOT NULL REFERENCES paw.solicitud_adopcion(id_solicitud) ON DELETE CASCADE,

  fecha_hora  TIMESTAMP NOT NULL,
  estado      TEXT NOT NULL DEFAULT 'programada'
    CHECK (estado IN ('programada','asistio','no_asistio','reprogramada','cancelada')),

  notas       TEXT
);

CREATE INDEX IF NOT EXISTS idx_cita_fecha ON paw.cita_visita(fecha_hora);


-- EVALUACIÓN (Resultado formal, separado de la cita)
CREATE TABLE IF NOT EXISTS paw.evaluacion (
  id_evaluacion BIGSERIAL PRIMARY KEY,
  id_solicitud  BIGINT UNIQUE NOT NULL REFERENCES paw.solicitud_adopcion(id_solicitud) ON DELETE CASCADE,

  fecha         DATE NOT NULL DEFAULT CURRENT_DATE,
  resultado     BOOLEAN NOT NULL,     -- true=aprobado, false=rechazado
  puntaje       INT CHECK (puntaje BETWEEN 0 AND 100),
  comentarios   TEXT
);


-- ADOPCIÓN 
CREATE TABLE IF NOT EXISTS paw.adopcion (
  id_adopcion   BIGSERIAL PRIMARY KEY,
  id_solicitud  BIGINT UNIQUE NOT NULL REFERENCES paw.solicitud_adopcion(id_solicitud) ON DELETE CASCADE,

  id_adoptante  BIGINT NOT NULL REFERENCES paw.adoptante(id_adoptante) ON DELETE CASCADE,
  id_mascota    INT NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,

  fecha_adopcion DATE NOT NULL DEFAULT CURRENT_DATE,
  contrato_url  TEXT,

  UNIQUE (id_mascota)
);

CREATE INDEX IF NOT EXISTS idx_adopcion_fecha ON paw.adopcion(fecha_adopcion);


-- SUPERVISIONES 
CREATE TABLE IF NOT EXISTS paw.supervision (
  id_supervision BIGSERIAL PRIMARY KEY,
  id_adopcion    BIGINT NOT NULL REFERENCES paw.adopcion(id_adopcion) ON DELETE CASCADE,

  fecha          DATE NOT NULL,
  tipo           TEXT NOT NULL
    CHECK (tipo IN ('1_mes','anual','extra')),

  resultado      TEXT CHECK (resultado IN ('ok','observacion','riesgo')),

  observaciones  TEXT
);

CREATE INDEX IF NOT EXISTS idx_supervision_adopcion ON paw.supervision(id_adopcion);

/* ============================================================
   POBLADO DE DATOS
   ============================================================ */

-- 1) Adoptantes
INSERT INTO paw.adoptante (nombre, email, telefono)
SELECT
  (ARRAY['Ana','Luis','Carlos','María','José','Fernanda','Jorge','Sofía','Miguel','Valeria','Daniel','Camila','Eduardo','Paola','Ricardo','Andrea'])
    [1 + floor(random()*16)::int]
  || ' ' ||
  (ARRAY['García','Hernández','López','Martínez','González','Pérez','Sánchez','Ramírez','Cruz','Flores','Gómez','Vargas','Morales','Castillo','Torres','Rivera'])
    [1 + floor(random()*16)::int] AS nombre,
  'user' || gs::text || '@petconnect.mx' AS email,
  '55' || lpad((10000000 + floor(random()*89999999)::int)::text, 8, '0') AS telefono
 
  FROM generate_series(1,40) gs
ON CONFLICT (email) DO NOTHING;

-- 2) Perfil adoptante 
--adoptantes modificaciones
INSERT INTO paw.adoptante_perfil (
  id_adoptante, edad, tel_movil, tel_fijo, email,
  codigo_postal, asentamiento, calle, num_exterior, num_interior,
  tipo_vivienda, situacion_vivienda, contacto_arrendador, espacio_cercado,
  adultos_hogar, personas_hogar, ninos_rango, otras_mascotas, otras_mascotas_detalle,
  experiencia_previa, nivel_experiencia, horas_fuera,
  nivel_actividad, gastos_vet, compromiso_esterilizacion, tiempo_dedicado,
  motivo_adopcion, que_haria_cambios,
  nivel_economico
)
SELECT
  a.id_adoptante,
  (18 + floor(random()*55)::int) AS edad,
  a.telefono AS tel_movil,
  CASE WHEN random() < 0.4 THEN '55' || lpad((10000000 + floor(random()*89999999)::int)::text, 8, '0') ELSE NULL END AS tel_fijo,
  a.email,

  c.codigo_postal,
  c.asentamiento,
  (ARRAY['Av. Siempre Viva','Calle Reforma','Insurgentes','Eje Central','Tláhuac','Patriotismo','Universidad'])
    [1 + floor(random()*7)::int] AS calle,
  (1 + floor(random()*250)::int)::text AS num_exterior,
  CASE WHEN random() < 0.3 THEN (1 + floor(random()*30)::int)::text ELSE NULL END AS num_interior,

  (ARRAY['casa-jardin','casa-sin-jardin','departamento-amplio','departamento-pequeno'])
    [1 + floor(random()*4)::int] AS tipo_vivienda,
  (ARRAY['propia','alquilada'])
    [1 + floor(random()*2)::int] AS situacion_vivienda,
  CASE WHEN random() < 0.35 THEN 'Arrendador: 55-1234-5678 / arr@correo.com' ELSE NULL END AS contacto_arrendador,
  (ARRAY['si','no','no-aplica'])
    [1 + floor(random()*3)::int] AS espacio_cercado,

  (1 + floor(random()*4)::int) AS adultos_hogar,
  (1 + floor(random()*6)::int) AS personas_hogar,
  ARRAY[
    (ARRAY['0-5','6-12','13+','no-hay'])[1 + floor(random()*4)::int]
  ]::text[] AS ninos_rango,
  ARRAY[
    (ARRAY['perros','gatos','otros','ninguna'])[1 + floor(random()*4)::int]
  ]::text[] AS otras_mascotas,
  CASE WHEN random() < 0.25 THEN 'Otros: conejo' ELSE NULL END AS otras_mascotas_detalle,

  (random() > 0.5) AS experiencia_previa,
  (ARRAY['novato','intermedio','avanzado'])[1 + floor(random()*3)::int] AS nivel_experiencia,
  (ARRAY['menos-4','4-8','mas-8'])[1 + floor(random()*3)::int] AS horas_fuera,

  (ARRAY['bajo','medio','alto'])[1 + floor(random()*3)::int] AS nivel_actividad,
  (ARRAY['si','no'])[1 + floor(random()*2)::int] AS gastos_vet,
  (ARRAY['si','no'])[1 + floor(random()*2)::int] AS compromiso_esterilizacion,
  (ARRAY['menos-1h','1-2h','mas-2h'])[1 + floor(random()*3)::int] AS tiempo_dedicado,

  'Quiero adoptar para dar un hogar responsable.' AS motivo_adopcion,
  'Buscaría apoyo familiar y mantendría el compromiso.' AS que_haria_cambios,

  (ARRAY['bajo','medio','alto'])[1 + floor(random()*3)::int] AS nivel_economico
FROM paw.adoptante a
JOIN LATERAL (
  SELECT codigo_postal, asentamiento
  FROM sepomex.codigos
  WHERE entidad_id IN (9,15)
    AND codigo_postal IS NOT NULL
    AND asentamiento IS NOT NULL
  ORDER BY random()
  LIMIT 1
) c ON true
ON CONFLICT (id_adoptante) DO NOTHING;

--datos faltantes de la base
-- Datos personales y contacto
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS edad INT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS tel_movil TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS tel_fijo TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS email TEXT;

-- Dirección (guardamos domicilio completo "simple")
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS codigo_postal CHAR(5);
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS asentamiento TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS calle TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS num_exterior TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS num_interior TEXT;

-- Vivienda
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS tipo_vivienda TEXT;        
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS situacion_vivienda TEXT;   
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS contacto_arrendador TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS espacio_cercado TEXT;     

-- Hogar y experiencia
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS adultos_hogar INT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS personas_hogar INT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS ninos_rango TEXT[];       
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS otras_mascotas TEXT[];    
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS otras_mascotas_detalle TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS experiencia_previa TEXT; 
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS nivel_experiencia Boolean;  
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS horas_fuera TEXT;        

-- Compromiso y estilo de vida
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS nivel_actividad TEXT;     
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS gastos_vet TEXT;          
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS compromiso_esterilizacion TEXT; 
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS tiempo_dedicado TEXT;     
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS motivo_adopcion TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS que_haria_cambios TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN IF NOT EXISTS nivel_economico TEXT;

--modificaciones adoptante perfil

UPDATE paw.adoptante_perfil
SET
  codigo_postal = lpad(trim(codigo_postal::text), 5, '0'),
  asentamiento  = trim(asentamiento),
  calle         = NULLIF(trim(calle), ''),
  num_exterior  = NULLIF(trim(num_exterior), ''),
  num_interior  = NULLIF(trim(num_interior), '');

--  Completar datos de calle/números si faltan 
UPDATE paw.adoptante_perfil
SET
  calle = COALESCE(calle, (ARRAY[
    'Av. Siempre Viva','Insurgentes','Reforma','Patriotismo','Eje Central','Tláhuac','Universidad','Zaragoza'
  ])[1 + floor(random()*8)::int]),
  num_exterior = COALESCE(num_exterior, (10 + floor(random()*240))::text),
  num_interior = CASE WHEN random() < 0.35 THEN (1 + floor(random()*30))::text ELSE NULL END;

-- agregar id_domicilio a adoptante perfil 
ALTER TABLE paw.adoptante_perfil
  ADD COLUMN IF NOT EXISTS id_domicilio BIGINT;

UPDATE paw.adoptante_perfil
SET id_domicilio = NULL;

-- Reasignar id_domicilio a cada adoptante_perfil
UPDATE paw.adoptante_perfil ap
SET id_domicilio = d.id_domicilio
FROM sepomex.domicilio d
WHERE d.codigo_postal = ap.codigo_postal
  AND d.asentamiento  = ap.asentamiento
  AND d.calle         = ap.calle
  AND d.num_exterior  = ap.num_exterior
  AND d.num_interior IS NOT DISTINCT FROM ap.num_interior;




/* ===========================
  Poblar tablas faltantes
============================== */

-- Solicitudes
INSERT INTO paw.solicitud_adopcion (id_adoptante, id_mascota, fecha_solicitud, estado)
SELECT
  a.id_adoptante,
  m.id_mascota,
  (CURRENT_DATE - (floor(random()*120)::int))::date AS fecha_solicitud,
  (ARRAY['pendiente','en_revision','aprobada','rechazada','cancelada','adoptada'])
    [1 + floor(random()*4)::int] AS estado
FROM paw.adoptante a
JOIN LATERAL (
  SELECT id_mascota
  FROM paw.mascota_rescatada
  ORDER BY random()
  LIMIT 1
) m ON true
WHERE random() < 0.75
ON CONFLICT DO NOTHING;

UPDATE paw.solicitud_adopcion s 
SET id_mascota = (
    SELECT id_mascota 
    FROM paw.mascota_rescatada 
    WHERE s.id_solicitud IS NOT NULL 
    ORDER BY random() 
    LIMIT 1
);

UPDATE paw.solicitud_adopcion
SET estado = 'aprobada'
WHERE id_solicitud IN (
  SELECT id_solicitud FROM paw.solicitud_adopcion ORDER BY random() LIMIT 12
);

UPDATE paw.solicitud_adopcion s
SET estado = 'adoptada'
FROM paw.adopcion a
WHERE a.id_solicitud = s.id_solicitud;


-- Citas
TRUNCATE TABLE paw.cita_visita RESTART IDENTITY CASCADE;
INSERT INTO paw.cita_visita (id_solicitud, fecha_hora, estado)
SELECT
    s.id_solicitud,
    val.fecha_unica, 
    CASE 
        WHEN val.fecha_unica < now() THEN 
             (ARRAY['asistio', 'no_asistio', 'reprogramada', 'cancelada'])[1 + floor(random()*4)::int]
        ELSE 'programada' 
    END AS estado

FROM paw.solicitud_adopcion s
JOIN LATERAL (
    SELECT (
        '2025-01-01 09:00:00'::timestamp 
        + (floor(random() * 400)::int || ' days')::interval 
        + (floor(random() * 8)::int || ' hours')::interval
        + (s.id_solicitud * interval '5 minutes')
    ) AS fecha_unica
) val ON true

WHERE random() < 0.8
ON CONFLICT DO NOTHING;

UPDATE paw.cita_visita
SET 
    fecha_hora = '2026-01-08 09:00:00'::timestamp + (random() * interval '4 hours'),
    
    estado = 'programada'
WHERE id_solicitud IN (
    SELECT id_solicitud FROM paw.cita_visita ORDER BY random() LIMIT 5
);

--Evaluación
INSERT INTO paw.evaluacion (id_solicitud, resultado, puntaje, comentarios, fecha)
SELECT
  s.id_solicitud,
  CASE WHEN random() < 0.65 THEN true ELSE false END AS resultado,
  (60 + floor(random()*41)::int) AS puntaje,
  CASE WHEN random() < 0.65 THEN 'Perfil adecuado.' ELSE 'No cumple requisitos.' end,
  (s.fecha_solicitud + (floor(random()*20)::int))::date
FROM paw.solicitud_adopcion s
WHERE s.estado IN ('en_revision','aprobada','rechazada')
ON CONFLICT (id_solicitud) DO NOTHING;

-- 6) Marcar solicitud como aprobada/rechazada según evaluación
UPDATE paw.solicitud_adopcion s
SET
  estado = CASE WHEN e.resultado THEN 'aprobada' ELSE 'rechazada' END,
  motivo_rechazo = CASE WHEN e.resultado THEN NULL ELSE COALESCE(e.comentarios,'Rechazo') END
FROM paw.evaluacion e
WHERE e.id_solicitud = s.id_solicitud;

-- Adopciones
TRUNCATE TABLE paw.adopcion RESTART IDENTITY CASCADE;

INSERT INTO paw.adopcion (id_solicitud, id_adoptante, id_mascota, fecha_adopcion, contrato_url)
SELECT DISTINCT ON (s.id_mascota)
  s.id_solicitud,
  s.id_adoptante,
  s.id_mascota,
  (CURRENT_DATE - floor(random()*60)::int)::date AS fecha_adopcion,
  NULL AS contrato_url
FROM paw.solicitud_adopcion s
WHERE s.estado = 'aprobada'
  AND random() < 0.8
ORDER BY s.id_mascota, random()
ON CONFLICT DO NOTHING;

-- Supervisión
-- 1) Supervisión del Primer Mes
INSERT INTO paw.supervision (id_adopcion, fecha, tipo, resultado, observaciones)
SELECT
  a.id_adopcion,
  (a.fecha_adopcion + INTERVAL '30 days')::date,
  
  '1_mes',
  
  CASE 
    WHEN random() < 0.80 THEN 'ok'
    WHEN random() < 0.95 THEN 'observacion' -- Sin tilde
    ELSE 'riesgo'
  END AS resultado,

  CASE 
    WHEN random() < 0.80 THEN 'Adaptación exitosa, todo en orden.'
    WHEN random() < 0.95 THEN 'Se dieron recomendaciones de alimentación.'
    ELSE 'ALERTA: El animal se ve descuidado.'
  END AS observaciones

FROM paw.adopcion a
ON CONFLICT DO NOTHING;

-- 2) Supervisión del Primer Año
INSERT INTO paw.supervision (id_adopcion, fecha, tipo, resultado, observaciones)
SELECT
  a.id_adopcion,
  (a.fecha_adopcion + INTERVAL '1 year')::date,
  
  'anual',
  
  CASE 
    WHEN random() < 0.85 THEN 'ok'
    WHEN random() < 0.98 THEN 'observacion' -- Sin tilde
    ELSE 'riesgo'
  END AS resultado,

  CASE 
    WHEN random() < 0.85 THEN 'Mantiene buen peso y salud.'
    WHEN random() < 0.98 THEN 'Falta actualizar vacunas.'
    ELSE 'URGENTE: No se pudo contactar o condiciones malas.'
  END AS observaciones

FROM paw.adopcion a
ON CONFLICT DO NOTHING;
