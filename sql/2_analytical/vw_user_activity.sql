-- ============================================
-- vw_user_activity.sql
-- Perfil de comportamento por usuário
-- Métricas: total_ratings, distinct_movies_rated,
-- avg_rating, std_rating, first_activity_ts, last_activity_ts
-- Dataset: netflix_analytical
-- ============================================

SELECT
   user_id,
   COUNT(*) AS total_ratings,
   COUNT(DISTINCT movie_id) AS distinct_movies_rated,
   AVG(rating) AS avg_rating,
   STDDEV(rating) AS std_rating,
   MIN(rating_ts) AS first_activity_ts,
   MAX(rating_ts) AS last_activity_ts
FROM netflix-pipeline-pedro-barbosa.netflix_analytical.fact_ratings
GROUP BY user_id
ORDER BY total_ratings DESC, avg_rating DESC
