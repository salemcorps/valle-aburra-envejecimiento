-- =====================================================================
-- El Valle de Aburrá envejece: ¿qué pasará con su población hasta 2050?
-- Consultas MySQL 8 sobre la base vda_envejecimiento
--
-- Tablas
--   poblacion   (anio, area, sexo, edad, poblacion)
--   indicadores (anio, area, poblacion_total, pob_0_14, pob_15_64, pob_65_mas,
--                pob_80_mas, pct_*, indice_envejecimiento, razon_dependencia,
--                razon_dep_vejez, edad_mediana, mujeres_por_100_hombres_65_mas)
--
-- Nota: el desglose Cabecera y Rural del DANE llega hasta 2045.
--       El total llega hasta 2050.
-- Requiere MySQL 8.0 o superior (CTEs y funciones de ventana).
-- =====================================================================


-- Q1. ¿Cómo cambian la edad mediana y el peso de los mayores de 65?
--     Variación frente a 5 años antes (LAG sobre la serie completa).
WITH serie AS (
    SELECT anio,
           poblacion_total,
           pct_65_mas,
           edad_mediana,
           ROUND(edad_mediana - LAG(edad_mediana, 5) OVER (ORDER BY anio), 1) AS cambio_edad_mediana_5a,
           ROUND(pct_65_mas  - LAG(pct_65_mas, 5)  OVER (ORDER BY anio), 2)   AS cambio_pct_65_5a
    FROM indicadores
    WHERE area = 'Total'
)
SELECT *
FROM serie
WHERE anio IN (2018, 2023, 2028, 2033, 2038, 2043, 2048, 2050)
ORDER BY anio;


-- Q2. ¿Cuándo hay más adultos mayores que niños y jóvenes?
--     Primer año en que los mayores de 65 superan a los menores de 15.
SELECT anio     AS anio_inversion,
       pob_65_mas AS mayores_65,
       pob_0_14   AS menores_15,
       indice_envejecimiento
FROM indicadores
WHERE area = 'Total' AND pob_65_mas > pob_0_14
ORDER BY anio
LIMIT 1;


-- Q3. ¿Cuándo deja de crecer la población y cuánto pierde después?
WITH serie AS (
    SELECT anio,
           poblacion_total,
           poblacion_total - LAG(poblacion_total) OVER (ORDER BY anio) AS variacion_anual,
           ROUND(100.0 * (poblacion_total - LAG(poblacion_total) OVER (ORDER BY anio))
                 / LAG(poblacion_total) OVER (ORDER BY anio), 2)       AS crecimiento_pct,
           MAX(poblacion_total) OVER ()                                AS maximo
    FROM indicadores
    WHERE area = 'Total'
)
SELECT anio, poblacion_total, variacion_anual, crecimiento_pct,
       CASE WHEN poblacion_total = maximo THEN 'PICO' ELSE '' END AS nota
FROM serie
WHERE anio BETWEEN 2030 AND 2050
ORDER BY anio;


-- Q4. Razón de dependencia: ¿quién pesa más sobre la población en edad de trabajar?
--     (por cada 100 personas de 15 a 64 años)
SELECT anio,
       ROUND(100.0 * pob_0_14   / pob_15_64, 1) AS dependencia_jovenes,
       ROUND(100.0 * pob_65_mas / pob_15_64, 1) AS dependencia_vejez,
       razon_dependencia                         AS dependencia_total
FROM indicadores
WHERE area = 'Total' AND anio IN (2018, 2025, 2030, 2035, 2040, 2045, 2050)
ORDER BY anio;


-- Q5. Pirámide en grupos quinquenales: 2025 frente a 2050, por sexo.
WITH grupos AS (
    SELECT anio, sexo,
           CASE WHEN edad >= 80 THEN 16 ELSE edad DIV 5 END AS g,
           SUM(poblacion) AS pob
    FROM poblacion
    WHERE area = 'Total' AND anio IN (2025, 2050)
    GROUP BY anio, sexo, g
)
SELECT CASE WHEN g = 16 THEN '80+' ELSE CONCAT(g * 5, '-', g * 5 + 4) END AS grupo_edad,
       SUM(CASE WHEN anio = 2025 AND sexo = 'Hombres' THEN pob END) AS hombres_2025,
       SUM(CASE WHEN anio = 2025 AND sexo = 'Mujeres' THEN pob END) AS mujeres_2025,
       SUM(CASE WHEN anio = 2050 AND sexo = 'Hombres' THEN pob END) AS hombres_2050,
       SUM(CASE WHEN anio = 2050 AND sexo = 'Mujeres' THEN pob END) AS mujeres_2050
FROM grupos
GROUP BY g
ORDER BY g;


-- Q6. ¿Qué grupos de edad ganan y pierden más gente entre 2025 y 2050?
--     Ranking con RANK() sobre el cambio absoluto.
WITH grupos AS (
    SELECT anio,
           CASE WHEN edad >= 80 THEN 16 ELSE edad DIV 5 END AS g,
           SUM(poblacion) AS pob
    FROM poblacion
    WHERE area = 'Total' AND anio IN (2025, 2050)
    GROUP BY anio, g
),
cambio AS (
    SELECT g,
           SUM(CASE WHEN anio = 2025 THEN pob END) AS pob_2025,
           SUM(CASE WHEN anio = 2050 THEN pob END) AS pob_2050
    FROM grupos
    GROUP BY g
)
SELECT CASE WHEN g = 16 THEN '80+' ELSE CONCAT(g * 5, '-', g * 5 + 4) END AS grupo_edad,
       pob_2025,
       pob_2050,
       pob_2050 - pob_2025                                AS cambio_absoluto,
       ROUND(100.0 * (pob_2050 - pob_2025) / pob_2025, 1) AS cambio_pct,
       RANK() OVER (ORDER BY pob_2050 - pob_2025 DESC)    AS ranking_ganancia
FROM cambio
ORDER BY ranking_ganancia;


-- Q7. Feminización de la vejez: mujeres por cada 100 hombres según edad.
SELECT anio,
       CASE WHEN edad BETWEEN 65 AND 79 THEN '65-79' ELSE '80+' END AS grupo,
       ROUND(100.0 * SUM(CASE WHEN sexo = 'Mujeres' THEN poblacion END)
                   / SUM(CASE WHEN sexo = 'Hombres' THEN poblacion END), 1) AS mujeres_por_100_hombres
FROM poblacion
WHERE area = 'Total' AND edad >= 65 AND anio IN (2018, 2030, 2050)
GROUP BY anio, grupo
ORDER BY grupo, anio;


-- Q8. Cabecera y rural (hasta 2045): ¿envejecen al mismo ritmo?
SELECT anio,
       MAX(CASE WHEN area = 'Cabecera' THEN pct_65_mas    END) AS pct_65_cabecera,
       MAX(CASE WHEN area = 'Rural'    THEN pct_65_mas    END) AS pct_65_rural,
       MAX(CASE WHEN area = 'Cabecera' THEN edad_mediana  END) AS edad_mediana_cabecera,
       MAX(CASE WHEN area = 'Rural'    THEN edad_mediana  END) AS edad_mediana_rural,
       MAX(CASE WHEN area = 'Rural'    THEN poblacion_total END) AS poblacion_rural
FROM indicadores
WHERE area IN ('Cabecera', 'Rural') AND anio IN (2018, 2025, 2035, 2045)
GROUP BY anio
ORDER BY anio;
