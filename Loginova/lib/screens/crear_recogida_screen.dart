import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../constants/permission_constants.dart';
import '../models/cliente.dart';
import '../models/recogida.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import '../providers/recogida_provider.dart';
import '../services/cliente_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_service.dart';
import '../themes/app_theme.dart';
import '../utils/app_logger.dart';

/// Pantalla profesional para crear una nueva recogida con selección de ubicación
class CrearRecogidaScreen extends StatefulWidget {
  const CrearRecogidaScreen({super.key});

  @override
  State<CrearRecogidaScreen> createState() => _CrearRecogidaScreenState();
}

class _CrearRecogidaScreenState extends State<CrearRecogidaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de cliente
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();

  // Controladores de recogida
  final _observacionesController = TextEditingController();

  // Ubicación de la recogida
  double? _selectedLatitude;
  double? _selectedLongitude;

  Timer? _direccionDebounceTimer;
  List<AddressSuggestion> _addressSuggestions = [];
  bool _isSearchingAddress = false;
  bool _guardando = false;

  @override
  void dispose() {
    _direccionDebounceTimer?.cancel();
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  /// Autocompletado de dirección mientras el usuario escribe: espera 300ms
  /// sin nuevas pulsaciones (debounce) antes de consultar el servicio de
  /// geocodificación, para no disparar una petición por cada tecla.
  void _onDireccionChanged(String value) {
    final query = value.trim();

    if (query.length < 3) {
      if (mounted) {
        setState(() => _addressSuggestions = []);
      }
      return;
    }

    _direccionDebounceTimer?.cancel();
    _direccionDebounceTimer = Timer(
      const Duration(milliseconds: 300),
      () async {
        if (!mounted) return;

        final ubicacionActual = Provider.of<LocationProvider>(
          context,
          listen: false,
        ).currentLocation;
        final suggestions = await GeocodingService.searchAddresses(
          query,
          nearLatitude: ubicacionActual?.latitude,
          nearLongitude: ubicacionActual?.longitude,
        );

        if (!mounted) return;

        setState(() {
          _addressSuggestions = suggestions.take(4).toList();
        });
      },
    );
  }

  /// Busca la dirección escrita al presionar el botón de búsqueda o al
  /// enviar el campo, y toma el primer resultado como ubicación (a
  /// diferencia del autocompletado, que solo sugiere).
  Future<void> _buscarDireccionManual() async {
    final query = _direccionController.text.trim();

    if (query.isEmpty) {
      setState(() => _addressSuggestions = []);
      return;
    }

    setState(() => _isSearchingAddress = true);

    try {
      final ubicacionActual = Provider.of<LocationProvider>(
        context,
        listen: false,
      ).currentLocation;
      final resultados = await GeocodingService.searchAddresses(
        query,
        nearLatitude: ubicacionActual?.latitude,
        nearLongitude: ubicacionActual?.longitude,
      );

      if (!mounted) return;

      if (resultados.isNotEmpty) {
        final resultado = resultados.first;
        setState(() {
          _direccionController.text = resultado.label;
          _selectedLatitude = resultado.latitude;
          _selectedLongitude = resultado.longitude;
          if ((resultado.city ?? '').isNotEmpty) {
            _ciudadController.text = resultado.city!;
          }
          _addressSuggestions = [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se encontró esa dirección. Prueba con otro texto.',
            ),
            backgroundColor: LoginovaColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo buscar la dirección: ${e.toString()}'),
            backgroundColor: LoginovaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingAddress = false);
      }
    }
  }

  /// Abre el selector de ubicación en el mapa
  Future<void> _selectLocation() async {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => _LocationPickerScreen(
          initialLocation:
              _selectedLatitude != null && _selectedLongitude != null
              ? LatLng(_selectedLatitude!, _selectedLongitude!)
              : null,
          currentLocation: locationProvider.currentLocation,
        ),
      ),
    );

    if (result != null) {
      final latitude = result['latitude'] as double?;
      final longitude = result['longitude'] as double?;

      if (latitude != null && longitude != null) {
        setState(() {
          _selectedLatitude = latitude;
          _selectedLongitude = longitude;
          _addressSuggestions = [];
        });

        final address = result['address']?.toString();

        if (address != null && address.isNotEmpty && mounted) {
          _direccionController.text = address;
        } else {
          try {
            final resolvedAddress =
                await LocationService.getAddressFromCoordinates(
                  latitude,
                  longitude,
                );

            if (resolvedAddress != null && mounted) {
              _direccionController.text = resolvedAddress;
            }
          } catch (e) {
            AppLogger.warn('Error obteniendo dirección: $e', error: e);
          }
        }
      }
    }
  }

  /// Guarda la nueva recogida
  Future<void> _guardarRecogida() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ubicación en el mapa'),
          backgroundColor: LoginovaColors.error,
        ),
      );
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una ubicación en el mapa'),
          backgroundColor: LoginovaColors.error,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final recogidaProvider = Provider.of<RecogidaProvider>(
        context,
        listen: false,
      );

      if (auth.usuario == null) {
        throw Exception('Sesión inválida');
      }

      // Primero se crea el cliente en el backend (con sus datos de contacto
      // y dirección) para poder referenciarlo por ID en la recogida.
      // Crear cliente
      final cliente = await ClienteService().crearCliente(
        Cliente(
          id: 0,
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
          direccion: _direccionController.text.trim(),
          ciudad: _ciudadController.text.trim(),
        ),
      );

      // Crear recogida con ubicación. La cantidad de paquetes se desconoce
      // en este punto: la registra el operador al cambiar el estado, cuando
      // ya tiene los paquetes en mano y puede contarlos con certeza.
      final recogida = Recogida(
        id: 0,
        clienteId: cliente.id,
        usuarioId: auth.usuario!.id,
        estado: 'Pendiente',
        cantidadPaquetes: 0,
        observaciones: _observacionesController.text.trim(),
        evidencias: const [],
        latitud: _selectedLatitude,
        longitud: _selectedLongitude,
        fechaCreacion: DateTime.now(),
      );

      await recogidaProvider.agregarRecogida(recogida);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recogida creada exitosamente'),
          backgroundColor: LoginovaColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: LoginovaColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final puedeCrear =
        auth.usuario?.tienePermiso(PermissionConstants.crearRecogidas) ?? false;

    if (!puedeCrear) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nueva Recogida'), elevation: 0),
        body: const Center(
          child: Text('No tienes permiso para crear recogidas.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Recogida'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección de ubicación
                _buildSectionTitle('Ubicación de la Recogida'),
                const SizedBox(height: 16),
                _buildLocationSelector(),
                const SizedBox(height: 32),

                // Sección de cliente
                _buildSectionTitle('Información del Cliente'),
                const SizedBox(height: 16),
                _buildClienteFields(),
                const SizedBox(height: 32),

                // Sección de recogida
                _buildSectionTitle('Detalles de la Recogida'),
                const SizedBox(height: 16),
                _buildRecogidaFields(),
                const SizedBox(height: 32),

                // Botones de acción
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el selector de ubicación
  Widget _buildLocationSelector() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: LoginovaColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _selectLocation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: LoginovaColors.primary,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selecciona la ubicación en el mapa',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          if (_selectedLatitude != null &&
                              _selectedLongitude != null)
                            Text(
                              '${_selectedLatitude!.toStringAsFixed(4)}, ${_selectedLongitude!.toStringAsFixed(4)}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: LoginovaColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                            )
                          else
                            Text(
                              'Toca para abrir el mapa',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: LoginovaColors.textSecondary,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Construye el título de una sección
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: LoginovaColors.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Construye los campos de cliente
  Widget _buildClienteFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nombreController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Nombre del Cliente',
            hintText: 'Ej: Empresa XYZ',
            prefixIcon: const Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el nombre del cliente';
            }
            if (value.length < 3) {
              return 'El nombre debe tener al menos 3 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _telefonoController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Teléfono',
            hintText: 'Ej: +34 123 456 789',
            prefixIcon: const Icon(Icons.phone),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa el teléfono';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _direccionController,
          textInputAction: TextInputAction.search,
          onChanged: _onDireccionChanged,
          onFieldSubmitted: (_) => _buscarDireccionManual(),
          decoration: InputDecoration(
            labelText: 'Dirección',
            hintText: 'Escribe la dirección o selecciónala en el mapa',
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSearchingAddress)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _buscarDireccionManual,
                    tooltip: 'Buscar dirección',
                  ),
                IconButton(
                  icon: const Icon(Icons.map_outlined),
                  onPressed: _selectLocation,
                  tooltip: 'Seleccionar en el mapa',
                ),
              ],
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la dirección';
            }
            return null;
          },
        ),
        if (_addressSuggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addressSuggestions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final suggestion = _addressSuggestions[index];
                return ListTile(
                  dense: true,
                  title: Text(suggestion.label),
                  leading: const Icon(Icons.location_on_outlined, size: 18),
                  onTap: () {
                    // La sugerencia ya trae sus coordenadas exactas: no hace
                    // falta volver a geocodificar el texto seleccionado.
                    setState(() {
                      _direccionController.text = suggestion.label;
                      _selectedLatitude = suggestion.latitude;
                      _selectedLongitude = suggestion.longitude;
                      if ((suggestion.city ?? '').isNotEmpty) {
                        _ciudadController.text = suggestion.city!;
                      }
                      _addressSuggestions = [];
                    });
                  },
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _ciudadController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Ciudad',
            hintText: 'Ej: Madrid',
            prefixIcon: const Icon(Icons.location_city),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor ingresa la ciudad';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// Construye los campos de recogida
  Widget _buildRecogidaFields() {
    return Column(
      children: [
        TextFormField(
          controller: _observacionesController,
          textInputAction: TextInputAction.done,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Observaciones',
            hintText: 'Notas o instrucciones especiales...',
            prefixIcon: const Icon(Icons.note),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  /// Construye los botones de acción
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _guardando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _guardando ? null : _guardarRecogida,
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Guardar'),
          ),
        ),
      ],
    );
  }
}

/// Pantalla para seleccionar ubicación en un mapa interactivo
class _LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final LocationData? currentLocation;

  const _LocationPickerScreen({this.initialLocation, this.currentLocation});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  LatLng? _selectedLocation;
  late LatLng _centerLocation;
  String? _resolvedAddress;
  bool _isSearchingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Usar ubicación inicial, ubicación actual o ubicación por defecto
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _centerLocation = widget.initialLocation!;
    } else if (widget.currentLocation != null) {
      _centerLocation = LatLng(
        widget.currentLocation!.latitude,
        widget.currentLocation!.longitude,
      );
      _selectedLocation = _centerLocation;
    } else {
      _centerLocation = const LatLng(6.2442, -75.5812); // Medellín por defecto
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Geocodifica el texto buscado, centra el mapa en el resultado y hace
  /// reverse geocoding para mostrar la dirección legible correspondiente.
  Future<void> _buscarUbicacionEnMapa() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearchingLocation = true);

    try {
      final location = await GeocodingService.geocodeAddress(
        query,
        nearLatitude: _centerLocation.latitude,
        nearLongitude: _centerLocation.longitude,
      );
      if (!mounted) return;

      if (location != null) {
        final target = LatLng(location.latitude, location.longitude);
        _mapController.move(target, 16);
        setState(() {
          _selectedLocation = target;
          _centerLocation = target;
          _resolvedAddress = null;
        });

        final address = await GeocodingService.reverseGeocode(
          location.latitude,
          location.longitude,
        );

        if (!mounted) return;
        setState(() {
          _resolvedAddress = address ?? query;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró esa dirección en el mapa'),
            backgroundColor: LoginovaColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar la ubicación: ${e.toString()}'),
            backgroundColor: LoginovaColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSearchingLocation = false);
      }
    }
  }

  /// Confirma el punto elegido en el mapa y lo devuelve a la pantalla que
  /// invocó este selector. Si aún no se resolvió la dirección legible del
  /// punto (p.ej. se tocó el mapa sin buscar), la resuelve aquí antes de
  /// devolver el resultado.
  Future<void> _confirmarUbicacion() async {
    if (_selectedLocation == null) return;

    final address =
        _resolvedAddress ??
        await LocationService.getAddressFromCoordinates(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        );

    if (!mounted) return;

    Navigator.pop(context, {
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'address': address ?? _searchController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona la ubicación'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerLocation,
              initialZoom: 14,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                  _resolvedAddress = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.loginova.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: LoginovaColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: LoginovaColors.primary.withValues(
                                alpha: 0.5,
                              ),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Centro del mapa (reticula)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: LoginovaColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: LoginovaColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _buscarUbicacionEnMapa(),
                        decoration: InputDecoration(
                          hintText: 'Buscar dirección o lugar',
                          border: InputBorder.none,
                          suffixIcon: _isSearchingLocation
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _buscarUbicacionEnMapa,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Panel de información inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ubicación seleccionada',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selectedLocation != null) ...[
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LoginovaColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _selectedLocation != null
                          ? _confirmarUbicacion
                          : null,
                      child: const Text('Confirmar ubicación'),
                    ),
                  ] else ...[
                    Text(
                      'Toca en el mapa para seleccionar una ubicación',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: LoginovaColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
