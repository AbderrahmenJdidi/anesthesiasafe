# AnesthesiaSafe - Sequence Diagrams

## 1. User Registration Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant UI as SignUpScreen
    participant AS as AuthService
    participant FA as FirebaseAuth
    participant FS as Firestore
    participant AW as AuthWrapper

    U->>UI: Fill registration form
    U->>UI: Submit registration
    UI->>AS: registerWithEmailAndPassword()
    AS->>FA: createUserWithEmailAndPassword()
    FA-->>AS: UserCredential
    AS->>FS: Create user document (status: pending)
    FS-->>AS: Success
    AS-->>UI: Registration successful
    UI->>AW: Navigate to PendingScreen
    AW->>U: Show pending approval message
```

## 2. Image Analysis Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant HS as HomeScreen
    participant IP as ImagePicker
    participant AS as AuthService
    participant SAM2 as SAM2 API
    participant FS as Firestore

    U->>HS: Select "Analyze Image"
    HS->>IP: Pick image from camera/gallery
    IP-->>HS: Selected image file
    U->>HS: Tap "Analyze Image"
    HS->>HS: Show progress indicator
    HS->>SAM2: POST /api/segment/ (multipart)
    SAM2->>SAM2: Process with SAM2 model
    SAM2-->>HS: Segmented image data
    HS->>HS: Generate mock CNN analysis
    HS->>AS: saveAnalysisResult()
    AS->>FS: Save to user's analyses collection
    FS-->>AS: Success
    AS-->>HS: Analysis saved
    HS->>HS: Hide progress indicator
    HS->>U: Display analysis results
```

## 3. Admin User Approval Sequence

```mermaid
sequenceDiagram
    participant A as Admin
    participant AD as AdminDashboard
    participant AS as AuthService
    participant FS as Firestore
    participant U as Pending User

    A->>AD: Open admin dashboard
    AD->>AS: getPendingRegistrations()
    AS->>FS: Query users with status='pending'
    FS-->>AS: Stream of pending users
    AS-->>AD: Display pending users list
    A->>AD: Click approve/deny button
    AD->>AS: updateUserStatus(userId, approve)
    AS->>FS: Update user document
    FS-->>AS: Success
    AS-->>AD: Status updated
    AD->>U: User can now access app (if approved)
```

## 4. Authentication State Management Sequence

```mermaid
sequenceDiagram
    participant App as AnesthesiaSafeApp
    participant AW as AuthWrapper
    participant AS as AuthService
    participant FA as FirebaseAuth
    participant FS as Firestore

    App->>AW: Initialize app
    AW->>AS: Listen to authStateChanges
    AS->>FA: authStateChanges stream
    FA-->>AS: User auth state
    AS-->>AW: Auth state update
    
    alt User is authenticated
        AW->>AS: getUserData(uid)
        AS->>FS: Get user document
        FS-->>AS: User data
        AS-->>AW: User data with role/status
        
        alt User is admin
            AW->>AW: Route to AdminDashboard
        else User is approved
            AW->>AW: Route to HomeScreen
        else User is pending
            AW->>AW: Route to PendingScreen
        else User is denied
            AW->>AS: signOut()
            AW->>AW: Route to SignInScreen
        end
    else User not authenticated
        AW->>AW: Route to SignInScreen
    end
```

## 5. Error Handling Sequence

```mermaid
sequenceDiagram
    participant U as User
    participant UI as UI Component
    participant S as Service Layer
    participant API as External API
    participant EH as Error Handler

    U->>UI: Perform action
    UI->>S: Call service method
    S->>API: Make API request
    API-->>S: Error response
    S->>EH: Handle exception
    EH->>EH: Log error details
    EH->>EH: Generate user-friendly message
    EH-->>S: Formatted error
    S-->>UI: Error result
    UI->>U: Show error snackbar/dialog
```