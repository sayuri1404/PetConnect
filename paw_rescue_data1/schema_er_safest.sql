-- Dependencias externas requeridas para las llaves foráneas
CREATE SCHEMA vacunas;

CREATE TABLE vacunas.mascota (
    id_mascotamasc SERIAL PRIMARY KEY,
    nombre_especie TEXT
);

CREATE TABLE vacunas.vacuna (
    id_vacunavac SERIAL PRIMARY KEY,
    nombre TEXT,
    descripcion TEXT
);
--tabla autenticación ya que usuario no tiene pasword 

CREATE TABLE paw.usuario_auth (
  id_usuario BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('adoptante', 'fundacion')),
  id_adoptante BIGINT NULL,
  id_fundacion BIGINT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);



-- Usamos ON CONFLICT para que si los emails ya existen, solo actualice el hash





-- tablas sepomex
CREATE SCHEMA sepomex;

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
 



-- =========================================================
-- Reasignar CP + asentamiento con pares de sepomex
-- =========================================================

--poblar domicilio 







/* =========================================================
   1) CREAR ESQUEMA PAW
   ========================================================= */
CREATE SCHEMA paw;

/* =========================================================
   2) 1FN - ATOMICIDAD
   - Se crea una tabla “staging” (stg_mascota)
     donde llega el CSV “tal cual”.
   ========================================================= */


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
CREATE TABLE paw.raza (
  id_raza SERIAL PRIMARY KEY,
  especie_id INT NOT NULL REFERENCES vacunas.mascota(id_mascotamasc),
  nombre TEXT NOT NULL,
  UNIQUE (especie_id, nombre)
);

--COLOR
CREATE TABLE paw.color (
  id_color SERIAL PRIMARY KEY,
  nombre TEXT UNIQUE NOT NULL
);

-- PADECIMIENTO
CREATE TABLE paw.padecimiento (
  id_padecimiento SERIAL PRIMARY KEY,
  nombre TEXT UNIQUE NOT NULL
);

-- Tabla principal
CREATE TABLE paw.mascota_rescatada (
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
CREATE TABLE paw.mascota_color (
  id_mascota INT REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  id_color INT REFERENCES paw.color(id_color),
  es_principal BOOLEAN NOT NULL,
  PRIMARY KEY (id_mascota, id_color, es_principal)
);

-- Padecimientos
CREATE TABLE paw.mascota_padecimiento (
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
CREATE TABLE paw.rescate (
  id_rescate SERIAL PRIMARY KEY,
  id_mascota INT UNIQUE NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  alcaldia TEXT NOT NULL,
  situacion TEXT NOT NULL,
  necesidades_especiales TEXT
);

-- Dueños anteriores
CREATE TABLE paw.duenio (
  id_duenio SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  identificacion TEXT
);

-- Historial de dueños anteriores (N:M)
CREATE TABLE paw.mascota_duenio_hist (
  id_mascota INT REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  id_duenio INT REFERENCES paw.duenio(id_duenio),
  desde DATE,
  hasta DATE,
  motivo TEXT,
  PRIMARY KEY (id_mascota, id_duenio, desde)
);

-- Lista negra (1:N)
CREATE TABLE paw.lista_negra (
  id_lista SERIAL PRIMARY KEY,
  id_duenio INT NOT NULL REFERENCES paw.duenio(id_duenio),
  motivo TEXT NOT NULL,
  inicio DATE NOT NULL,
  fin DATE,
  es_permanente BOOLEAN NOT NULL DEFAULT false
);

-- Expediente médico general (1:N)
CREATE TABLE paw.evento_medico (
  id_evento SERIAL PRIMARY KEY,
  id_mascota INT NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,
  tipo TEXT NOT NULL,    
  fecha DATE,
  detalle TEXT
);

-- Vacunas aplicadas (1:N)
CREATE TABLE paw.vacuna_aplicada (
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

-- Colores (principal)

-- Colores (secundario)

-- Padecimientos


/* =========================================================
 Poblar tabla principal (mascota_rescatada)
   ========================================================= */



/* =========================================================
  Poblar tablas en (4FN)
   ========================================================= */

-- mascota_color principal

-- mascota_color secundario

-- mascota_padecimiento


/* =========================================================
   Poblar tablas faltantes
   ========================================================= */

-- Rescate (usa municipio)



-- Dueño 


-- Historial de dueños anteriores


-- Lista negra



-- Evento médico


-- Vacuna aplicada (1 o 2 vacunas aleatorias por mascota)

-- SUCURSAL (Entidad independiente)
CREATE TABLE paw.sucursal (
  id_sucursal SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL UNIQUE,     
  municipio TEXT NOT NULL,       
  direccion TEXT
);

-- EMPLEADOS (Entidad independiente)
CREATE TABLE paw.empleados (
  id_empleado SERIAL PRIMARY KEY,
  nombre TEXT NOT NULL,
  puesto TEXT NOT NULL            
);


/* ============================================================
   2) 2FN - ELIMINAR DEPENDENCIAS PARCIALES
   - Asegurar que todos los atributos dependan de toda la PK.
   - ASISTENCIA tiene PK compuesta (id_empleado, fecha).
   ============================================================ */

CREATE TABLE paw.asistencia (
  id_empleado INT NOT NULL REFERENCES paw.empleados(id_empleado) ON DELETE CASCADE,
  fecha DATE NOT NULL,
  hora_entrada TIME,
  hora_salida TIME,
  estatus TEXT NOT NULL CHECK (estatus IN ('asistio','falta','retardo')),

  PRIMARY KEY (id_empleado, fecha)
);

CREATE INDEX idx_asistencia_fecha ON paw.asistencia(fecha);


/* ============================================================
   3) 3FN - ELIMINAR DEPENDENCIAS TRANSITIVAS
   - Separar relaciones de historial para no mantener
     dependencias temporales en la tabla de empleados.
   ============================================================ */

CREATE TABLE paw.empleado_sucursal_hist (
  id_empleado INT NOT NULL REFERENCES paw.empleados(id_empleado) ON DELETE CASCADE,
  id_sucursal INT NOT NULL REFERENCES paw.sucursal(id_sucursal) ON DELETE CASCADE,
  desde DATE NOT NULL,
  hasta DATE,
  motivo TEXT,

  PRIMARY KEY (id_empleado, id_sucursal, desde)
);

CREATE INDEX idx_emp_suc_empleado ON paw.empleado_sucursal_hist(id_empleado);
CREATE INDEX idx_emp_suc_sucursal ON paw.empleado_sucursal_hist(id_sucursal);


/* ============================================================
   4) 4FN - INDEPENDENCIA MÚLTIPLE / ESPECIALIZACIÓN
   - Separar CUIDADORES de EMPLEADOS para evitar atributos nulos
     si no aplican a todos los empleados (herencia/roles).
   - Separar DONACIONES como entidad transaccional independiente.
   ============================================================ */

-- CUIDADORES (Subtipo de Empleado)
CREATE TABLE paw.cuidadores (
  id_empleado INT PRIMARY KEY REFERENCES paw.empleados(id_empleado) ON DELETE CASCADE,
  area TEXT,                      
  turno TEXT                      
);

-- DONACIONES (Independiente de la operación diaria de sucursal)
CREATE TABLE paw.donacion (
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


-- Crear sucursales con municipio aleatorio 


-- Crear empleados 


-- Marcar algunos empleados como cuidadores 


-- Historial empleado-sucursal

-- Otros empleados con 1 sucursal fija


-- Asistencia últimos 14 días


-- Asistencia aleatoria 

-- Ver ids de fundacioness

/* ============================================================
   1) 1FN - ENTIDADES ATÓMICAS
   - Definir tablas con valores atómicos y PK única.
   ============================================================ */

CREATE TABLE paw.adoptante (
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

CREATE TABLE paw.adoptante_perfil (
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

CREATE TABLE paw.solicitud_adopcion (
  id_solicitud  BIGSERIAL PRIMARY KEY,
  id_adoptante  BIGINT NOT NULL REFERENCES paw.adoptante(id_adoptante) ON DELETE CASCADE,
  id_mascota    INT NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,

  fecha_solicitud DATE NOT NULL DEFAULT CURRENT_DATE,

  estado TEXT NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente','en_revision','aprobada','rechazada','cancelada','adoptada')),

  motivo_rechazo TEXT,

  UNIQUE (id_adoptante, id_mascota)
);

CREATE INDEX idx_solicitud_adoptante ON paw.solicitud_adopcion(id_adoptante);
CREATE INDEX idx_solicitud_mascota ON paw.solicitud_adopcion(id_mascota);

ALTER TABLE paw.solicitud_adopcion
  ADD COLUMN id_fundacion BIGINT;


/* ============================================================
   4) 5FN - FLUJOS DE PROCESO SEPARADOS 
   - Separar cada etapa del proceso (Cita, Evaluación, Adopción, Supervisión)
     en su propia tabla.
   - Esto evita anomalías de actualización y permite que cada etapa
     exista (o no) independientemente, uniéndose por la solicitud/adopción.
   ============================================================ */

-- CITAS (Independiente de la evaluación final)
CREATE TABLE paw.cita_visita (
  id_cita     BIGSERIAL PRIMARY KEY,
  id_solicitud BIGINT NOT NULL REFERENCES paw.solicitud_adopcion(id_solicitud) ON DELETE CASCADE,

  fecha_hora  TIMESTAMP NOT NULL,
  estado      TEXT NOT NULL DEFAULT 'programada'
    CHECK (estado IN ('programada','asistio','no_asistio','reprogramada','cancelada')),

  notas       TEXT
);

CREATE INDEX idx_cita_fecha ON paw.cita_visita(fecha_hora);


-- EVALUACIÓN (Resultado formal, separado de la cita)
CREATE TABLE paw.evaluacion (
  id_evaluacion BIGSERIAL PRIMARY KEY,
  id_solicitud  BIGINT UNIQUE NOT NULL REFERENCES paw.solicitud_adopcion(id_solicitud) ON DELETE CASCADE,

  fecha         DATE NOT NULL DEFAULT CURRENT_DATE,
  resultado     BOOLEAN NOT NULL,     -- true=aprobado, false=rechazado
  puntaje       INT CHECK (puntaje BETWEEN 0 AND 100),
  comentarios   TEXT
);


-- ADOPCIÓN 
CREATE TABLE paw.adopcion (
  id_adopcion   BIGSERIAL PRIMARY KEY,
  id_solicitud  BIGINT UNIQUE NOT NULL REFERENCES paw.solicitud_adopcion(id_solicitud) ON DELETE CASCADE,

  id_adoptante  BIGINT NOT NULL REFERENCES paw.adoptante(id_adoptante) ON DELETE CASCADE,
  id_mascota    INT NOT NULL REFERENCES paw.mascota_rescatada(id_mascota) ON DELETE CASCADE,

  fecha_adopcion DATE NOT NULL DEFAULT CURRENT_DATE,
  contrato_url  TEXT,

  UNIQUE (id_mascota)
);

CREATE INDEX idx_adopcion_fecha ON paw.adopcion(fecha_adopcion);


-- SUPERVISIONES 
CREATE TABLE paw.supervision (
  id_supervision BIGSERIAL PRIMARY KEY,
  id_adopcion    BIGINT NOT NULL REFERENCES paw.adopcion(id_adopcion) ON DELETE CASCADE,

  fecha          DATE NOT NULL,
  tipo           TEXT NOT NULL
    CHECK (tipo IN ('1_mes','anual','extra')),

  resultado      TEXT CHECK (resultado IN ('ok','observacion','riesgo')),

  observaciones  TEXT
);

CREATE INDEX idx_supervision_adopcion ON paw.supervision(id_adopcion);

/* ============================================================
   POBLADO DE DATOS
   ============================================================ */

-- 1) Adoptantes

-- 2) Perfil adoptante 
--adoptantes modificaciones

--datos faltantes de la base
-- Datos personales y contacto
ALTER TABLE paw.adoptante_perfil ADD COLUMN edad INT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN tel_movil TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN tel_fijo TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN email TEXT;

-- Dirección (guardamos domicilio completo "simple")
ALTER TABLE paw.adoptante_perfil ADD COLUMN codigo_postal CHAR(5);
ALTER TABLE paw.adoptante_perfil ADD COLUMN asentamiento TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN calle TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN num_exterior TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN num_interior TEXT;

-- Vivienda
ALTER TABLE paw.adoptante_perfil ADD COLUMN tipo_vivienda TEXT;        
ALTER TABLE paw.adoptante_perfil ADD COLUMN situacion_vivienda TEXT;   
ALTER TABLE paw.adoptante_perfil ADD COLUMN contacto_arrendador TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN espacio_cercado TEXT;     

-- Hogar y experiencia
ALTER TABLE paw.adoptante_perfil ADD COLUMN adultos_hogar INT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN personas_hogar INT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN ninos_rango TEXT[];       
ALTER TABLE paw.adoptante_perfil ADD COLUMN otras_mascotas TEXT[];    
ALTER TABLE paw.adoptante_perfil ADD COLUMN otras_mascotas_detalle TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN experiencia_previa TEXT; 
ALTER TABLE paw.adoptante_perfil ADD COLUMN nivel_experiencia Boolean;  
ALTER TABLE paw.adoptante_perfil ADD COLUMN horas_fuera TEXT;        

-- Compromiso y estilo de vida
ALTER TABLE paw.adoptante_perfil ADD COLUMN nivel_actividad TEXT;     
ALTER TABLE paw.adoptante_perfil ADD COLUMN gastos_vet TEXT;          
ALTER TABLE paw.adoptante_perfil ADD COLUMN compromiso_esterilizacion TEXT; 
ALTER TABLE paw.adoptante_perfil ADD COLUMN tiempo_dedicado TEXT;     
ALTER TABLE paw.adoptante_perfil ADD COLUMN motivo_adopcion TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN que_haria_cambios TEXT;
ALTER TABLE paw.adoptante_perfil ADD COLUMN nivel_economico TEXT;

--modificaciones adoptante perfil


--  Completar datos de calle/números si faltan 

-- agregar id_domicilio a adoptante perfil 
ALTER TABLE paw.adoptante_perfil
  ADD COLUMN id_domicilio BIGINT;


-- Reasignar id_domicilio a cada adoptante_perfil




/* ===========================
  Poblar tablas faltantes
============================== */

-- Solicitudes





-- Citas


--Evaluación

-- 6) Marcar solicitud como aprobada/rechazada según evaluación

-- Adopciones


-- Supervisión
-- 1) Supervisión del Primer Mes

-- 2) Supervisión del Primer Año
