-- Dependencias externas requeridas para las llaves foráneas
CREATE SCHEMA IF NOT EXISTS vacunas;

CREATE TABLE IF NOT EXISTS vacunas.mascota (
    id_mascotamasc SERIAL PRIMARY KEY,
    nombre_especie TEXT
);

CREATE TABLE IF NOT EXISTS vacunas.vacuna (
    id_vacunavac SERIAL PRIMARY KEY,
    nombre TEXT,
    descripcion TEXT
);
