/* ============================================================
   1) 1FN - ATOMICIDAD
   - Entidades: SUCURSAL, EMPLEADOS, FUNDACION.
   ============================================================ */

-- FUNDACION (Entidad independiente)
CREATE TABLE IF NOT EXISTS paw.fundacion (
  id_fundacion BIGSERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  telefono TEXT,
  rfc TEXT
);

-- SUCURSAL (Entidad independiente)
CREATE TABLE IF NOT EXISTS paw.sucursal (
  id_sucursal SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL UNIQUE,     
  municipio TEXT NOT NULL,       
  direccion TEXT
);

-- EMPLEADOS (Entidad independiente)
CREATE TABLE IF NOT EXISTS paw.empleados (
  id_empleado SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  puesto TEXT NOT NULL            
);


/* ============================================================
   2) 2FN - ELIMINAR DEPENDENCIAS PARCIALES
   - Asegurar que todos los atributos dependan de toda la PK.
   - ASISTENCIA tiene PK compuesta (id_empleado, fecha).
   ============================================================ */

CREATE TABLE IF NOT EXISTS paw.asistencia (
  id_empleado INT NOT NULL REFERENCES paw.empleados(id_empleado) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  hora_entrada TIME,
  hora_salida TIME,
  estatus TEXT NOT NULL CHECK (estatus IN ('asistio','falta','retardo')),

  PRIMARY KEY (id_empleado, fecha)
);

CREATE INDEX IF NOT EXISTS idx_asistencia_fecha ON paw.asistencia(fecha);


/* ============================================================
   3) 3FN - ELIMINAR DEPENDENCIAS TRANSITIVAS
   - Separar relaciones de historial para no mantener
     dependencias temporales en la tabla de empleados.
   ============================================================ */

CREATE TABLE IF NOT EXISTS paw.empleado_sucursal_hist (
  id_empleado INT NOT NULL REFERENCES paw.empleados(id_empleado) ON DELETE CASCADE,
  id_sucursal INT NOT NULL REFERENCES paw.sucursal(id_sucursal) ON DELETE CASCADE,
  desde DATE NOT NULL,
  hasta DATE,
  motivo TEXT,

  PRIMARY KEY (id_empleado, id_sucursal, desde)
);

CREATE INDEX IF NOT EXISTS idx_emp_suc_empleado ON paw.empleado_sucursal_hist(id_empleado);
CREATE INDEX IF NOT EXISTS idx_emp_suc_sucursal ON paw.empleado_sucursal_hist(id_sucursal);


/* ============================================================
   4) 4FN - INDEPENDENCIA MÚLTIPLE / ESPECIALIZACIÓN
   - Separar CUIDADORES de EMPLEADOS para evitar atributos nulos
     si no aplican a todos los empleados (herencia/roles).
   - Separar DONACIONES como entidad transaccional independiente.
   ============================================================ */

-- CUIDADORES (Subtipo de Empleado)
CREATE TABLE IF NOT EXISTS paw.cuidadores (
  id_empleado INT PRIMARY KEY REFERENCES paw.empleados(id_empleado) ON DELETE CASCADE,
  area TEXT,                      
  turno TEXT                      
);

-- DONACIONES (Independiente de la operación diaria de sucursal)
CREATE TABLE IF NOT EXISTS paw.donacion (
  id_donacion BIGSERIAL PRIMARY KEY,
  id_fundacion BIGINT NOT NULL REFERENCES paw.fundacion(id_fundacion),
  id_donador BIGINT NULL,                 
  donador_nombre TEXT NULL,               
  donador_email TEXT NULL,                
  monto NUMERIC(12,2) NOT NULL,
  mensaje TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


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


-- Crear sucursales con municipio aleatorio 
TRUNCATE TABLE paw.sucursal RESTART IDENTITY CASCADE;
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


-- Historial empleado-sucursal
TRUNCATE TABLE paw.empleado_sucursal_hist RESTART IDENTITY;
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


-- Asistencia últimos 14 días
TRUNCATE TABLE paw.asistencia RESTART IDENTITY;

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

-- Ver ids de fundacioness
SELECT id_fundacion, nombre, email FROM paw.fundacion ORDER BY id_fundacion;

