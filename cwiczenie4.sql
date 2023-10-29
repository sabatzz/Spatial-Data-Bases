CREATE EXTENSION postgis;

-- 1) Znajdź budynki, które zostały wybudowane lub wyremontowane 
--na przestrzeni roku (zmiana pomiędzy 2018 a 2019).
-- Znajdź budynki, które zostały wybudowane lub wyremontowane w ciągu roku

--left join: wszystkie rekordy b19 i null b18
WITH NewBuildings AS (
  SELECT b19.* FROM T2019_KAR_BUILDINGS b19
  LEFT JOIN T2018_KAR_BUILDINGS b18 ON b19.polygon_id = b18.polygon_id
  WHERE b18.gid IS NULL
),
--join: wszystkie rekordy zeby sprawdzic zmiane
ModifiedBuildings AS (
  SELECT b18.*  FROM T2018_KAR_BUILDINGS b18
  JOIN T2019_KAR_BUILDINGS b19 ON b18.polygon_id = b19.polygon_id
  WHERE ST_Equals(b18.geom, b19.geom) = FALSE
)
SELECT * INTO Changes FROM NewBuildings UNION SELECT * FROM ModifiedBuildings;

SELECT * FROM Changes;

--2) Znajdź ile nowych POI pojawiło się w promieniu 500 m od wyremontowanych lub 
--wybudowanych budynków, które znalezione zostały w zadaniu 1. Policz je wg ich kategorii

SELECT * FROM t2018_kar_poi_table;

WITH NewPoi AS(
  SELECT p19.* FROM T2019_KAR_POI_TABLE p19
  LEFT JOIN T2018_KAR_POI_TABLE p18 ON p19.poi_id = p18.poi_id
  WHERE p18.gid IS NULL
)  

SELECT p.type AS typ, COUNT(*) AS ilosc
FROM Changes c, NewPoi p
WHERE ST_DWithin(c.geom, p.geom, 500)
GROUP BY p.type;


--3)  Utwórz nową tabelę o nazwie ‘streets_reprojected’, która zawierać będzie dane z tabeli 
--T2019_KAR_STREETS przetransformowane do układu współrzędnych DHDN.Berlin/Cassini.

CREATE TABLE streets_reprojected AS
SELECT * FROM T2019_KAR_STREETS;

-- układ współrzędnych DHDN.Berlin/Cassini
UPDATE streets_reprojected
SET geom = ST_Transform(ST_SetSRID(geom,4326), 3068);

SELECT St_AsText(geom) FROM t2019_kar_streets;
SELECT St_AsText(geom) FROM streets_reprojected;

-- 4) Stwórz tabelę o nazwie ‘input_points’ i dodaj do niej dwa rekordy o geometrii punktowej.
CREATE TABLE input_points(
id INT PRIMARY KEY,
geom GEOMETRY NOT NULL
);
INSERT INTO input_points VALUES (1, ST_GeomFromText('POINT(8.36093 49.03174)', 4326));
INSERT INTO input_points VALUES (2, ST_GeomFromText('POINT(8.39876 49.00644)', 4326));

SELECT * FROM input_points;

-- 5) Zaktualizuj dane w tabeli ‘input_points’ tak, aby punkty te były w układzie
--współrzędnych DHDN.Berlin/Cassini. Wyświetl współrzędne za pomocą funkcji ST_AsText().

ALTER TABLE input_points
ALTER COLUMN geom
TYPE GEOMETRY(POINT, 3068) USING ST_Transform(geom, 3068);

SELECT St_AsText(geom) FROM input_points;

-- 6) Znajdź wszystkie skrzyżowania, które znajdują się w odległości 200 m od linii zbudowanej 
--z punktów w tabeli ‘input_points’. Wykorzystaj tabelę T2019_STREET_NODE. 
--Dokonaj reprojekcji geometrii, aby była zgodna z resztą tabel

SELECT * FROM t2019_kar_street_node
WHERE ST_DWithin(
	geom,
	(SELECT ST_Transform((ST_MakeLine(geom)), 4326) FROM input_points),200.0, true); 

-- 7. Policz jak wiele sklepów sportowych (‘Sporting Goods Store’ - tabela POIs) znajduje się 
-- w odległości 300 m od parków (LAND_USE_A).
WITH SportStore AS(
SELECT * FROM T2019_KAR_POI_TABLE
WHERE type='Sporting Goods Store'
),
Lands AS(
SELECT ST_Union(geom) AS geom  --union łączy wszystkie parki w jeden
FROM T2019_KAR_LAND_USE_A
WHERE type='Park (City/County)'
)
SELECT COUNT(s.type)
FROM SportStore s, Lands l
WHERE ST_DWithin(s.geom, l.geom, 300.0);


-- 8) Znajdź punkty przecięcia torów kolejowych (RAILWAYS) z ciekami (WATER_LINES). Zapisz 
--znalezioną geometrię do osobnej tabeli o nazwie ‘T2019_KAR_BRIDGES’

SELECT DISTINCT(ST_Intersection(r.geom, w.geom)) INTO T2019_KAR_BRIDGES 
FROM t2019_kar_railways r, t2019_kar_water_lines w;

SELECT * FROM T2019_KAR_BRIDGES AS bridges;



