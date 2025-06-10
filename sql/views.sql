 --- create a table with daily types of users trips and flagged prohibited duration of the trips over 24H
CREATE VIEW daily_user_counts AS
SELECT dates.date_key,
    dates.full_date,
    dates.month,
    dates.month_name,
    dates.day,
    dates.day_name,
    dates.weekend,
    count(trips.id) AS trips_totals,
    count(users.user_type) FILTER (WHERE users.user_type = 'Subscriber') AS subscriber_trips,
    count(users.user_type) FILTER (WHERE users.user_type = 'Customer') AS customer_trips,
    count(users.user_type) FILTER (WHERE users.user_type = 'Unknown') AS unknown_trips,
    count(trips.valid_duration) FILTER (WHERE NOT trips.valid_duration) AS late_return
FROM trips
    RIGHT JOIN dates ON trips.date_key = dates.date_key
    LEFT JOIN users ON trips.user_id = users.id
GROUP BY 1
ORDER BY 1;

 --- create a table with daily trips, monthly rising summaries of trips and weather
 CREATE VIEW daily_data AS
 SELECT daily_counts.date_key,
    daily_user_counts.full_date,
    daily_user_counts.month_name,
    daily_user_counts.day,
    daily_user_counts.day_name,
    daily_user_counts.trips_totals,
    sum(daily_user_counts.trips_totals) OVER (PARTITION BY daily_user_counts.month_name ORDER BY daily_user_counts.date_key) AS       month_running_total,
    daily_user_counts.subscriber_trips,
    daily_user_counts.customer_trips,
    daily_user_counts.unknown_trips,
    daily_user_counts.late_return,
    daily_user_counts.weekend,
    weather.temp_min,
    weather.temp_avg,
    weather.temp_max,
    weather.avg_wind,
    weather.prcp,
    weather.snow_amt,
    weather.rain,
    weather.snow
 FROM daily_user_counts
  	JOIN weather ON daily_user_counts.date_key = weather.date_key
 ORDER BY 1;


--- create the table with average number of users and average temperature and wind per month 
CREATE VIEW monthly_data AS
SELECT daily_user_counts.month,
    daily_user_counts.month_name,
    round(avg(trips_totals)::numeric, 2) AS avg_totals_trips,
    round(avg(subscriber_trips)::numeric, 2) AS avg_subscriber_trips,
    round(avg(customer_trips)::numeric, 2) AS avg_customer_trips,
    round(avg(unknown_trips)::numeric, 2) AS avg_unknown_trips,
    round(avg(late_return)::numeric, 2) AS avg_late_return,
    round(avg(weather.temp_avg)::numeric, 2) AS avg_temp,
    round(avg(weather.avg_wind)::numeric, 2) AS avg_wind,
    count(weather.rain) FILTER (WHERE weather.rain = 'True') AS rainy_days,
    count(weather.snow) FILTER (WHERE weather.snow = 'True') AS snowy_days
FROM daily_user_counts
  	JOIN weather ON daily_user_counts.date_key = weather.date_key
GROUP BY 1, 2
ORDER BY 1, 2;


--- create the table showing statistics of the Subscribers (Customers have missing age and unknown gender) 
CREATE VIEW subscribers_demographics_and_gender AS
SELECT users.age,
users.gender,
COUNT(*) AS "total_trips"
FROM trips
  LEFT JOIN users ON trips.user_id = users.id
WHERE users.user_type = 'Subscriber' AND users.gender = 'Male' OR users.gender = 'Female'
GROUP BY users.age, users.gender
ORDER BY 3 DESC;
    
--- create the table showing popularity of the stations considering start and end points and differences between number of them which can be helpful for the analzing transporation needs 
CREATE VIEW station_popularity AS
SELECT 
  dates.month,
  dates.month_name,
  stations.id AS station_id,
  stations.station_name,
  SUM(started) AS trips_started,
  SUM(ended) AS trips_ended,
  (SUM(started) + SUM(ended)) AS total_trips,
  ABS(SUM(started) - SUM(ended)) AS start_end_diff_abs
FROM (

  -- Starts
  SELECT 
    date_key,
    start_station_id AS station_id,
    1 AS started,
    0 AS ended
  FROM trips

  UNION ALL

  -- Ends
  SELECT 
    date_key,
    end_station_id AS station_id,
    0 AS started,
    1 AS ended
  FROM trips

) AS combined

JOIN stations ON stations.id = combined.station_id
JOIN dates ON dates.date_key = combined.date_key

GROUP BY 
  dates.month, 
  dates.month_name, 
  stations.id, 
  stations.station_name

ORDER BY 
  dates.month,
  total_trips DESC ;

-- create the table showing most used bikes monthly for the potential service needs
CREATE VIEW bikes_usage AS
SELECT dates.month,
	dates.month_name,
  t.bike_id,
  SUM(t.distance) AS min_covered_distance,
  COUNT(*) FILTER (WHERE t.distance_0 = True) AS same_station_trips,
  SUM(t.trip_duration_hours) AS month_trip_duration_hours,
  SUM(t.trip_duration_days) AS month_trip_duration_days,
  COUNT(*) FILTER (WHERE t.valid_duration = False) AS Rent_time_violations_num
FROM trips t 
LEFT JOIN dates ON dates.date_key = t.date_key
GROUP BY dates.month, dates.month_name, t.bike_id
ORDER BY dates.month, dates.month_name, min_covered_distance DESC;

