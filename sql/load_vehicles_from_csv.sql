-- Load data/vehicles_small.csv into the normalized schema.
-- Run sql/create_vehicle_schema.sql before this script.
--
-- Example:
-- mysql --local-infile=1 -u root -p < sql/create_vehicle_schema.sql
-- mysql --local-infile=1 -u root -p cars_analysis < sql/load_vehicles_from_csv.sql

USE cars_analysis;

TRUNCATE TABLE raw_vehicle_listings;

-- Replace this path with an absolute path if you run mysql outside the project root.
LOAD DATA LOCAL INFILE 'data/vehicles_small_clean.csv'
INTO TABLE raw_vehicle_listings
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
    id,
    url,
    region,
    region_url,
    price,
    year,
    manufacturer,
    model,
    vehicle_condition,
    cylinders,
    fuel,
    odometer,
    title_status,
    transmission,
    vin,
    drive,
    vehicle_size,
    vehicle_type,
    paint_color,
    image_url,
    description,
    county,
    state,
    lat,
    lng,
    posting_date_raw
);

INSERT IGNORE INTO states (state_code)
SELECT DISTINCT LOWER(state)
FROM raw_vehicle_listings
WHERE state IS NOT NULL AND state <> '';

INSERT IGNORE INTO regions (state_id, region_name, region_url)
SELECT DISTINCT s.state_id, r.region, r.region_url
FROM raw_vehicle_listings r
LEFT JOIN states s ON s.state_code = LOWER(r.state)
WHERE r.region IS NOT NULL
  AND r.region <> ''
  AND r.region_url IS NOT NULL
  AND r.region_url <> '';

INSERT IGNORE INTO manufacturers (manufacturer_name)
SELECT DISTINCT manufacturer
FROM raw_vehicle_listings
WHERE manufacturer IS NOT NULL AND manufacturer <> '';

INSERT IGNORE INTO vehicle_models (manufacturer_id, model_name)
SELECT DISTINCT m.manufacturer_id, r.model
FROM raw_vehicle_listings r
LEFT JOIN manufacturers m ON m.manufacturer_name = r.manufacturer
WHERE r.model IS NOT NULL AND r.model <> '';

INSERT IGNORE INTO vehicle_conditions (condition_name)
SELECT DISTINCT vehicle_condition
FROM raw_vehicle_listings
WHERE vehicle_condition IS NOT NULL AND vehicle_condition <> '';

INSERT IGNORE INTO cylinder_types (cylinder_description)
SELECT DISTINCT cylinders
FROM raw_vehicle_listings
WHERE cylinders IS NOT NULL AND cylinders <> '';

INSERT IGNORE INTO fuel_types (fuel_type_name)
SELECT DISTINCT fuel
FROM raw_vehicle_listings
WHERE fuel IS NOT NULL AND fuel <> '';

INSERT IGNORE INTO title_statuses (title_status_name)
SELECT DISTINCT title_status
FROM raw_vehicle_listings
WHERE title_status IS NOT NULL AND title_status <> '';

INSERT IGNORE INTO transmission_types (transmission_type_name)
SELECT DISTINCT transmission
FROM raw_vehicle_listings
WHERE transmission IS NOT NULL AND transmission <> '';

INSERT IGNORE INTO drive_types (drive_type_name)
SELECT DISTINCT drive
FROM raw_vehicle_listings
WHERE drive IS NOT NULL AND drive <> '';

INSERT IGNORE INTO vehicle_sizes (vehicle_size_name)
SELECT DISTINCT vehicle_size
FROM raw_vehicle_listings
WHERE vehicle_size IS NOT NULL AND vehicle_size <> '';

INSERT IGNORE INTO vehicle_types (vehicle_type_name)
SELECT DISTINCT vehicle_type
FROM raw_vehicle_listings
WHERE vehicle_type IS NOT NULL AND vehicle_type <> '';

INSERT IGNORE INTO paint_colors (paint_color_name)
SELECT DISTINCT paint_color
FROM raw_vehicle_listings
WHERE paint_color IS NOT NULL AND paint_color <> '';

DROP PROCEDURE IF EXISTS load_vehicles_in_batches;
DROP PROCEDURE IF EXISTS load_vehicle_listings_in_batches;

DELIMITER //

CREATE PROCEDURE load_vehicles_in_batches(IN batch_size INT UNSIGNED)
BEGIN
    DECLARE current_start BIGINT UNSIGNED DEFAULT 1;
    DECLARE max_raw_id BIGINT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(raw_listing_id), 0) INTO max_raw_id
    FROM raw_vehicle_listings;

    WHILE current_start <= max_raw_id DO
        INSERT IGNORE INTO vehicles (
            source_listing_id,
            vin,
            year,
            manufacturer_id,
            model_id,
            condition_id,
            cylinder_type_id,
            fuel_type_id,
            title_status_id,
            transmission_type_id,
            drive_type_id,
            vehicle_size_id,
            vehicle_type_id,
            paint_color_id
        )
        SELECT
            CAST(NULLIF(r.id, '') AS UNSIGNED),
            NULLIF(r.vin, ''),
            CAST(CAST(NULLIF(r.year, '') AS DECIMAL(6, 1)) AS UNSIGNED),
            m.manufacturer_id,
            vm.model_id,
            vc.condition_id,
            ct.cylinder_type_id,
            ft.fuel_type_id,
            ts.title_status_id,
            tt.transmission_type_id,
            dt.drive_type_id,
            vs.vehicle_size_id,
            vt.vehicle_type_id,
            pc.paint_color_id
        FROM raw_vehicle_listings r
        LEFT JOIN manufacturers m ON m.manufacturer_name = r.manufacturer
        LEFT JOIN vehicle_models vm
            ON vm.model_name = r.model
            AND (vm.manufacturer_id = m.manufacturer_id OR vm.manufacturer_id IS NULL)
        LEFT JOIN vehicle_conditions vc ON vc.condition_name = r.vehicle_condition
        LEFT JOIN cylinder_types ct ON ct.cylinder_description = r.cylinders
        LEFT JOIN fuel_types ft ON ft.fuel_type_name = r.fuel
        LEFT JOIN title_statuses ts ON ts.title_status_name = r.title_status
        LEFT JOIN transmission_types tt ON tt.transmission_type_name = r.transmission
        LEFT JOIN drive_types dt ON dt.drive_type_name = r.drive
        LEFT JOIN vehicle_sizes vs ON vs.vehicle_size_name = r.vehicle_size
        LEFT JOIN vehicle_types vt ON vt.vehicle_type_name = r.vehicle_type
        LEFT JOIN paint_colors pc ON pc.paint_color_name = r.paint_color
        WHERE r.raw_listing_id >= current_start
          AND r.raw_listing_id < current_start + batch_size
          AND NULLIF(r.id, '') IS NOT NULL;

        SET current_start = current_start + batch_size;
    END WHILE;
END//

CREATE PROCEDURE load_vehicle_listings_in_batches(IN batch_size INT UNSIGNED)
BEGIN
    DECLARE current_start BIGINT UNSIGNED DEFAULT 1;
    DECLARE max_raw_id BIGINT UNSIGNED DEFAULT 0;

    SELECT COALESCE(MAX(raw_listing_id), 0) INTO max_raw_id
    FROM raw_vehicle_listings;

    WHILE current_start <= max_raw_id DO
        INSERT IGNORE INTO vehicle_listings (
            listing_id,
            vehicle_id,
            region_id,
            listing_url,
            price,
            odometer,
            image_url,
            description,
            county,
            latitude,
            longitude,
            posting_date,
            posting_timezone_offset
        )
        SELECT
            CAST(NULLIF(r.id, '') AS UNSIGNED),
            v.vehicle_id,
            rg.region_id,
            r.url,
            CAST(NULLIF(r.price, '') AS UNSIGNED),
            CAST(CAST(NULLIF(r.odometer, '') AS DECIMAL(10, 1)) AS UNSIGNED),
            NULLIF(r.image_url, ''),
            NULLIF(r.description, ''),
            NULLIF(r.county, ''),
            CAST(NULLIF(r.lat, '') AS DECIMAL(9, 6)),
            CAST(NULLIF(r.lng, '') AS DECIMAL(9, 6)),
            STR_TO_DATE(SUBSTRING(r.posting_date_raw, 1, 19), '%Y-%m-%dT%H:%i:%s'),
            CASE
                WHEN r.posting_date_raw REGEXP '[+-][0-9]{4}$'
                THEN CONCAT(
                    SUBSTRING(r.posting_date_raw, -5, 3),
                    ':',
                    SUBSTRING(r.posting_date_raw, -2)
                )
                ELSE NULL
            END
        FROM raw_vehicle_listings r
        JOIN vehicles v ON v.source_listing_id = CAST(NULLIF(r.id, '') AS UNSIGNED)
        JOIN regions rg ON rg.region_url = r.region_url
        WHERE r.raw_listing_id >= current_start
          AND r.raw_listing_id < current_start + batch_size
          AND NULLIF(r.id, '') IS NOT NULL
          AND r.url IS NOT NULL
          AND NULLIF(r.price, '') IS NOT NULL;

        SET current_start = current_start + batch_size;
    END WHILE;
END//

DELIMITER ;

CALL load_vehicles_in_batches(1000);
CALL load_vehicle_listings_in_batches(1000);

DROP PROCEDURE IF EXISTS load_vehicles_in_batches;
DROP PROCEDURE IF EXISTS load_vehicle_listings_in_batches;
