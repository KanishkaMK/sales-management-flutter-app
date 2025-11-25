import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management_app/data/datasources/api_client.dart';
import 'package:sales_management_app/data/datasources/local_storage.dart';
import 'package:sales_management_app/data/repositories/auth_repository_impl.dart';
import 'package:sales_management_app/domain/repositories/auth_repository.dart';
import 'package:sales_management_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:sales_management_app/presentation/pages/login_page.dart';
import 'package:sales_management_app/presentation/viewmodels/login_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>(
          create: (context) => ApiClient(),
        ),
        RepositoryProvider<LocalStorage>(
          create: (context) => LocalStorage(),
        ),
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            apiClient: RepositoryProvider.of<ApiClient>(context),
            localStorage: RepositoryProvider.of<LocalStorage>(context),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            )..add(CheckAuthStatusEvent()),
          ),
        ],
        child: MaterialApp(
          title: 'Sales Management',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const AppWrapper(),
        ),
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final authBloc = BlocProvider.of<AuthBloc>(context);
        
        if (state is AuthAuthenticated) {
          // Return your main dashboard here
          return const DashboardPlaceholder();
        }
        
        // Show login page
        final viewModel = LoginViewModel(authBloc: authBloc);
        return LoginPage(viewModel: viewModel);
      },
    );
  }
}

// Temporary placeholder for dashboard
class DashboardPlaceholder extends StatelessWidget {
  const DashboardPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              BlocProvider.of<AuthBloc>(context).add(LogoutEvent());
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Welcome to Sales Management App!'),
      ),
    );
  }
}