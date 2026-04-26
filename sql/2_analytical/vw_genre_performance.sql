-- ============================================
-- vw_genre_performance.sql
-- Performance por gênero
-- Técnica: SPLIT + UNNEST + CROSS JOIN (explode)
-- Métricas: total_ratings, avg_rating, std_rating por gênero
-- Dataset: netflix_analytical
-- ============================================

WITH exploded AS (
  SELECT
    r.rating,
    genre
  FROM netflix-pipeline-pedro-barbosa.netflix_analytical.fact_ratings r
  JOIN netflix-pipeline-pedro-barbosa.netflix_analytical.dim_movies m
    ON m.movie_id = r.movie_id
  CROSS JOIN UNNEST(SPLIT(COALESCE(m.genres, ''), '|')) AS genre
)
SELECT
  genre,
  COUNT(*) AS total_ratings,
  AVG(rating) AS avg_rating,
  STDDEV(rating) AS std_rating
FROM exploded
WHERE genre IS NOT NULL
  AND genre != ''
  AND genre != '(no genres listed)'
GROUP BY 1
ORDER BY total_ratings DESC, avg_rating DESC
