
/*
------------------ En el siguiente codigo les voy a mostar un equivalente a mi trabajo actual de 
CONTEXTO:
- La universidad nos pide estimar nota media de estudiantes de cada curso.
- Tengo que crear e ingresar los datos que me piden.
- Diseñar los ingresos en el tiempo de manera automatica para que luego se pueda correr el modelo

*/


------------------ 1. Crear las tablas
------ Despues de ya conocer el dominio, entiendo que voy a tener distintas tablas 


--- DATABASE base_alumno
CREATE DATABASE base_alumno;
USE base_alumno;

CREATE TABLE personal_informacion (
    alumno_id INT PRIMARY KEY,
    nombre VARCHAR(100),
    apellido VARCHAR(100),
    edad INT,
    fecha_nac DATE,
    email VARCHAR(100),
    telefono VARCHAR(20),
    nacionalidad VARCHAR(50),
    pais VARCHAR(50),
    provincia VARCHAR(50),
    estado_civil VARCHAR(20),
    trabaja BOOLEAN,
    horas_trabajadas_sem INT
);

CREATE TABLE rama_familiar (
    alumno_id INT PRIMARY KEY,
    situacion_padre VARCHAR(100),
    situacion_madre VARCHAR(100),
    estudio_padre VARCHAR(100),
    estudio_madre VARCHAR(100),
    actividad_padre VARCHAR(100),
    actividad_madre VARCHAR(100)
);

CREATE TABLE formacion_academica_previa (
    alumno_id INT PRIMARY KEY,
    colegio_desc VARCHAR(100),
    sector VARCHAR(50),
    ciudad_colegio VARCHAR(100),
    estudio_previo VARCHAR(100)
);

CREATE TABLE situacion_academica (
    alumno_id INT PRIMARY KEY,
    responsable_academica_id INT,
    plan_version_desc VARCHAR(100),
    beca BOOLEAN,
    anio_ingreso_institucion INT
);

--- DATABASE base_rendimiento
CREATE DATABASE base_rendimiento;
USE base_rendimiento;

CREATE TABLE rendimiento (
    alumno_id INT,
    anio_academico_materia INT,
    reinscripto BOOLEAN,
    materia_id INT,
    profesor_materia_id INT,
    nota_cursada DECIMAL(4,2),
    nota_final DECIMAL(4,2),
    PRIMARY KEY (alumno_id),
    FOREIGN KEY (alumno_id) REFERENCES base_alumno.personal_informacion(alumno_id)
);

CREATE TABLE rendimiento_historico (
    alumno_id INT,
    materia_id INT,
    anio_academico_materia INT,
    profesor_materia_id INT,
    nota_cursada DECIMAL(4,2),
    nota_final DECIMAL(4,2),
    intento_materia INT,
    egresado BOOLEAN,
    PRIMARY KEY (alumno_id),
    FOREIGN KEY (alumno_id) REFERENCES base_alumno.personal_informacion(alumno_id)
);

CREATE TABLE equivalencias_materia (
    alumno_id INT,
    materia_equivalente INT,
    materia_id INT,
    nota_equivalente DECIMAL(4,2),
    coloquio BOOLEAN,
    nota_final DECIMAL(4,2),
    PRIMARY KEY (alumno_id),
    FOREIGN KEY (alumno_id) REFERENCES base_alumno.personal_informacion(alumno_id)
);

------------------ 2. Migrar informacion
------ Cargar la informacion a las tablas
------ Luego de crear las bases por primera vez, es momento de trabajar en migrar la informacion.
------ Lo hago de forma sencilla como si fuera un excel. 

-- Para cargar datos en la tabla personal_informacion
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_alumno.personal_informacion
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- Para cargar datos en la tabla rama_familiar
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_alumno.rama_familiar
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- Para cargar datos en la tabla formacion_academica_previa
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_alumno.formacion_academica_previa
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- Para cargar datos en la tabla situacion_academica
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_alumno.situacion_academica
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- Para cargar datos en la tabla rendimiento
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_rendimiento.rendimiento
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- Para cargar datos en la tabla rendimiento_historico
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_rendimiento.rendimiento_historico
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- Para cargar datos en la tabla equivalencias_materia
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_rendimiento.equivalencias_materia
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;



------------------ 3. Es momento de limpiar los datos
------ Luego de crear las bases por primera vez e ingresar los datos, hay que limpirlos
------ Por cuestiones de tiempo y proteccion, voy a hacer algunos ejemplos de lo que nos encontramos actualmente

-- Reemplazar NULLs en la columna egresado con 0
UPDATE rendimiento_historico
SET egresado = COALESCE(egresado, 0)
WHERE egresado IS NULL;

-- Eliminar registros donde la columna reinscripto tiene valor -1
DELETE FROM rendimiento
WHERE reinscripto = -1;

-- Reemplazar edades menores a 18 con 18
UPDATE personal_informacion
SET edad = CASE
             WHEN edad < 18 THEN 18
             ELSE edad
          END;

-- Reemplazar "N" con 0 y "S" con 1 en la columna beca
UPDATE situacion_academica
SET beca = CASE
             WHEN beca = 'N' THEN 0
             WHEN beca = 'S' THEN 1
          END;

-- Reemplazar "Vigente" con 1 y "No Vigente" con 0 en la columna plan_version_desc
UPDATE situacion_academica
SET plan_version_desc = CASE
                           WHEN plan_version_desc = 'Vigente' THEN 1
                           WHEN plan_version_desc = 'No Vigente' THEN 0
                        END;






------------------ 4. Migrar los datos de rendimiento a rendimiento_historico
------ Una de las cosas que se va a hacer para manejar bases distintas, es trabajar con diferentes tablas dependiendo si es informacion corriente (año en curso) o no (año pasado)
------ por eso a fin de año migramos de una tabla a otra, SOLO si es diciembre, ya que ejecutar esto antes, migraria informacion incompleta

IF MONTH(CURRENT_DATE()) = 12 THEN

    -- Migrar datos de rendimiento a rendimiento_historico
    INSERT INTO base_rendimiento.rendimiento_historico (alumno_id, materia_id, anio_academico_materia, profesor_materia_id, nota_cursada, nota_final, intento_materia, egresado)
    SELECT alumno_id, materia_id, anio_academico_materia, profesor_materia_id, nota_cursada, nota_final, 
        CASE 
            WHEN reinscripto = 1 THEN 2
            ELSE intento_materia
        END AS intento_materia,
        egresado
    FROM base_rendimiento.rendimiento;

    -- Actualizar el campo reinscripto en rendimiento a 0
    UPDATE base_rendimiento.rendimiento
    SET reinscripto = 0;

END IF;
