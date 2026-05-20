# Cars Analysis

This project explores the Craigslist cars and trucks dataset from Kaggle. It now includes a data-cleaning workflow, a normalized MySQL database design, SQL load scripts for small and larger CSV files, an ER diagram, and notebook helpers for querying the database into Pandas.

## Dataset

The source dataset comes from Kaggle:

```python
import kagglehub

path = kagglehub.dataset_download("austinreese/craigslist-carstrucks-data")
print("Path to dataset files:", path)
```

The full raw CSV is intentionally ignored by Git because it is too large for GitHub. The repository keeps `data/vehicles_small.csv` as a small sample dataset.

Ignored local data files include:

```text
data/vehicles.csv
data/vehicles_clean.csv
data/*_clean.csv
```

## Python Setup

This project uses Python 3.12+ and `uv`.

Install or sync dependencies:

```bash
uv sync
```

Main dependencies include:

- `pandas` for CSV cleaning and dataframe analysis
- `jupyter` for notebooks
- `sqlalchemy` and `pymysql` for MySQL access
- `python-dotenv` for reading local database credentials from `.env`
- `kagglehub` for downloading the dataset

## Cleaning CSV Data

[clean_vehicles.py](clean_vehicles.py) removes rows with null values in important analysis fields.

Example:

```bash
python3 clean_vehicles.py data/vehicles_small.csv data/vehicles_small_clean.csv
```

For the full dataset:

```bash
python3 clean_vehicles.py data/vehicles.csv data/vehicles_clean.csv
```

The default important fields are:

```text
price, year, manufacturer, model, odometer, fuel, title_status,
transmission, state, lat, long, posting_date
```

## MySQL Database

The database is normalized into lookup tables and fact tables.

Core tables:

- `states`
- `regions`
- `manufacturers`
- `vehicle_models`
- `vehicle_conditions`
- `cylinder_types`
- `fuel_types`
- `title_statuses`
- `transmission_types`
- `drive_types`
- `vehicle_sizes`
- `vehicle_types`
- `paint_colors`
- `vehicles`
- `vehicle_listings`
- `raw_vehicle_listings`

SQL files:

- [sql/create_vehicle_schema.sql](sql/create_vehicle_schema.sql) creates the database and tables.
- [sql/load_vehicles_from_csv.sql](sql/load_vehicles_from_csv.sql) loads CSV data through the staging table and inserts into normalized tables in batches.
- [sql/check_load_status.sql](sql/check_load_status.sql) checks row counts, timeout settings, and relationship integrity.
- [sql/vehicle_er_diagram.svg](sql/vehicle_er_diagram.svg) shows the ER diagram.

Database design diagram:

[View the normalized vehicle database ER diagram](sql/vehicle_er_diagram.svg)

To run in MySQL Workbench, open each SQL file with `File > Open SQL Script...` and execute it. If loading from Workbench, use an absolute path in the `LOAD DATA LOCAL INFILE` statement.

Example path:

```sql
LOAD DATA LOCAL INFILE '/Users/aadarshbandyopadhyay/Documents/Python_Projects/cars_analysis/data/vehicles_clean_medium.csv'
```

For larger files, the load script uses batched stored procedures:

```sql
CALL load_vehicles_in_batches(1000);
CALL load_vehicle_listings_in_batches(1000);
```

If Workbench disconnects after about 30 seconds but row counts are complete, it is likely a client timeout rather than a failed load. Use `sql/check_load_status.sql` to verify:

```text
raw_vehicle_listings row count
vehicles row count
vehicle_listings row count
listings_without_vehicle
listings_without_region
staged_rows_not_loaded_to_listings
```

The last three checks should be `0`.

## Notebook Database Access

Copy [.env.example](.env.example) to `.env` and fill in your MySQL credentials:

```env
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=cars_analysis
MYSQL_USER=root
MYSQL_PASSWORD=your_password
```

The real `.env` file is ignored by Git.

[db.py](db.py) provides helpers for notebook exploration:

```python
from db import create_mysql_engine_from_env, get_vehicle_listings

engine = create_mysql_engine_from_env()

df = get_vehicle_listings(
    engine,
    min_price=10000,
    max_price=30000,
    min_year=2015,
    manufacturer="toyota",
    state="ca",
    limit=100,
)

df.head()
```

The query helper returns a Pandas dataframe with listing price, year, manufacturer, model, odometer, fuel type, transmission, title status, condition, vehicle type, paint color, location, posting date, and listing URL.

## Notebooks

- `Initial.ipynb` contains early dataset exploration.
- `db_analysis.ipynb` is intended for database-backed analysis using `db.py`.

## Project Status

Completed so far:

- Initialized the Git project and ignored large local data files.
- Added a reusable CSV cleaning module.
- Generated cleaned sample/full CSV outputs locally.
- Designed a normalized MySQL schema.
- Added SQL scripts for schema creation, CSV loading, and load validation.
- Added a lightweight SVG ER diagram.
- Added `.env`-based MySQL connection helpers.
- Added a reusable Pandas query function for filtered vehicle listing exploration.

## TODO

- Add richer notebook analysis for price, mileage, year, manufacturer, and region trends.
- Add indexes or query tuning based on common analysis patterns.
- Add a small Python CLI for loading/querying the database outside Workbench.
- Build a web component or lightweight dashboard for searching listings and visualizing filters.
- Add tests for `clean_vehicles.py` and `db.py`.
- Document common MySQL Workbench timeout fixes and load troubleshooting.
