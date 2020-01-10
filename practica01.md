# Practica 1: Introducción al manejo de Bases de Datos Espaciales (BDE)

Una base de datos espacial como su nombre los dice trabaja con objetos existentes en un espacio delimitado por geometrías, en este tipo de bases de datos es necesario determinar un Sistema de Referencia Espacial para definir la localización y relación entre objetos analizar la composición de los objeto en el espacio, determinar su relación con otros objetos, transformarlos, entre otras operaciones.

Estructurar este tipo de bases de datos implica un proceso complejo donde proyectamos las interacciones espaciales del mundo real a una representación simplificada a través de primitivas básicas de dibujo o geometría, de tal forma que toda la complejidad de la realidad ha de ser reducida a puntos, líneas o polígonos.



## ¿Pero como podemos extraer información de una base de datos espacial? 
<img src="https://postgis.readthedocs.io/es/latest/_images/ogc_sfs.png" alt="Markdown Monster icon"
     style="margin-left: 10px; margin-right: 10px;" />



En este primer ejercicio vamos a estudiar la forma en la que se construye la estructura jerárquica de los objetos geométricos en una base de datos.
--Supongamos que obtuvimos las coordenadas de varios puntos alrededor de un lago y las representamos como puntos. 
--Pero lo que necesitamos es un poligo que represente el lago. 
--El primer paso es crear una linea a partir de los puntos de la tabla waypoints. 
--y para ello debemos considerar el orden en el que los juntemos, por lo que es necesario ordenarlos por id, 
--usando la cláusula GROUP BY track_id, que agrupa los puntos de acuerdo a un identificador de recorrido.
--(Guarda nota de esto porque será importante en los ejercicios)

CREATE TABLE gps_tracks AS
SELECT
ST_MakeLine(geom) AS geom, track_id
FROM ( SELECT * FROM waypoints ORDER BY id) AS ordered_points
GROUP BY track_id;

--¿Que tipo de geometría generamos al unir los puntos? Veamos:

SELECT ST_asText(geom) from gps_tracks;

-- Si visualizas la capa en QGis, notarás que la linea que construimos contiene una auto-intersección 
-- y que no está cerrada (el primero y el último punto no coinciden)
-- Para resolver este problema, vamos a generar un nodo en la auto-intersección:

--[Pregunta # 1: ¿Qué hace el operador ST_UnaryUnion() y, más en general, ¿Qué hace una unión en Postgis?]

UPDATE gps_tracks SET geom = ST_UnaryUnion(geom)
-- ST_UnaryUnion(geom) para poligonos es un equivalente del dissolve en Arc, para lineas
-- se usa esta funcion para agregar un nodo de unión entre ellas cuando intersectan

-- Para ver el resultado de la operación anterior, vamos a desbaratar la linea que creamos en sus componentes:

SELECT  ST_asText(ST_GeometryN(geom,generate_series(1,ST_NumGeometries(geom)))) AS lines
FROM gps_tracks
select st_geometryn(geom, generate_series(1,st_numgeometries(geom))) from gps_tracks -- colection 
select st_numgeometries(geom) from gps_tracks

--st_astext, Devuelve la epresentación de las geometrías en WKT ( Well-Known Text) sin estar codificado como SRID
--st_geometryN, nos dice en caso de ser una colección de geometrias las N geometrías contenidas en esa tabla 
--ST_NumGeometries, numero de geometrías en una colección 

--Esto nos regresa un conjunto de objetos tipo Linestring (véanlo). 
--Ahora que hemos separado el Multilinestring en sus componentes, vamos a desarmar éstas líneas en sus 
--componentes básicos:

--Ya que la geometría de líneas como tal no existe es necesario crearla a través de una subconsulta
--SELECT st_astext(ST_GeometryN(geom, generate_series(1,ST_NumGeometries(geom)))) FROM gps_tracks


SELECT ST_AsText(ST_PointN(line_geom,generate_series(1, ST_NPoints(line_geom)))) point_geom
FROM (SELECT ST_GeometryN(geom, generate_series(1,ST_NumGeometries(geom))) AS line_geom 
	  FROM gps_tracks
) AS foo;


--Nota que hicimos las dos consultas anidadas, es decir, primero hacemos la consulta anterior y luego la envolvemos 
--con la consulta que nos regresa los puntos.
--Ahora, para poder visualizar el resultado en QGis, necesitamos agregar un id a los puntos y ponerlos en una tabla:

CREATE TABLE waypoints_nuevos AS
SELECT 
   ST_PointN(
	  lines,
	  generate_series(1, ST_NPoints(lines))
   ) as geom
FROM (
	SELECT 
		ST_GeometryN(geom,
	generate_series(1,ST_NumGeometries(geom))) AS lines
	FROM gps_tracks
) AS foo;

alter table waypoints_nuevos add column id serial;

--Como podemos ver, creamos un punto el la auto-intersección. Ahora regresemos a la tabla gps_tracks y creemos un polígono:

CREATE TABLE gps_lakes AS
SELECT
ST_BuildArea(geom) AS lake,
track_id
FROM gps_tracks;

--Ahora pueden visualizar el lago en QGis. 
--PREGUNTA #2: ¿Qué hubiera pasado si no ponemos un nodo en la auto-intersección?
--Hint: ver en la documentación--> ¿Qué es un polígono?

--EJERCICIO # 1: Con los puntos de las estaciones del metro de la práctica anterior, crea las líneas del metro.
--Hint: Para crear todas las líneas tienes que agrupar los puntos
