import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/recogida_provider.dart';

/// Pantalla que muestra un resumen de recogidas y una vista de tipo mapa.
class MapaScreen extends StatelessWidget {
  const MapaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RecogidaProvider>(context);
    final recogidas = provider.recogidas;

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Recogidas')),
      body: RefreshIndicator(
        onRefresh: provider.cargarRecogidas,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: provider.cargando
              ? const Center(child: CircularProgressIndicator())
              : recogidas.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: 80),
                    Center(child: Text('No hay recogidas disponibles')),
                  ],
                )
              : ListView(
                  children: [
                    const Text(
                      'Visión general de recogidas',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Esta pantalla presenta una vista simplificada de ubicaciones y estados de las recogidas.',
                    ),
                    const SizedBox(height: 20),
                    ...recogidas.map(
                      (recogida) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text('Recogida #${recogida.id}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cliente: #${recogida.clienteId}'),
                              Text(
                                'Dirección: ${recogida.observaciones.isNotEmpty ? recogida.observaciones : 'Sin dirección registrada'}',
                              ),
                              Text('Estado: ${recogida.estado}'),
                            ],
                          ),
                          trailing: Text(
                            '${recogida.cantidadPaquetes} paquetes',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
