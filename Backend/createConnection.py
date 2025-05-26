import psycopg2 # type: ignore
from dotenv import load_dotenv # type: ignore
import os


def create_connection():
    """
    Create a connection to the PostgreSQL database.
    
    Returns:
        conn: A connection object to the PostgreSQL database.
    """
    load_dotenv()
    host = os.getenv("host")
    user = os.getenv("user")
    password = os.getenv("password")
    database = os.getenv("dbname")
    port = os.getenv("port")

    
    
    try:
        conn = psycopg2.connect(
            f'postgres://{user}:{password}@{host}:{port}/{database}?sslmode=require'
        )
        print("Connection to the database established successfully.")
        return conn
    except Exception as e:
        print(f"An error occurred while connecting to the database: {e}")
        return None
