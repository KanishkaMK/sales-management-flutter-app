import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sales_management_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:sales_management_app/presentation/viewmodels/login_viewmodel.dart';

class LoginPage extends StatelessWidget {
  final LoginViewModel viewModel;

  const LoginPage({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sales Management',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 32),
                _LoginForm(viewModel: viewModel, state: state),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoginForm extends StatefulWidget {
  final LoginViewModel viewModel;
  final AuthState state;

  const _LoginForm({required this.viewModel, required this.state});

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter username';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          widget.state is AuthLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.viewModel.login(
                        _usernameController.text,
                        _passwordController.text,
                      );
                    }
                  },
                  child: const Text('Login'),
                ),
        ],
      ),
    );
  }
}