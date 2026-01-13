SET search_path TO paw, vacunas, sepomex, public;


-- =============================================
-- SOURCE: Vacunas_editado1.sql
-- =============================================


-- =============================================
-- SOURCE: create_auth_tables.sql
-- =============================================





-- Usamos ON CONFLICT para que si los emails ya existen, solo actualice el hash
INSERT INTO paw.usuario_auth (email, password_hash, rol, id_fundacion)
VALUES 
('fundacion1@pawrescue.com', '$2b$12$MNx8Ho2ok8/8hBL8..g04urclhX.UQ12caxjkII.pLq7m3APsXCGi', 'fundacion', 1),
('fundacion2@pawrescue.com', '$2b$12$MNx8Ho2ok8/8hBL8..g04urclhX.UQ12caxjkII.pLq7m3APsXCGi', 'fundacion', 2)
ON CONFLICT (email) 
DO UPDATE SET password_hash = EXCLUDED.password_hash;
-- =============================================
-- SOURCE: domicilios.sql
-- =============================================




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
-- =============================================
-- SOURCE: paw.sql
-- =============================================



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
-- =============================================
-- SOURCE: paw_fundacion.sql
-- =============================================




/* ============================================================
   5) 5FN - RELACIONES DE UNIÓN Y CONSISTENCIA
   - (En este esquema, las relaciones N:M ya están resueltas
     en 3FN y 4FN, asegurando que no haya pérdidas de información
     al hacer JOIN).
   ============================================================ */

/* ============================================================
   POBLADO DE DATOS
   ============================================================ */

-- Fundaciones pre creadas 
INSERT INTO paw.fundacion (nombre, email, telefono, rfc)
VALUES
('Fundación Patitas Felices','fundacion1@pawrescue.com','5555555555','PAW010101AAA'),
('Albergue Huellitas','fundacion2@pawrescue.com','5555555556','HUE020202BBB')
ON CONFLICT (email) DO NOTHING;
INSERT INTO paw.sucursal (nombre, municipio, direccion)
VALUES 
  ('Sucursal Norte', 'Gustavo A. Madero', 'Av. Insurgentes Norte 123'),
  ('Sucursal Centro', 'Cuauhtémoc', 'Calle Reforma 456'),
  ('Sucursal EdoMex', 'Toluca', 'Portal Constitución 789')
ON CONFLICT (nombre) DO UPDATE 
SET direccion = EXCLUDED.direccion,
    municipio = EXCLUDED.municipio;


-- Crear empleados 
INSERT INTO paw.empleados (nombre, puesto)
SELECT
  (ARRAY['Ana','Luis','Carlos','María','José','Fernanda','Jorge','Sofía','Miguel','Valeria','Daniel','Camila'])
    [1 + floor(random()*12)::int]
  || ' ' ||
  (ARRAY['García','Hernández','López','Martínez','González','Pérez','Sánchez','Ramírez'])
    [1 + floor(random()*8)::int] AS nombre,

  (ARRAY['Cuidador','Veterinario','Recepcion','Supervisor','Voluntario'])
    [1 + floor(random()*5)::int] AS puesto
FROM generate_series(1,18);


-- Marcar algunos empleados como cuidadores 
INSERT INTO paw.cuidadores (id_empleado, area, turno)
SELECT
  e.id_empleado,
  (ARRAY['perros','gatos','general'])[1 + floor(random()*3)::int] AS area,
  (ARRAY['matutino','vespertino'])[1 + floor(random()*2)::int] AS turno
FROM paw.empleados e
WHERE e.puesto = 'Cuidador'
ON CONFLICT (id_empleado) DO NOTHING;
WITH emp AS (
  SELECT id_empleado FROM paw.empleados ORDER BY id_empleado LIMIT 1
)
INSERT INTO paw.empleado_sucursal_hist (id_empleado, id_sucursal, desde, hasta, motivo)
SELECT
  e.id_empleado,
  s.id_sucursal,
  (CURRENT_DATE - INTERVAL '120 days')::date AS desde,
  NULL,
  'Rotación_programada'
FROM emp e
CROSS JOIN paw.sucursal s
ON CONFLICT DO NOTHING;

-- Otros empleados con 1 sucursal fija
INSERT INTO paw.empleado_sucursal_hist (id_empleado, id_sucursal, desde, hasta, motivo)
SELECT
  e.id_empleado,
  (SELECT id_sucursal FROM paw.sucursal ORDER BY random() LIMIT 1),
  (CURRENT_DATE - INTERVAL '200 days')::date,
  NULL,
  'Asignación'
FROM paw.empleados e
WHERE e.id_empleado NOT IN (SELECT id_empleado FROM paw.empleados ORDER BY id_empleado LIMIT 1)
  AND random() < 0.85
ON CONFLICT DO NOTHING;

WITH un_cuidador AS (
  SELECT id_empleado
  FROM paw.cuidadores
  ORDER BY id_empleado
  LIMIT 1
)
INSERT INTO paw.asistencia (id_empleado, fecha, hora_entrada, hora_salida, estatus)
SELECT
  u.id_empleado,
  (CURRENT_DATE - d)::date,
  '08:00:00'::time,
  '16:00:00'::time,
  'asistio'
FROM un_cuidador u
CROSS JOIN generate_series(0, 13) d;

-- Asistencia aleatoria 
INSERT INTO paw.asistencia (id_empleado, fecha, hora_entrada, hora_salida, estatus)
SELECT
  e.id_empleado,
  (CURRENT_DATE - d)::date,
  ('08:00:00'::time + (floor(random()*60)::int || ' minutes')::interval)::time,
  ('16:00:00'::time + (floor(random()*60)::int || ' minutes')::interval)::time,
  CASE
    WHEN random() < 0.08 THEN 'falta'
    WHEN random() < 0.20 THEN 'retardo'
    ELSE 'asistio'
  END
FROM paw.empleados e
CROSS JOIN generate_series(0, 13) d
WHERE NOT EXISTS (
  SELECT 1 FROM paw.cuidadores c 
  WHERE c.id_empleado = e.id_empleado 
  ORDER BY c.id_empleado LIMIT 1
);
-- =============================================
-- SOURCE: paw_adopciones.sql
-- =============================================



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