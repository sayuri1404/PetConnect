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

