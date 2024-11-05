\pset pager off

SET client_encoding = 'UTF8';
CREATE DATABASE tienda_db;
\c tienda_db
BEGIN;
\echo 'creando el esquema para la tienda'
CREATE SCHEMA IF NOT EXISTS tienda;



\echo 'creando un esquema temporal'
CREATE SCHEMA IF NOT EXISTS tienda_temporal;

CREATE TABLE IF NOT EXISTS tienda_temporal.Usuarios (
    nombre TEXT,
    nombre_usuario TEXT,
    email TEXT,
    contrasena TEXT
);

CREATE TABLE IF NOT EXISTS tienda_temporal.Discos(
    id TEXT UNIQUE,
    titulo TEXT,
    anno_publicacion TEXT,
    grupo_id TEXT,
    grupo_nombre TEXT,
    grupo_enlace TEXT,
    generos TEXT,
    enlace_portada TEXT
);

CREATE TABLE IF NOT EXISTS tienda_temporal.Ediciones(
    disco_id TEXT,
    anno_edicion TEXT,
    pais TEXT,
    formato TEXT
);

CREATE TABLE IF NOT EXISTS tienda_temporal.UDeseaD(
    usuario_nombre_usuario TEXT,
    disco_titulo TEXT,
    disco_anno_publicacion TEXT
);

CREATE TABLE IF NOT EXISTS tienda_temporal.UTieneE(
    usuario_nombre_usuario TEXT,
    disco_titulo TEXT,
    disco_anno_publicacion TEXT,
    edicion_anno_edicion TEXT,
    edicion_pais TEXT,
    edicion_formato TEXT,
    estado TEXT
);

CREATE TABLE IF NOT EXISTS tienda_temporal.Canciones(
    disco_id TEXT,
    titulo TEXT,
    duracion TEXT
);


SET search_path= tienda_temporal;
\echo 'Cargando datos'
-- Crear tablas temporales
CREATE TEMP TABLE temp_usuarios AS TABLE tienda_temporal.Usuarios WITH NO DATA;
CREATE TEMP TABLE temp_discos AS TABLE tienda_temporal.Discos WITH NO DATA;
CREATE TEMP TABLE temp_ediciones AS TABLE tienda_temporal.Ediciones WITH NO DATA;
CREATE TEMP TABLE temp_udesead AS TABLE tienda_temporal.UDeseaD WITH NO DATA;
CREATE TEMP TABLE temp_utienee AS TABLE tienda_temporal.UTieneE WITH NO DATA;
CREATE TEMP TABLE temp_canciones AS TABLE tienda_temporal.Canciones WITH NO DATA;

-- Copiar datos a las tablas temporales
\COPY temp_usuarios FROM 'usuarios.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY temp_discos FROM 'discos.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY temp_ediciones FROM 'ediciones.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY temp_udesead FROM 'usuario_desea_disco.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY temp_utienee FROM 'usuario_tiene_edicion.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY temp_canciones FROM 'canciones.csv' DELIMITER ';' CSV HEADER NULL 'NULL';

-- Insertar datos distintos en las tablas de destino
INSERT INTO tienda_temporal.Usuarios
SELECT DISTINCT * FROM temp_usuarios;

INSERT INTO tienda_temporal.Discos
SELECT DISTINCT * FROM temp_discos;

INSERT INTO tienda_temporal.Ediciones
SELECT DISTINCT * FROM temp_ediciones;

INSERT INTO tienda_temporal.UDeseaD
SELECT DISTINCT * FROM temp_udesead;

INSERT INTO tienda_temporal.UTieneE
SELECT DISTINCT * FROM temp_utienee;

INSERT INTO tienda_temporal.Canciones
SELECT DISTINCT * FROM temp_canciones;

DROP TABLE temp_usuarios;
DROP TABLE temp_discos;
DROP TABLE temp_ediciones;
DROP TABLE temp_udesead;
DROP TABLE temp_utienee;
DROP TABLE temp_canciones;


-- \quit
\echo insertando datos en el esquema final

CREATE TABLE IF NOT EXISTS tienda.Usuarios (
    nombre_usuario TEXT,
    email TEXT NOT NULL CHECK (email ~ '^[A-Za-z0-9áÁéÉíÍóÓúÚüÜñÑ._%+-]+@[A-Za-z0-9áÁéÉíÍóÓúÚüÜñÑ.-]+\.[A-Za-z]{2,}$'),
    nombre TEXT NOT NULL,
    contrasena TEXT NOT NULL,
    PRIMARY KEY (nombre_usuario)
);

CREATE TABLE IF NOT EXISTS tienda.Grupos (
    nombre TEXT,
    enlace TEXT CHECK (enlace ~ '^(http|https):\/\/[^\s/$.?#].[^\s]*$'),
    PRIMARY KEY (nombre)
);

CREATE TABLE IF NOT EXISTS tienda.Discos(
    titulo TEXT,
    anno_publicacion INTEGER,
    enlace_portada TEXT CHECK (enlace_portada IS NULL OR enlace_portada ~ '^(http|https):\/\/[^\s/$.?#].[^\s]*$'),
    grupo_nombre TEXT,
    PRIMARY KEY (titulo, anno_publicacion),
    FOREIGN KEY (grupo_nombre) REFERENCES tienda.Grupos(nombre)
);

CREATE TABLE IF NOT EXISTS tienda.GenerosDisco(
    disco_titulo TEXT,
    disco_anno_publicacion INTEGER,
    genero TEXT,
    PRIMARY KEY (disco_titulo, disco_anno_publicacion, genero),
    FOREIGN KEY (disco_titulo, disco_anno_publicacion) REFERENCES tienda.Discos(titulo, anno_publicacion)
);
CREATE TYPE formato_enum AS ENUM ('CD', 'Vinyl', 'Cassette', 'Flexi-disc', 'CDr', 'Box Set', 'File', 'All Media', 'Lathe Cut', 'DVD', 'VHS', 'Reel-To-Reel', 'Shellac', 'Blu-ray', 'SACD', '8-Track Cartridge', 'Floppy Disk');
CREATE TABLE IF NOT EXISTS tienda.Ediciones(
    pais TEXT,
    anno_edicion INTEGER,
    formato formato_enum,
    disco_titulo TEXT,
    disco_anno_publicacion INTEGER,
    PRIMARY KEY (pais, anno_edicion, formato, disco_titulo, disco_anno_publicacion),
    FOREIGN KEY (disco_titulo, disco_anno_publicacion) REFERENCES tienda.Discos(titulo, anno_publicacion)
);

CREATE TABLE IF NOT EXISTS tienda.Canciones(
    titulo TEXT,
    duracion INTEGER CHECK (duracion >= 0),
    disco_titulo TEXT,
    disco_anno_publicacion INTEGER,
    PRIMARY KEY (titulo, disco_titulo, disco_anno_publicacion),
    FOREIGN KEY (disco_titulo, disco_anno_publicacion) REFERENCES tienda.Discos(titulo, anno_publicacion)
);

CREATE TABLE IF NOT EXISTS tienda.UDeseaD(
    usuario_nombre TEXT,
    disco_titulo TEXT,
    disco_anno_publicacion INTEGER,
    PRIMARY KEY (usuario_nombre, disco_titulo, disco_anno_publicacion),
    FOREIGN KEY (usuario_nombre) REFERENCES tienda.Usuarios(nombre_usuario),
    FOREIGN KEY (disco_titulo, disco_anno_publicacion) REFERENCES tienda.Discos(titulo, anno_publicacion)
);
CREATE TYPE estado_enum AS ENUM ('M', 'NM', 'EX', 'VG+', 'VG', 'G', 'F');
CREATE TABLE IF NOT EXISTS tienda.UTieneE(
    usuario_nombre TEXT,
    disco_titulo TEXT,
    disco_anno_publicacion INTEGER,
    edicion_pais TEXT,
    edicion_anno INTEGER,
    edicion_formato formato_enum,
    estado estado_enum NOT NULL,
    id INTEGER CHECK(id > 0) NOT NULL,
    PRIMARY KEY (usuario_nombre, disco_titulo, disco_anno_publicacion, edicion_pais, edicion_anno, edicion_formato,id),
    FOREIGN KEY (usuario_nombre) REFERENCES tienda.Usuarios(nombre_usuario),
    FOREIGN KEY (disco_titulo, disco_anno_publicacion) REFERENCES tienda.Discos(titulo, anno_publicacion),
    FOREIGN KEY (edicion_pais, edicion_anno, edicion_formato, disco_titulo, disco_anno_publicacion) REFERENCES tienda.Ediciones(pais, anno_edicion, formato, disco_titulo, disco_anno_publicacion)
);
\echo 'Commenzation de la transformation'
INSERT INTO tienda.Usuarios
SELECT nombre_usuario, email, nombre, contrasena
FROM tienda_temporal.Usuarios;

INSERT INTO tienda.Grupos
SELECT DISTINCT grupo_nombre, grupo_enlace
FROM tienda_temporal.Discos;

INSERT INTO tienda.Discos
SELECT DISTINCT titulo, anno_publicacion::INTEGER, enlace_portada, grupo_nombre
FROM tienda_temporal.Discos;

INSERT INTO tienda.Ediciones
SELECT e.pais, e.anno_edicion::INTEGER, e.formato::formato_enum, d.titulo, d.anno_publicacion::INTEGER
FROM tienda_temporal.Ediciones e
JOIN tienda_temporal.Discos d ON e.disco_id = d.id;

DELETE FROM tienda_temporal.Canciones
USING tienda_temporal.Canciones c2
WHERE tienda_temporal.Canciones.titulo = c2.titulo
  AND tienda_temporal.Canciones.disco_id = c2.disco_id
  AND tienda_temporal.Canciones.duracion IS NULL
  AND c2.duracion IS NOT NULL;

DELETE FROM tienda_temporal.Canciones a
USING tienda_temporal.Canciones b
WHERE a.ctid < b.ctid
  AND a.titulo = b.titulo
  AND a.disco_id = b.disco_id
  AND a.duracion IS NOT NULL
  AND b.duracion IS NOT NULL;

INSERT INTO tienda.Canciones
SELECT DISTINCT c.titulo, (CAST(split_part(c.duracion, ':', 1) AS INTEGER) * 60) + CAST(split_part(c.duracion, ':', 2) AS INTEGER), d.titulo, d.anno_publicacion::INTEGER
FROM tienda_temporal.Canciones c
JOIN tienda_temporal.Discos d ON c.disco_id = d.id;

SELECT * FROM tienda.Discos WHERE titulo = 'Waves';


INSERT INTO tienda.GenerosDisco
SELECT DISTINCT titulo, anno_publicacion::INTEGER, trim(both ' ' from replace(trim(both '[]' from unnest(string_to_array(replace(trim(both '[]' from generos), ' & ', ''), ','))), '''', ''))
FROM tienda_temporal.Discos;

--Borrar los UDeseaD con un nombre de usuario que no exista en la tabla de usuarios
DELETE FROM tienda_temporal.UDeseaD
WHERE usuario_nombre_usuario NOT IN (SELECT nombre_usuario FROM tienda.Usuarios);

INSERT INTO tienda.UDeseaD
SELECT usuario_nombre_usuario, disco_titulo, disco_anno_publicacion::INTEGER
FROM tienda_temporal.UDeseaD;

DELETE FROM tienda_temporal.UTieneE
WHERE usuario_nombre_usuario NOT IN (SELECT nombre_usuario FROM tienda.Usuarios);

CREATE SEQUENCE tienda.UTieneE_id_seq;

INSERT INTO tienda.UTieneE
SELECT usuario_nombre_usuario, disco_titulo, disco_anno_publicacion::INTEGER, edicion_pais, edicion_anno_edicion::INTEGER, edicion_formato::formato_enum, estado::estado_enum, nextval('tienda.UTieneE_id_seq')
FROM tienda_temporal.UTieneE;

SET search_path= tienda;
\quit


\echo Consulta n:


ROLLBACK;                       -- importante! permite correr el script multiples veces...p