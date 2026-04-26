-- ============================================
-- create_external_tables.sql
-- Criação das tabelas externas no BigQuery
-- apontando para os CSVs no GCS (camada Bronze)
-- Todas as colunas definidas como STRING para evitar
-- erros de ingestão — tipos são tratados na camada analytical
-- Bucket: gs://pedro-barbosa-netflix-data/bronze/
-- Dataset: netflix_raw
-- ============================================


-- --------------------------------------------
-- raw_movies
-- Catálogo de filmes (movieId, title, genres)
-- --------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `netflix-pipeline-pedro-barbosa.netflix_raw.raw_movies`
(
  movieId STRING,
  title   STRING,
  genres  STRING
)
OPTIONS (
  format            = 'CSV',
  uris              = ['gs://pedro-barbosa-netflix-data/bronze/movies.csv'],
  skip_leading_rows = 1
);


-- --------------------------------------------
-- raw_user_rating_history
-- Avaliações dos usuários principais
-- --------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `netflix-pipeline-pedro-barbosa.netflix_raw.raw_user_rating_history`
(
  userId  STRING,
  movieId STRING,
  rating  STRING,
  tstamp  STRING
)
OPTIONS (
  format            = 'CSV',
  uris              = ['gs://pedro-barbosa-netflix-data/bronze/user_rating_history.csv'],
  skip_leading_rows = 1
);


-- --------------------------------------------
-- raw_ratings_for_additional_users
-- Avaliações de usuários adicionais
-- --------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `netflix-pipeline-pedro-barbosa.netflix_raw.raw_ratings_for_additional_users`
(
  userId  STRING,
  movieId STRING,
  rating  STRING,
  tstamp  STRING
)
OPTIONS (
  format            = 'CSV',
  uris              = ['gs://pedro-barbosa-netflix-data/bronze/ratings_for_additional_users.csv'],
  skip_leading_rows = 1
);


-- --------------------------------------------
-- raw_user_recommendation_history
-- Recomendações geradas pelo sistema
-- --------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `netflix-pipeline-pedro-barbosa.netflix_raw.raw_user_recommendation_history`
(
  userId          STRING,
  tstamp          STRING,
  movieId         STRING,
  predictedRating STRING
)
OPTIONS (
  format            = 'CSV',
  uris              = ['gs://pedro-barbosa-netflix-data/bronze/user_recommendation_history.csv'],
  skip_leading_rows = 1
);


-- --------------------------------------------
-- raw_movie_elicitation_set
-- Filmes usados para sondar preferências iniciais
-- source: 1=Popularidade, 2=Bem avaliado, 3=Lançamento recente
--         4=Em tendência, 5=Serendipidade
-- --------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `netflix-pipeline-pedro-barbosa.netflix_raw.raw_movie_elicitation_set`
(
  movieId   STRING,
  month_idx STRING,
  source    STRING,
  tstamp    STRING
)
OPTIONS (
  format            = 'CSV',
  uris              = ['gs://pedro-barbosa-netflix-data/bronze/movie_elicitation_set.csv'],
  skip_leading_rows = 1
);


-- --------------------------------------------
-- raw_belief_data
-- Tabela principal do dataset: avaliações reais,
-- previsões de nota e "beliefs" dos usuários
-- isSeen: -1=não respondeu, 0=não viu, 1=já viu
-- --------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `netflix-pipeline-pedro-barbosa.netflix_raw.raw_belief_data`
(
  userId              STRING,
  movieId             STRING,
  isSeen              STRING,
  watchDate           STRING,
  userElicitRating    STRING,
  userPredictRating   STRING,
  userCertainty       STRING,
  tstamp              STRING,
  month_idx           STRING,
  source              STRING,
  systemPredictRating STRING
)
OPTIONS (
  format            = 'CSV',
  uris              = ['gs://pedro-barbosa-netflix-data/bronze/belief_data.csv'],
  skip_leading_rows = 1
);
