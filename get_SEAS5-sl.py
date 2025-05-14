import cdsapi

leadtime_hour = list(range(12, 5172, 12))

dataset = "seasonal-original-single-levels"
request = {
    "originating_centre": "ecmwf",
    "system": "51",
    "variable": [
        "10m_u_component_of_wind",
        "10m_v_component_of_wind",
        "2m_dewpoint_temperature",
        "2m_temperature",
        "land_sea_mask",
        "mean_sea_level_pressure",
        "sea_surface_temperature",
        "sea_ice_cover",
        "snow_depth"
    ],
    "year": ["YY1"],
    "month": ["MM1"],
    "day": ["DD1"],
    "leadtime_hour": leadtime_hour,
    "area":"Nort/West/Sout/East",
    "data_format": "grib"
}

c = cdsapi.Client()
c.retrieve(dataset, request).download("SEAS5-YY1MM1DD100-sl.grib")

