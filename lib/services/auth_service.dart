import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String fullName, String specialty) async {
    try {
      print('Starting Firebase Auth registration...');
      
      // Check if Firebase is properly initialized
      if (Firebase.apps.isEmpty) {
        throw 'Firebase is not initialized. Please check your Firebase configuration.';
      }
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('Firebase Auth registration successful for: $email');

      // Create user document in Firestore
      if (result.user != null) {
        print('Creating user document in Firestore...');
        await _createUserDocument(result.user!, fullName, specialty);
        print('User document created successfully');
      }
      
      return result;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      print('Firebase Exception: ${e.code} - ${e.message}');
      throw 'Firebase error: ${e.message ?? 'Unknown Firebase error'}';
    } catch (e) {
      print('General Exception during registration: $e');
      throw e.toString();
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String fullName, String specialty) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fullName': fullName,
        'specialty': specialty,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      print('User document created successfully for ${user.email}');
    } catch (e) {
      print('Error creating user document: $e');
      throw 'Failed to create user profile. Please try again.';
    }
  }

  // Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Save analysis result
  Future<void> saveAnalysisResult(Map<String, dynamic> result) async {
    if (currentUser != null) {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('analyses')
          .add({
        ...result,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser!.uid,
      });
    }
  }

  // Get user's analysis history
  Stream<QuerySnapshot> getUserAnalyses() {
    if (currentUser != null) {
      return _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('analyses')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    return const Stream.empty();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Starting sign out process...');
      await _auth.signOut();
      print('Sign out successful');
    } catch (e) {
      print('Sign out error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    print('Handling Firebase Auth Exception: ${e.code}');
    switch (e.code) {
      case 'configuration-not-found':
        return 'Firebase configuration not found. Please check your Firebase setup.';
      case 'project-not-found':
        return 'Firebase project not found. Please verify your project configuration.';
      case 'invalid-api-key':
        return 'Invalid Firebase API key. Please check your configuration.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      default:
        return 'Authentication failed: ${e.message ?? e.code}. Please try again.';
    }
  }
}