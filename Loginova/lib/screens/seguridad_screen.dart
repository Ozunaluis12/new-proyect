import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../themes/app_theme.dart';
import '../widgets/menu_drawer.dart';

/// Pantalla donde un usuario YA autenticado cambia su propia contraseña.
/// Reutiliza el mismo flujo de dos pasos (código por correo + nueva
/// contraseña) que [ForgotPasswordScreen], porque el backend no expone un
/// endpoint de "cambiar contraseña sabiendo la actual": aquí también se pide
/// verificar por código en vez de pedir la contraseña vieja.
class SeguridadScreen extends StatefulWidget {
  const SeguridadScreen({super.key});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _mostrarPassword = false;
  bool _mostrarConfirm = false;
  bool _codigoEnviado = false;

  /// Precarga el correo del usuario logueado en el campo de correo (una
  /// sola vez) para que no tenga que volver a escribirlo, ya que el cambio
  /// de contraseña siempre es sobre la cuenta propia.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_correoController.text.isEmpty) {
      final correo = Provider.of<AuthProvider>(
        context,
        listen: false,
      ).usuario?.correo;
      if (correo != null) {
        _correoController.text = correo;
      }
    }
  }

  @override
  void dispose() {
    _correoController.dispose();
    _codigoController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Solicita al backend el envío del código de verificación por correo
  /// (paso 1 del flujo de recuperación, reutilizado aquí como confirmación
  /// de identidad para el cambio de contraseña).
  Future<void> _enviarCodigo() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.solicitarCodigoRecuperacion(
      _correoController.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      setState(() => _codigoEnviado = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te enviamos un código de verificación al correo'),
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

  /// Valida el código recibido por correo y la nueva contraseña, y llama a
  /// [AuthProvider.resetPassword] (mismo endpoint que "olvidé mi
  /// contraseña") para completar el cambio.
  Future<void> _actualizarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: LoginovaColors.error,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.resetPassword(
      _correoController.text.trim(),
      _codigoController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      _codigoController.clear();
      _passwordController.clear();
      _confirmController.clear();
      setState(() => _codigoEnviado = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: LoginovaColors.success,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(auth.error ?? 'No se pudo actualizar la contraseña'),
        backgroundColor: LoginovaColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuDrawer(currentRoute: '/seguridad'),
      appBar: AppBar(title: const Text('Seguridad')),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actualizar contraseña',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codigoEnviado
                          ? 'Ingresa el código que enviamos a tu correo y tu nueva contraseña.'
                          : 'Te enviaremos un código de verificación a tu correo para confirmar el cambio.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _correoController,
                      enabled: !_codigoEnviado,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un correo';
                        }
                        return null;
                      },
                    ),
                    if (!_codigoEnviado) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: auth.cargando ? null : _enviarCodigo,
                          icon: auth.cargando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: const Text('Enviar código'),
                        ),
                      ),
                    ],
                    if (_codigoEnviado) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codigoController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Código de verificación',
                        counterText: '',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length != 6) {
                          return 'Ingresa el código de 6 dígitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_mostrarPassword,
                      decoration: InputDecoration(
                        labelText: 'Nueva contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _mostrarPassword = !_mostrarPassword,
                            );
                          },
                          icon: Icon(
                            _mostrarPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa una contraseña';
                        }
                        if (value.length < 6) {
                          return 'Debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: !_mostrarConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _mostrarConfirm = !_mostrarConfirm);
                          },
                          icon: Icon(
                            _mostrarConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: auth.cargando ? null : _actualizarPassword,
                        icon: auth.cargando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.security_update_good),
                        label: const Text('Actualizar contraseña'),
                      ),
                    ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
