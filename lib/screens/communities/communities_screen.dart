import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/auth/login.dart' as auth; // Para usar las constantes de color
import 'package:hackathon_frontend/screens/communities/community_detail.dart'
    as detail;
import 'package:hackathon_frontend/screens/communities/create_community.dart';
import 'package:hackathon_frontend/services/communities_service.dart';

// --- 1. Modelo de Datos para una Comunidad ---
class Community {
  final String name;
  final String description;
  final String imageUrl;
  final int memberCount;
  final bool isPrivate;

  Community({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.memberCount,
    this.isPrivate = false,
  });
}

// --- 2. Pantalla Principal de Comunidades ---
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  // --- Datos de Ejemplo (en un app real vendrían de una base de datos) ---
  final List<Community> _myCommunities = [
    Community(
      name: 'Senderistas USB',
      description:
          'Grupo para organizar excursiones y hikes en El Ávila y más allá.',
      imageUrl: 'https://via.placeholder.com/150/2E8B57/FFFFFF?text=USB',
      memberCount: 280,
    ),
  ];

  // Controlador para la búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late CommunitiesService _communitiesService;
  List<CommunitySummary> _discoverCommunities = [];
  bool _isLoadingDiscover = true;
  String? _discoverError;

  @override
  void initState() {
    super.initState();
    _communitiesService = CommunitiesService();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadCommunities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCommunities() async {
    setState(() {
      _isLoadingDiscover = true;
      _discoverError = null;
    });

    try {
      final communities = await _communitiesService.fetchCommunities();
      if (!mounted) {
        return;
      }
      setState(() {
        _discoverCommunities = communities;
        _isLoadingDiscover = false;
      });
    } on CommunitiesException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _discoverError = e.message;
        _isLoadingDiscover = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _discoverError = 'Error inesperado al cargar comunidades.';
        _isLoadingDiscover = false;
      });
    }
  }

  // Función para filtrar comunidades según la búsqueda
  List<Community> _filterCommunities(List<Community> communities) {
    if (_searchQuery.isEmpty) {
      return communities;
    }
    return communities
        .where(
          (community) =>
              community.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              community.description.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos un TabController para manejar las pestañas
    return DefaultTabController(
      length: 2, // Número de pestañas
      child: Scaffold(
        backgroundColor: auth.kBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            'Comunidades',
            style: TextStyle(color: auth.kPrimaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: auth.kPrimaryColor,
            labelColor: auth.kPrimaryColor,
            unselectedLabelColor: Colors.grey[500],
            tabs: const [
              Tab(text: 'Mis Comunidades'),
              Tab(text: 'Descubrir'),
            ],
          ),
        ),
        body: Column(
          children: [
            // --- Barra de Búsqueda ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar comunidades...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // --- Contenido de las Pestañas ---
            Expanded(
              child: TabBarView(
                children: [
                  // Contenido de "Mis Comunidades"
                  _buildCommunityList(_filterCommunities(_myCommunities)),
                  // Contenido de "Descubrir"
                  _buildDiscoverTab(),
                ],
              ),
            ),
          ],
        ),
        // --- Botón para Crear Comunidad ---
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateCommunityScreen(),
              ),
            );

            if (!mounted) {
              return;
            }

            if (result is CreatedCommunity) {
              await _loadCommunities();
            }
          },
          backgroundColor: auth.kPrimaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // --- Widget Helper para construir la lista de comunidades ---
  Widget _buildCommunityList(List<Community> communities) {
    if (communities.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No hay comunidades aquí.'
              : 'No se encontraron resultados.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];
        return _buildCommunityCard(community);
      },
    );
  }

  // --- Widget Helper para el diseño de cada tarjeta de comunidad ---
  Widget _buildCommunityCard(Community community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // TODO: Navegar a la pantalla de detalle de la comunidad
          print('Viendo detalles de: ${community.name}');
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Imagen de la comunidad
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(community.imageUrl),
              ),
              const SizedBox(width: 16.0),
              // Información de la comunidad
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          community.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (community.isPrivate) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${community.memberCount} miembros',
                      style: TextStyle(
                        color: auth.kPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Icono para unirse
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    if (_isLoadingDiscover) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_discoverError != null) {
      return _buildDiscoverError();
    }

    final filtered = _filterCommunitySummaries(_discoverCommunities);
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty
              ? 'No hay comunidades disponibles.'
              : 'No se encontraron comunidades con ese nombre.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final community = filtered[index];
        return _buildCommunitySummaryCard(community);
      },
    );
  }

  Widget _buildDiscoverError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _discoverError ?? 'Error al cargar comunidades.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCommunities,
              style: ElevatedButton.styleFrom(
                backgroundColor: auth.kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  List<CommunitySummary> _filterCommunitySummaries(
    List<CommunitySummary> communities,
  ) {
    if (_searchQuery.isEmpty) {
      return communities;
    }
    return communities
        .where(
          (community) => community.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  Widget _buildCommunitySummaryCard(CommunitySummary community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => detail.CommunityDetailsScreen(
                communityId: community.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Hero(
                tag: 'community-${community.id}',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: auth.kPrimaryColor.withOpacity(0.2),
                  child: const Icon(Icons.people, color: auth.kPrimaryColor),
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${community.membersCount} miembros · ${community.eventsCount} eventos',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${community.requestsCount} solicitudes pendientes',
                      style: TextStyle(color: Colors.grey[500]),
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
}
