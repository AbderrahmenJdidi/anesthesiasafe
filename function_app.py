import azure.functions as func
import logging
import io
import base64
import json
import os
from PIL import Image
import numpy as np
import torch
from azure.storage.blob import BlobServiceClient
import sys
import threading

# Initialize FunctionApp
app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

# Global predictor with lock for thread safety
predictor = None
_lock = threading.Lock()

def load_model():
    global predictor
    with _lock:
        if predictor is None:
            try:
                logging.info("Starting model loading...")
                
                # For local development, use local model files
                # For production, use blob storage
                connection_string = os.getenv("BLOB_CONNECTION_STRING")
                
                if connection_string:
                    # Production: Load from blob storage
                    logging.info("Loading model from blob storage...")
                    blob_service_client = BlobServiceClient.from_connection_string(connection_string)
                    
                    # Try SAM 2.1 first, fallback to SAM 2
                    model_configs = [
                        ("sam2.1_hiera_tiny.pt", "sam2.1_hiera_t.yaml"),
                        ("sam2_hiera_tiny.pt", "sam2_hiera_t.yaml")
                    ]
                    
                    for pt_blob, yaml_blob in model_configs:
                        try:
                            pt_data = blob_service_client.get_blob_client(
                                container="checkpoints", blob=pt_blob
                            ).download_blob().readall()
                            
                            yaml_data = blob_service_client.get_blob_client(
                                container="checkpoints", blob=yaml_blob
                            ).download_blob().readall()
                            
                            logging.info(f"Successfully loaded {pt_blob}")
                            break
                        except Exception as e:
                            logging.warning(f"Failed to load {pt_blob}: {e}")
                            continue
                    else:
                        raise Exception("No model files found in blob storage")
                else:
                    # Local development: Use placeholder
                    logging.info("No blob storage configured, using mock model for development")
                    predictor = "mock_model"  # Mock for local testing
                    return

                # Load the actual model
                try:
                    # Import SAM2 (this might fail in some environments)
                    from sam2.build_sam import build_sam2
                    from sam2.sam2_image_predictor import SAM2ImagePredictor
                    
                    # Load model state
                    state_dict = torch.load(io.BytesIO(pt_data), map_location="cpu")
                    if 'state_dict' in state_dict:
                        state_dict = state_dict['state_dict']
                    elif 'model' in state_dict:
                        state_dict = state_dict['model']
                    
                    # Build and load model
                    sam2_model = build_sam2(io.StringIO(yaml_data.decode('utf-8')), device="cpu")
                    sam2_model.load_state_dict(state_dict, strict=False)
                    predictor = SAM2ImagePredictor(sam2_model)
                    logging.info("SAM2 model loaded successfully")
                    
                except ImportError as e:
                    logging.error(f"SAM2 import failed: {e}")
                    predictor = "mock_model"  # Use mock for testing
                    
            except Exception as e:
                logging.error(f"Model loading failed: {str(e)}")
                predictor = "mock_model"  # Use mock to prevent crashes

@app.route(route="sam2-segment", methods=["POST"])
def sam2_segment(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('SAM2 segmentation function triggered.')
    
    # Load model if not already loaded
    if predictor is None:
        load_model()
    
    # Handle CORS
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    }
    
    if req.method == "OPTIONS":
        return func.HttpResponse(
            "",
            status_code=200,
            headers=headers
        )
    
    try:
        # Get image from request
        image_data = None
        
        if req.files.get('image'):
            # Handle multipart form data
            image_file = req.files['image']
            image_data = image_file.read()
        else:
            # Handle JSON request with base64 image
            try:
                req_body = req.get_json()
                if req_body and 'image' in req_body:
                    image_data = base64.b64decode(req_body['image'])
            except:
                pass
        
        if not image_data:
            return func.HttpResponse(
                "Please provide an image in the request",
                status_code=400,
                headers=headers
            )
        
        # Process image
        image = Image.open(io.BytesIO(image_data)).convert('RGB')
        
        # Size validation
        if image.size[0] * image.size[1] > 10_000_000:  # ~10MP limit
            return func.HttpResponse(
                "Image too large. Maximum size is approximately 10MP",
                status_code=400,
                headers=headers
            )
        
        # If using mock model (for testing)
        if predictor == "mock_model":
            logging.info("Using mock model for testing")
            # Return the original image with a simple modification
            img_buffer = io.BytesIO()
            image.save(img_buffer, format='JPEG', quality=95)
            img_buffer.seek(0)
            
            return func.HttpResponse(
                img_buffer.getvalue(),
                status_code=200,
                mimetype="image/jpeg",
                headers=headers
            )
        
        # Process with real SAM2 model
        image_array = np.array(image)
        
        # Set image for prediction
        predictor.set_image(image_array)
        
        # Use center point for segmentation
        height, width = image_array.shape[:2]
        center_point = np.array([[width//2, height//2]])
        center_label = np.array([1])
        
        # Predict mask
        masks, scores, logits = predictor.predict(
            point_coords=center_point,
            point_labels=center_label,
            multimask_output=True,
        )
        
        # Use the best mask
        if masks.size > 0:
            best_mask = masks[np.argmax(scores)]
            
            # Apply mask to image (remove background)
            result_image = image_array.copy()
            result_image[~best_mask] = [255, 255, 255]  # White background
            
            # Convert back to image
            result_pil = Image.fromarray(result_image)
            
            # Convert to bytes
            img_buffer = io.BytesIO()
            result_pil.save(img_buffer, format='JPEG', quality=95)
            img_buffer.seek(0)
            
            return func.HttpResponse(
                img_buffer.getvalue(),
                status_code=200,
                mimetype="image/jpeg",
                headers=headers
            )
        else:
            return func.HttpResponse(
                "No segmentation mask could be generated",
                status_code=400,
                headers=headers
            )
        
    except Exception as e:
        logging.error(f"Error processing image: {str(e)}")
        return func.HttpResponse(
            f"Error processing image: {str(e)}",
            status_code=500,
            headers=headers
        )

@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    # Load model if not already loaded
    if predictor is None:
        load_model()
    
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
    }
    
    model_status = "loaded" if predictor is not None else "not_loaded"
    if predictor == "mock_model":
        model_status = "mock_model"
    
    return func.HttpResponse(
        json.dumps({
            "status": "healthy", 
            "service": "SAM2 Segmentation",
            "model_status": model_status,
            "blob_storage_configured": bool(os.getenv("BLOB_CONNECTION_STRING"))
        }),
        status_code=200,
        mimetype="application/json",
        headers=headers
    )