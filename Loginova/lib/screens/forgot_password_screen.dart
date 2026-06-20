import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';

/// Pantalla profesional para restablecer la contraseña de un usuario registrado.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Valida y envía el formulario de restablecimiento
  Future<void> _restablecer() async {
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
    final exito = await auth.resetPassword(
      _correoController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña restablecida exitosamente'),
          backgroundColor: LoginovaColors.success,
        ),
      );
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? 'No se pudo restablecer la contraseña'),
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
      appBar: AppBar(
        title: const Text('Restablecer Contraseña'),
        elevation: 0,
      ),
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
                const SizedBox(height: 20),

                // Encabezado
                _buildHeader(),
                const SizedBox(height: 40),

                // Formulario
                _buildForm(),
                const SizedBox(height: 32),

                // Botones de acción
                _buildActionButtons(),
                const SizedBox(height: 16),

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
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: LoginovaColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.lock_reset,
            color: LoginovaColors.warning,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Restablecer tu contraseña',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: LoginovaColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu correo y define una nueva contraseña',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: LoginovaColors.textSecondary,
              ),
        ),
      ],
    );
  }

  /// Construye el formulario
  Widget _buildForm() {
    return Column(
      children: [
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

        // Campo de nueva contraseña
        TextFormField(
          controller: _passwordController,
          textInputAction: TextInputAction.next,
          obscureText: !_mostrarPassword,
          decoration: InputDecoration(
            labelText: 'Nueva Contraseña',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined),
            prefixIconColor: LoginovaColors.primary,
            suffixIcon: IconButton(
              icon: Icon(
                _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                color: LoginovaColors.textSecondary,
              ),
              onPressed: () => setState(
                () => _mostrarPassword = !_mostrarPassword,
              ),
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
          onFieldSubmitted: (_) => _restablecer(),
          decoration: InputDecoration(
            labelText: 'Confirmar Nueva Contraseña',
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outlined),
            prefixIconColor: LoginovaColors.primary,
            suffixIcon: IconButton(
              icon: Icon(
                _mostrarConfirmPassword ? Icons.visibility : Icons.visibility_off,
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
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: auth.cargando ? null : _restablecer,
                child: auth.cargando
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Restablecer Contraseña',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ),
          ],
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
            '¿Recuerdas tu contraseña? ',
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ingresa tu correo y una nueva contraseña.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!value.contains('@')) {
                    return 'Correo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una contraseña';
                  }
                  if (value.length < 8) {
                    return 'La contraseña debe tener al menos 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.cargando ? null : restablecer,
                      child: Text(
                        auth.cargando
                            ? 'Restableciendo...'
                            : 'Restablecer contraseña',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                child: const Text('Volver al login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
