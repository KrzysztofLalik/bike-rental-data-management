# bike-rental-data-management Writeup

## Project Overview

This project focuses on designing a scalable and well-structured relational database to organize and analyze data from Citi Bike and NOAA. The main tasks included:
- inspecting and cleaning both datasets
- designing a normalized database schema
- building the database in PostgreSQL and populating it with cleaned data
- creating reusable, analytics-friendly SQL views for streamlined data access


# Inspecting and cleaning both datasets

Input Datasets:
- Citi Bike Jersey City (2016): 12x Monthly trip records
- NOAA Weather (Newark Airport, 2016): 1x Daily weather measurements 

# Data Cleaning and Preprocessing Report

## Overview

While inspecting both datasets, a number of issues were detected and the necessary actions were taken.  
In addition to these, column names were adjusted to follow consistent naming conventions, data types were corrected, and more intuitive columns were created based on the existing ones.

---

## Missing Data

- Missing values were detected in the `user_type` column (0.15%) and `birth_year` column (7.6%), along with a high number of unknown values in the `gender` column (8%).
- Further inspection revealed that the missing data is **not completely random**.
- All records missing `birth_year` also lack data in the `gender` column. These missing values are found exclusively among records with the `user_type` of **Customer**. Because of this pattern, the records were **not removed**—deleting them would have left only **Subscriber** data.
- Missing values in the `user_type` column are **not uniformly distributed over time**. This has been visualized to support further analysis by data analysts.
- In the **weather dataset**, columns without any data as well as those related to fastest wind speeds (`WDF2`, `WDF5` – direction; `WSF2`, `WSF5` – speed) were **removed** due to the complete lack of recorded data and limited future usefulness.

---

## Defective and Potentially Defective Data

- One record was removed due to an **unrealistic age (116 years)**.
- There are numerous **unnaturally long trips**, some lasting several days and one extreme case reaching **189 days**—this contradicts the citybike policy (maximum trip time: 24 hours). These records were **not removed**; instead, a new column `valid_duration` was created to **flag trips exceeding 24 hours** for further analysis.

---

## Created Columns for Analysis

- Columns were added to represent **trip durations** in **trip_durations_min**, **trip_durations_hours**, and **trip_durations_days**.
- The **distance** was calculated based on the coordinates of the start and end stations and the column **distance_0** was created to flag the records with same start and end station for the bike (flagged as True value)
- An **age** column was added, offering a more intuitive metric for analysis than `birth_year`.

# Designing a normalized database schema

To ensure efficient and well-organized data storage, the **Citibike database** was divided into several tables:  
- `trips`  
- `users` (user profiles)  
- `stations` (bike station data)

The **weather database** did not require additional splits. However, due to the general nature of the weather data, a central `dates` table was created to facilitate consistency across time-based analyses.

To link the tables:
- A `key_date` column was added to the `dates`, `trips`, and `weather` tables.  
- A `user_id` column was used to connect the `users` and `trips` tables.  
- The `stations` table uses `station_id` as its key.

This structure is illustrated in the attached file: **ERD.pdf**.

#building the database in PostgreSQL and populating it with cleaned data

In the final part of the `Bike-rental-data-management.ipynb` notebook, the data is prepared for export in the form of clean, structured tables matching the schema created in PostgreSQL.  
Additionally, SQLAlchemy was used to connect to the previously created database, utilizing the schema defined in the `tables.sql` file.

# Creating reusable, analytics-friendly SQL views for streamlined data access

### `daily_user_counts`

This view organizes trips by user type over time. It also includes:
- Flagged cases of trips exceeding the maximum allowed rental duration (24 hours)
- Records with missing `user_type`, marked here as `"Unknown"` for further investigation by analysts

It includes:
- Date breakdowns (e.g. month and day of the week)
- Total number of trips
- Trip breakdowns by `Subscriber`, `Customer`, `Unknown`, and `Late return`

---

### `daily_data`

This view combines trip data by user type with corresponding daily weather data.  
It also calculates monthly running totals using window functions.

It includes:
- Date breakdowns (e.g. month and day of the week)
- Running monthly totals (using window functions)
- Weather data (temperature, wind, precipitation, snow)

---

### `monthly_data`

This view summarizes the `daily_data` by month and is designed to help quickly identify trends throughout the year.

It includes:
- Monthly breakdown of average trips by user type (`Subscriber`, `Customer`, `Unknown`) and flagged long-duration trips
- Average temperature and wind
- Counts of rainy and snowy days

---

### `subscribers_demographics_and_gender`

This view focuses on identifying the typical profile of `Subscribers` by age and gender.  
(`Customer` type was excluded due to frequent lack of age and gender data.)

It includes:
- Number of trips grouped by age and gender

---

### `station_popularity`

This view shows station usage trends across each month. It presents:
- Number of trip **starts** and **ends** at each station
- Total trips and the absolute difference between starts and ends (which may indicate transport rebalancing needs)

It includes:
- Month
- Station name
- Number of trip starts and ends
- Total trips
- Start-end difference

---

### `bikes_usage`

This view helps identify bikes that may require service.

It includes:
- Grouped bike usage stats by month
- Total estimated distance covered (based on station coordinates)
- Number of trips returned to the same station
- Total rental time (in hours and days)
- Number of violations of rental time limits


