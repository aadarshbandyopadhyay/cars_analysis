-- MySQL schema for normalized Craigslist vehicle listing data.
-- Designed for data/vehicles_small.csv and the full vehicles.csv file.

CREATE DATABASE IF NOT EXISTS cars_analysis
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE cars_analysis;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS vehicle_listings;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS vehicle_models;
DROP TABLE IF EXISTS manufacturers;
DROP TABLE IF EXISTS regions;
DROP TABLE IF EXISTS states;
DROP TABLE IF EXISTS vehicle_conditions;
DROP TABLE IF EXISTS cylinder_types;
DROP TABLE IF EXISTS fuel_types;
DROP TABLE IF EXISTS title_statuses;
DROP TABLE IF EXISTS transmission_types;
DROP TABLE IF EXISTS drive_types;
DROP TABLE IF EXISTS vehicle_sizes;
DROP TABLE IF EXISTS vehicle_types;
DROP TABLE IF EXISTS paint_colors;
DROP TABLE IF EXISTS raw_vehicle_listings;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE states (
    state_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    state_code CHAR(2) NOT NULL,
    UNIQUE KEY uq_states_state_code (state_code)
) ENGINE = InnoDB;

CREATE TABLE regions (
    region_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    state_id SMALLINT UNSIGNED NULL,
    region_name VARCHAR(120) NOT NULL,
    region_url VARCHAR(255) NOT NULL,
    UNIQUE KEY uq_regions_region_url (region_url),
    KEY idx_regions_state_id (state_id),
    CONSTRAINT fk_regions_state
        FOREIGN KEY (state_id) REFERENCES states (state_id)
) ENGINE = InnoDB;

CREATE TABLE manufacturers (
    manufacturer_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    manufacturer_name VARCHAR(80) NOT NULL,
    UNIQUE KEY uq_manufacturers_name (manufacturer_name)
) ENGINE = InnoDB;

CREATE TABLE vehicle_models (
    model_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    manufacturer_id SMALLINT UNSIGNED NULL,
    model_name VARCHAR(255) NOT NULL,
    UNIQUE KEY uq_vehicle_models_manufacturer_model (manufacturer_id, model_name),
    KEY idx_vehicle_models_manufacturer_id (manufacturer_id),
    CONSTRAINT fk_vehicle_models_manufacturer
        FOREIGN KEY (manufacturer_id) REFERENCES manufacturers (manufacturer_id)
) ENGINE = InnoDB;

CREATE TABLE vehicle_conditions (
    condition_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    condition_name VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_vehicle_conditions_name (condition_name)
) ENGINE = InnoDB;

CREATE TABLE cylinder_types (
    cylinder_type_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cylinder_description VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_cylinder_types_description (cylinder_description)
) ENGINE = InnoDB;

CREATE TABLE fuel_types (
    fuel_type_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    fuel_type_name VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_fuel_types_name (fuel_type_name)
) ENGINE = InnoDB;

CREATE TABLE title_statuses (
    title_status_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title_status_name VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_title_statuses_name (title_status_name)
) ENGINE = InnoDB;

CREATE TABLE transmission_types (
    transmission_type_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transmission_type_name VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_transmission_types_name (transmission_type_name)
) ENGINE = InnoDB;

CREATE TABLE drive_types (
    drive_type_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    drive_type_name VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_drive_types_name (drive_type_name)
) ENGINE = InnoDB;

CREATE TABLE vehicle_sizes (
    vehicle_size_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_size_name VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_vehicle_sizes_name (vehicle_size_name)
) ENGINE = InnoDB;

CREATE TABLE vehicle_types (
    vehicle_type_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    vehicle_type_name VARCHAR(60) NOT NULL,
    UNIQUE KEY uq_vehicle_types_name (vehicle_type_name)
) ENGINE = InnoDB;

CREATE TABLE paint_colors (
    paint_color_id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    paint_color_name VARCHAR(40) NOT NULL,
    UNIQUE KEY uq_paint_colors_name (paint_color_name)
) ENGINE = InnoDB;

CREATE TABLE vehicles (
    vehicle_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source_listing_id BIGINT UNSIGNED NULL,
    vin VARCHAR(17) NULL,
    year SMALLINT UNSIGNED NULL,
    manufacturer_id SMALLINT UNSIGNED NULL,
    model_id INT UNSIGNED NULL,
    condition_id TINYINT UNSIGNED NULL,
    cylinder_type_id TINYINT UNSIGNED NULL,
    fuel_type_id TINYINT UNSIGNED NULL,
    title_status_id TINYINT UNSIGNED NULL,
    transmission_type_id TINYINT UNSIGNED NULL,
    drive_type_id TINYINT UNSIGNED NULL,
    vehicle_size_id TINYINT UNSIGNED NULL,
    vehicle_type_id TINYINT UNSIGNED NULL,
    paint_color_id TINYINT UNSIGNED NULL,
    UNIQUE KEY uq_vehicles_source_listing_id (source_listing_id),
    KEY idx_vehicles_vin (vin),
    KEY idx_vehicles_year (year),
    KEY idx_vehicles_manufacturer_id (manufacturer_id),
    KEY idx_vehicles_model_id (model_id),
    CONSTRAINT fk_vehicles_manufacturer
        FOREIGN KEY (manufacturer_id) REFERENCES manufacturers (manufacturer_id),
    CONSTRAINT fk_vehicles_model
        FOREIGN KEY (model_id) REFERENCES vehicle_models (model_id),
    CONSTRAINT fk_vehicles_condition
        FOREIGN KEY (condition_id) REFERENCES vehicle_conditions (condition_id),
    CONSTRAINT fk_vehicles_cylinder_type
        FOREIGN KEY (cylinder_type_id) REFERENCES cylinder_types (cylinder_type_id),
    CONSTRAINT fk_vehicles_fuel_type
        FOREIGN KEY (fuel_type_id) REFERENCES fuel_types (fuel_type_id),
    CONSTRAINT fk_vehicles_title_status
        FOREIGN KEY (title_status_id) REFERENCES title_statuses (title_status_id),
    CONSTRAINT fk_vehicles_transmission_type
        FOREIGN KEY (transmission_type_id) REFERENCES transmission_types (transmission_type_id),
    CONSTRAINT fk_vehicles_drive_type
        FOREIGN KEY (drive_type_id) REFERENCES drive_types (drive_type_id),
    CONSTRAINT fk_vehicles_vehicle_size
        FOREIGN KEY (vehicle_size_id) REFERENCES vehicle_sizes (vehicle_size_id),
    CONSTRAINT fk_vehicles_vehicle_type
        FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_types (vehicle_type_id),
    CONSTRAINT fk_vehicles_paint_color
        FOREIGN KEY (paint_color_id) REFERENCES paint_colors (paint_color_id)
) ENGINE = InnoDB;

CREATE TABLE vehicle_listings (
    listing_id BIGINT UNSIGNED PRIMARY KEY,
    vehicle_id BIGINT UNSIGNED NOT NULL,
    region_id INT UNSIGNED NOT NULL,
    listing_url VARCHAR(500) NOT NULL,
    price INT UNSIGNED NOT NULL,
    odometer INT UNSIGNED NULL,
    image_url VARCHAR(500) NULL,
    description MEDIUMTEXT NULL,
    county VARCHAR(120) NULL,
    latitude DECIMAL(9, 6) NULL,
    longitude DECIMAL(9, 6) NULL,
    posting_date DATETIME NULL,
    posting_timezone_offset CHAR(5) NULL,
    UNIQUE KEY uq_vehicle_listings_listing_url (listing_url),
    KEY idx_vehicle_listings_vehicle_id (vehicle_id),
    KEY idx_vehicle_listings_region_id (region_id),
    KEY idx_vehicle_listings_price (price),
    KEY idx_vehicle_listings_posting_date (posting_date),
    CONSTRAINT fk_vehicle_listings_vehicle
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (vehicle_id),
    CONSTRAINT fk_vehicle_listings_region
        FOREIGN KEY (region_id) REFERENCES regions (region_id)
) ENGINE = InnoDB;

-- Staging table with one column per CSV field. Load the CSV here first, then
-- insert distinct values into the normalized tables.
CREATE TABLE raw_vehicle_listings (
    id VARCHAR(32) NULL,
    url VARCHAR(500) NULL,
    region VARCHAR(120) NULL,
    region_url VARCHAR(255) NULL,
    price VARCHAR(32) NULL,
    year VARCHAR(32) NULL,
    manufacturer VARCHAR(80) NULL,
    model VARCHAR(255) NULL,
    vehicle_condition VARCHAR(40) NULL,
    cylinders VARCHAR(40) NULL,
    fuel VARCHAR(40) NULL,
    odometer VARCHAR(32) NULL,
    title_status VARCHAR(40) NULL,
    transmission VARCHAR(40) NULL,
    vin VARCHAR(17) NULL,
    drive VARCHAR(40) NULL,
    vehicle_size VARCHAR(40) NULL,
    vehicle_type VARCHAR(60) NULL,
    paint_color VARCHAR(40) NULL,
    image_url VARCHAR(500) NULL,
    description MEDIUMTEXT NULL,
    county VARCHAR(120) NULL,
    state CHAR(2) NULL,
    lat VARCHAR(32) NULL,
    lng VARCHAR(32) NULL,
    posting_date_raw VARCHAR(32) NULL,
    KEY idx_raw_vehicle_listings_id (id),
    KEY idx_raw_vehicle_listings_vin (vin),
    KEY idx_raw_vehicle_listings_region_url (region_url)
) ENGINE = InnoDB;
