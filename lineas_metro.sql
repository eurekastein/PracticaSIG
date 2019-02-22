
SELECT
      geom,
      ARRAY[gid] AS idlist
    FROM estaciones_metro
    WHERE gid = 159

---
SELECT
      s.geom,
      array_append(n.idlist, s.gid) AS idlist  ---- Aquí metemos el resultado en el array de gids 
    FROM estaciones_metro s, next_stop n  ----- next stop va a ser el resultado de la iteración
                                                                      ---anterior
    WHERE (s.nombreline, 'A') != 0     --- Esto está raro, pero sólo estás diciendo que el nombre 
                                                           ---de la línea empiece con la letra A
    AND NOT n.idlist @> ARRAY[s.gid] --- no quiero que el nuevo punto ya esté en el array
    ORDER BY ST_Distance(n.geom, s.geom) ASC
    LIMIT 1 --- dame el más cercano!!!!


-----

WITH RECURSIVE next_stop(geom, idlist) AS (
    (SELECT
      geom,
      ARRAY[gid] AS idlist
    FROM estaciones_metro
    WHERE gid = 159)
    UNION ALL
    (SELECT
      s.geom,
      array_append(n.idlist, s.gid) AS idlist
    FROM estaciones_metro s, next_stop n
    WHERE (s.nombreline, 'A') != 0
    AND NOT n.idlist @> ARRAY[s.gid]
    ORDER BY ST_Distance(n.geom, s.geom) ASC
    LIMIT 1)
)
SELECT geom, idlist FROM next_stop;stop;

Este es el resultado (sin la geometría)

idlist
[159]
[159, 158]
[159, 158, 157]
[159, 158, 157, 156]
[159, 158, 157, 156, 155]
[159, 158, 157, 156, 155, 154]
[159, 158, 157, 156, 155, 154, 153]
[159, 158, 157, 156, 155, 154, 153, 152]
[159, 158, 157, 156, 155, 154, 153, 152, 151]
[159, 158, 157, 156, 155, 154, 153, 152, 151, 150]

WITH RECURSIVE next_stop(geom, idlist) AS (
    (SELECT
      geom,
      ARRAY[gid] AS idlist
    FROM estaciones_metro
    WHERE gid = 159)
    UNION ALL
    (SELECT
      s.geom,
      array_append(n.idlist, s.gid) AS idlist
    FROM estaciones_metro s, next_stop n
    WHERE strpos(s.nombreline, 'A') != 0
    AND NOT n.idlist @> ARRAY[s.gid]
    ORDER BY ST_Distance(n.geom, s.geom) ASC
    LIMIT 1)
)
SELECT ST_MakeLine(geom) AS geom FROM next_stop;

SELECT ST_Centroid(ST_Collect(geom)) AS geom, nombreline
FROM estaciones_metro
GROUP BY nombreline

With 
centroids as (
	SELECT ST_Centroid(ST_Collect(geom)) AS geom, nombreline
	FROM estaciones_metro
	GROUP BY nombreline
	ORDER BY nombreline
),
stops_distance as (
	SELECT s.*, ST_Distance(s.geom, c.geom) AS distance
	FROM estaciones_metro s JOIN centroids c
	ON (s.nombreline = c.nombreline)
	ORDER BY nombreline, distance DESC
),
first_stops AS (
	SELECT DISTINCT ON (nombreline) stops_distance.*
	FROM stops_distance
)
SELECT * FROM first_stops;

CREATE OR REPLACE function walk_subway(integer, text) returns geometry AS
$$
WITH RECURSIVE next_stop(geom, idlist) AS (
    (SELECT
      geom AS geom,
      ARRAY[gid] AS idlist
    FROM estaciones_metro
    WHERE gid = $1)
    UNION ALL
    (SELECT
      s.geom AS geom,
      array_append(n.idlist, s.gid) AS idlist
    FROM estaciones_metro s, next_stop n
    WHERE strpos(s.nombreline, $2) != 0
    AND NOT n.idlist @> ARRAY[s.gid]
    ORDER BY ST_Distance(n.geom, s.geom) ASC
    LIMIT 1)
)
SELECT ST_MakeLine(geom) AS geom
FROM next_stop;
$$
language 'sql';

With 
centroids as (
	SELECT ST_Centroid(ST_Collect(geom)) AS geom, nombreline
	FROM estaciones_metro
	GROUP BY nombreline
	ORDER BY nombreline
),
stops_distance as (
	SELECT s.*, ST_Distance(s.geom, c.geom) AS distance
	FROM estaciones_metro s JOIN centroids c
	ON (s.nombreline = c.nombreline)
	ORDER BY nombreline, distance DESC
),
first_stops AS (
	SELECT DISTINCT ON (nombreline) stops_distance.*
	FROM stops_distance
)
SELECT
  nombreline,
  gid,
  walk_subway(gid, nombreline) AS geom
FROM first_stops;

http://postgis.net/workshops/postgis-intro/advanced_geometry_construction.html


