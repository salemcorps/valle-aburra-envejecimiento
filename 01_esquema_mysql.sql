-- =====================================================================
-- El Valle de Aburrá envejece · Esquema MySQL 8
-- Se ejecuta desde el notebook (celda "Crear esquema"), o a mano:
--   mysql -u root -p < 01_esquema_mysql.sql
-- =====================================================================

CREATE DATABASE IF NOT EXISTS vda_envejecimiento
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE vda_envejecimiento;

DROP TABLE IF EXISTS poblacion;
DROP TABLE IF EXISTS indicadores;

-- Una fila por año, área, sexo y edad simple (0 a 100+)
CREATE TABLE poblacion (
    anio       SMALLINT         NOT NULL,
    area       VARCHAR(10)      NOT NULL,   -- Total, Cabecera, Rural
    sexo       VARCHAR(7)       NOT NULL,   -- Hombres, Mujeres
    edad       TINYINT UNSIGNED NOT NULL,   -- 100 = 100 años y más
    poblacion  INT              NOT NULL,
    PRIMARY KEY (anio, area, sexo, edad)
);

-- Indicadores demográficos por año y área
CREATE TABLE indicadores (
    anio                            SMALLINT     NOT NULL,
    area                            VARCHAR(10)  NOT NULL,
    poblacion_total                 INT          NOT NULL,
    pob_0_14                        INT          NOT NULL,
    pob_15_64                       INT          NOT NULL,
    pob_65_mas                      INT          NOT NULL,
    pob_80_mas                      INT          NOT NULL,
    pct_0_14                        DECIMAL(5,2) NOT NULL,
    pct_15_64                       DECIMAL(5,2) NOT NULL,
    pct_65_mas                      DECIMAL(5,2) NOT NULL,
    pct_80_mas                      DECIMAL(5,2) NOT NULL,
    indice_envejecimiento           DECIMAL(6,1) NOT NULL,
    razon_dependencia               DECIMAL(5,1) NOT NULL,
    razon_dep_vejez                 DECIMAL(5,1) NOT NULL,
    edad_mediana                    DECIMAL(4,1) NOT NULL,
    mujeres_por_100_hombres_65_mas  DECIMAL(5,1) NOT NULL,
    PRIMARY KEY (area, anio)
);
