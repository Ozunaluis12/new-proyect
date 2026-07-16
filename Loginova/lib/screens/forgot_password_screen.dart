import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';

/// Pantalla de recuperación de contraseña en dos pasos: primero se solicita
/// un código por correo, luego se verifica ese código y se define la nueva
/// contraseña.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

enum _PasoRecuperacion { correo, codigo }

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKeyCorreo = GlobalKey<FormState>();
  final _formKeyCodigo = GlobalKey<FormState>();

  final _correoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _PasoRecuperacion _paso = _PasoRecuperacion.correo;
  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;

  @override
  void dispose() {
    _correoController.dispose();
    _codigoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Paso 1 del flujo: pide al backend que envíe un código de 6 dígitos al
  /// correo ingresado. Si tiene éxito, avanza al paso 2. El mensaje de éxito
  /// es intencionalmente genérico ("si el correo está registrado...") para
  /// no revelar si ese correo existe o no en el sistema.
  Future<void> _solicitarCodigo() async {
    if (!_formKeyCorreo.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.solicitarCodigoRecuperacion(
      _correoController.text.trim(),
    );

    if (!mounted) return;

    if (exito) {
      setState(() => _paso = _PasoRecuperacion.codigo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Si el correo está registrado, te enviamos un código de recuperación.',
          ),
          backgroundColor: LoginovaColors.success,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? 'No se pudo enviar el código'),
        backgroundColor: LoginovaColors.error,
      ),
    );
  }

  /// Paso 2 del flujo: valida que las dos contraseñas coincidan y envía el
  /// código de 6 dígitos junto con la nueva contraseña al backend, que
  /// verifica el código antes de aplicar el cambio.
  Future<void> _restablecer() async {
    if (!_formKeyCodigo.currentState!.validate()) return;

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
      _codigoController.text.trim(),
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
      appBar: AppBar(title: const Text('Restablecer Contraseña'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 40),
              if (_paso == _PasoRecuperacion.correo)
                _buildPasoCorreo()
              else
                _buildPasoCodigo(),
              const SizedBox(height: 16),
              _buildLoginLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final esPasoCorreo = _paso == _PasoRecuperacion.correo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: LoginovaColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            esPasoCorreo ? Icons.lock_reset : Icons.mark_email_read_outlined,
            color: LoginovaColors.warning,
            size: 30,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          esPasoCorreo ? 'Restablecer tu contraseña' : 'Ingresa el código',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: LoginovaColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          esPasoCorreo
              ? 'Ingresa tu correo y te enviaremos un código de recuperación'
              : 'Revisa tu correo (${_correoController.text.trim()}) e ingresa el código de 6 dígitos junto con tu nueva contraseña',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: LoginovaColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPasoCorreo() {
    return Form(
      key: _formKeyCorreo,
      child: Column(
        children: [
          TextFormField(
            controller: _correoController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.emailAddress,
            onFieldSubmitted: (_) => _solicitarCodigo(),
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
          const SizedBox(height: 32),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.cargando ? null : _solicitarCodigo,
                  child: auth.cargando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Enviar código',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasoCodigo() {
    return Form(
      key: _formKeyCodigo,
      child: Column(
        children: [
          TextFormField(
            controller: _codigoController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Código de recuperación',
              hintText: '123456',
              counterText: '',
              prefixIcon: Icon(Icons.pin_outlined),
              prefixIconColor: LoginovaColors.primary,
            ),
            validator: (value) {
              if (value == null || value.trim().length != 6) {
                return 'Ingresa el código de 6 dígitos que te enviamos';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
                onPressed: () =>
                    setState(() => _mostrarPassword = !_mostrarPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingresa una contraseña';
              }
              if (value.length < 8) {
                return 'La contraseña debe tener al menos 8 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 32),
          Consumer<AuthProvider>(
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
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
                      onPressed: auth.cargando
                          ? null
                          : () => setState(() {
                              _paso = _PasoRecuperacion.correo;
                              _codigoController.clear();
                            }),
                      child: const Text('Usar otro correo'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

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
