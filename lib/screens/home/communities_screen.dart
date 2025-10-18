import 'package:flutter/material.dart';
import 'package:hackathon_frontend/screens/auth/login.dart'; // Para usar las constantes de color

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

  final List<Community> _popularCommunities = [
    Community(
      name: 'Foodies Caracas',
      description:
          'Descubrimos y calificamos los mejores points gastronómicos de la ciudad.',
      imageUrl: 'https://via.placeholder.com/150/FF6347/FFFFFF?text=Food',
      memberCount: 1250,
    ),
    Community(
      name: 'Rumbas Ccs 2.0',
      description:
          'Aquí se publican los mejores eventos y fiestas del fin de semana.',
      imageUrl: 'https://via.placeholder.com/150/9370DB/FFFFFF?text=Party',
      memberCount: 3400,
      isPrivate: true,
    ),
    Community(
      name: 'USB Rock & Devs',
      description:
          'Para gente de la Simón que le gusta el rock, la tecnología y el café.',
      imageUrl: 'https://via.placeholder.com/150/696969/FFFFFF?text=Rock',
      memberCount: 450,
    ),
  ];

  // Controlador para la búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      length: 3, // Número de pestañas
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: kPrimaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Comunidades',
            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: kPrimaryColor,
            labelColor: kPrimaryColor,
            unselectedLabelColor: Colors.grey[500],
            tabs: const [
              Tab(text: 'Mis Grupos'),
              Tab(text: 'Populares'),
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
                  // Contenido de "Mis Grupos"
                  _buildCommunityList(_filterCommunities(_myCommunities)),
                  // Contenido de "Populares"
                  _buildCommunityList(_filterCommunities(_popularCommunities)),
                  // Contenido de "Descubrir" (usamos los populares como ejemplo)
                  _buildCommunityList(
                    _filterCommunities(_popularCommunities.reversed.toList()),
                  ),
                ],
              ),
            ),
          ],
        ),
        // --- Botón para Crear Comunidad ---
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO: Lógica para navegar a una pantalla de creación de comunidad
            print('Crear nueva comunidad');
          },
          backgroundColor: kPrimaryColor,
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
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Icono para unirse
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
