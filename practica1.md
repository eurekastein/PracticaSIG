## Practica 1: Operaciones Espaciales Básicas ##

Introducción


El primer paso es proyectar las geometrías de las manzanas para que sean compatibles con las estaciones del metro y el límite metropolitano
-- Es mejor proyectar las manzanas para que todo está en coordenadas planas, de ese modo los cálculos geométricos son mucho más rápidos

 ALTER TABLE estaciones_metro
   ALTER COLUMN geom
   TYPE Geometry(MultiPoint, 32614)
   USING ST_Transform(geom, 32614);

--Repite la misma operación para todas las capas que estén en coordenadas geográficas (SRID: 4326)

-- (2) Ahora vamos a cortar las manzanas con el polígono del límite metropolitano (lo que se llama un clip, pues) y meter el resultado en la tabla  merge_manzanas:
create table manzanas_zmvm as(
select merge_manzanas.*
from merge_manzanas
inner join limite_metropolitano on
st_intersects(limite_metropolitano.geom,merge_manzanas.geom)
)
--Nota como lo que hicimos fue en realidad un inner join pero como condición utilizamos una relación espacial: st_intersects

-- (3) creamos un índice espacial sobre la geometría
-- TAREA: investiga qué son y para qué sirven los índices espaciales
create index manzanas_zmvm_gix on manzanas_zmvm using GIST(geom);


-- (4) vemos si los id son únicos
select count(*) from manzanas_zmvm  group by id order by count(*) desc;
-- ¿Por qué no son únicos los ids?

-- (5) como la tabla tiene unos id's repetidos, alteramos la columna para que sean únicos
CREATE SEQUENCE "manzanas_zmvm_id_seq";
update manzanas_zmvm set id = nextval('"manzanas_zmvm_id_seq"');

-- (6) Creamos los constraints necesarios y agregamos un PK
ALTER TABLE manzanas_zmvm ALTER COLUMN "id" SET NOT NULL;
ALTER TABLE manzanas_zmvm ADD UNIQUE ("id");
ALTER TABLE manzanas_zmvm ADD PRIMARY KEY ("id");


-- (7) Ahora podemos empezar a hacer algunas preguntas interesantes, por ejemplo:
--¿cuantas manzanas quedan a 500 metros de cada estación del metro?
select foo.* from
(with buf as (select st_buffer(estaciones_metro.geom,500.0) as geom , estaciones_metro.nombreesta as estacion from estaciones_metro)
select count(manzanas_zmvm.id), buf.estacion from manzanas_zmvm join buf on
st_intersects(buf.geom,manzanas_zmvm.geom)
group by buf.estacion) as foo;

-- (8) Tambien podemos preguntar ¿Cuánta gente vive a 500 m de una estación del metro?
--Nota: La columna pob1 contiene la población de cada manzana
select foo.* from
(with buf as (select st_buffer(estaciones_metro.geom,500.0) as geom , estaciones_metro.nombreesta as estacion from estaciones_metro)
select sum(manzanas_zmvm.pob1), buf.estacion from manzanas_zmvm join buf on
st_intersects(buf.geom,manzanas_zmvm.geom)
group by buf.estacion) as foo;

--PUNTO EXTRA: ¿Cuántas personas no viven a 500 metros de una estación de metro?
--Hint: Tienes que sumar el resultado de la expresión de arriba y restarla de la población total
--como es el primer quiz, puedes hacerlo en dos querys

--EJERCICIO # 1.- En los datos del Censo encontrarás shapes con las calles del DF y del Estado de México, así como de las
--AGEBS.
-- Agrega estos shapes como capas en Postgis y repite los pasos 1 a 6 de este archivo para obtener un corte
-- de las calles y de las AGEBS con la forma de la ZMVM en una tabla indexada espacialmente y con llave primaria (PK)


--(9) Aquí vamos a crear una tabla que contenga la clave de la manzana (cvegeo), la geometría de la manzana y la clave de la colonia
--en la que se encuentra la manzana:

select  manzanas_zmvm.id, manzanas_zmvm.cvegeo, colonias.id_colonia,manzanas_zmvm.geom
into manzanas_colonias
from manzanas_zmvm 
join colonias 
on st_intersects(colonias.geom, manzanas_zmvm.geom);

--EJERCICIO # 2: Crea un índice espacial sobre la geometría y agrega una llave primaria a la tabla que acabas de crear.
--EJERCICIO # 3: De la misma forma en que creamos la tabla manzanas_colonias, crea una tabla que una la geometría de las calles con el id de las colonias
--recuerda crear su propio índice espacial y llave primaria.

-- Finalmente, para entender algunas de las diferencias entre Arc y el modelo PostGis, agregaremos las manzanas en colonias a través del id de colonia,
-- lo que en Arc se conoce como 'dissolve'.

select st_union(geom), id_colonia into manzanas_union
from manzanas_colonias
group by id_colonia;

-- PREGUNTA #1 ¿Qué tipo de geometría obtenemos?-- (1) El primer paso es proyectar las geometrías de las manzanas para que sean compatibles con las estaciones del metro y el límite metropolitano
-- Es mejor proyectar las manzanas para que todo está en coordenadas planas, de ese modo los cálculos geométricos son mucho más rápidos

 ALTER TABLE estaciones_metro
   ALTER COLUMN geom
   TYPE Geometry(MultiPoint, 32614)
   USING ST_Transform(geom, 32614);

--Repite la misma operación para todas las capas que estén en coordenadas geográficas (SRID: 4326)

-- (2) Ahora vamos a cortar las manzanas con el polígono del límite metropolitano (lo que se llama un clip, pues) y meter el resultado en la tabla  merge_manzanas:
create table manzanas_zmvm as(
select merge_manzanas.*
from merge_manzanas
inner join limite_metropolitano on
st_intersects(limite_metropolitano.geom,merge_manzanas.geom)
)
--Nota como lo que hicimos fue en realidad un inner join pero como condición utilizamos una relación espacial: st_intersects

-- (3) creamos un índice espacial sobre la geometría
-- TAREA: investiga qué son y para qué sirven los índices espaciales
create index manzanas_zmvm_gix on manzanas_zmvm using GIST(geom);


-- (4) vemos si los id son únicos
select count(*) from manzanas_zmvm  group by id order by count(*) desc;
-- ¿Por qué no son únicos los ids?

-- (5) como la tabla tiene unos id's repetidos, alteramos la columna para que sean únicos
CREATE SEQUENCE "manzanas_zmvm_id_seq";
update manzanas_zmvm set id = nextval('"manzanas_zmvm_id_seq"');

-- (6) Creamos los constraints necesarios y agregamos un PK
ALTER TABLE manzanas_zmvm ALTER COLUMN "id" SET NOT NULL;
ALTER TABLE manzanas_zmvm ADD UNIQUE ("id");
ALTER TABLE manzanas_zmvm ADD PRIMARY KEY ("id");


-- (7) Ahora podemos empezar a hacer algunas preguntas interesantes, por ejemplo:
--¿cuantas manzanas quedan a 500 metros de cada estación del metro?
select foo.* from
(with buf as (select st_buffer(estaciones_metro.geom,500.0) as geom , estaciones_metro.nombreesta as estacion from estaciones_metro)
select count(manzanas_zmvm.id), buf.estacion from manzanas_zmvm join buf on
st_intersects(buf.geom,manzanas_zmvm.geom)
group by buf.estacion) as foo;

-- (8) Tambien podemos preguntar ¿Cuánta gente vive a 500 m de una estación del metro?
--Nota: La columna pob1 contiene la población de cada manzana
select foo.* from
(with buf as (select st_buffer(estaciones_metro.geom,500.0) as geom , estaciones_metro.nombreesta as estacion from estaciones_metro)
select sum(manzanas_zmvm.pob1), buf.estacion from manzanas_zmvm join buf on
st_intersects(buf.geom,manzanas_zmvm.geom)
group by buf.estacion) as foo;

--PUNTO EXTRA: ¿Cuántas personas no viven a 500 metros de una estación de metro?
--Hint: Tienes que sumar el resultado de la expresión de arriba y restarla de la población total
--como es el primer quiz, puedes hacerlo en dos querys

--EJERCICIO # 1.- Con los shapes de las calles de la CDMX y del Estado de México, así como de las
--AGEBS.Agrega estos shapes como capas en Postgis y repite los pasos 1 a 6 de este archivo para obtener un corte
-- de las calles y de las AGEBS con la forma de la ZMVM en una tabla indexada espacialmente y con llave primaria (PK)


--(9) Aquí vamos a crear una tabla que contenga la clave de la manzana (cvegeo), la geometría de la manzana y la clave de la colonia
--en la que se encuentra la manzana:

select  manzanas_zmvm.id, manzanas_zmvm.cvegeo, colonias.id_colonia,manzanas_zmvm.geom
into manzanas_colonias
from manzanas_zmvm 
join colonias 
on st_intersects(colonias.geom, manzanas_zmvm.geom);

--EJERCICIO # 2: Crea un índice espacial sobre la geometría y agrega una llave primaria a la tabla que acabas de crear.
--EJERCICIO # 3: De la misma forma en que creamos la tabla manzanas_colonias, crea una tabla que una la geometría de las calles con el id de las colonias
--recuerda crear su propio índice espacial y llave primaria.

-- Finalmente, para entender algunas de las diferencias entre Arc y el modelo PostGis, agregaremos las manzanas en colonias a través del id de colonia,
-- lo que en Arc se conoce como 'dissolve'.

select st_union(geom), id_colonia into manzanas_union
from manzanas_colonias
group by id_colonia;

-- PREGUNTA #1 ¿Qué tipo de geometría obtenemos?
© 2020 GitHub, Inc.
Terms
Privacy
Security
Status
Help
Contact GitHub
Pricing
API
Training
Blog
About
