------------------ En el siguiente codigo les voy a mostar un equivalente a mi trabajo actual de 

/*
CONTEXTO:
- La universidad nos pide estimar nota media de estudiantes de cada curso.
- Tengo que crear e ingresar los datos que me piden.
- Diseñar los ingresos en el tiempo de manera automatica para que luego se pueda correr el modelo

*/


------------------ 1. Crear las tablas
------ Despues de ya conocer el dominio, entiendo que voy a tener distintas tablas 

-- Crear la base de datos
CREATE DATABASE Libreria

-- Crear la tabla de Autores
CREATE TABLE Autores (
    AutorID INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Nacionalidad VARCHAR(50)
);

-- Crear la tabla de Libros
CREATE TABLE Libros (
    LibroID INT PRIMARY KEY,
    Titulo VARCHAR(100),
    AutorID INT,
    AnioPublicacion INT,
    FOREIGN KEY (AutorID) REFERENCES Autores(AutorID)
);

-- Crear la tabla de Usuarios
CREATE TABLE Usuarios (
    UsuarioID INT PRIMARY KEY,
    Nombre VARCHAR(100),
    Email VARCHAR(100)
);

-- Crear la tabla de Préstamos
CREATE TABLE Prestamos (
    PrestamoID INT PRIMARY KEY,
    LibroID INT,
    UsuarioID INT,
    FechaPrestamo DATE,
    FechaDevolucion DATE,
    FOREIGN KEY (LibroID) REFERENCES Libros(LibroID),
    FOREIGN KEY (UsuarioID) REFERENCES Usuarios(UsuarioID)
);



