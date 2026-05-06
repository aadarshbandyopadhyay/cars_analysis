"""Utilities for cleaning vehicle listing data with pandas."""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

import pandas as pd
import argparse


IMPORTANT_FIELDS = [
    "price",
    "year",
    "manufacturer",
    "model",
    "odometer",
    "fuel",
    "title_status",
    "transmission",
    "state",
    "lat",
    "long",
    "posting_date",
]


def remove_null_important_fields(
    vehicles: pd.DataFrame,
    important_fields: Iterable[str] = IMPORTANT_FIELDS,
) -> pd.DataFrame:
    """Return rows where every important field has a non-null value."""
    fields = list(important_fields)
    missing_columns = [field for field in fields if field not in vehicles.columns]

    if missing_columns:
        missing = ", ".join(missing_columns)
        raise ValueError(f"Missing required column(s): {missing}")

    return vehicles.dropna(subset=fields).copy()


def clean_vehicle_csv(
    input_path: str | Path,
    output_path: str | Path | None = None,
    important_fields: Iterable[str] = IMPORTANT_FIELDS,
) -> pd.DataFrame:
    """Load vehicle listings, remove nulls in important fields, and optionally save."""
    vehicles = pd.read_csv(input_path)
    cleaned = remove_null_important_fields(vehicles, important_fields)

    if output_path is not None:
        cleaned.to_csv(output_path, index=False)

    return cleaned


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Remove rows with null values in important vehicle fields."
    )
    parser.add_argument("input_path", help="Path to the input vehicle CSV file.")
    parser.add_argument("output_path", help="Path to save the cleaned CSV file.")
    args = parser.parse_args()

    cleaned_vehicles = clean_vehicle_csv(
        args.input_path,
        args.output_path,
    )
    print(f"Saved {len(cleaned_vehicles)} cleaned vehicle records.")
