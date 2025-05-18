import 'package:blog_app/core/error/exceptions.dart';
import 'package:blog_app/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract interface class AuthRemoteDataSource {
  User? get currentUser;
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  });

  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<UserModel?> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  AuthRemoteDataSourceImpl(this.firebaseAuth, this.firestore);

  @override
  User? get currentUser => firebaseAuth.currentUser;

  @override
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const ServerException('User is null');
      }
      // Fetch user profile from Firestore
      final userDoc = await firestore.collection('profiles').doc(user.uid).get();
      if (!userDoc.exists) {
        throw const ServerException('User profile not found');
      }
      return UserModel.fromJson({
        'id': user.uid,
        'email': user.email,
        'name': userDoc.data()?['name'] ?? '',
      });
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Authentication error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user == null) {
        throw const ServerException('User is null');
      }
      // Store user profile in Firestore
      await firestore.collection('profiles').doc(user.uid).set({
        'name': name,
        'email': email,
      });
      return UserModel(
        id: user.uid,
        email: user.email ?? email,
        name: name,
      );
    } on FirebaseAuthException catch (e) {
      throw ServerException(e.message ?? 'Authentication error');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user != null) {
        final userDoc = await firestore.collection('profiles').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromJson({
            'id': user.uid,
            'email': user.email,
            'name': userDoc.data()?['name'] ?? '',
          });
        }
      }
      return null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}