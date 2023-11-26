-------------------Ładowanie rastrow------------------

--Przykład 1 – ładowanie rastra przy użyciu pliku .sql
raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d "C:\Users\zsaba\OneDrive\Dokumenty\Bazy_danych_przestrzennych\Dane-cw7\srtm_1arc_v3.tif" rasters.dem > "C:\Users\zsaba\OneDrive\Dokumenty\Bazy_danych_przestrzennych\Dane-cw7\dem.sql"

--Przykład 2 – ładowanie rastra bezpośrednio do bazy
raster2pgsql.exe -s 3763 -N -32767 -t 100x100 -I -C -M -d "C:\Users\zsaba\OneDrive\Dokumenty\Bazy_danych_przestrzennych\Dane-cw7\srtm_1arc_v3.tif" rasters.dem | psql -d zajecia7 -h localhost -U postgres -p 5433

--Przykład 3 – załadowanie danych landsat 8 o wielkości kafelka 128x128 bezpośrednio do
bazy danych.

raster2pgsql.exe -s 3763 -N -32767 -t 128x128 -I -C -M -d "C:\Users\zsaba\OneDrive\Dokumenty\Bazy_danych_przestrzennych\Dane-cw7\Landsat8_L1TP_RGBN.tif" rasters.landsat8 | psql -d zajecia7 -h localhost -U postgres -p 5433

----------------Tworzenie rastrow z istniejacych rastrow-------------

--Przyklad 1
CREATE TABLE sabat.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto';

alter table sabat.intersects
add column rid SERIAL PRIMARY KEY;

CREATE INDEX idx_intersects_rast_gist ON sabat.intersects
USING gist (ST_ConvexHull(rast));

-- schema::name table_name::name raster_column::name
SELECT AddRasterConstraints('sabat'::name,
'intersects'::name,'rast'::name);

--Przyklad 1
CREATE TABLE sabat.clip AS
SELECT ST_Clip(a.rast, b.geom, true), b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

--Przyklad 2
CREATE TABLE sabat.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);

--Przyklad 3
CREATE TABLE sabat.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true))
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast);


-----------------Tworzenie rastrow z wektorow------------------

--Przyklad 1
CREATE TABLE sabat.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--Przyklad 2
DROP TABLE sabat.porto_parishes; --> drop table porto_parishes first
CREATE TABLE sabat.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1
)
SELECT st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

--Przyklad 3
DROP TABLE sabat.porto_parishes; --> drop table porto_parishes first
CREATE TABLE sabat.porto_parishes AS
WITH r AS (
SELECT rast FROM rasters.dem
LIMIT 1 )
SELECT st_tile(st_union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-
32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ilike 'porto';

------------------Konwertowanie rastrow na wektory---------------------

--Przyklad 1
create table sabat.intersection as
SELECT
a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)
).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Przyklad 2
CREATE TABLE sabat.dumppolygons AS
SELECT
a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(S
T_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast)

-----------------------Analiza rastrow--------------------------------

--Przyklad 1
CREATE TABLE sabat.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast
FROM rasters.landsat8;

--Przyklad 2
CREATE TABLE sabat.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ilike 'paranhos' and ST_Intersects(b.geom,a.rast);

--Przyklad 3
CREATE TABLE sabat.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') as rast
FROM sabat.paranhos_dem AS a;

--Przyklad 4
CREATE TABLE sabat.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3',
'32BF',0)
FROM sabat.paranhos_slope AS a;

--Przyklad 5
SELECT st_summarystats(a.rast) AS stats
FROM sabat.paranhos_dem AS a;

--Przyklad 6
SELECT st_summarystats(ST_Union(a.rast))
FROM sabat.paranhos_dem AS a;

--Przyklad 7
WITH t AS (
SELECT st_summarystats(ST_Union(a.rast)) AS stats
FROM sabat.paranhos_dem AS a
)
SELECT (stats).min,(stats).max,(stats).mean FROM t;

--Przyklad 8
WITH t AS (
SELECT b.parish AS parish, st_summarystats(ST_Union(ST_Clip(a.rast,
b.geom,true))) AS stats
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
group by b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

--Przyklad 9
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM
rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

--Przyklad 10 
create table sabat.tpi30 as
select ST_TPI(a.rast,1) as rast
from rasters.dem a;

--indeks
CREATE INDEX idx_tpi30_rast_gist ON sabat.tpi30
USING gist (ST_ConvexHull(rast));

--constriant
SELECT AddRasterConstraints('sabat'::name,
'tpi30'::name,'rast'::name);

CREATE TABLE sabat.tpi30porto as
WITH porto AS (
	SELECT a.rast
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto'
)
SELECT ST_TPI(porto.rast,1) as rast FROM porto;

------------------------Algebra map-----------------------

--Przyklad 1
NDVI=(NIR-Red)/(NIR+Red)

CREATE TABLE sabat.porto_ndvi AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, 1,
r.rast, 4,
'([rast2.val] - [rast1.val]) / ([rast2.val] +
[rast1.val])::float','32BF'
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON sabat.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('sabat'::name,
'porto_ndvi'::name,'rast'::name);

--Przyklad 2
create or replace function sabat.ndvi(
value double precision [] [] [],
pos integer [][],
VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug
purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

CREATE TABLE sabat.porto_ndvi2 AS
WITH r AS (
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT
r.rid,ST_MapAlgebra(
r.rast, ARRAY[1,4],
'sabat.ndvi(double precision[],
integer[],text[])'::regprocedure, --> This is the function!
'32BF'::text
) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON sabat.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('sabat'::name,
'porto_ndvi2'::name,'rast'::name);

------------------------Eksport danych-------------------------

--Przyklad 1
SELECT ST_AsTiff(ST_Union(rast))
FROM sabat.porto_ndvi;

--Przyklad 2
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
FROM sabat.porto_ndvi;

SELECT ST_GDALDrivers();

--Przyklad 3
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE',
'PREDICTOR=2', 'PZLEVEL=9'])
) AS loid
FROM sabat.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'G:\myraster.tiff') --> Save the file in a place
where the user postgres have access. In windows a flash drive usualy works
fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.

--Przyklad 4
--gdal_translate -co COMPRESS=DEFLATE -co PREDICTOR=2 -co ZLEVEL=9
--PG:"host=localhost port=5432 dbname=postgis_raster user=postgres
--password=postgis schema=sabat table=porto_ndvi mode=2"
--porto_ndvi.tiff

------------------------Publikowanie danych----------------------
--Przyklad 1
--MAP
--NAME 'map'
--SIZE 800 650
--STATUS ON
--EXTENT -58968 145487 30916 206234
--UNITS METERS
--WEB
--METADATA
--'wms_title' 'Terrain wms'
--'wms_srs' 'EPSG:3763 EPSG:4326 EPSG:3857'
--'wms_enable_request' '*'
--'wms_onlineresource'
--'http://54.37.13.53/mapservices/srtm'
--END
--END
--PROJECTION
--'init=epsg:3763'
--END
--LAYER
--NAME srtm
--TYPE raster
--STATUS OFF
--DATA "PG:host=localhost port=5432 dbname='postgis_raster' user='sasig'
--password='postgis' schema='rasters' table='dem' mode='2'" PROCESSING
--"SCALE=AUTO"
--PROCESSING "NODATA=-32767"
--OFFSITE 0 0 0
--METADATA
--'wms_title' 'srtm'
--END
--END
--END

create table sabat.tpi30_porto as
SELECT ST_TPI(a.rast,1) as rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ilike 'porto'

CREATE INDEX idx_tpi30_porto_rast_gist ON sabat.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('sabat'::name,
'tpi30_porto'::name,'rast'::name);




