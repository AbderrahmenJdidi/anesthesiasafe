# AnesthesiaSafe - Database Schema (Firestore)

```mermaid
erDiagram
    USERS {
        string uid PK "Firebase Auth UID"
        string email UK "User email address"
        string fullName "Full name"
        string specialty "Medical specialty"
        string role "user|admin|pending|denied"
        string status "pending|approved|denied"
        timestamp createdAt "Account creation time"
        timestamp lastLoginAt "Last login timestamp"
        timestamp updatedAt "Last profile update"
    }

    ANALYSES {
        string id PK "Auto-generated document ID"
        string userId FK "Reference to USERS.uid"
        boolean safety "Safety assessment result"
        number confidence "Confidence score (0-1)"
        string recommendation "AI recommendation text"
        array riskFactors "List of identified risk factors"
        string notes "Additional clinical notes"
        string segmentedImageUrl "URL to processed image"
        timestamp timestamp "Analysis creation time"
    }

    USER_SESSIONS {
        string sessionId PK "Session identifier"
        string userId FK "Reference to USERS.uid"
        timestamp createdAt "Session start time"
        timestamp expiresAt "Session expiration"
        string deviceInfo "Device information"
        boolean isActive "Session status"
    }

    SYSTEM_LOGS {
        string logId PK "Log entry identifier"
        string userId FK "Reference to USERS.uid (optional)"
        string action "Action performed"
        string level "info|warning|error"
        string message "Log message"
        map metadata "Additional log data"
        timestamp timestamp "Log entry time"
    }

    APP_SETTINGS {
        string settingId PK "Setting identifier"
        string key "Setting key"
        string value "Setting value"
        string description "Setting description"
        timestamp updatedAt "Last update time"
        string updatedBy FK "Reference to USERS.uid"
    }

    %% Relationships
    USERS ||--o{ ANALYSES : "has many"
    USERS ||--o{ USER_SESSIONS : "has many"
    USERS ||--o{ SYSTEM_LOGS : "generates"
    USERS ||--o{ APP_SETTINGS : "can modify"

    %% Collection Structure in Firestore
    %% /users/{uid}
    %% /users/{uid}/analyses/{analysisId}
    %% /users/{uid}/sessions/{sessionId}
    %% /systemLogs/{logId}
    %% /appSettings/{settingId}
```

## Firestore Security Rules Structure

```javascript
// Firestore Security Rules (conceptual)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
                     get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      
      // User's analyses subcollection
      match /analyses/{analysisId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
        allow read: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      }
      
      // User's sessions subcollection
      match /sessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // System logs (admin only)
    match /systemLogs/{logId} {
      allow read, write: if request.auth != null && 
                            get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // App settings (admin only)
    match /appSettings/{settingId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Data Models

### User Document Structure
```json
{
  "uid": "firebase_auth_uid",
  "email": "doctor@hospital.com",
  "fullName": "Dr. John Smith",
  "specialty": "Pediatric Anesthesiologist",
  "role": "user", // user|admin|pending|denied
  "status": "approved", // pending|approved|denied
  "createdAt": "2025-01-XX...",
  "lastLoginAt": "2025-01-XX...",
  "updatedAt": "2025-01-XX..."
}
```

### Analysis Document Structure
```json
{
  "userId": "firebase_auth_uid",
  "safety": true,
  "confidence": 0.92,
  "recommendation": "Patient appears to be in good condition...",
  "riskFactors": ["None detected"],
  "notes": "Patient shows normal facial characteristics...",
  "segmentedImageUrl": "http://server/processed_image.jpg",
  "timestamp": "2025-01-XX..."
}
```

## Indexing Strategy

### Composite Indexes
- `users`: `(status, createdAt)` for admin dashboard
- `analyses`: `(userId, timestamp)` for user history
- `systemLogs`: `(level, timestamp)` for error monitoring

### Single Field Indexes
- `users.email` for login lookups
- `users.role` for role-based queries
- `analyses.safety` for safety statistics
- `analyses.confidence` for confidence analysis