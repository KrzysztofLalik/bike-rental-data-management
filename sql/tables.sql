CREATE TABLE dates(
        date_key integer PRIMARY KEY,
        full_date date,
	month integer,
	day integer,
	month_name varchar(20),
	day_name varchar(20),
        weekend boolean,
	financial_qtr integer
);

CREATE TABLE stations(
	id integer PRIMARY KEY,
	station_name varchar(50),
	latitude real,
	longitude real
);
  
CREATE TABLE users(
	id integer PRIMARY KEY,
	user_type varchar(50),
	gender integer,
	birth_year integer,
	age integer
);

CREATE TABLE weather (
	date_key integer PRIMARY KEY REFERENCES dates(date_key),
        date date,
	avg_wind real,
	prcp real,
	snow_amt real,
	snow_depth real,
	tavg integer,
	tmax integer,
	tmin integer,
	rain boolean,
	snow boolean
);

CREATE TABLE trips(
     id integer,
     trip_duration_sec integer,
     trip_duration_min real,
     trip_duration_hours real,
     trip_duration_days real,
     valid_duration boolean,
     start_time timestamp,
     end_station timestamp,
     start_station_id integer,
     stop_station_id integer,
     distance real,
     distance_0 boolean,
     bike_id integer,
     date_key integer,
     user_id integer,
     FOREIGN KEY(date_key) REFERENCES dates(date_key),
     FOREIGN KEY(user_id) REFERENCES users(id),
     FOREIGN KEY(start_station_id) REFERENCES stations(id),
     FOREIGN KEY(stop_station_id) REFERENCES stations(id)
);

