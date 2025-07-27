# src/schemas.py
from pydantic import BaseModel

class LatLonRequest(BaseModel):
    lat: float
    lon: float

class LatLonResponse(BaseModel):
    customer_id: int
    email: str
    revenue: float

class CityRevenueRequest(BaseModel):
    city_name: str

class CityRevenueResponse(BaseModel):
    city_name: str
    total_revenue: float
