

import psycopg2 # type: ignore
import bcrypt # type: ignore
from dotenv import load_dotenv # type: ignore
import os
from createConnection import create_connection

def create_table():
    try:
        connection = create_connection()
        if connection is None:
            print("Failed to create a database connection.")
            return
        cursor = connection.cursor()
        # cursor.execute("DROP TABLE IF EXISTS users;")  # Drop the table if it exists
        # Create the users table
        cursor.execute('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";')
        connection.commit()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                userId UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                email VARCHAR(255) UNIQUE NOT NULL,
                password TEXT NOT NULL,
                full_name VARCHAR(255),
                country VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        connection.commit()
        print("Extension and table created (if not existed).")
    except psycopg2.Error as e:
        print(f"An error occurred while creating the table: {e}")

create_table()