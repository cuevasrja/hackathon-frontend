import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/auth/login.dart'
    as auth; // Para usar las constantes de color
import 'package:hackathon_frontend/screens/communities/community_detail.dart'
    as detail;
import 'package:hackathon_frontend/screens/communities/create_community.dart';
import 'package:hackathon_frontend/services/communities_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- 2. Pantalla Principal de Comunidades ---
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  // Controlador para la búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late CommunitiesService _communitiesService;
  List<CommunitySummary> _discoverCommunities = [];
  List<CommunitySummary> _myCommunities = [];
  bool _isLoadingDiscover = true;
  bool _isLoadingMyCommunities = true;
  String? _discoverError;
  String? _myCommunitiesError;

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
      _isLoadingMyCommunities = true;
      _myCommunitiesError = null;
    });

    SharedPreferences? prefs;
    int? userId;

    try {
      prefs = await SharedPreferences.getInstance();
      userId = prefs.getInt(auth.LoginStorageKeys.userId);
    } on Exception {
      userId = null;
    }

    List<CommunitySummary> discoverCommunities = [];
    List<CommunitySummary> myCommunities = [];
    String? discoverError;
    String? myError;

    try {
      discoverCommunities = await _communitiesService.fetchCommunities();
    } on CommunitiesException catch (e) {
      discoverError = e.message;
    } catch (_) {
      discoverError = 'Error inesperado al cargar comunidades.';
    }

    if (userId == null) {
      myError = 'No se pudo identificar al usuario autenticado.';
    } else {
      try {
        myCommunities = await _communitiesService.fetchUserCommunities(userId);
      } on CommunitiesException catch (e) {
        myError = e.message;
      } catch (_) {
        myError = 'Error inesperado al cargar tus comunidades.';
      }
    }

    if (userId != null) {
      final ownerCommunities = discoverCommunities
          .where(
            (community) =>
                community.createdById != null &&
                community.createdById == userId,
          )
          .toList();

      if (ownerCommunities.isNotEmpty) {
        final existingIds = myCommunities
            .map((community) => community.id)
            .toSet();
        for (final ownerCommunity in ownerCommunities) {
          if (!existingIds.contains(ownerCommunity.id)) {
            myCommunities.add(ownerCommunity);
            existingIds.add(ownerCommunity.id);
          }
        }
      }
    }

    if (userId != null) {
      final filteredMyCommunities = myCommunities
          .where((community) => community.createdById == userId)
          .toList();
      myCommunities = filteredMyCommunities;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _discoverCommunities = discoverCommunities;
      _isLoadingDiscover = false;
      _discoverError = discoverError;

      _myCommunities = myCommunities;
      _isLoadingMyCommunities = false;
      _myCommunitiesError = myError;
    });
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
            style: TextStyle(
              color: auth.kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
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
                  _buildMyCommunitiesTab(),
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

  Widget _buildMyCommunitiesTab() {
    if (_isLoadingMyCommunities) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myCommunitiesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _myCommunitiesError!,
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

    final filtered = _filterCommunitySummaries(_myCommunities);
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sentiment_dissatisfied,
              color: auth.kPrimaryColor,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Por ahora no perteneces a ninguna comunidad.'
                  : 'No se encontraron comunidades con ese nombre.',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildCommunitySummaryCard(filtered[index]);
      },
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
    return communities.where((community) {
      final query = _searchQuery.toLowerCase();
      final nameMatch = community.name.toLowerCase().contains(query);
      final descriptionMatch =
          community.description?.toLowerCase().contains(query) ?? false;
      return nameMatch || descriptionMatch;
    }).toList();
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
              builder: (context) =>
                  detail.CommunityDetailsScreen(communityId: community.id),
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
                  backgroundImage:
                      community.imageUrl != null &&
                          community.imageUrl!.isNotEmpty
                      ? NetworkImage(community.imageUrl!)
                      : null,
                  child:
                      (community.imageUrl != null &&
                          community.imageUrl!.isNotEmpty)
                      ? null
                      : const Icon(Icons.people, color: auth.kPrimaryColor),
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
                    if (community.description != null &&
                        community.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        community.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
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
