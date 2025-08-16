# AnesthesiaSafe - System Architecture Overview

```mermaid
graph TB
    %% Client Layer
    subgraph "Client Layer (Flutter)"
        UI[User Interface]
        Widgets[Custom Widgets]
        Screens[Screen Components]
        Services[Client Services]
    end

    %% Business Logic Layer
    subgraph "Business Logic Layer"
        AuthLogic[Authentication Logic]
        ImageLogic[Image Processing Logic]
        UserLogic[User Management Logic]
        ValidationLogic[Validation Logic]
    end

    %% Data Layer
    subgraph "Data Layer"
        AuthService[Auth Service]
        UserRepo[User Repository]
        AnalysisRepo[Analysis Repository]
        LocalStorage[Local Storage]
    end

    %% External Services
    subgraph "External Services"
        Firebase[Firebase Services]
        SAM2[SAM2 API Server]
        ImagePicker[Device Camera/Gallery]
    end

    %% Firebase Components
    subgraph "Firebase Services"
        FireAuth[Firebase Auth]
        Firestore[Cloud Firestore]
        FireStorage[Firebase Storage]
    end

    %% SAM2 Processing
    subgraph "AI Processing Pipeline"
        SAM2Server[SAM2 Django Server]
        SAM2Model[SAM2 Model]
        ImageSegmentation[Image Segmentation]
        CNNAnalysis[CNN Analysis Mock]
    end

    %% Data Flow
    UI --> Screens
    Screens --> Widgets
    Widgets --> Services
    Services --> AuthLogic
    Services --> ImageLogic
    Services --> UserLogic

    AuthLogic --> AuthService
    ImageLogic --> AnalysisRepo
    UserLogic --> UserRepo

    AuthService --> FireAuth
    UserRepo --> Firestore
    AnalysisRepo --> Firestore
    LocalStorage --> SharedPreferences[Shared Preferences]

    ImageLogic --> SAM2Server
    SAM2Server --> SAM2Model
    SAM2Model --> ImageSegmentation
    ImageSegmentation --> CNNAnalysis

    Services --> ImagePicker
    
    %% Styling
    classDef client fill:#e3f2fd,stroke:#1976d2,stroke-width:2px
    classDef business fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    classDef data fill:#e8f5e8,stroke:#388e3c,stroke-width:2px
    classDef external fill:#fff3e0,stroke:#f57c00,stroke-width:2px
    classDef firebase fill:#ffebee,stroke:#d32f2f,stroke-width:2px
    classDef ai fill:#f1f8e9,stroke:#689f38,stroke-width:2px

    class UI,Widgets,Screens,Services client
    class AuthLogic,ImageLogic,UserLogic,ValidationLogic business
    class AuthService,UserRepo,AnalysisRepo,LocalStorage data
    class Firebase,SAM2,ImagePicker external
    class FireAuth,Firestore,FireStorage firebase
    class SAM2Server,SAM2Model,ImageSegmentation,CNNAnalysis ai
```

## Architecture Patterns Used

### 1. **Repository Pattern**
- `UserRepository` and `AnalysisRepository` abstract data access
- Provides clean separation between business logic and data persistence
- Enables easy testing and data source switching

### 2. **Service Layer Pattern**
- `AuthService` handles all authentication-related operations
- `ImageAnalysisService` manages image processing workflow
- `UserManagementService` handles user administration

### 3. **Widget Composition**
- Modular widget architecture with reusable components
- Clear separation of concerns between UI and business logic
- Custom widgets for consistent design patterns

### 4. **State Management**
- StatefulWidget for local component state
- StreamBuilder for real-time Firebase data
- FutureBuilder for asynchronous operations

### 5. **Error Handling Strategy**
- Custom exception hierarchy for different error types
- Centralized error handling in service layer
- User-friendly error messages in UI layer

## Data Flow Architecture

1. **Authentication Flow**
   - User input → AuthService → Firebase Auth → User Repository → Firestore
   - Real-time auth state changes propagated through streams

2. **Image Analysis Flow**
   - Image selection → Image validation → SAM2 API → Image segmentation
   - Mock CNN analysis → Results storage → UI display

3. **User Management Flow**
   - Admin actions → UserManagementService → User Repository → Firestore
   - Real-time updates via Firestore streams

## Security Architecture

- **Authentication**: Firebase Auth with email/password
- **Authorization**: Role-based access control (admin/user/pending)
- **Data Security**: Firestore security rules and RLS
- **Input Validation**: Client and server-side validation
- **Error Handling**: Secure error messages without sensitive data exposure