--Consultas solicitadas 

SET search_path TO paw, vacunas, sepomex, public;

/* =========================================================
   CONSULTA 1) Mascotas recuperadas HOY + datos rescate + personales
========================================================= */
SELECT m.nombre, m.tamanio, m.sexo, m.id_raza, r.fecha, r.alcaldia, r.situacion
FROM paw.mascota_rescatada m
JOIN paw.rescate r ON m.id_mascota = r.id_mascota
WHERE r.fecha = CURRENT_DATE;


/* =========================================================
   CONSULTA 2) Mascotas recuperadas en "Gustavo A. Madero" en 2025
========================================================= */
SELECT m.nombre, r.fecha, r.alcaldia
FROM paw.mascota_rescatada m
JOIN paw.rescate r ON m.id_mascota = r.id_mascota
WHERE r.alcaldia = 'Gustavo A. Madero' 
  AND r.fecha BETWEEN '2025-01-01' AND '2025-12-31';

/* =========================================================
   CONSULTA 3) Personas a las que se les han quitado más de 1 mascota
   -> usamos duenio + mascota_duenio_hist
========================================================= */
SELECT
  d.id_duenio,
  d.nombre,
  COUNT(DISTINCT h.id_mascota) AS mascotas_retiradas
FROM paw.mascota_duenio_hist h
JOIN paw.duenio d ON d.id_duenio = h.id_duenio
GROUP BY d.id_duenio, d.nombre
HAVING COUNT(DISTINCT h.id_mascota) > 1
ORDER BY mascotas_retiradas DESC, d.nombre;


/* =========================================================
   CONSULTA 4) Personas que han adoptado a más de 1 mascota
========================================================= */
SELECT 
    a.id_adoptante, 
    a.nombre AS nombre_adoptante, 
    COUNT(ad.id_mascota) AS total_mascotas_adoptadas
FROM paw.adoptante a
JOIN paw.adopcion ad ON a.id_adoptante = ad.id_adoptante
GROUP BY a.id_adoptante, a.nombre
HAVING COUNT(ad.id_mascota) > 1
ORDER BY total_mascotas_adoptadas DESC;

/* =========================================================
   CONSULTA 5) Relación Mascota–Adoptante idóneo
   Reglas:
   - Económico alto + perro requiere cuidados especiales (salud o rescate)
   - O tiene patio (casa-jardin) y perro grande/mediano
   - O vive en departamento y perro chico
========================================================= */
WITH perro_especial AS (
  SELECT DISTINCT m.id_mascota
  FROM paw.mascota_rescatada m
  LEFT JOIN paw.mascota_padecimiento mp ON mp.id_mascota = m.id_mascota
  LEFT JOIN paw.rescate r ON r.id_mascota = m.id_mascota
  WHERE m.especie_id = 1 -- perro
    AND (
      mp.id_padecimiento IS NOT NULL
      OR r.necesidades_especiales IS NOT NULL
    )
)
SELECT
  adp.id_adoptante,
  adp.nombre AS adoptante,
  p.nivel_economico,
  p.tipo_vivienda,
  m.id_mascota,
  m.nombre AS mascota,
  m.tamanio,
  CASE
    WHEN (p.nivel_economico = 'alto' AND m.especie_id = 1 AND m.id_mascota IN (SELECT id_mascota FROM perro_especial))
      THEN 'Económico alto + cuidados especiales'
    WHEN (p.tipo_vivienda = 'casa-jardin' AND m.especie_id = 1 AND m.tamanio IN ('grande','mediano'))
      THEN 'Patio + perro grande/mediano'
    WHEN (p.tipo_vivienda LIKE 'departamento%' AND m.especie_id = 1 AND m.tamanio = 'pequeño')
      THEN 'Departamento + perro chico'
    ELSE 'No idóneo'
  END AS regla
FROM paw.adoptante adp
JOIN paw.adoptante_perfil p ON p.id_adoptante = adp.id_adoptante
JOIN paw.mascota_rescatada m ON m.especie_id = 1 -- perro
WHERE
  (p.nivel_economico = 'alto' AND m.id_mascota IN (SELECT id_mascota FROM perro_especial))
  OR (p.tipo_vivienda = 'casa-jardin' AND m.tamanio IN ('grande','mediano'))
  OR (p.tipo_vivienda LIKE 'departamento%' AND m.tamanio = 'pequeño')
ORDER BY adp.id_adoptante, m.id_mascota;


/* =========================================================
   CONSULTA 6) Visitantes que vendrán HOY a ver mascotas, por hora
========================================================= */
SELECT a.nombre AS visitante, c.fecha_hora, m.nombre AS mascota_a_ver
FROM paw.cita_visita c
JOIN paw.solicitud_adopcion s ON c.id_solicitud = s.id_solicitud
JOIN paw.adoptante a ON s.id_adoptante = a.id_adoptante
JOIN paw.mascota_rescatada m ON s.id_mascota = m.id_mascota
WHERE c.fecha_hora::date = CURRENT_DATE
ORDER BY c.fecha_hora ASC;

/* =========================================================
   CONSULTA 7) Perros adoptados ESTE MES en la CDMX
========================================================= */
SELECT DISTINCT
  a.id_adopcion,
  a.fecha_adopcion,
  m.id_mascota,
  m.nombre AS mascota,
  ad.id_adoptante,
  ad.nombre AS adoptante,
  p.codigo_postal,
  c.entidad_id,
  CASE c.entidad_id
    WHEN 9  THEN 'CDMX'
    WHEN 15 THEN 'EDOMEX'
    ELSE 'OTRO'
  END AS estado
FROM paw.adopcion a
JOIN paw.mascota_rescatada m  ON m.id_mascota = a.id_mascota
JOIN paw.adoptante ad         ON ad.id_adoptante = a.id_adoptante
JOIN paw.adoptante_perfil p   ON p.id_adoptante = ad.id_adoptante
JOIN sepomex.codigos c
  ON c.codigo_postal::text = lpad(regexp_replace(p.codigo_postal::text, '\D', '', 'g'), 5, '0')
WHERE
  m.especie_id = 1
  AND a.fecha_adopcion >= date_trunc('month', CURRENT_DATE)::date
  AND a.fecha_adopcion <  (date_trunc('month', CURRENT_DATE) + INTERVAL '1 month')::date
  AND c.entidad_id IN (9, 15)
ORDER BY a.fecha_adopcion DESC;


/* =========================================================
   CONSULTA 8) Cuidadores que han venido TODOS los días de la semana
========================================================= */
WITH dias AS (
  SELECT generate_series(CURRENT_DATE - 6, CURRENT_DATE, interval '1 day')::date AS dia
)
SELECT
  c.id_empleado,
  e.nombre,
  COUNT(DISTINCT a.fecha) AS dias_cubiertos
FROM paw.cuidadores c
JOIN paw.empleados e ON e.id_empleado = c.id_empleado
JOIN dias d ON TRUE
LEFT JOIN paw.asistencia a
  ON a.id_empleado = c.id_empleado
 AND a.fecha = d.dia
 AND lower(a.estatus) <> 'falta' 
GROUP BY c.id_empleado, e.nombre
HAVING COUNT(DISTINCT a.fecha) = 7
ORDER BY e.nombre;

/* =========================================================
   CONSULTA 9) Empleados que han laborado en TODAS las sucursales
========================================================= */
SELECT
  e.id_empleado,
  e.nombre
FROM paw.empleados e
JOIN paw.empleado_sucursal_hist h ON h.id_empleado = e.id_empleado
GROUP BY e.id_empleado, e.nombre
HAVING COUNT(DISTINCT h.id_sucursal) = (SELECT COUNT(*) FROM paw.sucursal)
ORDER BY e.nombre;


/* =========================================================
   CONSULTA 10) Perros que tienen TODAS sus vacunas esenciales al corriente
   Criterio:
   - Para cada vacuna esencial (vacunas.vacuna.esencialvac = true)
   - debe existir una aplicación para el perro con:
     (proxima_dosis IS NULL OR proxima_dosis >= hoy)
========================================================= */
SELECT
  m.id_mascota,
  m.nombre,
  COUNT(DISTINCT va.id_vacuna) AS vacunas_distintas,
  MAX(va.fecha_aplicacion)     AS ultima_aplicacion
FROM paw.mascota_rescatada m
JOIN paw.vacuna_aplicada va
  ON va.id_mascota = m.id_mascota
WHERE
  m.especie_id = 1  -- perro (si en tu BD perro=2, cámbialo)
  AND NOT EXISTS (
    SELECT 1
    FROM paw.vacuna_aplicada va2
    WHERE va2.id_mascota = m.id_mascota
      AND va2.proxima_dosis IS NOT NULL
      AND va2.proxima_dosis < CURRENT_DATE
  )
GROUP BY m.id_mascota, m.nombre
ORDER BY m.nombre;








