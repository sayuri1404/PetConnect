💉 Catálogo y Esquemas de Vacunación VeterinariaEste repositorio contiene el modelo relacional y los archivos de datos (CSV) para la base de datos de esquemas de vacunación. El modelo está diseñado en Tercera Forma Normal (3NF) para asegurar la integridad y flexibilidad de los datos.1. Estructura del Modelo (11 Tablas)El modelo se compone de 11 tablas basadas en los comandos DDL proporcionados.Tablas de Catálogo y Entidades (Nivel 1 & 2)TablaPropósitoClave Primaria (PK)Dependencias (FKs)CSV AsociadoMascotaTipos de animales (Perro, Gato, Ave).id_mascotaMascNingunamascota.csvEstadoCondición de vida (De casa, De refugio).id_estadoEstadoNingunaestado.csvEnfermedadNombres de las enfermedades prevenibles.id_enfermedadEnfNingunaenfermedad.csvTipo_VacunaComponente biológico (MLV, Inactivada, etc.).id_tipoTipoNingunatipo_vacuna.csvAdministracionVía de aplicación (Parenteral, Oral, etc.).id_administracionAdNingunaadministracion.csvCondicionEspecialCatálogo de condiciones de aplicación.id_condicionCondNingunacondicion_especial.csvVacunaProducto comercial final (Contiene propiedades booleanas).id_vacunaVacCondicionEspecialid_condicionCondvacuna.csvTablas de Unión y Reglas (Nivel 3 & 4)TablaPropósitoClave Primaria (PK)Dependencias (FKs)CSV AsociadoVacuna_Tipo_VacunaEnlace M:N entre Vacuna y sus Tipos/Activos.PK CompuestaVacuna, Tipo_Vacunavacuna_tipo_vacuna.csvVacuna_EnfermedadEnlace M:N entre Vacuna y las Enfermedades que trata.PK CompuestaVacuna, Enfermedadvacuna_enfermedad.csvVacuna_AdministracionEnlace M:N entre Vacuna y sus Vías de Administración.PK CompuestaVacuna, Administracionvacuna_administracion.csvEsquemaTabla central de reglas de dosificación.id_esquemaEsqVacuna, Mascota, Estadoesquema.csv2. Proceso de Carga de Datos (PostgreSQL)Para importar los archivos CSV, es OBLIGATORIO seguir el orden de dependencia, cargando primero los catálogos antes que las tablas que los referencian.Fase A: Preparación de la Base de DatosAsegúrate de tener un archivo SQL (ej: vacunas.sql) con los comandos CREATE TABLE y ALTER TABLE.
Ejecuta los comandos para crear la estructura (tablas y restricciones).# Entrar a la terminal de PostgreSQL (psql)
psql -U tu_usuario -d tu_base_de_datos

# Ejecutar el archivo de esquema:
psql -U tu_usuario -d tu_base_de_datos -f ruta/a/vacunas.sql
Fase B: Carga de Archivos CSVUtiliza el comando \COPY de PostgreSQL (dentro de psql) o el comando COPY (desde la terminal) para importar los CSV.Nota: Asegúrate de que tus CSV estén codificados en UTF-8 y usen la coma.Nivel 1: Carga de Catálogos (Sin FKs)Estos se cargan primero.# 1-6. Carga de Catálogos
\COPY Mascota FROM 'mascota.csv' WITH (FORMAT csv, HEADER true);
\COPY Estado FROM 'estado.csv' WITH (FORMAT csv, HEADER true);
\COPY Enfermedad FROM 'enfermedad.csv' WITH (FORMAT csv, HEADER true);
\COPY Tipo_Vacuna FROM 'tipo_vacuna.csv' WITH (FORMAT csv, HEADER true);
\COPY Administracion FROM 'administracion.csv' WITH (FORMAT csv, HEADER true);
\COPY CondicionEspecial FROM 'condicion_especial.csv' WITH (FORMAT csv, HEADER true);
Nivel 2: Carga de la Tabla Principal# 7. Carga de Vacunas (Depende de CondicionEspecial)
\COPY Vacuna FROM 'vacuna.csv' WITH (FORMAT csv, HEADER true);
Nivel 3: Carga de Tablas de Enlace (Uniones M:N)# 8-10. Carga de Enlaces (Dependen de Vacuna y Catálogos)
\COPY Vacuna_Tipo_Vacuna FROM 'vacuna_tipo_vacuna.csv' WITH (FORMAT csv, HEADER true);
\COPY Vacuna_Enfermedad FROM 'vacuna_enfermedad.csv' WITH (FORMAT csv, HEADER true);
\COPY Vacuna_Administracion FROM 'vacuna_administracion.csv' WITH (FORMAT csv, HEADER true);
Nivel 4: Carga de la Tabla Central de Reglas# 11. Carga del Esquema (Depende de Vacuna, Mascota, Estado)
\COPY Esquema FROM 'esquema.csv' WITH (FORMAT csv, HEADER true);
Una vez completados estos pasos, todos los datos estarán cargados en la base de datos con las Claves Foráneas establecidas correctamente.