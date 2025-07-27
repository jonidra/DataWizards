# src/main.py
from fastapi import FastAPI
from src.routes.lat_lon_revenue import router as llr_router
from src.routes.city_revenue import router as cr_router

app = FastAPI(title="Sales Analysis API")

app.include_router(llr_router)
app.include_router(cr_router)
