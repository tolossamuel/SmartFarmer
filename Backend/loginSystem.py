import psycopg2  # type: ignore
import bcrypt  # type: ignore
from dotenv import load_dotenv  # type: ignore
from fastapi.responses import JSONResponse
from createConnection import create_connection
import os

class AuthenticationSystem:

    def register(self, password: str, email: str, name: str, country: str):
        try:
            conn = create_connection()
            if conn is None:
                return JSONResponse(status_code=500, content={"success": False, "message": "Database connection failed."})

            cursor = conn.cursor()
            cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
            existing_user = cursor.fetchone()
            if existing_user:
                cursor.close()
                conn.close()
                return JSONResponse(status_code=409, content={"success": False, "message": "User with this email already exists."})

            hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
            cursor.execute("""
                INSERT INTO users (email, password, full_name, country)
                VALUES (%s, %s, %s, %s)
            """, (email, hashed_password.decode('utf-8'), name, country))

            conn.commit()
            cursor.close()
            conn.close()
            return JSONResponse(status_code=201, content={"success": True, "message": "User registered successfully."})

        except psycopg2.Error as e:
            print(f"Database error: {e}")
            if conn:
                cursor.close()
                conn.close()
            return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

    def login(self, email: str, password: str):
        try:
            conn = create_connection()
            if conn is None:
                return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

            cursor = conn.cursor()
            cursor.execute("""
                SELECT userId, email, password, full_name, country 
                FROM users 
                WHERE email = %s
            """, (email,))
            user = cursor.fetchone()

            if user is None:
                cursor.close()
                conn.close()
                return JSONResponse(status_code=401, content={"success": False, "message": "Email or password is incorrect."})

            user_id, email, hashed_password, full_name, country = user
            if not bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8')):
                return JSONResponse(status_code=401, content={"success": False, "message": "Email or password is incorrect."})

            cursor.close()
            conn.close()
            return JSONResponse(status_code=200, content={
                "success": True,
                "message": "Login successful.",
                "user": {
                    "userId": str(user_id),
                    "email": email,
                    "full_name": full_name,
                    "country": country
                }
            })

        except psycopg2.Error as e:
            print(f"Database error: {e}")
            if conn:
                cursor.close()
                conn.close()
            return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

    def updatePassword(self, userId: str, old_password: str, new_password: str):
        try:
            conn = create_connection()
            if conn is None:
                return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

            cursor = conn.cursor()
            cursor.execute("SELECT password FROM users WHERE userId = %s", (userId,))
            user = cursor.fetchone()

            if user is None:
                cursor.close()
                conn.close()
                return JSONResponse(status_code=404, content={"success": False, "message": "User not found."})

            hashed_password = user[0]
            if not bcrypt.checkpw(old_password.encode('utf-8'), hashed_password.encode('utf-8')):
                cursor.close()
                conn.close()
                return JSONResponse(status_code=401, content={"success": False, "message": "Old password is incorrect."})

            new_hashed_password = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt())
            cursor.execute("UPDATE users SET password = %s WHERE userId = %s", (new_hashed_password.decode('utf-8'), userId))
            conn.commit()
            cursor.close()
            conn.close()
            return JSONResponse(status_code=200, content={"success": True, "message": "Password updated successfully."})

        except psycopg2.Error as e:
            print(f"Database error: {e}")
            if conn:
                cursor.close()
                conn.close()
            return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

    def updatinfo(self, name: str, email: str, userId: str, country: str):
        try:
            conn = create_connection()
            if conn is None or not all([name, email, userId, country]):
                if conn:
                    conn.close()
                return JSONResponse(status_code=400, content={"success": False, "message": "Invalid input."})

            cursor = conn.cursor()
            cursor.execute("""
                UPDATE users 
                SET full_name = %s, email = %s, country = %s 
                WHERE userId = %s
            """, (name, email, country, userId))
            conn.commit()
            cursor.close()
            conn.close()
            return JSONResponse(status_code=200, content={"success": True, "message": "User information updated successfully."})

        except psycopg2.Error as e:
            print(f"Database error: {e}")
            if conn:
                cursor.close()
                conn.close()
            return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

    def deleteUser(self, userId: str):
        try:
            conn = create_connection()
            if conn is None:
                return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

            cursor = conn.cursor()
            cursor.execute("DELETE FROM users WHERE userId = %s", (userId,))
            conn.commit()
            cursor.close()
            conn.close()
            return JSONResponse(status_code=200, content={"success": True, "message": "User deleted successfully."})

        except psycopg2.Error as e:
            print(f"Database error: {e}")
            if conn:
                cursor.close()
                conn.close()
            return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

    def getAllUsers(self):
        try:
            conn = create_connection()
            if conn is None:
                return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

            cursor = conn.cursor()
            cursor.execute("SELECT userId, email, full_name, country FROM users")
            users = cursor.fetchall()
            user_list = [{
                "userId": str(user[0]),
                "email": user[1],
                "full_name": user[2],
                "country": user[3]
            } for user in users]

            cursor.close()
            conn.close()
            return JSONResponse(status_code=200, content={"success": True, "users": user_list})

        except psycopg2.Error as e:
            print(f"Database error: {e}")
            if conn:
                cursor.close()
                conn.close()
            return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

    def getUserById(self, userId: str):
        try:
            conn = create_connection()
            if conn is None:
                return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})

            cursor = conn.cursor()
            cursor.execute("""
                SELECT userId, email, full_name, country 
                FROM users 
                WHERE userId = %s
            """, (userId,))
            user = cursor.fetchone()

            if user is None:
                cursor.close()
                conn.close()
                return JSONResponse(status_code=404, content={"success": False, "message": "User not found."})

            user_data = {
                "userId": str(user[0]),
                "email": user[1],
                "full_name": user[2],
                "country": user[3]
            }

            cursor.close()
            conn.close()
            return JSONResponse(status_code=200, content={"success": True, "user": user_data})

        except psycopg2.Error as e:
            print(f"Database error: {e}")
            if conn:
                cursor.close()
                conn.close()
            return JSONResponse(status_code=500, content={"success": False, "message": "Try again later!"})
