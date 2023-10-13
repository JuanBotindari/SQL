
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

-- DATOS: personal_informacion
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_alumno.personal_informacion
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- DATOS: rama_familiar
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_alumno.rama_familiar
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- DATOS: formacion_academica_previa
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_alumno.formacion_academica_previa
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- DATOS: situacion_academica
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_alumno.situacion_academica
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- DATOS: rendimiento
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_rendimiento.rendimiento
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- DATOS: rendimiento_historico
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_rendimiento.rendimiento_historico
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;

-- DATOS: equivalencias_materia
LOAD DATA INFILE '/ruta/del/archivo/datos.csv'
INTO TABLE base_rendimiento.equivalencias_materia
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\r\n' 
IGNORE 1 LINES;



------------------ 3. Es momento de limpiar los datos
------ Luego de crear las bases por primera vez e ingresar los datos, hay que limpirlos
------ Por cuestiones de tiempo y proteccion, voy a hacer algunos ejemplos de lo que nos encontramos actualmente

-- Limpieza: egresado
UPDATE rendimiento_historico
SET egresado = COALESCE(egresado, 0)
WHERE egresado IS NULL;

-- Limpieza: reinscripto
DELETE FROM rendimiento
WHERE reinscripto = -1;

-- Limpieza: edad
UPDATE personal_informacion
SET edad = CASE
             WHEN edad < 18 THEN 18
             ELSE edad
          END;

-- Limpieza: beca
UPDATE situacion_academica
SET beca = CASE
             WHEN beca = 'N' THEN 0
             WHEN beca = 'S' THEN 1
          END;

-- Limpieza: plan_version_desc
UPDATE situacion_academica
SET plan_version_desc = CASE
                           WHEN plan_version_desc = 'Vigente' THEN 1
                           WHEN plan_version_desc = 'No Vigente' THEN 0
                        END;






------------------ 4. Migrar los datos de rendimiento a rendimiento_historico
------ Una de las cosas que se va a hacer para manejar bases distintas, es trabajar con diferentes tablas dependiendo si es informacion corriente (año en curso) o no (año pasado)
------ por eso a fin de año migramos de una tabla a otra, SOLO si es diciembre, ya que ejecutar esto antes, migraria informacion incompleta

-- Verificar si la fecha es diciembre
IF MONTH(CURRENT_DATE()) = 12 THEN

    -- Contar la cantidad de filas antes de ejecutar el código
    DECLARE @count_rendimiento_anterior INT;
    DECLARE @count_rendimiento_historico_anterior INT;

    SELECT @count_rendimiento_anterior = COUNT(*) FROM base_rendimiento.rendimiento;
    SELECT @count_rendimiento_historico_anterior = COUNT(*) FROM base_rendimiento.rendimiento_historico;

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

    -- Eliminar todos los datos de la tabla rendimiento
    DELETE FROM base_rendimiento.rendimiento;

    -- Verificar si la migración fue correcta
    DECLARE @count_rendimiento_nuevo INT;
    DECLARE @count_rendimiento_historico_nuevo INT;

    SELECT @count_rendimiento_nuevo = COUNT(*) FROM base_rendimiento.rendimiento;
    SELECT @count_rendimiento_historico_nuevo = COUNT(*) FROM base_rendimiento.rendimiento_historico;

    IF @count_rendimiento_anterior = @count_rendimiento_nuevo AND @count_rendimiento_nuevo = 0 THEN
        SELECT 'Migracion correcta' AS Resultado;
    ELSE
        SELECT 'Error en la migracion' AS Resultado;
    END IF;

END IF;



------------------ 5. Consultas Ad-hoc
------ Suponiendo que ahora somos analista de datos, y queremos ver ciertas variables.
------ Cada consulta la insertamos en PowerBI, excel o donde la queramos consumir. 
------ Por ejemplo lo podriamos poner en PowerBI y generar los graficos que necesitemos


-- Consulta 1: Quiero ver la cantidad de alumnos que tengo por cada versión del plan y luego ver la nota media usando las tablas de rendimiento_historico y base alumno
SELECT plan_version_desc, COUNT(*) AS cantidad_alumnos, AVG(nota_final) AS nota_media
FROM base_alumno.situacion_academica
JOIN base_rendimiento.rendimiento_historico ON base_alumno.situacion_academica.alumno_id = base_rendimiento.rendimiento_historico.alumno_id
GROUP BY plan_version_desc;


-- Consulta 2: Quiero que me junte los profesores y ver la nota media que tengo para ver si tengo alguna desviación. Usa tabla rendimiento_historico
SELECT profesor_materia_id, AVG(nota_final) AS nota_media
FROM base_rendimiento.rendimiento_historico
GROUP BY profesor_materia_id;


-- Consulta 3: Quiero ver la nota media por cada materia en la tabla rendimiento_historico y la nota media por cada materia en la tabla rendimiento 
SELECT materia_id, AVG(nota_final) AS nota_media_rendimiento_historico
FROM base_rendimiento.rendimiento_historico
GROUP BY materia_id;

SELECT materia_id, AVG(nota_final) AS nota_media_rendimiento
FROM base_rendimiento.rendimiento
GROUP BY materia_id;





------------------ 6. Modelo predictivo de ML - Linnear Regression
------ En este caso vamos a hacer una regresión lineal para tratar de predecir la nota final de un alumno

/* 
Modelo Python y SQL

import pandas as pd
from sqlalchemy import create_engine
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import OneHotEncoder
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import cross_val_score

# Establecer conexión con la base de datos
engine = create_engine(       ACA DEBERIA ESTAR LA CONEZION DE LA BASE DE DATOS )
connection = engine.connect()  )

# Definir la consulta SQL
query = """
SELECT pi.edad, pi.horas_trabajadas_sem, rh.nota_cursada, rh.anio_academico_materia, rh.nota_final
FROM base_alumno.personal_informacion pi
JOIN base_rendimiento.rendimiento_historico rh ON pi.alumno_id = rh.alumno_id
"""


df = pd.read_sql_query(query, engine)


''' Definir columnas numéricas y categóricas '''
num_features = ['edad', 'horas_trabajadas_sem', 'nota_cursada', 'anio_academico_materia']
cat_features = ['beca', 'plan_version_desc']

''' Definir el preprocesamiento para las columnas numéricas y categóricas '''
num_transformer = Pipeline(steps=[
    ('imputer', SimpleImputer(strategy='mean'))
])

cat_transformer = Pipeline(steps=[
    ('imputer', SimpleImputer(strategy='most_frequent')),
    ('onehot', OneHotEncoder(handle_unknown='ignore'))
])

''' Combinar preprocesadores '''
preprocessor = ColumnTransformer(
    transformers=[
        ('num', num_transformer, num_features),
        ('cat', cat_transformer, cat_features)
    ])

''' Definir el modelo de regresión lineal '''
model = LinearRegression()

''' Combinar preprocesamiento y modelo en un pipeline '''
clf = Pipeline(steps=[('preprocessor', preprocessor),
                     ('classifier', model)])

''' Separar las variables predictoras (X) de la variable objetivo (Y) '''
X = df[['edad', 'horas_trabajadas_sem', 'nota_cursada', 'anio_academico_materia']]
Y = df['nota_final']

''' Realizar validación cruzada '''
cv_scores = cross_val_score(clf, X, Y, cv=10)  

''' Imprimir los resultados de la validación cruzada '''
print(f"Puntuaciones de Validación Cruzada: {cv_scores}")
print(f"Puntuación Media de Validación Cruzada: {cv_scores.mean()}")



*/



------------------ 7. Usuarios
------


-- Crear usuario administrador con privilegios de administración
CREATE USER 'administrador'@'localhost' IDENTIFIED BY 'contraseña_admin';
GRANT ALL PRIVILEGES ON *.* TO 'administrador'@'localhost';

-- Crear usuario editor con permisos de edición
CREATE USER 'editor'@'localhost' IDENTIFIED BY 'contraseña_editor';
GRANT INSERT, UPDATE, DELETE ON nombre_basedatos.* TO 'editor'@'localhost';

-- Crear usuario consultor con permisos de consulta
CREATE USER 'consultor'@'localhost' IDENTIFIED BY 'contraseña_consultor';
GRANT SELECT ON nombre_basedatos.* TO 'consultor'@'localhost';
