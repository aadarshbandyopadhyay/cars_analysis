"""Database helpers for notebook exploration."""

from __future__ import annotations

import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import URL, create_engine, text
from sqlalchemy.engine import Connection, Engine


def create_mysql_engine_from_env(env_path: str = ".env") -> Engine:
    """Create a SQLAlchemy MySQL engine from environment variables."""
    load_dotenv(env_path)

    required_vars = [
        "MYSQL_HOST",
        "MYSQL_PORT",
        "MYSQL_DATABASE",
        "MYSQL_USER",
        "MYSQL_PASSWORD",
    ]
    missing_vars = [name for name in required_vars if not os.getenv(name)]

    if missing_vars:
        missing = ", ".join(missing_vars)
        raise ValueError(f"Missing required environment variable(s): {missing}")

    url = URL.create(
        drivername="mysql+pymysql",
        username=os.environ["MYSQL_USER"],
        password=os.environ["MYSQL_PASSWORD"],
        host=os.environ["MYSQL_HOST"],
        port=int(os.environ["MYSQL_PORT"]),
        database=os.environ["MYSQL_DATABASE"],
    )

    return create_engine(url)


def get_vehicle_listings(
    connection: Engine | Connection,
    min_price: int | None = None,
    max_price: int | None = None,
    min_year: int | None = None,
    max_year: int | None = None,
    manufacturer: str | None = None,
    model: str | None = None,
    state: str | None = None,
    fuel_type: str | None = None,
    transmission: str | None = None,
    limit: int = 1000,
) -> pd.DataFrame:
    """Return vehicle listings matching the provided criteria."""
    if limit < 1:
        raise ValueError("limit must be at least 1")

    params: dict[str, int | str] = {"limit": limit}
    where_clauses = []

    if min_price is not None:
        where_clauses.append("vl.price >= :min_price")
        params["min_price"] = min_price

    if max_price is not None:
        where_clauses.append("vl.price <= :max_price")
        params["max_price"] = max_price

    if min_year is not None:
        where_clauses.append("v.year >= :min_year")
        params["min_year"] = min_year

    if max_year is not None:
        where_clauses.append("v.year <= :max_year")
        params["max_year"] = max_year

    if manufacturer is not None:
        where_clauses.append("LOWER(m.manufacturer_name) = LOWER(:manufacturer)")
        params["manufacturer"] = manufacturer

    if model is not None:
        where_clauses.append("LOWER(vm.model_name) = LOWER(:model)")
        params["model"] = model

    if state is not None:
        where_clauses.append("LOWER(s.state_code) = LOWER(:state)")
        params["state"] = state

    if fuel_type is not None:
        where_clauses.append("LOWER(ft.fuel_type_name) = LOWER(:fuel_type)")
        params["fuel_type"] = fuel_type

    if transmission is not None:
        where_clauses.append("LOWER(tt.transmission_type_name) = LOWER(:transmission)")
        params["transmission"] = transmission

    where_sql = ""
    if where_clauses:
        where_sql = "WHERE " + " AND ".join(where_clauses)

    query = text(
        f"""
        SELECT
            vl.listing_id,
            vl.price,
            v.year,
            m.manufacturer_name AS manufacturer,
            vm.model_name AS model,
            vl.odometer,
            ft.fuel_type_name AS fuel_type,
            tt.transmission_type_name AS transmission,
            ts.title_status_name AS title_status,
            vc.condition_name AS vehicle_condition,
            dt.drive_type_name AS drive_type,
            vt.vehicle_type_name AS vehicle_type,
            pc.paint_color_name AS paint_color,
            s.state_code AS state,
            r.region_name AS region,
            vl.latitude,
            vl.longitude,
            vl.posting_date,
            vl.listing_url
        FROM vehicle_listings vl
        JOIN vehicles v ON v.vehicle_id = vl.vehicle_id
        JOIN regions r ON r.region_id = vl.region_id
        LEFT JOIN states s ON s.state_id = r.state_id
        LEFT JOIN manufacturers m ON m.manufacturer_id = v.manufacturer_id
        LEFT JOIN vehicle_models vm ON vm.model_id = v.model_id
        LEFT JOIN fuel_types ft ON ft.fuel_type_id = v.fuel_type_id
        LEFT JOIN transmission_types tt
            ON tt.transmission_type_id = v.transmission_type_id
        LEFT JOIN title_statuses ts ON ts.title_status_id = v.title_status_id
        LEFT JOIN vehicle_conditions vc ON vc.condition_id = v.condition_id
        LEFT JOIN drive_types dt ON dt.drive_type_id = v.drive_type_id
        LEFT JOIN vehicle_types vt ON vt.vehicle_type_id = v.vehicle_type_id
        LEFT JOIN paint_colors pc ON pc.paint_color_id = v.paint_color_id
        {where_sql}
        ORDER BY vl.posting_date DESC, vl.listing_id DESC
        LIMIT :limit
        """
    )

    return pd.read_sql_query(query, connection, params=params)
