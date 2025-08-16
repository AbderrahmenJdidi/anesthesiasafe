import 'package:anesthesia_safe/screens/auth/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';
import 'auth/pending_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SignInScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: AuthService().getUserData(snapshot.data!.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                ),
              );
            }

            if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const SignInScreen();
            }

            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
            String status = userData['status'];
            String role = userData['role'];

            if (status == 'pending') {
              return PendingScreen();
            } else if (status == 'denied') {
              AuthService().signOut();
              return const SignInScreen();
            } else if (role == 'admin') {
              return const AdminDashboard();
            } else {
              return const HomeScreen();
            }
          },
        );
      },
    );
  }
}