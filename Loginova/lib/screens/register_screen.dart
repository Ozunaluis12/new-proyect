import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';

/// Pantalla profesional de registro para crear un nuevo usuario en el sistema.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// Estado de [RegisterScreen]: controla el formulario de alta de usuario y
/// llama a [AuthProvider.register]. El backend crea toda cuenta nueva con
/// rol Operador por defecto (los demás roles se asignan luego desde
/// administración).
class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Valida y envía el formulario de registro
  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: LoginovaColors.error,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.register(
      _nombreController.text.trim(),
      _correoController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (exito) {
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? 'Error al registrar'),
        backgroundColor: LoginovaColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: LoginovaColors.background,
      appBar: AppBar(title: const Text('Crear Cuenta'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40,
            vertical: 20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                _buildHeader(),
                const SizedBox(height: 40),

                // Formulario
                _buildRegisterForm(),
                const SizedBox(height: 32),

                // Botones de acción
                _buildActionButtons(),
                const SizedBox(height: 16),

                Text(
                  'Todos los registros nuevos se crean con rol Operador.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: LoginovaColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Link a login
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el encabezado
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crear tu Cuenta',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: LoginovaColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          'Únete a Loginova y comienza a gestionar tus recogidas',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: LoginovaColors.textSecondary),
        ),
      ],
    );
  }

  /// Construye el formulario de registro
  Widget _buildRegisterForm() {
    return Column(
      children: [
        // Campo de nombre
        TextFormField(
          controller: _nombreController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Nombre Completo',
            hintText: 'Tu nombre completo',
            prefixIcon: const Icon(Icons.person_outline),
            prefixIconColor: LoginovaColors.primary,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa tu nombre';
            }
            if (value.length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Campo de correo
        TextFormField(
          controller: _correoController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
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
          textInputAction: TextInputAction.next,
          obscureText: !_mostrarPassword,
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
              return 'Por favor ingresa una contraseña';
            }
            if (value.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Campo de confirmación de contraseña
        TextFormField(
          controller: _confirmPasswordController,
          textInputAction: TextInputAction.done,
          obscureText: !_mostrarConfirmPassword,
          onFieldSubmitted: (_) => _registrar(),
          decoration: InputDecoration(
            labelText: 'Confirmar Contraseña',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined),
            prefixIconColor: LoginovaColors.primary,
            suffixIcon: IconButton(
              icon: Icon(
                _mostrarConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: LoginovaColors.textSecondary,
              ),
              onPressed: () => setState(
                () => _mostrarConfirmPassword = !_mostrarConfirmPassword,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor confirma tu contraseña';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Construye los botones de acción
  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: auth.cargando ? null : _registrar,
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
                    'Crear Cuenta',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        );
      },
    );
  }

  /// Construye el link a login
  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '¿Ya tienes cuenta? ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LoginovaColors.textSecondary,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Inicia Sesión'),
          ),
        ],
      ),
    );
  }
}
