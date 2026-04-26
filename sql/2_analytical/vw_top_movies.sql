-- ============================================
-- vw_top_movies.sql
-- Top 10 filmes mais bem avaliados
-- Filtro de relevância: total_ratings >= 20
-- Fonte: vw_movies_kpi
-- Dataset: netflix_analytical
-- ============================================

SELECT
  movie_id,
  title,
  genres,
  release_year,
  total_ratings,
  ROUND(avg_rating, 2) AS avg_rating
FROM netflix-pipeline-pedro-barbosa.netflix_analytical.vw_movies_kpi
WHERE total_ratings >= 20
  AND avg_rating BETWEEN 0 AND 5
ORDER BY avg_rating DESC, total_ratings DESC
LIMIT 10
