-- ============================================
-- fact_ratings.sql
-- Fatos de avaliações — UNION ALL de duas fontes
-- Fontes: raw_user_rating_history + raw_ratings_for_additional_users
-- Técnicas: SAFE_CAST, NULLIF, COALESCE, TIMESTAMP_SECONDS, UNION ALL
-- Coluna `src` para rastreabilidade da origem
-- Filtro final remove linhas com campos essenciais nulos
-- Dataset: netflix_analytical
-- ============================================

CREATE OR REPLACE TABLE `netflix-pipeline-pedro-barbosa.netflix_analytical.fact_ratings` AS

SELECT *
FROM (

  -- Fonte 1: histórico de avaliações dos usuários principais
  SELECT
    SAFE_CAST(NULLIF(userId,  '') AS INT64)    AS user_id,
    SAFE_CAST(NULLIF(movieId, '') AS INT64)    AS movie_id,
    SAFE_CAST(NULLIF(rating,  '') AS FLOAT64)  AS rating,
    COALESCE(
      TIMESTAMP_SECONDS(SAFE_CAST(NULLIF(tstamp, '') AS INT64)),
      SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', NULLIF(tstamp, ''))
    )                                          AS rating_ts,
    'user_rating_history'                      AS src
  FROM `netflix-pipeline-pedro-barbosa.netflix_raw.raw_user_rating_history`

  UNION ALL

  -- Fonte 2: avaliações de usuários adicionais
  SELECT
    SAFE_CAST(NULLIF(userId,  '') AS INT64)    AS user_id,
    SAFE_CAST(NULLIF(movieId, '') AS INT64)    AS movie_id,
    SAFE_CAST(NULLIF(rating,  '') AS FLOAT64)  AS rating,
    COALESCE(
      TIMESTAMP_SECONDS(SAFE_CAST(NULLIF(tstamp, '') AS INT64)),
      SAFE.PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S', NULLIF(tstamp, ''))
    )                                          AS rating_ts,
    'additional_users'                         AS src
  FROM `netflix-pipeline-pedro-barbosa.netflix_raw.raw_ratings_for_additional_users`

)
WHERE user_id   IS NOT NULL
  AND movie_id  IS NOT NULL
  AND rating    IS NOT NULL
  AND rating_ts IS NOT NULL
