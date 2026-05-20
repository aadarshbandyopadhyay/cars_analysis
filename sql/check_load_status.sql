-- Quick checks to run in MySQL Workbench when a large CSV load disconnects.

USE cars_analysis;

SELECT
    'raw_vehicle_listings' AS table_name,
    COUNT(*) AS row_count
FROM raw_vehicle_listings
UNION ALL
SELECT 'vehicles', COUNT(*) FROM vehicles
UNION ALL
SELECT 'vehicle_listings', COUNT(*) FROM vehicle_listings;

SELECT
    MIN(raw_listing_id) AS first_raw_listing_id,
    MAX(raw_listing_id) AS last_raw_listing_id,
    COUNT(*) AS staged_rows
FROM raw_vehicle_listings;

SHOW VARIABLES WHERE Variable_name IN (
    'local_infile',
    'max_allowed_packet',
    'net_read_timeout',
    'net_write_timeout',
    'wait_timeout',
    'interactive_timeout'
);

SHOW GLOBAL STATUS WHERE Variable_name IN (
    'Aborted_clients',
    'Aborted_connects',
    'Bytes_received',
    'Bytes_sent',
    'Threads_connected'
);

SELECT
    COUNT(*) AS listings_without_vehicle
FROM vehicle_listings vl
LEFT JOIN vehicles v ON v.vehicle_id = vl.vehicle_id
WHERE v.vehicle_id IS NULL;

SELECT
    COUNT(*) AS listings_without_region
FROM vehicle_listings vl
LEFT JOIN regions r ON r.region_id = vl.region_id
WHERE r.region_id IS NULL;

SELECT
    COUNT(*) AS staged_rows_not_loaded_to_listings
FROM raw_vehicle_listings r
LEFT JOIN vehicle_listings vl
    ON vl.listing_id = CAST(NULLIF(r.id, '') AS UNSIGNED)
WHERE NULLIF(r.id, '') IS NOT NULL
  AND NULLIF(r.price, '') IS NOT NULL
  AND r.url IS NOT NULL
  AND vl.listing_id IS NULL;
