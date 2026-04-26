-- ============================================
-- vw_belief_analysis.sql
-- Comparação entre previsão do usuário, previsão do
-- sistema e nota real — apenas para filmes já assistidos
--
-- Perguntas que esta view responde:
--   • O usuário sabia o quanto ia gostar antes de assistir?
--   • O sistema de recomendação foi mais preciso que o próprio usuário?
--   • Filmes com alta incerteza tendem a surpreender positivamente?
--
-- Filtros:
--   • isSeen = '1'            → somente filmes assistidos
--   • userElicitRating IS NOT NULL → somente quem avaliou de verdade
--
-- Técnicas: SAFE_CAST, NULLIF, ROUND, ABS, JOIN
-- Dataset: netflix_analytical
-- ============================================

SELECT
  -- Identificadores
  SAFE_CAST(NULLIF(b.userId,  '') AS INT64)   AS user_id,
  dm.movie_id,
  dm.title,
  dm.genres,
  dm.release_year,

  -- Notas
  SAFE_CAST(NULLIF(b.userElicitRating,   '') AS FLOAT64) AS actual_rating,
  SAFE_CAST(NULLIF(b.userPredictRating,  '') AS FLOAT64) AS user_predicted_rating,
  SAFE_CAST(NULLIF(b.systemPredictRating,'') AS FLOAT64) AS system_predicted_rating,

  -- Confiança do usuário na previsão (1–5)
  SAFE_CAST(NULLIF(b.userCertainty, '') AS INT64) AS user_certainty,

  -- Erro absoluto: diferença entre previsto e real
  ROUND(ABS(
    SAFE_CAST(NULLIF(b.userPredictRating,  '') AS FLOAT64) -
    SAFE_CAST(NULLIF(b.userElicitRating,   '') AS FLOAT64)
  ), 2) AS user_prediction_error,

  ROUND(ABS(
    SAFE_CAST(NULLIF(b.systemPredictRating,'') AS FLOAT64) -
    SAFE_CAST(NULLIF(b.userElicitRating,   '') AS FLOAT64)
  ), 2) AS system_prediction_error,

  -- Quem acertou mais? (menor erro absoluto vence)
  CASE
    WHEN SAFE_CAST(NULLIF(b.userPredictRating,  '') AS FLOAT64) IS NULL THEN 'no_user_prediction'
    WHEN SAFE_CAST(NULLIF(b.systemPredictRating,'') AS FLOAT64) IS NULL THEN 'no_system_prediction'
    WHEN ABS(SAFE_CAST(NULLIF(b.userPredictRating,  '') AS FLOAT64) -
             SAFE_CAST(NULLIF(b.userElicitRating,   '') AS FLOAT64))
       < ABS(SAFE_CAST(NULLIF(b.systemPredictRating,'') AS FLOAT64) -
             SAFE_CAST(NULLIF(b.userElicitRating,   '') AS FLOAT64))
    THEN 'user'
    WHEN ABS(SAFE_CAST(NULLIF(b.userPredictRating,  '') AS FLOAT64) -
             SAFE_CAST(NULLIF(b.userElicitRating,   '') AS FLOAT64))
       = ABS(SAFE_CAST(NULLIF(b.systemPredictRating,'') AS FLOAT64) -
             SAFE_CAST(NULLIF(b.userElicitRating,   '') AS FLOAT64))
    THEN 'tie'
    ELSE 'system'
  END AS more_accurate,

  -- Surpresa: nota real maior que o previsto pelo usuário?
  CASE
    WHEN SAFE_CAST(NULLIF(b.userPredictRating,'') AS FLOAT64) IS NULL THEN NULL
    WHEN SAFE_CAST(NULLIF(b.userElicitRating, '') AS FLOAT64) >
         SAFE_CAST(NULLIF(b.userPredictRating,'') AS FLOAT64) THEN 'positive_surprise'
    WHEN SAFE_CAST(NULLIF(b.userElicitRating, '') AS FLOAT64) <
         SAFE_CAST(NULLIF(b.userPredictRating,'') AS FLOAT64) THEN 'disappointment'
    ELSE 'as_expected'
  END AS surprise_type,

  TIMESTAMP_SECONDS(
    SAFE_CAST(NULLIF(b.tstamp, '') AS INT64)
  ) AS recorded_at

FROM `netflix-pipeline-pedro-barbosa.netflix_raw.raw_belief_data` b
JOIN `netflix-pipeline-pedro-barbosa.netflix_analytical.dim_movies` dm
  ON dm.movie_id = SAFE_CAST(NULLIF(b.movieId, '') AS INT64)

WHERE b.isSeen = '1'
  AND SAFE_CAST(NULLIF(b.userElicitRating, '') AS FLOAT64) IS NOT NULL
