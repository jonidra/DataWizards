# src/routes/city_revenue.py
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from src.db import SessionLocal
from src.schemas import CityRevenueRequest, CityRevenueResponse

router = APIRouter()

def get_db():
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/city-revenue", response_model=CityRevenueResponse)
def city_revenue(req: CityRevenueRequest, db: Session = Depends(get_db)):
    sql = text("""
      SELECT SUM(f.revenue::numeric) AS total_revenue
      FROM fact_installation AS f
      JOIN city AS ct ON f.city_id = ct.id
      WHERE ct.city = :city_name
    """)
    row = db.execute(sql, {"city_name": req.city_name}).fetchone()
    total = float(row[0] or 0.0)
    return CityRevenueResponse(city_name=req.city_name, total_revenue=total)
