--Dodaj funkcjonalności PostGIS’a do bazy 
CREATE EXTENSION postgis;

--Utwórz trzy tabele: budynki (id, geometria, nazwa), drogi
--(id, geometria, nazwa), punkty_informacyjne (id, geometria, nazwa).
CREATE SCHEMA miasto;

CREATE TABLE miasto.budynki(
id INT PRIMARY KEY,
geometria GEOMETRY NOT NULL,
nazwa VARCHAR(50) NOT NULL
);

CREATE TABLE miasto.drogi(
id INT PRIMARY KEY,
geometria GEOMETRY NOT NULL,
nazwa VARCHAR(50) NOT NULL
);

CREATE TABLE miasto.punkty_informacyjne(
id INT PRIMARY KEY,
geometria GEOMETRY NOT NULL,
nazwa VARCHAR(70) NOT NULL
);

--Dodaj współrzędne oraz nazwy obiektów.
INSERT INTO miasto.budynki VALUES
(1, ST_GeomFromText('POLYGON((8 4, 10.5 4, 10.5 1.5, 8 1.5, 8 4))'), 'Building A'),
(2, ST_GeomFromText('POLYGON((4 7, 6 7, 6 5, 4 5, 4 7))'), 'Building B'),
(3, ST_GeomFromText('POLYGON((3 8, 5 8, 5 6, 3 6, 3 8))'), 'Building C'),
(4, ST_GeomFromText('POLYGON((9 9, 10 9, 10 8, 9 8, 9 9))'), 'Building D'),
(5, ST_GeomFromText('POLYGON((1 2, 2 2, 2 1, 1 1, 1 2))'), 'Building F');

--SELECT id, ST_AsText(geometria), geometria, nazwa FROM miasto.budynki

INSERT INTO miasto.drogi VALUES
(1, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)'), 'Road X'),
(2, ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)'), 'Road Y');

INSERT INTO miasto.punkty_informacyjne VALUES
(1, ST_GeomFromText('POINT(1 3.5)'), 'G'),
(2, ST_GeomFromText('POINT(5.5 1.5)'), 'H'),
(3, ST_GeomFromText('POINT(9.5 6)'), 'I'),
(4, ST_GeomFromText('POINT(6.5 6)'), 'J'),
(5, ST_GeomFromText('POINT(6 9.5)'), 'K');

--a) Wyznacz całkowitą długość dróg w analizowanym mieście.
SELECT SUM(ST_Length(geometria)) AS długość_dróg
FROM miasto.drogi

----b) Wypisz geometrię (WKT), pole powierzchni oraz obwód poligonu reprezentującego
--budynek o nazwie BuildingA.
SELECT nazwa, ST_AsText(geometria) AS WKT, ST_Area(geometria) AS pole, ST_Perimeter(geometria) AS obwód
FROM miasto.budynki
WHERE nazwa = 'Building A';

--c) Wypisz nazwy i pola powierzchni wszystkich poligonów w warstwie budynki. Wyniki
--posortuj alfabetycznie
SELECT nazwa, ST_Area(geometria) AS pole
FROM miasto.budynki
ORDER BY nazwa;

--d) Wypisz nazwy i obwody 2 budynków o największej powierzchni.
SELECT nazwa, ST_Perimeter(geometria) AS obwód
FROM miasto.budynki
ORDER BY ST_Area(geometria) DESC
LIMIT 2;

--e) Wyznacz najkrótszą odległość między budynkiem BuildingC a punktem G.
SELECT ROUND(ST_Distance(c.geometria, g.geometria)::numeric, 2) AS odległość
FROM miasto.budynki c, miasto.punkty_informacyjne g
WHERE c.nazwa = 'Building C' AND g.nazwa = 'G';

--f) Wypisz pole powierzchni tej części budynku BuildingC, która znajduje się w
--odległości większej niż 0.5 od budynku BuildingB.
SELECT ROUND(ST_Area(ST_Difference(c.geometria, ST_Buffer(b.geometria, 0.5)))::numeric, 2) AS pole
FROM miasto.budynki c, miasto.budynki b 
WHERE c.nazwa = 'Building C' AND b.nazwa = 'Building B';

--g) Wybierz te budynki, których centroid (środek ciężkości) znajduje się
--powyżej drogi o nazwie RoadX.
SELECT b.nazwa, ST_AsTExt(ST_Centroid(b.geometria)) AS centroid
FROM miasto.budynki b, miasto.drogi x
WHERE ST_Y(ST_Centroid(b.geometria)) > ST_Y(ST_Centroid(x.geometria))
AND x.nazwa = 'Road X';

--h) Oblicz pole powierzchni tych części budynku BuildingC i poligonu
--o współrzędnych (4 7, 6 7, 6 8, 4 8, 4 7), które nie są wspólne dla tych dwóch
--obiektów.
SELECT ST_Area(ST_SymDifference(c.geometria, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))) AS pole
FROM miasto.budynki c
WHERE c.nazwa = 'Building C';







