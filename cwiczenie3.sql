--4) Wyznacz liczbę budynków położonych w odległości mniejszej niż 1000 jednostek od głównych rzek. 
--Budynki spełniające to kryterium zapisz do osobnej tabeli tableB

SELECT p.* INTO TableB
FROM popp p, majrivers m
WHERE 
p.f_codedesc='Building' 
AND
ST_DWithin(p.geom, m.geom, 1000);

SELECT COUNT(f_codedesc) AS Ilosc_budynkow FROM TableB;

--5) Utwórz tabelę o nazwie airportsNew. Z tabeli airports do zaimportuj nazwy lotnisk, ich
-- geometrię, a także atrybut elev, reprezentujący wysokość n.p.m.

CREATE TABLE airportsNew AS (
SELECT name, geom, elev
FROM airports
);
SELECT * FROM airportsNew;

--a) Znajdź lotnisko, które położone jest najbardziej na zachód 
-- i najbardziej na wschód.

-- W
SELECT * FROM airportsNew
ORDER BY ST_XMin(geom)
LIMIT 1;

-- E
SELECT * FROM airportsNew
ORDER BY ST_XMax(geom) DESC
LIMIT 1;

--b) Do tabeli airportsNew dodaj nowy obiekt - lotnisko, które położone jest w punkcie
-- środkowym drogi pomiędzy lotniskami znalezionymi w punkcie a. Lotnisko nazwij airportB.
-- Wysokość n.p.m. przyjmij dowolną.

INSERT INTO airportsNew (name) VALUES ('airportB');
--CTE
WITH 
zachod AS (
  SELECT geom FROM airportsNew ORDER BY ST_X(geom) LIMIT 1
),
wschod AS (
  SELECT geom FROM airportsNew ORDER BY ST_X(geom) DESC LIMIT 1
)
INSERT INTO airportsNew (geom)
SELECT ST_Centroid(ST_MakeLine((SELECT geom FROM zachod), (SELECT geom FROM wschod)));

--sprawdzenie
SELECT name  FROM airportsNew
WHERE name='airportB'

--6) Wyznacz pole powierzchni obszaru, który oddalony jest mniej niż 1000 jednostek od najkrótszej
-- linii łączącej jezioro o nazwie ‘Iliamna Lake’ i lotnisko o nazwie „AMBLER”
										 
WITH 
obiekty AS (
  SELECT
    (SELECT geom FROM lakes WHERE names='Iliamna Lake') AS jezioro,
    (SELECT geom FROM airports WHERE name='AMBLER') AS lotnisko
)
SELECT ROUND(ST_Area(ST_Buffer(ST_ShortestLine(jezioro, lotnisko), 1000))::NUMERIC,2) AS pole_powierzchni
FROM obiekty;

--7)Napisz zapytanie, które zwróci sumaryczne pole powierzchni poligonów reprezentujących
-- poszczególne typy drzew znajdujących się na obszarze tundry i bagien (swamps).

WITH 
tundra
AS(
	SELECT tr.vegdesc AS drzewo, ST_Area(ST_Collect(ST_Intersection(tu.geom, tr.geom))) AS obszar
	FROM tundra tu, trees tr
	GROUP BY tr.vegdesc
),
bagna
AS(
	SELECT tr.vegdesc AS drzewo, ST_Area(ST_Collect(ST_Intersection(s.geom, tr.geom))) AS obszar
	FROM swamp s, trees tr
	GROUP BY tr.vegdesc
)
SELECT t.drzewo,(t.obszar + b.obszar)::NUMERIC(20, 2) AS obszar
FROM tundra t
INNER JOIN bagna b
ON t.drzewo = b.drzewo;











