import 'package:flutter/material.dart';

import '../services/empresa_service.dart';
import '../themes/app_theme.dart';
import '../widgets/responsive_center.dart';
import 'soporte_empresa_detalle_screen.dart';

/// Buscador global: cuando un cliente escribe a Soporte dando solo su
/// correo (sin decir de qué empresa es), esta pantalla encuentra a qué
/// empresa pertenece y permite entrar directo a su Detalle.
class SoporteBuscadorScreen extends StatefulWidget {
  const SoporteBuscadorScreen({super.key});

  @override
  State<SoporteBuscadorScreen> createState() => _SoporteBuscadorScreenState();
}

class _SoporteBuscadorScreenState extends State<SoporteBuscadorScreen> {
  final _service = EmpresaService();
  final _correoController = TextEditingController();
  bool _buscando = false;
  String? _error;
  Map<String, dynamic>? _resultado;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final correo = _correoController.text.trim();
    if (correo.isEmpty) return;

    setState(() {
      _buscando = true;
      _error = null;
      _resultado = null;
    });

    try {
      final resultado = await _service.buscarUsuarioPorCorreo(correo);
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        if (resultado == null) {
          _error = 'No se encontró ningún usuario con ese correo.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _irAlDetalle() {
    final resultado = _resultado;
    if (resultado == null || resultado['empresaId'] == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoporteEmpresaDetalleScreen(
          empresaId: resultado['empresaId'],
          nombreEmpresa: resultado['nombreEmpresa'] ?? 'Empresa',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar usuario por correo'), elevation: 0),
      body: ResponsiveCenter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Si un cliente escribe solo dando su correo, búscalo aquí '
                'para saber a qué empresa pertenece.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _correoController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                onSubmitted: (_) => _buscar(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _buscando ? null : _buscar,
                  icon: _buscando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('Buscar'),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: LoginovaColors.error)),
              if (_resultado != null) _buildResultado(_resultado!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultado(Map<String, dynamic> resultado) {
    final activo = resultado['activo'] == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: activo
                      ? LoginovaColors.primary.withValues(alpha: 0.15)
                      : LoginovaColors.error.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.person,
                    color: activo ? LoginovaColors.primary : LoginovaColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resultado['nombre'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(resultado['correo'] ?? ''),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Rol: ${resultado['rol'] ?? 'Soporte'}'),
            Text('Cuenta: ${activo ? 'Activa' : 'Desactivada'}'),
            Text('Empresa: ${resultado['nombreEmpresa'] ?? 'Sin empresa (Soporte)'}'),
            if (resultado['empresaId'] != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _irAlDetalle,
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Ir al Detalle de la empresa'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
