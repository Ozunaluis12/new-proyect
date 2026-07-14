import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';

/// Pantalla profesional de inicio de sesión con validaciones y diseño moderno.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _mostrarPassword = false;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida y envía el formulario de login
  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.login(
      _correoController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (exito) {
      final isAdmin = auth.usuario?.rol.toLowerCase() == 'administrador';
      Navigator.pushReplacementNamed(context, isAdmin ? '/admin' : '/home');
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Error al iniciar sesión'),
          backgroundColor: LoginovaColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: LoginovaColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 40,
              vertical: 20,
            ),
            child: SizedBox(
              height: size.height - 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo y Título
                  _buildHeader(),
                  SizedBox(height: isMobile ? 40 : 50),

                  // Formulario
                  _buildLoginForm(),

                  SizedBox(height: isMobile ? 30 : 40),

                  // Links adicionales
                  _buildAdditionalLinks(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el encabezado con logo y título
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LoginovaColors.primary, LoginovaColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: LoginovaColors.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'LOGINOVA',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: LoginovaColors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gestión Logística Profesional',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: LoginovaColors.textSecondary),
        ),
      ],
    );
  }

  /// Construye el formulario de login
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Campo de correo
          TextFormField(
            controller: _correoController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico',
              hintText: 'tu@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              prefixIconColor: LoginovaColors.primary,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu correo';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                return 'Por favor ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo de contraseña
          TextFormField(
            controller: _passwordController,
            obscureText: !_mostrarPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _iniciarSesion(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outlined),
              prefixIconColor: LoginovaColors.primary,
              suffixIcon: IconButton(
                icon: Icon(
                  _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                  color: LoginovaColors.textSecondary,
                ),
                onPressed: () =>
                    setState(() => _mostrarPassword = !_mostrarPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa tu contraseña';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Botón de inicio de sesión
          _buildLoginButton(),
        ],
      ),
    );
  }

  /// Construye el botón de inicio de sesión con estado de carga
  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: auth.cargando ? null : _iniciarSesion,
            child: auth.cargando
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Iniciar Sesión',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }

  /// Construye los links adicionales (olvidé contraseña, registrarse)
  Widget _buildAdditionalLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/forgot'),
          icon: const Icon(Icons.help_outline),
          label: const Text('¿Olvidaste tu contraseña?'),
        ),
        const Text('•', style: TextStyle(color: LoginovaColors.textSecondary)),
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/register'),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Registrarse'),
        ),
      ],
    );
  }
}
