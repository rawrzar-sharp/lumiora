from sqlalchemy import create_engine, text
from datetime import datetime
import os

# ==========================================
# 1. KONFIGURASI DATABASE
# ==========================================
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("DB_PORT", "3307")
DB_NAME = os.getenv("DB_NAME", "lumiora")

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}",
    pool_pre_ping=True,
)


def run_data_pipeline():
    print(f"[{datetime.now()}] Memulai Lumiora Data Pipeline...")
    print(f"Menghubungkan ke MySQL: {DB_HOST}:{DB_PORT}/{DB_NAME}")

    with engine.begin() as conn:
        print("Menghitung Metrik 1: Total Sales per day...")
        conn.execute(text("DROP TABLE IF EXISTS metric_sales_per_day"))
        conn.execute(text("""
            CREATE TABLE metric_sales_per_day AS
            SELECT
                DATE(o.created_at) as sales_date,
                SUM(oi.quantity * oi.price_at_sale) as total_sales
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            GROUP BY DATE(o.created_at)
        """))

        print("Menghitung Metrik 2: Total Sales per day per item...")
        conn.execute(text("DROP TABLE IF EXISTS metric_sales_per_item"))
        conn.execute(text("""
            CREATE TABLE metric_sales_per_item AS
            SELECT
                DATE(o.created_at) as sales_date,
                mi.name as item_name,
                SUM(oi.quantity * oi.price_at_sale) as total_item_sales
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            JOIN menu_items mi ON oi.menu_item_id = mi.id
            GROUP BY DATE(o.created_at), mi.name
        """))

        print("Menghitung Metrik 3: Total quantity sold per day per item...")
        conn.execute(text("DROP TABLE IF EXISTS metric_qty_per_item"))
        conn.execute(text("""
            CREATE TABLE metric_qty_per_item AS
            SELECT
                DATE(o.created_at) as sales_date,
                mi.name as item_name,
                SUM(oi.quantity) as total_quantity
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            JOIN menu_items mi ON oi.menu_item_id = mi.id
            GROUP BY DATE(o.created_at), mi.name
        """))

        print("Menghitung Metrik 4: Total quantity ordered per hour per day...")
        conn.execute(text("DROP TABLE IF EXISTS metric_qty_per_hour"))
        conn.execute(text("""
            CREATE TABLE metric_qty_per_hour AS
            SELECT
                DATE(o.created_at) as sales_date,
                HOUR(o.created_at) as hour_of_day,
                SUM(oi.quantity) as total_quantity
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            GROUP BY DATE(o.created_at), HOUR(o.created_at)
        """))

    print(f"[{datetime.now()}] Data Pipeline Selesai! 4 Tabel Metrik berhasil dibuat di Database.")


if __name__ == "__main__":
    try:
        run_data_pipeline()
    except Exception as e:
        print(f"Terjadi Kesalahan: {e}")
