# Azure SAM2 Function

This Azure Function provides SAM2 (Segment Anything Model 2) image segmentation capabilities.

## Setup Instructions

### 1. Local Development

1. Install Azure Functions Core Tools:
   ```bash
   npm install -g azure-functions-core-tools@4 --unsafe-perm true
   ```

2. Create and activate virtual environment:
   ```bash
   python -m venv venv
   # Windows
   venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. Start the function locally:
   ```bash
   func start
   ```

### 2. Deploy to Azure

1. Login to Azure:
   ```bash
   az login
   ```

2. Create a Function App:
   ```bash
   az functionapp create \
     --resource-group your-resource-group \
     --consumption-plan-location eastus \
     --runtime python \
     --runtime-version 3.9 \
     --functions-version 4 \
     --name your-function-app-name \
     --storage-account your-storage-account
   ```

3. Deploy the function:
   ```bash
   func azure functionapp publish your-function-app-name
   ```

### 3. Configure Model Storage

1. Create a storage account and container named "checkpoints"
2. Upload your SAM2 model files:
   - `sam2_hiera_tiny.pt` (or `sam2.1_hiera_tiny.pt`)
   - `sam2_hiera_t.yaml` (or `sam2.1_hiera_t.yaml`)

3. Set the `BLOB_CONNECTION_STRING` environment variable in your Function App settings

## API Endpoints

### POST /api/sam2-segment
Segments an image using SAM2 model.

**Request:**
- Multipart form with `image` file, or
- JSON with base64 encoded `image` field

**Response:**
- Segmented image (JPEG format)

### GET /api/health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "service": "SAM2 Segmentation",
  "model_status": "loaded",
  "blob_storage_configured": true
}
```

## Troubleshooting

1. **Model loading issues**: Check that your blob storage is configured correctly and model files are uploaded
2. **Memory issues**: Consider using a smaller model variant or upgrading to a Premium plan
3. **Timeout issues**: Increase the function timeout in `host.json`