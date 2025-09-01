# AnesthesiaSafe - Flutter Mobile Application

A Flutter-based mobile application designed for medical professionals to assess pediatric anesthesia safety using AI-powered image analysis.

## Overview

AnesthesiaSafe is a medical application that helps healthcare professionals evaluate the safety of administering anesthesia to pediatric patients through AI-assisted image analysis. The app uses advanced image segmentation and CNN models to provide safety assessments and recommendations.

## Installation & Setup

### Prerequisites
- Flutter SDK (3.0+)
- Firebase CLI
- Android Studio / Xcode
- Firebase project with Authentication and Firestore enabled

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/AbderrahmenJdidi/anesthesiasafe
   cd anesthesia_safe
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Download and configure Firebase configuration files
   - Update `lib/firebase_options.dart` with your project credentials

4. **Backend Configuration**
   -repository url : https://github.com/AbderrahmenJdidi/SAM2-django-web-app
   - Ensure Django backend is running on your network
   - Update API endpoint in `lib/screens/home_screen.dart`:
     ```dart
     Uri.parse('http://YOUR_SERVER_IP:8000/api/segment/')
     ```

5. **Run the application**
   ```bash
   flutter run
   ```

## Firebase Setup

### Authentication Configuration
Enable Email/Password authentication in Firebase Console.

### Firestore Database Structure
```
users/
  {uid}/
    - uid: string
    - email: string
    - fullName: string
    - specialty: string
    - role: string ('admin' | 'user' | 'pending' | 'denied')
    - status: string ('pending' | 'approved' | 'denied')
    - createdAt: timestamp
    - lastLoginAt: timestamp
    - updatedAt: timestamp
    
    analyses/
      {analysisId}/
        - safety: boolean
        - confidence: number
        - recommendation: string
        - riskFactors: array
        - notes: string
        - segmented_image_url: string
        - timestamp: timestamp
        - user_id: string
```

### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Analysis subcollection
      match /analyses/{analysisId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Admins can access all user documents for approval
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## API Integration

The app communicates with a Django backend for image processing:

### Endpoints Used
- `POST /api/segment-and-analyze/` - Image segmentation and analysis
- `GET /api/health/` - Server health check

### Image Processing Flow
1. User captures/selects image
2. Image uploaded to Django backend via multipart form
3. SAM2 model performs image segmentation
4. CNN model analyzes safety
5. Results returned to app with segmented image
6. Results saved to Firestore for history



## Security Considerations

- All user registrations require admin approval
- Firebase security rules restrict data access
- Secure image transmission to backend
- Professional verification through specialty selection
- Account status monitoring (pending, approved, denied)

## Development

### Running in Development
```bash
# Run with hot reload
flutter run

# Run on specific device
flutter run -d <device-id>

# Build for release
flutter build apk --release
flutter build ios --release
```

### Testing
```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```
