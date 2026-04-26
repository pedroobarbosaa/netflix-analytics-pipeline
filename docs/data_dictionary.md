# Data Dictionary

Complete reference for all tables and views in the Netflix Analytics Pipeline.

---

## Raw Layer — `netflix_raw`

External tables that read directly from CSV files stored in GCS. All columns are typed as `STRING` to prevent ingestion errors — type casting happens in the analytical layer.

---

### `raw_movies`

Movie catalog.

| Column | Type | Description |
|---|---|---|
| `movieId` | STRING | Unique movie identifier |
| `title` | STRING | Movie title including release year in parentheses, e.g. `Inception (2010)` |
| `genres` | STRING | Pipe-separated list of genres, e.g. `Action|Adventure|Sci-Fi`. Value `(no genres listed)` when unknown |

---

### `raw_user_rating_history`

Real ratings given by primary users for movies they have watched.

| Column | Type | Description |
|---|---|---|
| `userId` | STRING | Anonymous user identifier |
| `movieId` | STRING | Rated movie identifier |
| `rating` | STRING | Star rating on a 0.5–5.0 scale |
| `tstamp` | STRING | Unix timestamp (seconds since 1970-01-01) when the rating was submitted |

---

### `raw_ratings_for_additional_users`

Same structure as `raw_user_rating_history` for a second cohort of users. Combined with the primary source in `fact_ratings` via `UNION ALL`.

| Column | Type | Description |
|---|---|---|
| `userId` | STRING | Anonymous user identifier |
| `movieId` | STRING | Rated movie identifier |
| `rating` | STRING | Star rating on a 0.5–5.0 scale |
| `tstamp` | STRING | Unix timestamp when the rating was submitted |

---

### `raw_user_recommendation_history`

Movies recommended by the MovieLens system to each user.

| Column | Type | Description |
|---|---|---|
| `userId` | STRING | User who received the recommendation |
| `tstamp` | STRING | Unix timestamp when the recommendation was generated |
| `movieId` | STRING | Recommended movie identifier |
| `predictedRating` | STRING | Rating the system predicted the user would give |

---

### `raw_movie_elicitation_set`

Movies selected to ask users for rating predictions (used in the belief elicitation experiment).

| Column | Type | Description |
|---|---|---|
| `movieId` | STRING | Movie identifier |
| `month_idx` | STRING | Month index of the experiment when the movie was included |
| `source` | STRING | Selection group: `1`=Popularity, `2`=Highly rated, `3`=Recent popular, `4`=Trending, `5`=Serendipity |
| `tstamp` | STRING | Unix timestamp when the movie was presented to the user |

---

### `raw_belief_data`

Core table of the dataset. Captures what users believe they would rate a movie before watching it, alongside their actual rating after watching.

| Column | Type | Description |
|---|---|---|
| `userId` | STRING | Anonymous user identifier |
| `movieId` | STRING | Movie identifier |
| `isSeen` | STRING | Whether the user has watched the movie: `-1`=no answer, `0`=not seen, `1`=seen |
| `watchDate` | STRING | Approximate date the user watched the movie (populated only when `isSeen = 1`) |
| `userElicitRating` | STRING | Actual rating given by the user for movies they have seen (0.5–5.0) |
| `userPredictRating` | STRING | Predicted rating for movies the user has not seen yet (0.5–5.0) |
| `userCertainty` | STRING | User's confidence in their prediction (scale 1–5) |
| `tstamp` | STRING | Unix timestamp when the record was captured |
| `month_idx` | STRING | Month index of the experiment |
| `source` | STRING | Selection group the movie came from (same scale as `raw_movie_elicitation_set`) |
| `systemPredictRating` | STRING | Rating predicted by the MovieLens recommendation system |

---

## Analytical Layer — `netflix_analytical`

Typed, modeled tables following a Star Schema. Built from the raw layer using `SAFE_CAST`, `NULLIF`, `COALESCE`, and `REGEXP_EXTRACT`.

---

### `dim_movies` — Dimension Table

Movie dimension with cleaned and typed columns.

| Column | Type | Description |
|---|---|---|
| `movie_id` | INT64 | Unique movie identifier (cast from `raw_movies.movieId`) |
| `title` | STRING | Movie title with the year removed, e.g. `Inception` |
| `release_year` | INT64 | Year extracted from the original title string via `REGEXP_EXTRACT` |
| `genres` | STRING | Original pipe-separated genre string from the raw source |

---

### `fact_ratings` — Fact Table

All user ratings consolidated from two raw sources via `UNION ALL`. Rows with null values in any essential field are excluded.

| Column | Type | Description |
|---|---|---|
| `user_id` | INT64 | Anonymous user identifier |
| `movie_id` | INT64 | Rated movie — foreign key to `dim_movies.movie_id` |
| `rating` | FLOAT64 | Star rating (0.5–5.0) |
| `rating_ts` | TIMESTAMP | Timestamp converted from Unix epoch via `TIMESTAMP_SECONDS` |
| `src` | STRING | Source table: `user_rating_history` or `additional_users` |

---

## Analytical Views — `netflix_analytical`

Views built on top of the dimension and fact tables. No data is stored — each view re-runs its query on access.

---

### `vw_movies_kpi`

KPI summary per movie. Base view used as the source for `vw_top_movies` and `vw_scatter_popularity_vs_quality`.

| Column | Type | Description |
|---|---|---|
| `movie_id` | INT64 | Movie identifier |
| `title` | STRING | Movie title |
| `genres` | STRING | Pipe-separated genres |
| `release_year` | INT64 | Release year |
| `total_ratings` | INT64 | Total number of ratings received |
| `avg_rating` | FLOAT64 | Average rating |
| `std_rating` | FLOAT64 | Standard deviation of ratings (consistency indicator) |
| `first_rating_ts` | TIMESTAMP | Timestamp of the earliest rating |
| `last_rating_ts` | TIMESTAMP | Timestamp of the most recent rating |

---

### `vw_top_movies`

Top 10 highest-rated movies with a minimum of 20 ratings for statistical relevance.

| Column | Type | Description |
|---|---|---|
| `movie_id` | INT64 | Movie identifier |
| `title` | STRING | Movie title |
| `genres` | STRING | Pipe-separated genres |
| `release_year` | INT64 | Release year |
| `total_ratings` | INT64 | Total number of ratings |
| `avg_rating` | FLOAT64 | Average rating rounded to 2 decimal places |

---

### `vw_genre_performance`

Performance metrics per genre. Uses `SPLIT + UNNEST + CROSS JOIN` to explode the pipe-separated `genres` field into individual rows.

| Column | Type | Description |
|---|---|---|
| `genre` | STRING | Individual genre name |
| `total_ratings` | INT64 | Total ratings across all movies in this genre |
| `avg_rating` | FLOAT64 | Average rating for the genre |
| `std_rating` | FLOAT64 | Standard deviation of ratings for the genre |

---

### `vw_ratings_heatmap`

Rating volume by month and year. Used as the data source for the heatmap visualization in Metabase.

| Column | Type | Description |
|---|---|---|
| `year` | INT64 | Year extracted via `EXTRACT(YEAR ...)` |
| `month_number` | INT64 | Month number (1–12) for correct chronological ordering |
| `month_name` | STRING | Abbreviated month name, e.g. `Jan`, `Feb` (via `FORMAT_TIMESTAMP`) |
| `total_ratings` | INT64 | Number of ratings submitted in that month/year |

---

### `vw_scatter_popularity_vs_quality`

Data for the scatter plot comparing popularity (total ratings) vs quality (avg rating). Filtered to movies with at least 50 ratings to reduce noise.

| Column | Type | Description |
|---|---|---|
| `movie_id` | INT64 | Movie identifier |
| `title` | STRING | Movie title |
| `genres` | STRING | Pipe-separated genres |
| `release_year` | INT64 | Release year |
| `total_ratings` | INT64 | Total number of ratings (x-axis) |
| `avg_rating` | FLOAT64 | Average rating (y-axis) |

---

### `vw_belief_analysis`

Compares what users predicted they would rate a movie, what the system predicted, and what they actually rated after watching. Only includes records where `isSeen = 1` and the user submitted a real rating.

| Column | Type | Description |
|---|---|---|
| `user_id` | INT64 | Anonymous user identifier |
| `movie_id` | INT64 | Movie identifier — foreign key to `dim_movies` |
| `title` | STRING | Movie title |
| `genres` | STRING | Pipe-separated genres |
| `release_year` | INT64 | Release year |
| `actual_rating` | FLOAT64 | Real rating given by the user after watching (0.5–5.0) |
| `user_predicted_rating` | FLOAT64 | Rating the user predicted before watching (0.5–5.0) |
| `system_predicted_rating` | FLOAT64 | Rating predicted by the MovieLens system (0.5–5.0) |
| `user_certainty` | INT64 | User's confidence in their own prediction (1–5) |
| `user_prediction_error` | FLOAT64 | Absolute error: `ABS(user_predicted - actual)` |
| `system_prediction_error` | FLOAT64 | Absolute error: `ABS(system_predicted - actual)` |
| `more_accurate` | STRING | Who predicted closer to the real rating: `user`, `system`, `tie`, or `no_*_prediction` |
| `surprise_type` | STRING | `positive_surprise` (liked more than expected), `disappointment`, or `as_expected` |
| `recorded_at` | TIMESTAMP | When the belief record was captured |

---

### `vw_user_activity`

Behavioral profile aggregated per user.

| Column | Type | Description |
|---|---|---|
| `user_id` | INT64 | Anonymous user identifier |
| `total_ratings` | INT64 | Total number of ratings submitted |
| `distinct_movies_rated` | INT64 | Number of unique movies rated |
| `avg_rating` | FLOAT64 | User's average rating across all movies |
| `std_rating` | FLOAT64 | Standard deviation — indicates how varied the user's ratings are |
| `first_activity_ts` | TIMESTAMP | Timestamp of the user's first rating |
| `last_activity_ts` | TIMESTAMP | Timestamp of the user's most recent rating |
