import 'package:flutter/material.dart';
import 'package:hackathon_frontend/services/communities_service.dart';

const Color kPrimaryColor = Color(0xFF4BBAC3);
const Color kBackgroundColor = Color(0xFFF5F4EF);

class CommunityDetailsScreen extends StatefulWidget {
  const CommunityDetailsScreen({super.key, required this.communityId});

  final int communityId;

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen>
    with SingleTickerProviderStateMixin {
  late CommunitiesService _communitiesService;
  CommunityDetail? _community;
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _communitiesService = CommunitiesService();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCommunity();
  }

  Future<void> _fetchCommunity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final community =
          await _communitiesService.fetchCommunityDetail(widget.communityId);
      if (!mounted) {
        return;
      }
      setState(() {
        _community = community;
        _isLoading = false;
      });
    } on CommunitiesException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Error inesperado al cargar la comunidad.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage ?? 'Error al cargar la comunidad.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCommunity,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final community = _community!;
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: kPrimaryColor,
              leading: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: Text(
                  community.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                background: Hero(
                  tag: 'community-${community.id}',
                  child: community.imageUrl != null &&
                          community.imageUrl!.isNotEmpty
                      ? Image.network(
                          community.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: kPrimaryColor,
                          child: const Icon(
                            Icons.groups,
                            color: Colors.white,
                            size: 96,
                          ),
                        ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildCommunityInfo(community)),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: kPrimaryColor,
                  labelColor: kPrimaryColor,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(icon: Icon(Icons.event_note), text: 'Eventos'),
                    Tab(icon: Icon(Icons.group), text: 'Miembros'),
                    Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEventsTab(community),
            _buildMembersTab(community),
            _buildChatPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityInfo(CommunityDetail community) {
    return Container(
      color: kBackgroundColor,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            community.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.group, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text('${community.membersCount} miembros'),
              const SizedBox(width: 16),
              const Icon(Icons.event, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text('${community.eventsCount} eventos'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            community.description.isNotEmpty
                ? community.description
                : 'Esta comunidad aún no tiene una descripción.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.group_add, color: Colors.white),
                  label: const Text(
                    'Solicitar unirme',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share, color: kPrimaryColor),
                style: IconButton.styleFrom(
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(CommunityDetail community) {
    final events = community.events;
    if (events == null || events.isEmpty) {
      return const Center(
        child: Text('No hay eventos creados en esta comunidad.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index] as Map<String, dynamic>?;
        if (event == null) {
          return const SizedBox.shrink();
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'] as String? ?? 'Evento sin título',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (event['description'] != null)
                  Text(
                    event['description'] as String,
                    style: const TextStyle(color: Colors.black54),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(event['date']?.toString() ?? 'Fecha por definir'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event['location']?.toString() ?? 'Ubicación por definir',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(CommunityDetail community) {
    final members = community.members;
    if (members == null || members.isEmpty) {
      return const Center(
        child: Text('Esta comunidad aún no tiene miembros listados.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index] as Map<String, dynamic>?;
        if (member == null) {
          return const SizedBox.shrink();
        }
        final name = member['name'] as String? ?? 'Miembro sin nombre';
        final email = member['email'] as String? ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: kPrimaryColor.withOpacity(0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: kPrimaryColor),
            ),
          ),
          title: Text(name),
          subtitle: email.isNotEmpty ? Text(email) : null,
        );
      },
    );
  }

  Widget _buildChatPlaceholder() {
    return const Center(
      child: Text('El chat de la comunidad estará disponible próximamente.'),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: kBackgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
