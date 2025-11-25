
import 'package:sales_management_app/data/datasources/api_client.dart';
import 'package:sales_management_app/data/datasources/local_storage.dart';
import 'package:sales_management_app/domain/entities/user.dart';
import 'package:sales_management_app/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;
  final LocalStorage localStorage;

  AuthRepositoryImpl({required this.apiClient, required this.localStorage});

  @override
  Future<User> login(String username, String password) async {
    try {
      final response = await apiClient.post('/api/login', {
        'username': username,
        'password': password,
      });
      
      final user = User.fromJson(response);
      await localStorage.saveUser(user.toJson());
      return user;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    await localStorage.clear();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localStorage.isLoggedIn();
  }

  @override
  Future<User?> getCurrentUser() async {
    final userData = await localStorage.getUser();
    if (userData != null) {
      return User(
        id: userData['id'],
        name: userData['name'],
        token: userData['token'],
      );
    }
    return null;
  }
}