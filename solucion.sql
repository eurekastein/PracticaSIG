select pob_tot-pob_buf as resta
from
(select a.suma as pob_buf, 
(select sum(manzanas_zmvm.pob1) from manzanas_zmvm) as pob_tot 
from
(with buf as (select st_buffer(estaciones_metro.geom,500.0) as geom, 
estaciones_metro.nombreesta as estacion 
from estaciones_metro)
select sum(manzanas_zmvm.pob1) as suma 
from manzanas_zmvm
join buf 
on st_intersects(buf.geom,manzanas_zmvm.geom)) as a) as b 
