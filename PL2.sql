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
-- Crear tablas temporales para las tablas temporales
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

-- Evitar duplicados
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
    usuario_nombre_usuario TEXT,
    disco_titulo TEXT,
    disco_anno_publicacion INTEGER,
    PRIMARY KEY (usuario_nombre_usuario, disco_titulo, disco_anno_publicacion),
    FOREIGN KEY (usuario_nombre_usuario) REFERENCES tienda.Usuarios(nombre_usuario),
    FOREIGN KEY (disco_titulo, disco_anno_publicacion) REFERENCES tienda.Discos(titulo, anno_publicacion)
);
CREATE TYPE estado_enum AS ENUM ('M', 'NM', 'EX', 'VG+', 'VG', 'G', 'F');
CREATE TABLE IF NOT EXISTS tienda.UTieneE(
    usuario_nombre_usuario TEXT,
    disco_titulo TEXT,
    disco_anno_publicacion INTEGER,
    edicion_pais TEXT,
    edicion_anno_edicion INTEGER,
    edicion_formato formato_enum,
    estado estado_enum NOT NULL,
    id INTEGER CHECK(id > 0) NOT NULL,
    PRIMARY KEY (usuario_nombre_usuario, disco_titulo, disco_anno_publicacion, edicion_pais, edicion_anno_edicion, edicion_formato,id),
    FOREIGN KEY (usuario_nombre_usuario) REFERENCES tienda.Usuarios(nombre_usuario),
    FOREIGN KEY (disco_titulo, disco_anno_publicacion) REFERENCES tienda.Discos(titulo, anno_publicacion),
    FOREIGN KEY (edicion_pais, edicion_anno_edicion, edicion_formato, disco_titulo, disco_anno_publicacion) REFERENCES tienda.Ediciones(pais, anno_edicion, formato, disco_titulo, disco_anno_publicacion)
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


INSERT INTO tienda.GenerosDisco
SELECT DISTINCT titulo, anno_publicacion::INTEGER, trim(both ' ' from replace(trim(both '[]' from unnest(string_to_array(replace(trim(both '[]' from generos), ' & ', ''), ','))), '''', ''))
FROM tienda_temporal.Discos;


INSERT INTO tienda.UDeseaD
SELECT usuario_nombre_usuario, disco_titulo, disco_anno_publicacion::INTEGER
FROM tienda_temporal.UDeseaD
WHERE usuario_nombre_usuario IN (SELECT nombre_usuario FROM tienda.Usuarios);


CREATE SEQUENCE tienda.UTieneE_id_seq;

INSERT INTO tienda.UTieneE
SELECT usuario_nombre_usuario, disco_titulo, disco_anno_publicacion::INTEGER, edicion_pais, edicion_anno_edicion::INTEGER, edicion_formato::formato_enum, estado::estado_enum, nextval('tienda.UTieneE_id_seq')
FROM tienda_temporal.UTieneE
WHERE usuario_nombre_usuario IN (SELECT nombre_usuario FROM tienda.Usuarios);

SET search_path= tienda;

\echo 'Fin de la transformación'

\echo 'Consulta 1: '
SELECT d.titulo, d.anno_publicacion, COUNT(*) AS num_canciones
FROM Discos d JOIN Canciones c ON d.titulo = c.disco_titulo AND d.anno_publicacion = c.disco_anno_publicacion
GROUP BY d.titulo, d.anno_publicacion
HAVING COUNT(*) > 5
ORDER BY num_canciones;
-- Juntamos las tablas Discos y Canciones, y las agrupamos por titulo y anno_publicacion. Contamos el número de canciones por disco y nos quedamos con aquellos que tengan más de 5 canciones. Finalmente, ordenamos por el número de canciones (de menor a mayor).

\echo 'Consulta 2: '
SELECT u.nombre_usuario, u.nombre, e.disco_titulo, e.disco_anno_publicacion, e.edicion_pais, e.edicion_anno_edicion, e.edicion_formato, e.estado
FROM UTieneE e
JOIN Usuarios u ON e.usuario_nombre_usuario = u.nombre_usuario
WHERE u.nombre LIKE 'Juan García Gómez' AND e.edicion_formato = 'Vinyl';

\echo 'Consulta 3: '
WITH DuracionesDisco AS (
    SELECT d.titulo, d.anno_publicacion, SUM(c.duracion) AS duracion_total
    FROM Discos d JOIN Canciones c ON d.titulo = c.disco_titulo AND d.anno_publicacion = c.disco_anno_publicacion
    GROUP BY d.titulo, d.anno_publicacion
    HAVING SUM(c.duracion) IS NOT NULL
)
SELECT d.titulo, d.anno_publicacion, SUM(c.duracion) AS duracion_total
FROM Discos d JOIN Canciones c ON d.titulo = c.disco_titulo AND d.anno_publicacion = c.disco_anno_publicacion
GROUP BY d.titulo, d.anno_publicacion
HAVING SUM(c.duracion) >= ALL(SELECT duracion_total FROM DuracionesDisco);
-- Creamos una tabla temporal DuracionesDisco que contiene el título, año de publicación y duración total de las canciones de cada disco. Para obtener la duración total de cada disco, agrupamos la tabla por título y año de publicación, y sumamos la duración de las canciones de cada grupo. Finalmente, creamos otra tabla que contiene el título, año de publicación y duración total de las canciones de cada disco (realizando los mismos pasos que antes), y nos quedamos con aquellos discos cuya duración total sea mayor o igual a todos los valores de la columna duracion_total de la tabla DuracionesDisco.
\echo 'Consulta 4: '
SELECT u.nombre_usuario, u.nombre, udd.disco_titulo, udd.disco_anno_publicacion, d.grupo_nombre
FROM usuarios u JOIN udesead udd ON u.nombre_usuario = udd.usuario_nombre_usuario
JOIN discos d ON udd.disco_titulo = d.titulo AND udd.disco_anno_publicacion = d.anno_publicacion
WHERE u.nombre LIKE 'Juan García Gómez';

\echo 'Consulta 5: '
SELECT disco_titulo, disco_anno_publicacion, anno_edicion, pais, formato
FROM Ediciones
WHERE disco_anno_publicacion BETWEEN 1970 AND 1972
ORDER BY disco_anno_publicacion, disco_titulo;
-- Seleccionamos todas las ediciones cuya clave foránea disco_anno_publicacion esté entre 1970 y 1972, y las ordenamos por año de publicación y título del disco.
\echo 'Consulta 6: '
SELECT DISTINCT d.grupo_nombre
FROM discos d JOIN generosdisco gd ON d.titulo = gd.disco_titulo AND d.anno_publicacion = gd.disco_anno_publicacion
WHERE gd.genero = 'Electronic';

\echo 'Consulta 7: '
SELECT DISTINCT d.titulo, d.anno_publicacion, SUM(c.duracion) AS duracion_total
FROM Discos d
JOIN Canciones c ON d.titulo = c.disco_titulo AND d.anno_publicacion = c.disco_anno_publicacion
JOIN Ediciones e ON d.titulo = e.disco_titulo AND d.anno_publicacion = e.disco_anno_publicacion
WHERE e.anno_edicion < 2000
GROUP BY d.titulo, d.anno_publicacion;
-- Juntamos las tablas Discos, Canciones y Ediciones, y nos quedamos con aquellos discos cuya clave foránea anno_edicion de la tabla Ediciones sea menor a 2000. Agrupamos por título y año de publicación del disco para sumamos la duración de las canciones de cada disco usando SUM, obteniendo así la duración total del disco.
\echo 'Consulta 8: '
SELECT ut.nombre AS lo_tiene, ud.nombre AS lo_desea, ute.disco_titulo, ute.disco_anno_publicacion, ute.edicion_pais, ute.edicion_anno_edicion, ute.edicion_formato, ute.estado
FROM UTieneE ute JOIN UDeseaD udd ON ute.disco_titulo = udd.disco_titulo AND ute.disco_anno_publicacion = udd.disco_anno_publicacion JOIN usuarios ud ON udd.usuario_nombre_usuario = ud.nombre_usuario JOIN usuarios ut ON ute.usuario_nombre_usuario = ut.nombre_usuario
WHERE ut.nombre LIKE 'Juan García Gómez' AND ud.nombre LIKE 'Lorena Sáez Pérez';

\echo 'Consulta 9: '
SELECT u.nombre AS nombre_del_usuario, ute.disco_titulo, ute.disco_anno_publicacion, ute.edicion_pais, ute.edicion_anno_edicion, ute.edicion_formato, ute.estado, ute.id
FROM UTieneE ute JOIN Usuarios u ON ute.usuario_nombre_usuario = u.nombre_usuario
WHERE u.nombre LIKE '%Gómez García%' AND (ute.estado = 'NM' OR ute.estado = 'M');
-- Juntamos las tablas UTieneE y Usuarios para juntar el nombre real del usuario con el nombre de usuario. Nos quedamos con aquellos usuarios cuyo nombre contenga 'Gómez García' y cuyo estado sea 'NM' o 'M'.
\echo 'Consulta 10: '
SELECT u.nombre_usuario, COUNT(ute.id),MIN(ute.disco_anno_publicacion)::INTEGER, MAX(ute.disco_anno_publicacion)::INTEGER, AVG(ute.disco_anno_publicacion)::INTEGER
FROM Usuarios u JOIN UTieneE ute ON u.nombre_usuario = ute.usuario_nombre_usuario
GROUP BY u.nombre_usuario;

\echo 'Consulta 11: '
SELECT d.grupo_nombre, COUNT(*)
FROM Discos d JOIN Ediciones e ON d.titulo = e.disco_titulo AND d.anno_publicacion = e.disco_anno_publicacion
GROUP BY d.grupo_nombre
HAVING COUNT(*) > 5;
-- Juntamos las tablas Discos y Ediciones, y las agrupamos por el nombre del grupo. Así, contamos el número de discos por cada grupo con COUNT y nos quedamos con aquellos grupos que tengan más de 5 discos. Finalmente, ordenamos por el número de discos (ascendentemente).
\echo 'Consulta 12: '
WITH discos_por_usuario AS (
    SELECT usuario_nombre_usuario, COUNT(id) AS num_discos
    FROM UTieneE
    GROUP BY usuario_nombre_usuario
)
SELECT usuario_nombre_usuario, COUNT(id)
FROM UTieneE
GROUP BY usuario_nombre_usuario
HAVING COUNT(id) >= ALL(SELECT num_discos FROM discos_por_usuario);
--Creamos una tabla temporal discos_por_usuario que contiene el nombre de usuario y el número de discos que tiene cada usuario, que calculamos agrupando la tabla por el atributo usuario_nombre_usuario y contando el número de discos con COUNT. Finalmente, creamos otra tabla con los mismos atributos y nos quedamos con aquellos usuarios cuyo número de discos sea mayor o igual a todos los valores de la columna num_discos de la tabla discos_por_usuario.

ROLLBACK;                       -- importante! permite correr el script multiples veces...p