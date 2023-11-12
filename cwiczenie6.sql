--1. Utwórz tabelę obiekty. W tabeli umieść nazwy i geometrie obiektów przedstawionych poniżej. Układ odniesienia
--ustal jako niezdefiniowany. Definicja geometrii powinna odbyć się za pomocą typów złożonych, właściwych dla EWKT
CREATE EXTENSION postgis;

CREATE TABLE obiekty(
id INT PRIMARY KEY, 
nazwa VARCHAR(10) NOT NULL,
geom GEOMETRY NOT NULL
);

INSERT INTO obiekty(id, nazwa, geom) VALUES --geometry collection zagniezdza rozne typy geometrii w jednym obiekcie
('1', 'obiekt1', ST_GeomFromEWKT('GEOMETRYCOLLECTION(
		LINESTRING(0 0, 1 1),CIRCULARSTRING(1 1, 2 0, 3 1), CIRCULARSTRING(3 1, 4 0, 5 1), LINESTRING(4 0, 5 1))')),
('2','obiekt2', ST_GeomFromEWKT('CURVEPOLYGON( 
					COMPOUNDCURVE( (10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2), CIRCULARSTRING(14 2, 12 0, 10 2), (10 2, 10 6)),
					COMPOUNDCURVE( CIRCULARSTRING(11 2, 12 3, 13 2), CIRCULARSTRING(13 2, 12 1, 11 2)))')),
('3','obiekt3', ST_GeomFromEWKT('TRIANGLE((7 15, 10 17, 12 13, 7 15))')),
('4','obiekt4', ST_GeomFromEWKT('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)')),
('5', 'obiekt5', ST_GeomFromEWKT('MULTIPOINT(30 30 59, 38 32 234)')),
('6','obiekt6', ST_GeomFromEWKT('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))'));

--1) Wyznacz pole powierzchni bufora o wielkości 5 jednostek, który został utworzony wokół najkrótszej linii łączącej
--obiekt 3 i 4.
SELECT
ROUND(ST_Area(ST_Buffer(ST_ShortestLine((SELECT geom FROM obiekty WHERE nazwa='obiekt3'), 
								        (SELECT geom FROM obiekty WHERE nazwa='obiekt4')),
				5)
			 )
::NUMERIC, 4)
AS pole;
	 
--2) Zamień obiekt4 na poligon. Jaki warunek musi być spełniony, aby można było wykonać to zadanie? Zapewnij te
--warunki
UPDATE obiekty
SET geom = ST_GeomFromEWKT('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20)')
WHERE nazwa = 'obiekt4';

--3) W tabeli obiekty, jako obiekt7 zapisz obiekt złożony z obiektu 3 i obiektu 4
INSERT INTO obiekty(id, nazwa, geom) VALUES
('7', 'obiekt7', ST_Union((SELECT geom FROM obiekty WHERE nazwa = 'obiekt3'),
						  (SELECT geom FROM obiekty WHERE nazwa = 'obiekt4')));
						  
--4) Wyznacz pole powierzchni wszystkich buforów o wielkości 5 jednostek, które zostały utworzone wokół obiektów nie
--zawierających łuków.
SELECT nazwa, ST_Area(ST_Buffer(geom, 5)) AS pole
FROM obiekty
WHERE NOT ST_HasArc(geom);


SELECT * FROM obiekty;