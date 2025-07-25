# Azure SAM2 Model Setup Guide

This guide will help you deploy the SAM2 model to Azure and configure your Flutter app to use it.

## Prerequisites

- Azure account with active subscription
- Azure CLI installed
- Python 3.8+ (for local testing)
- SAM2 model files

## Step 1: Create Azure Function App

### Using Azure Portal

1. **Create a Function App**
   - Go to Azure Portal (portal.azure.com)
   - Click "Create a resource" → "Function App"
   - Fill in the details:
     - **Subscription**: Your Azure subscription
     - **Resource Group**: Create new or use existing
     - **Function App name**: `your-app-name-sam2` (must be globally unique)
     - **Runtime stack**: Python 3.9
     - **Region**: Choose closest to your users
     - **Plan type**: Consumption (Pay for what you use)

2. **Configure Function App**
   - After creation, go to your Function App
   - Navigate to "Configuration" → "Application settings"
   - Add these settings:
     ```
     FUNCTIONS_WORKER_RUNTIME = python
     FUNCTIONS_EXTENSION_VERSION = ~4
     ```

### Using Azure CLI

```bash
# Login to Azure
az login

# Create resource group
az group create --name sam2-rg --location eastus

# Create storage account
az storage account create \
  --name sam2storage \
  --resource-group sam2-rg \
  --location eastus \
  --sku Standard_LRS

# Create function app
az functionapp create \
  --resource-group sam2-rg \
  --consumption-plan-location eastus \
  --runtime python \
  --runtime-version 3.9 \
  --functions-version 4 \
  --name your-app-name-sam2 \
  --storage-account sam2storage
```

## Step 2: Prepare SAM2 Function Code

Create a new directory for your Azure Function:

```bash
mkdir azure-sam2-function
cd azure-sam2-function
```

### Create `requirements.txt`

```txt
azure-functions
torch
torchvision
opencv-python-headless
numpy
Pillow
segment-anything-2
```

### Create `function_app.py`

```python
import azure.functions as func
import logging
import io
import base64
import json
from PIL import Image
import numpy as np
import torch
from sam2.build_sam import build_sam2
from sam2.sam2_image_predictor import SAM2ImagePredictor

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

# Global variables for model (loaded once)
predictor = None

def load_model():
    global predictor
    if predictor is None:
        # Load SAM2 model
        sam2_checkpoint = "./checkpoints/sam2_hiera_large.pt"
        model_cfg = "sam2_hiera_l.yaml"
        
        sam2_model = build_sam2(model_cfg, sam2_checkpoint, device="cpu")
        predictor = SAM2ImagePredictor(sam2_model)
        logging.info("SAM2 model loaded successfully")

@app.route(route="sam2-segment", methods=["POST"])
def sam2_segment(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('SAM2 segmentation function triggered.')
    
    try:
        # Load model if not already loaded
        load_model()
        
        # Get image from request
        if req.files.get('image'):
            # Handle multipart form data
            image_file = req.files['image']
            image_data = image_file.read()
        else:
            # Handle JSON request with base64 image
            req_body = req.get_json()
            if not req_body or 'image' not in req_body:
                return func.HttpResponse(
                    "Please provide an image in the request",
                    status_code=400
                )
            
            image_base64 = req_body['image']
            image_data = base64.b64decode(image_base64)
        
        # Process image
        image = Image.open(io.BytesIO(image_data)).convert('RGB')
        image_array = np.array(image)
        
        # Set image for prediction
        predictor.set_image(image_array)
        
        # For automatic segmentation, you might want to use SAM2AutomaticMaskGenerator
        # For now, we'll do a simple center point prediction
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
            mimetype="image/jpeg"
        )
        
    except Exception as e:
        logging.error(f"Error processing image: {str(e)}")
        return func.HttpResponse(
            f"Error processing image: {str(e)}",
            status_code=500
        )

@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        json.dumps({"status": "healthy", "service": "SAM2 Segmentation"}),
        status_code=200,
        mimetype="application/json"
    )
```

### Create `host.json`

```json
{
  "version": "2.0",
  "functionTimeout": "00:05:00",
  "extensions": {
    "http": {
      "routePrefix": "api"
    }
  }
}
```

## Step 3: Deploy to Azure

### Option 1: Using Azure Functions Core Tools

```bash
# Install Azure Functions Core Tools
npm install -g azure-functions-core-tools@4 --unsafe-perm true

# Initialize function app
func init --python

# Deploy to Azure
func azure functionapp publish your-app-name-sam2
```

### Option 2: Using VS Code

1. Install Azure Functions extension
2. Sign in to Azure
3. Right-click your function folder
4. Select "Deploy to Function App"
5. Choose your function app

### Option 3: Using GitHub Actions

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Azure Functions

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
    
    - name: Deploy to Azure Functions
      uses: Azure/functions-action@v1
      with:
        app-name: your-app-name-sam2
        package: .
        publish-profile: ${{ secrets.AZURE_FUNCTIONAPP_PUBLISH_PROFILE }}
```

## Step 4: Upload SAM2 Model Files

You need to upload the SAM2 model checkpoints to your Azure Function:

### Option 1: Using Azure Storage

1. Create a storage account
2. Upload model files to blob storage
3. Mount the storage to your function app

### Option 2: Include in deployment package

1. Download SAM2 checkpoints
2. Place them in a `checkpoints` folder in your function directory
3. Deploy the entire package

## Step 5: Configure Flutter App

1. **Update `lib/config/azure_config.dart`**:
   ```dart
   static const String functionAppUrl = 'https://your-app-name-sam2.azurewebsites.net';
   static const String functionKey = 'your-function-key-from-azure-portal';
   ```

2. **Get your Function Key**:
   - Go to Azure Portal
   - Navigate to your Function App
   - Go to "Functions" → "sam2-segment"
   - Click "Function Keys"
   - Copy the default key

## Step 6: Test the Integration

1. **Test Azure Function directly**:
   ```bash
   curl -X POST "https://your-app-name-sam2.azurewebsites.net/api/sam2-segment?code=YOUR_FUNCTION_KEY" \
        -F "image=@test_image.jpg"
   ```

2. **Test in Flutter app**:
   - Run your Flutter app
   - Check the Azure Status widget
   - Try uploading and processing an image

## Troubleshooting

### Common Issues

1. **Function timeout**: Increase timeout in `host.json`
2. **Memory issues**: Upgrade to Premium plan
3. **Model loading errors**: Check model file paths
4. **CORS issues**: Configure CORS in Function App settings

### Monitoring

- Use Azure Application Insights for monitoring
- Check Function App logs in Azure Portal
- Monitor performance and costs

### Cost Optimization

- Use Consumption plan for low usage
- Consider Premium plan for consistent usage
- Monitor and set up billing alerts

## Security Considerations

- Use Function Keys for authentication
- Consider Azure AD authentication for production
- Implement rate limiting
- Validate input images
- Use HTTPS only

## Next Steps

- Implement caching for better performance
- Add batch processing capabilities
- Integrate with Azure Cognitive Services for additional AI features
- Set up CI/CD pipeline for automated deployments