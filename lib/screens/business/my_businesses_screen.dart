import 'package:flutter/material.dart';
import 'package:hackathon_frontend/services/places_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login.dart';
import 'my_business_detail.dart';
import 'create_my_business.dart';

class MyBusinessesListScreen extends StatefulWidget {
  const MyBusinessesListScreen({super.key});

  @override
  State<MyBusinessesListScreen> createState() => _MyBusinessesListScreenState();
}

class _MyBusinessesListScreenState extends State<MyBusinessesListScreen> {
  final PlacesService _placesService = PlacesService();
  final ScrollController _scrollController = ScrollController();

  final List<PlaceSummary> _places = [];
  PlacePagination? _pagination;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String? _cityFilter;
  String? _countryFilter;
  String? _typeFilter;
  String? _statusFilter;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeUser();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(LoginStorageKeys.userId);

      if (!mounted) {
        return;
      }

      if (userId == null) {
        setState(() {
          _errorMessage = 'No se pudo identificar al usuario autenticado.';
        });
        return;
      }

      setState(() {
        _currentUserId = userId;
      });

      await _loadPlaces(reset: true);
    } on Exception {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Error inesperado al cargar tus negocios.';
      });
    }
  }

  Future<void> _loadPlaces({required bool reset}) async {
    if (_isLoading || _isLoadingMore) {
      return;
    }

    setState(() {
      if (reset) {
        _isLoading = true;
        _errorMessage = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final nextPage = reset ? 1 : (_pagination?.page ?? 1) + 1;
      final userId = _currentUserId;
      if (userId == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _errorMessage =
              'No se pudo identificar al usuario autenticado para cargar los negocios.';
        });
        return;
      }

      final response = await _placesService.fetchPlaces(
        city: _cityFilter,
        country: _countryFilter,
        type: _typeFilter,
        status: _statusFilter,
        page: nextPage,
        limit: 10,
      );

      if (!mounted) {
        return;
      }

      final filteredPlaces = response.places
          .where((place) => place.ownerId == userId)
          .toList();

      setState(() {
        if (reset) {
          _places
            ..clear()
            ..addAll(filteredPlaces);
        } else {
          _places.addAll(filteredPlaces);
        }
        _pagination = response.pagination;
      });
    } on PlacesException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Error inesperado al cargar tus negocios.';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        (_pagination?.hasMore ?? false) &&
        !_isLoading &&
        !_isLoadingMore) {
      _loadPlaces(reset: false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadPlaces(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Mis Negocios',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: kPrimaryColor,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading
            ? null
            : () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => const CreateBusinessScreen(),
                  ),
                );

                if (created == true) {
                  await _loadPlaces(reset: true);
                }
              },
        backgroundColor: kPrimaryColor,
        child: const Icon(Icons.add_business_outlined, color: Colors.white),
        tooltip: 'Añadir Negocio',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _places.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _places.isEmpty) {
      return _buildErrorState();
    }

    if (_places.isEmpty) {
      return _buildEmptyState();
    }

    final itemCount = _places.length + (_isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= _places.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final place = _places[index];
        return _buildBusinessCard(place);
      },
    );
  }

  Widget _buildBusinessCard(PlaceSummary place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // --- NAVEGACIÓN A LA PANTALLA DE DETALLE ---
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BusinessDetailsScreen(place: place),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    place.imageUrl != null && place.imageUrl!.isNotEmpty
                    ? NetworkImage(place.imageUrl!)
                    : null,
                backgroundColor: kPrimaryColor.withOpacity(0.1),
                child: place.imageUrl != null && place.imageUrl!.isNotEmpty
                    ? null
                    : const Icon(
                        Icons.store_mall_directory,
                        color: kPrimaryColor,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.type.isNotEmpty ? place.type : 'Sin categoría',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${place.city}, ${place.country}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.event_note_outlined,
                          label: '${place.eventsCount} eventos',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.reviews_outlined,
                          label: '${place.reviewsCount} reseñas',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kPrimaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.redAccent.shade200),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'Error al cargar los negocios.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _loadPlaces(reset: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      children: const [
        SizedBox(height: 120),
        Icon(Icons.sentiment_dissatisfied, size: 48, color: kPrimaryColor),
        SizedBox(height: 16),
        Text(
          'Aún no registras ningún negocio.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }
}
