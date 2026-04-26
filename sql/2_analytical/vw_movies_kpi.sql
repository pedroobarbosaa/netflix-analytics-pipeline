-- ============================================
-- vw_movies_kpi.sql
-- KPIs de performance por filme
-- LEFT JOIN entre fact_ratings e dim_movies
-- Métricas: total_ratings, avg_rating, std_rating,
-- first_rating_ts, last_rating_ts
-- Dataset: netflix_analytical
-- ============================================

SELECT
  r.movie_id,
  m.title,
  m.genres,
  m.release_year,
  COUNT(*) AS total_ratings,
  AVG(r.rating) AS avg_rating,
  STDDEV(r.rating) AS std_rating,
  MIN(r.rating_ts) AS first_rating_ts,
  MAX(r.rating_ts) AS last_rating_ts
FROM netflix-pipeline-pedro-barbosa.netflix_analytical.fact_ratings r
LEFT JOIN netflix-pipeline-pedro-barbosa.netflix_analytical.dim_movies m
  ON m.movie_id = r.movie_id
GROUP BY r.movie_id, m.title, m.genres, m.release_year
