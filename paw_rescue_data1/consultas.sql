-- =========================================================
-- CONSULTA 1) Mascotas recuperadas HOY
-- =========================================================
SELECT m.nombre, m.tamanio, m.sexo, r.fecha, r.alcaldia, r.situacion
FROM paw.mascota_rescatada m
JOIN paw.rescate r ON m.id_mascota = r.id_mascota
WHERE r.fecha = CURRENT_DATE;

-- =========================================================
-- CONSULTA 2) Mascotas recuperadas en "Gustavo A. Madero" en 2025
-- =========================================================
SELECT m.nombre, r.fecha, r.alcaldia
FROM paw.mascota_rescatada m
JOIN paw.rescate r ON m.id_mascota = r.id_mascota
WHERE r.alcaldia = 'Gustavo A. Madero' 
  AND r.fecha BETWEEN '2025-01-01' AND '2025-12-31';

-- =========================================================
-- CONSULTA 3) Personas a las que se les han quitado más de 1 mascota
-- =========================================================
SELECT d.nombre, COUNT(DISTINCT h.id_mascota) AS mascotas_retiradas
FROM paw.mascota_duenio_hist h
JOIN paw.duenio d ON d.id_duenio = h.id_duenio
GROUP BY d.id_duenio, d.nombre
HAVING COUNT(DISTINCT h.id_mascota) > 1
ORDER BY mascotas_retiradas DESC;

-- =========================================================
-- CONSULTA 4) Personas que han adoptado a más de 1 mascota
-- =========================================================
SELECT a.nombre AS nombre_adoptante, COUNT(ad.id_mascota) AS total_mascotas
FROM paw.adoptante a
JOIN paw.adopcion ad ON a.id_adoptante = ad.id_adoptante
GROUP BY a.id_adoptante, a.nombre
HAVING COUNT(ad.id_mascota) > 1;

-- =========================================================
-- CONSULTA 5) Relación Mascota-Adoptante idóneo
-- =========================================================
SELECT adp.nombre AS adoptante, m.nombre AS mascota,
  CASE
    WHEN (p.nivel_economico = 'alto' AND r.necesidades_especiales IS NOT NULL) THEN 'Idoneo: Cuidados Especiales'
    WHEN (p.tipo_vivienda = 'casa-jardin' AND m.tamanio IN ('grande','mediano')) THEN 'Idoneo: Patio'
    WHEN (p.tipo_vivienda LIKE 'departamento%' AND m.tamanio = 'pequeño') THEN 'Idoneo: Departamento'
    ELSE 'No idoneo'
  END AS clasificacion
FROM paw.adoptante adp
JOIN paw.adoptante_perfil p ON p.id_adoptante = adp.id_adoptante
JOIN paw.mascota_rescatada m ON m.especie_id = 1
LEFT JOIN paw.rescate r ON r.id_mascota = m.id_mascota;

-- =========================================================
-- CONSULTA 6) Lista de visitantes que vendrán HOY (por hora)
-- =========================================================
SELECT a.nombre AS visitante, c.fecha_hora, m.nombre AS mascota
FROM paw.cita_visita c
JOIN paw.solicitud_adopcion s ON c.id_solicitud = s.id_solicitud
JOIN paw.adoptante a ON s.id_adoptante = a.id_adoptante
JOIN paw.mascota_rescatada m ON s.id_mascota = m.id_mascota
WHERE c.fecha_hora::date = CURRENT_DATE
ORDER BY c.fecha_hora ASC;

-- =========================================================
-- CONSULTA 7) Perros adoptados ESTE MES en la CDMX
-- =========================================================
SELECT m.nombre, a.fecha_adopcion, 'CDMX' as estado
FROM paw.adopcion a
JOIN paw.mascota_rescatada m ON m.id_mascota = a.id_mascota
JOIN paw.adoptante_perfil p ON p.id_adoptante = a.id_adoptante
JOIN sepomex.codigos c ON c.codigo_postal = p.codigo_postal
WHERE m.especie_id = 1
  AND a.fecha_adopcion >= date_trunc('month', CURRENT_DATE)
  AND c.entidad_id = 9; -- CDMX

-- =========================================================
-- CONSULTA 8) Cuidadores que han venido TODOS los días de la semana
-- =========================================================
WITH dias_semana AS (
   SELECT generate_series(CURRENT_DATE - 6, CURRENT_DATE, '1 day')::date AS dia
)
SELECT e.nombre, COUNT(DISTINCT a.fecha) as dias_asistidos
FROM paw.cuidadores c
JOIN paw.empleados e ON e.id_empleado = c.id_empleado
JOIN dias_semana d ON TRUE
LEFT JOIN paw.asistencia a ON a.id_empleado = c.id_empleado AND a.fecha = d.dia
GROUP BY e.id_empleado, e.nombre
HAVING COUNT(DISTINCT a.fecha) = 7;

-- =========================================================
-- CONSULTA 9) Empleados en TODAS las sucursales
-- =========================================================
SELECT e.nombre
FROM paw.empleados e
JOIN paw.empleado_sucursal_hist h ON h.id_empleado = e.id_empleado
GROUP BY e.id_empleado, e.nombre
HAVING COUNT(DISTINCT h.id_sucursal) = (SELECT COUNT(*) FROM paw.sucursal);

-- =========================================================
-- CONSULTA 10) Perros con TODAS sus vacunas al corriente
-- =========================================================
SELECT m.nombre
FROM paw.mascota_rescatada m
WHERE m.especie_id = 1
  AND NOT EXISTS (
    SELECT 1 FROM paw.vacuna_aplicada va
    WHERE va.id_mascota = m.id_mascota
      AND va.proxima_dosis < CURRENT_DATE
  );
