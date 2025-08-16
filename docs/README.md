# AnesthesiaSafe - UML Documentation

This directory contains comprehensive UML diagrams for the AnesthesiaSafe application, a Flutter-based medical assessment tool for pediatric anesthesia safety.

## 📋 Diagram Overview

### 1. [Use Case Diagram](./uml/use_case_diagram.md)
- **Purpose**: Shows the functional requirements and user interactions
- **Actors**: Medical Professionals, Admins, AI System
- **Key Use Cases**: 
  - User registration and authentication
  - Image upload and analysis
  - Safety assessment generation
  - Admin user management

### 2. [Frontend Class Diagram](./uml/frontend_class_detailed.md)
- **Purpose**: Detailed view of Flutter application architecture
- **Components**:
  - Screen classes (HomeScreen, AccountScreen, etc.)
  - Widget components (CustomAppBar, UploadSectionWidget, etc.)
  - Service classes (AuthService)
  - Authentication flow components

### 3. [Backend Class Diagram](./uml/backend_class_diagram.md)
- **Purpose**: Shows backend services and data management
- **Components**:
  - Firebase services integration
  - Repository pattern implementation
  - Data models and DTOs
  - External API services (SAM2)
  - Error handling hierarchy

### 4. [System Architecture](./uml/system_architecture.md)
- **Purpose**: High-level system overview
- **Layers**:
  - Client Layer (Flutter UI)
  - Business Logic Layer
  - Data Layer (Repositories)
  - External Services (Firebase, SAM2 API)

### 5. [Sequence Diagrams](./uml/sequence_diagrams.md)
- **Purpose**: Shows interaction flows for key processes
- **Scenarios**:
  - User registration and approval
  - Image analysis workflow
  - Authentication state management
  - Error handling patterns

### 6. [Database Schema](./uml/database_schema.md)
- **Purpose**: Firestore database structure and relationships
- **Collections**:
  - Users collection with role-based access
  - Analyses subcollection for user history
  - System logs and app settings
  - Security rules and indexing strategy

## 🏗️ Architecture Highlights

### **Clean Architecture Principles**
- **Separation of Concerns**: UI, business logic, and data layers are clearly separated
- **Dependency Inversion**: Services depend on abstractions, not concrete implementations
- **Single Responsibility**: Each class has a focused, well-defined purpose

### **Design Patterns Used**
- **Repository Pattern**: Data access abstraction
- **Service Layer Pattern**: Business logic encapsulation
- **Observer Pattern**: Real-time data updates via streams
- **Factory Pattern**: Widget creation and configuration
- **State Pattern**: Authentication state management

### **Security Architecture**
- **Role-Based Access Control**: Admin, user, pending, denied roles
- **Firebase Security Rules**: Document-level access control
- **Input Validation**: Multi-layer validation strategy
- **Secure Authentication**: Firebase Auth integration

### **Scalability Considerations**
- **Modular Widget Architecture**: Easy to extend and maintain
- **Stream-Based Updates**: Real-time data synchronization
- **External API Integration**: Scalable AI processing pipeline
- **Cloud-Native Design**: Firebase backend for automatic scaling

## 🔄 Key Workflows

1. **User Onboarding**: Registration → Admin Approval → Account Activation
2. **Image Analysis**: Upload → SAM2 Processing → Safety Assessment → Results Storage
3. **Admin Management**: Dashboard → User Review → Approval/Denial → Notification
4. **Data Persistence**: Local State → Service Layer → Repository → Firebase

## 📱 Mobile-First Design

- **Responsive UI**: Adapts to different screen sizes
- **Touch-Optimized**: Gesture-friendly interface design
- **Offline Capability**: Local storage for critical data
- **Performance**: Optimized image handling and processing

This documentation provides a complete architectural overview of the AnesthesiaSafe application, suitable for developers, stakeholders, and system architects.