
-- =============================================
-- SOURCE: Vacunas_editado1.sql
-- =============================================

SET search_path TO vacunas;

-- Catálogos vacunas 

CREATE TABLE CondicionEspecial (
  id_condicionCond SERIAL NOT NULL,
  NombreCond varchar(255) NOT NULL,
  PRIMARY KEY (id_condicionCond)
);

CREATE TABLE Enfermedad (
  id_enfermedadEnf SERIAL NOT NULL,
  NombreEnf varchar(255) NOT NULL,
  PRIMARY KEY (id_enfermedadEnf)
);

CREATE TABLE Mascota (
  id_mascotaMasc SERIAL NOT NULL,
  nombreMasc varchar(255) NOT NULL,
  PRIMARY KEY (id_mascotaMasc)
);

CREATE TABLE Estado (
  id_estadoEstado SERIAL NOT NULL,
  nombre_estadoestado varchar(255) NOT NULL,
  PRIMARY KEY (id_estadoEstado)
);

CREATE TABLE Tipo_Vacuna (
  id_tipoTipo SERIAL NOT NULL,
  Tipo_vacunaTipo varchar(255) NOT NULL,
  PRIMARY KEY (id_tipoTipo)
);

CREATE TABLE Administracion (
  id_administracionAd SERIAL NOT NULL,
  NombreAd varchar(255) NOT NULL,
  PRIMARY KEY (id_administracionAd)
);

-- Vacuna 
CREATE TABLE Vacuna (
  id_vacunaVac SERIAL NOT NULL,
  NombreVac varchar(255) NOT NULL,
  EscencialVac bool NOT NULL,
  RecomendadaVac bool NOT NULL,
  EsquemaContinuoVac bool, 
  CondicionEspecialid_condicionCond int4,
  PRIMARY KEY (id_vacunaVac)
);

ALTER TABLE Vacuna
  ADD CONSTRAINT FKVacuna_Condicion
  FOREIGN KEY (CondicionEspecialid_condicionCond)
  REFERENCES CondicionEspecial (id_condicionCond);

-- 3) Relaciones  vacuna_enfermedad, vacuna_administracion, vacuna_tipoVacuna

-- vacuna_enfermedad.csv
CREATE TABLE Vacuna_Enfermedad (
  vacunaid_vacunavac int4 NOT NULL,
  enfermedadid_enfermedadenf int4 NOT NULL,
  PRIMARY KEY (vacunaid_vacunavac, enfermedadid_enfermedadenf)
);

ALTER TABLE Vacuna_Enfermedad
  ADD CONSTRAINT FK_VE_Vacuna
  FOREIGN KEY (vacunaid_vacunavac) REFERENCES Vacuna (id_vacunaVac);

ALTER TABLE Vacuna_Enfermedad
  ADD CONSTRAINT FK_VE_Enfermedad
  FOREIGN KEY (enfermedadid_enfermedadenf) REFERENCES Enfermedad (id_enfermedadEnf);

-- vacuna_administracion.csv 
CREATE TABLE Vacuna_Administracion (
  vacunaid_vacunaVac int4 NOT NULL,
  Asministracionid_administracionAd int4 NOT NULL,
  PRIMARY KEY (vacunaid_vacunaVac, Asministracionid_administracionAd)
);

ALTER TABLE Vacuna_Administracion
  ADD CONSTRAINT FK_VA_Vacuna
  FOREIGN KEY (vacunaid_vacunaVac) REFERENCES Vacuna (id_vacunaVac);

ALTER TABLE Vacuna_Administracion
  ADD CONSTRAINT FK_VA_Administracion
  FOREIGN KEY (Asministracionid_administracionAd) REFERENCES Administracion (id_administracionAd);

-- vacuna_tipoVacuna.csv
CREATE TABLE Vacuna_Tipo_Vacuna (
  Vacunaid_VacunaVac int4 NOT NULL,
  Tipo_Vacunaid_tipoTipo int4 NOT NULL,
  PRIMARY KEY (Vacunaid_VacunaVac, Tipo_Vacunaid_tipoTipo)
);

ALTER TABLE Vacuna_Tipo_Vacuna
  ADD CONSTRAINT FK_VTV_Vacuna
  FOREIGN KEY (Vacunaid_VacunaVac) REFERENCES Vacuna (id_vacunaVac);

ALTER TABLE Vacuna_Tipo_Vacuna
  ADD CONSTRAINT FK_VTV_TipoVacuna
  FOREIGN KEY (Tipo_Vacunaid_tipoTipo) REFERENCES Tipo_Vacuna (id_tipoTipo);

-- Esquema 
CREATE TABLE Esquema (
  id_esquemaEsq SERIAL NOT NULL,
  id_VacunaVac int4 NOT NULL,
  id_mascotaMasc int4 NOT NULL,
  id_EstadoEstado int4 NOT NULL,

  EdadPrimeraAplicEsq numeric(4, 2),
  NumeroDosisPrimerAplicEsq numeric(2, 0),
  FrecuenciaDosisPrimerAplicEsq varchar(255),
  IntervaloDosisPrimerAplicEsq numeric(2, 0),

  EdadRefuerzoEsq numeric(4, 2),
  NumeroDosisRefuerzoEsq numeric(2, 0),
  FrecuenciaDosisRefuerzoEsq varchar(255),
  IntervaloDosisRefuerzoEsq numeric(2, 0),

  PRIMARY KEY (id_esquemaEsq)
);

ALTER TABLE Esquema
  ADD CONSTRAINT FK_Esq_Vacuna
  FOREIGN KEY (id_VacunaVac) REFERENCES Vacuna (id_vacunaVac);

ALTER TABLE Esquema
  ADD CONSTRAINT FK_Esq_Mascota
  FOREIGN KEY (id_mascotaMasc) REFERENCES Mascota (id_mascotaMasc);

ALTER TABLE Esquema
  ADD CONSTRAINT FK_Esq_Estado
  FOREIGN KEY (id_EstadoEstado) REFERENCES Estado (id_estadoEstado);


TRUNCATE TABLE vacunas.vacuna_enfermedad;

truncate table vacunas.vacuna_tipo_vacuna;

truncate table vacunas.esquema;
-- =============================================
-- SOURCE: create_auth_tables.sql
-- =============================================

--tabla autenticación ya que usuario no tiene pasword 
DROP TABLE IF EXISTS paw.usuario_auth CASCADE;

CREATE TABLE paw.usuario_auth (
  id_usuario BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  rol TEXT NOT NULL CHECK (rol IN ('adoptante', 'fundacion')),
  id_adoptante BIGINT NULL,
  id_fundacion BIGINT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

SELECT email, password_hash, rol FROM paw.usuario_auth;
-- =============================================
-- SOURCE: domicilios.sql
-- =============================================

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
-- =============================================
-- SOURCE: paw.sql
-- =============================================

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


-- Lista negra
TRUNCATE TABLE paw.lista_negra RESTART IDENTITY;
-- =============================================
-- SOURCE: paw_fundacion.sql
-- =============================================

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


-- Crear sucursales con municipio aleatorio 
TRUNCATE TABLE paw.sucursal RESTART IDENTITY CASCADE;


-- Historial empleado-sucursal
TRUNCATE TABLE paw.empleado_sucursal_hist RESTART IDENTITY;


-- Asistencia últimos 14 días
TRUNCATE TABLE paw.asistencia RESTART IDENTITY;

-- Ver ids de fundacioness
SELECT id_fundacion, nombre, email FROM paw.fundacion ORDER BY id_fundacion;
-- =============================================
-- SOURCE: paw_adopciones.sql
-- =============================================

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

-- agregar id_domicilio a adoptante perfil 
ALTER TABLE paw.adoptante_perfil
  ADD COLUMN IF NOT EXISTS id_domicilio BIGINT;


-- Citas
TRUNCATE TABLE paw.cita_visita RESTART IDENTITY CASCADE;

-- Adopciones
TRUNCATE TABLE paw.adopcion RESTART IDENTITY CASCADE;