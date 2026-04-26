-- ============================================
-- dim_movies.sql
-- Dimensão de filmes com tipos convertidos
-- Fonte: netflix_raw.raw_movies
-- Técnicas: SAFE_CAST, REGEXP_EXTRACT, REGEXP_REPLACE
-- Bug corrigido: release_year usava \{4} → corrigido para \d{4}
-- Dataset: netflix_analytical
-- ============================================

CREATE OR REPLACE TABLE `netflix-pipeline-pedro-barbosa.netflix_analytical.dim_movies` AS
SELECT
  SAFE_CAST(movieId AS INT64)                                         AS movie_id,
  REGEXP_REPLACE(title, r'\s*\(\d{4}\)\s*$', '')                     AS title,
  SAFE_CAST(REGEXP_EXTRACT(title, r'\((\d{4})\)') AS INT64)          AS release_year,
  genres
FROM `netflix-pipeline-pedro-barbosa.netflix_raw.raw_movies`
WHERE movieId IS NOT NULL
  AND movieId != ''
