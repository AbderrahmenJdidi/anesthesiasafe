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
      print('[AuthService] Signing in: $email');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update lastLoginAt
      await _firestore.collection('users').doc(result.user!.uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Check user status
      DocumentSnapshot userDoc = await getUserData(result.user!.uid);
      if (userDoc.exists && userDoc['status'] == 'pending') {
        throw 'Your account is pending approval. Please wait for admin approval.';
      }
      if (userDoc.exists && userDoc['status'] == 'denied') {
        throw 'Your account has been denied. Please contact support.';
      }
      print('[AuthService] Sign-in successful: $email');
      return result;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Sign-in error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] General sign-in error: $e');
      throw 'Failed to sign in: $e';
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
      String email, String password, String fullName, String specialty) async {
    try {
      print('[AuthService] Registering: $email');
      if (Firebase.apps.isEmpty) {
        throw 'Firebase is not initialized. Please check your Firebase configuration.';
      }
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('[AuthService] Firebase Auth registration successful: $email');
      if (result.user != null) {
        await _createUserDocument(result.user!, fullName, specialty);
        print('[AuthService] User document created: $email');
      }
      return result;
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Firebase Auth error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      print('[AuthService] Firebase error: ${e.code} - ${e.message}');
      throw 'Firebase error: ${e.message ?? 'Unknown Firebase error'}';
    } catch (e) {
      print('[AuthService] General registration error: $e');
      throw 'Registration failed: $e';
    }
  }

  // Create user document in Firestore with pending status
  Future<void> _createUserDocument(User user, String fullName, String specialty) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'fullName': fullName,
        'specialty': specialty,
        'role': 'pending',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[AuthService] User document created: ${user.email}');
    } catch (e) {
      print('[AuthService] Error creating user document: $e');
      throw 'Failed to create user profile: $e';
    }
  }

  // Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      print('[AuthService] Fetching user data: $uid');
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      print('[AuthService] Error fetching user data: $e');
      throw 'Failed to fetch user data: $e';
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String specialty,
  }) async {
    try {
      print('[AuthService] Updating profile: $uid');
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        'specialty': specialty,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[AuthService] Profile updated: $uid');
    } catch (e) {
      print('[AuthService] Error updating profile: $e');
      throw 'Failed to update profile: $e';
    }
  }

  // Save analysis result
  Future<void> saveAnalysisResult(Map<String, dynamic> result) async {
    try {
      if (currentUser == null) {
        throw 'No authenticated user';
      }
      print('[AuthService] Saving analysis result: ${currentUser!.uid}');
      DocumentSnapshot userDoc = await getUserData(currentUser!.uid);
      if (userDoc.exists && userDoc['status'] != 'approved') {
        throw 'Cannot save analysis: Account not approved.';
      }
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('analyses')
          .add({
        ...result,
        'timestamp': FieldValue.serverTimestamp(),
        'user_id': currentUser!.uid, // Aligned with Django views.py
      });
      print('[AuthService] Analysis result saved: ${currentUser!.uid}');
    } catch (e) {
      print('[AuthService] Error saving analysis result: $e');
      throw 'Failed to save analysis result: $e';
    }
  }

  // Get user's analysis history
  Stream<QuerySnapshot> getUserAnalyses() {
    if (currentUser != null) {
      print('[AuthService] Fetching analysis history: ${currentUser!.uid}');
      return _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('analyses')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
    print('[AuthService] No authenticated user for analysis history');
    return const Stream.empty();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('[AuthService] Signing out: ${currentUser?.uid}');
      await _auth.signOut();
      print('[AuthService] Sign out successful');
    } catch (e) {
      print('[AuthService] Sign out error: $e');
      throw 'Failed to sign out: $e';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      print('[AuthService] Sending password reset email: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('[AuthService] Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print('[AuthService] Password reset error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('[AuthService] General password reset error: $e');
      throw 'Failed to send password reset email: $e';
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    if (currentUser == null) {
      print('[AuthService] No authenticated user for admin check');
      return false;
    }
    try {
      print('[AuthService] Checking admin status: ${currentUser!.uid}');
      DocumentSnapshot userDoc = await getUserData(currentUser!.uid);
      return userDoc.exists && userDoc['role'] == 'admin';
    } catch (e) {
      print('[AuthService] Error checking admin status: $e');
      return false;
    }
  }

  // Get pending registrations for admin
  Stream<QuerySnapshot> getPendingRegistrations() {
    print('[AuthService] Fetching pending registrations');
    return _firestore
        .collection('users')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Admin approves or denies user registration
  Future<void> updateUserStatus({
    required String userId,
    required bool approve,
  }) async {
    try {
      print('[AuthService] Updating user status: $userId, approve: $approve');
      if (approve) {
        await _firestore.collection('users').doc(userId).update({
          'role': 'user',
          'status': 'approved',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('[AuthService] User approved: $userId');
      } else {
        await _firestore.collection('users').doc(userId).update({
          'role': 'denied',
          'status': 'denied',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('[AuthService] User denied: $userId');
      }
    } catch (e) {
      print('[AuthService] Error updating user status: $e');
      throw 'Failed to update user status: $e';
    }
  }

  // Create an admin user
  Future<void> createAdmin({
    required String email,
    required String password,
    required String fullName,
    required String specialty,
  }) async {
    try {
      print('[AuthService] Creating admin: $email');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection('users').doc(result.user!.uid).set({
        'uid': result.user!.uid,
        'email': email,
        'fullName': fullName,
        'specialty': specialty,
        'role': 'admin',
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('[AuthService] Admin created: $email');
    } catch (e) {
      print('[AuthService] Error creating admin: $e');
      throw 'Failed to create admin user: $e';
    }
  }

  // Delete user account
  Future<void> deleteAccount(String uid) async {
    try {
      print('[AuthService] Deleting account: $uid');
      await _firestore.collection('users').doc(uid).delete();
      if (currentUser != null && currentUser!.uid == uid) {
        await currentUser!.delete();
      }
      print('[AuthService] Account deleted: $uid');
    } catch (e) {
      print('[AuthService] Error deleting account: $e');
      throw 'Failed to delete account: $e';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    print('[AuthService] Firebase Auth error: ${e.code} - ${e.message}');
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
        return 'Authentication failed: ${e.message ?? e.code}.';
    }
  }
}