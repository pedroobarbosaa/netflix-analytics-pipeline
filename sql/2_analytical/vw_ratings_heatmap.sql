-- ============================================
-- vw_ratings_heatmap.sql
-- Volume de avaliações por mês/ano
-- Base para o gráfico de mapa de calor
-- Técnicas: EXTRACT, FORMAT_TIMESTAMP
-- Dataset: netflix_analytical
-- ============================================

SELECT
  EXTRACT(YEAR FROM rating_ts) AS year,
  EXTRACT(MONTH FROM rating_ts) AS month_number,
  FORMAT_TIMESTAMP('%b', rating_ts) AS month_name,
  COUNT(*) AS total_ratings
FROM netflix-pipeline-pedro-barbosa.netflix_analytical.fact_ratings
GROUP BY year, month_number, month_name
ORDER BY year, month_number
