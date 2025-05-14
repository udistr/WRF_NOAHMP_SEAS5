import cdsapi
import numpy as np

c = cdsapi.Client()

leadtime_hour = list(range(12, 5172, 12))

variables = ["geopotential", "specific_humidity", "temperature", "u_component_of_wind", "v_component_of_wind"]
vstrings = ["H", "Q", "T", "U", "V"]

dataset = "seasonal-original-pressure-levels"
request = {
    "originating_centre": "ecmwf",
    "system": "51",
    "variable": ["VAR"],
    "pressure_level": [
        "10", "30", "50",
        "100", "200", "300",
        "400", "500", "700",
        "850", "925", "1000"
    ],
    "year": ["YY1"],  # Replace "2016" with desired year or variable
    "month": ["MM1"],   # Replace "11" with desired month
    "day": ["DD1"],     # Replace "01" with desired day
    "leadtime_hour": leadtime_hour,
    "area":"Nort/West/Sout/East",  # Format: North/West/South/East (global)
    "data_format": "grib"
}

c.retrieve(dataset, request).download("SEAS5_VARN-YY1MM1DD100-pl.grib")

