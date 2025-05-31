import google.generativeai as genai
import os
from dotenv import load_dotenv
import json
from fastapi.responses import JSONResponse


class ChatSystem:
    def __init__(self):
        load_dotenv()
        api_key = os.getenv("gemini_api")
        genai.configure(api_key = api_key )
        self.client = genai.GenerativeModel("gemini-2.0-flash")
        self.prompt = """
        You are AgriBuddy, a professional agricultural advisor trained in crop science, 
        soil management, pest control, irrigation, and local farming practices. Your job is to assist farmers using simple, 
        clear, and respectful language, just like a real expert would in a face-to-face conversation.
        The farmer may ask about planting, fertilizers, pests, weather, or how to increase yield. Speak in a friendly tone, 
        using local farming examples where possible. Your advice must be practical, region-aware, and tailored to small to medium-scale farmers.
        If the farmer doesn’t know technical terms, explain them simply. Ask clarifying questions if needed, just like a human advisor.
        Assume that farmer is located in  India.
        Start by greeting the farmer respectfully and asking what help they need today.
        
        if the farmer ask about a specific crop, provide advice on that crop.
        if the question is out of scope, politely inform the farmer that you can only provide advice on agricultural topics.
        Always end with a friendly note, encouraging the farmer to ask more questions if they need further assistance.
        
        here is the convesation history if available:
        {user_history}
        
        Here is the user input:
        {user_input}
        
        """
    def chat(self, user_input,user_history = ""):
        try:
            prompts = self.prompt.format(user_history=user_history, user_input=user_input)
            response = self.client.generate_content(
                prompts
            )
           
            if response and response.text:
                generated_text = response.text
                
                return JSONResponse(
                    content={
                        "status": "success",
                        "message": generated_text
                    },
                    status_code=200
                )
            return JSONResponse(
                content={
                    "status": "error",
                    "message": "No response generated."
                },
                status_code=500
            )
        except Exception as e:
            return JSONResponse(
                content={
                    "status": "error",
                    "message": str(e)
                },
                status_code=500
            )
    def weather(self, user_input):
        try:
            prompts = f"""
            You are AgriBuddy, a professional agricultural advisor. 
            The farmer is asking about what he/she can do based on weather data provided.
            only answer with out any question explain the actions that can be taken based on the weather data.
            
            Here is the user input:
            {user_input}
            """
            
            response = self.client.generate_content(
                prompts
            )
            if response and response.text:
                generated_text = response.text
                return JSONResponse(
                    content={
                        "status": "success",
                        "message": generated_text
                    },
                    status_code=200
                )
                
            return JSONResponse(
                content={
                    "status": "error",
                    "message": "No response generated."
                },
                status_code=500
            )
        except Exception as e:
            return JSONResponse(
                content={
                    "status": "error",
                    "message": str(e)
                },
                status_code=500
            )
    