-- ============================================
-- vw_scatter_popularity_vs_quality.sql
-- Dados para gráfico de dispersão
-- Popularidade (total_ratings) vs Qualidade (avg_rating)
-- Filtro: total_ratings >= 50 AND avg_rating BETWEEN 1 AND 5
-- Fonte: vw_movies_kpi
-- Dataset: netflix_analytical
-- ============================================

SELECT
  movie_id,
  title,
  genres,
  release_year,
  total_ratings,
  avg_rating
FROM netflix-pipeline-pedro-barbosa.netflix_analytical.vw_movies_kpi
WHERE total_ratings >= 50
  AND avg_rating BETWEEN 1 AND 5
