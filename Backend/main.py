

# fast api login
from fastapi import FastAPI, HTTPException # type: ignore
from fastapi.middleware.cors import CORSMiddleware # type: ignore
from loginSystem import AuthenticationSystem
from chatSystem import ChatSystem
from fastapi import FastAPI, File, UploadFile, Form
import os
import shutil
from crop_photo import CropPhoto # Assuming this is the correct import path for your CropPhoto class
app = FastAPI()
# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development; adjust in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Initialize the login system
login_system = AuthenticationSystem()
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
ChatSystem = ChatSystem()
@app.post("/login")
async def login(email: str, password: str):
    """
    Endpoint for user login.
    """
    try:
        response = login_system.login(email, password)
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
@app.post("/register")
async def register(email: str, password: str, name: str, country: str):
    """
    Endpoint for user registration.
    """
    try:
        print(f"Registering user: {email}, Name: {name}, Country: {country}")
        response = login_system.register(password, email, name, country)
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
@app.put("/updateInfo")
async def update_info(email: str, name: str, country: str, userId: str):
    """
    Endpoint for updating user information.
    """
    try:
        response = login_system.updatinfo(name, email, userId,country)
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
@app.put("/updatePassword")
async def update_password(userId: str, old_password: str, new_password: str):
    """_summary_

    Args:
        userId (str): _description_
        old_password (str): _description_
        new_password (str): _description_
    """
    try:
        response = login_system.updatePassword(userId, old_password, new_password)
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
@app.delete("/deleteUser")
async def delete_user(userId: str):
    """
    Endpoint for deleting a user.
    """
    try:
        response = login_system.deleteUser(userId)
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
@app.get("/getUserInfo")
async def get_user_info(userId: str):
    """
    Endpoint for retrieving user information.
    """
    try:
        response = login_system.getUserById(userId)
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
@app.get("/getAllUsers")
async def get_all_users():
    """
    Endpoint for retrieving all users.
    """
    try:
        response = login_system.getAllUsers()
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
    
# chat system

@app.get("/weather-discription")
async def weather_description(user_input: str):
    """
    Endpoint for getting weather-related advice.
    """
    try:
        response = ChatSystem.weather(user_input)
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
@app.post("/chat")
async def chat(user_input: str, user_history: str = ""):
    """
    Endpoint for chatting with the AgriBuddy system.
    """
    try:
        response = ChatSystem.chat(user_input, user_history)
     
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))
@app.post("/crop")
async def crop(image: UploadFile = File(...) ):
    """
    Endpoint for analyzing crop images.
    """
    try:
        file_path = os.path.join(UPLOAD_DIR, image.filename)
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)
        crop_photo = CropPhoto(file_path)
        response = crop_photo.crop()
        if "\"crop_name\": \"unknown\"" in response:
            return HTTPException(status_code=400, detail="Crop not recognized or image not clear.")
        return response
    except Exception as e:
        return HTTPException(status_code=500, detail=str(e))