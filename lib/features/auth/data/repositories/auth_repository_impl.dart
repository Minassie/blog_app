import 'package:blog_app/core/error/exceptions.dart';
import 'package:blog_app/core/error/failures.dart';
import 'package:blog_app/core/network/connection_checker.dart';
import 'package:blog_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:blog_app/core/common/entities/user.dart';
import 'package:blog_app/features/auth/data/models/user_model.dart';
import 'package:blog_app/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ConnectionChecker connectionChecker;
  const AuthRepositoryImpl(this.remoteDataSource, this.connectionChecker);

  @override
  Future<Either<Failure, User>> currentUser() async {
    try {
      if (!await connectionChecker.isConnected) {
        final user = remoteDataSource.currentUser;
        if (user == null) {
          return left(const Failure('User not logged in'));
        }
        return right(
          UserModel(
            id: user.uid,
            email: user.email ?? '',
            name: '',
          ),
        );
      }
      final user = await remoteDataSource.getCurrentUser();
      if (user == null) {
        return left(const Failure('User not logged in'));
      }
      return right(user);
    } on fb.FirebaseAuthException catch (e) {
      return left(Failure(e.message ?? 'Authentication error'));
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, User>> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => remoteDataSource.loginWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => remoteDataSource.signUpWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  Future<Either<Failure, User>> _getUser(Future<User> Function() fn) async {
    try {
      if (!await connectionChecker.isConnected) {
        return left(const Failure('No internet connection'));
      }
      final user = await fn();
      return right(user);
    } on fb.FirebaseAuthException catch (e) {
      return left(Failure(e.message ?? 'Authentication error'));
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}