import google.generativeai as genai
import os
from PIL import Image # Required for opening image files
import json
from fastapi.responses import JSONResponse
class CropPhoto:
    def __init__(self, image_path):
        self.image_path = image_path
        api_key = os.getenv("gemini_api")
        genai.configure(api_key=api_key)
        self.client = genai.GenerativeModel("gemini-1.5-flash-latest")
        self.text_instructions = """Your are smart farmer, you provide detailed information about the crop in the image.
        You will provide the crop name, its growth stage, and any visible issues or pests. 
        If the crop is healthy, you will say 'healthy'. If there are issues, you will describe them in detail.
        the response should be in the joson format not in text format.
        example response:
        {"crop_name": "wheat",
        "growth_stage" : "mature",
        "health_status": "healthy",
        "recommendations" : "based on the crop health status, provide recommendations for care or treatment."
        }
        do not provide any other information, just the json response.
        if the crop is not recognized, respond with:
        {"crop_name" : "unknown",
        "description" : "crop not recognized, please provide a clear image of the crop."}
        
        alway provide for similar image similar response.
        """ # Note: I'm assuming this is the text prompt, and not the one with image_path concatenated.

    def crop(self):
        try:
            # Open the image file from the provided path
            img = Image.open(self.image_path)
        except FileNotFoundError:
            safe_image_path = self.image_path.replace('"', '\\"')
            return f'{{"crop_name": "unknown", "description": "Error: Image file not found at {safe_image_path}."}}'
        except Exception as e:
            safe_error_message = str(e).replace('"', '\\"')
            return f'{{"crop_name": "unknown", "description": "Error: Could not open image - {safe_error_message}."}}'

        content_parts = [self.text_instructions, img]
        
        try:
            response = self.client.generate_content(
                content_parts,
                generation_config=genai.types.GenerationConfig(
                    # Requesting JSON output directly if supported by the model/SDK version
                    response_mime_type="application/json" 
                )
            )
            # The model is instructed to return JSON directly.

            data = json.loads(response.text)
            return JSONResponse(content=data, status_code=200)
        except AttributeError: # Fallback if response_mime_type or genai.types is not supported
            try:
                response = self.client.generate_content(content_parts)
                return response.text # Model should still attempt to return JSON based on prompt
            except Exception as e:
                return JSONResponse(content={
                    "crop_name": "unknown",
                    "description": "Model did not return valid JSON.",
                    "raw_response": response.text
                }, status_code=500)

        except Exception as e:
            return JSONResponse(content={
                "crop_name": "unknown",
                "description": f"Error: API call failed - {str(e)}"
            }, status_code=500)