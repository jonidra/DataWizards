# src/routes/lat_lon_revenue.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text
from sqlalchemy.orm import Session
from src.db import SessionLocal
from src.schemas import LatLonRequest, LatLonResponse

router = APIRouter()

def get_db():
    db: Session = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/lat-lon-revenue", response_model=LatLonResponse)
def lat_lon_revenue(req: LatLonRequest, db: Session = Depends(get_db)):
    # 1) Nearest city (using PostGIS KNN on geom)
    sql_city = text("""
      SELECT id
      FROM city
      ORDER BY geom <-> ST_SetSRID(ST_Point(:lon, :lat), 4326)
      LIMIT 1
    """)
    city_row = db.execute(sql_city, {"lon": req.lon, "lat": req.lat}).fetchone()
    if not city_row:
        raise HTTPException(404, "No nearby city found")

    city_id = city_row[0]

    # 2) Top customer by revenue in that city
    sql_cust = text("""
      SELECT f.customer_id, c.email, SUM(f.revenue) AS revenue
      FROM fact_installation AS f
      JOIN customer AS c ON f.customer_id = c.id
      WHERE f.city_id = :city_id
      GROUP BY f.customer_id, c.email
      ORDER BY revenue DESC
      LIMIT 1
    """)
    cust_row = db.execute(sql_cust, {"city_id": city_id}).fetchone()
    if not cust_row:
        raise HTTPException(404, "No installations found for nearest city")

    return LatLonResponse(
        customer_id=cust_row[0],
        email=cust_row[1],
        revenue=float(cust_row[2]),
    )
