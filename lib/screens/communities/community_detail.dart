import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:hackathon_frontend/models/event_model.dart';
import 'package:hackathon_frontend/services/communities_service.dart';
import 'package:hackathon_frontend/services/event_service.dart';
import 'package:hackathon_frontend/screens/auth/login.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryColor = Color(0xFF4BBAC3);
const Color kBackgroundColor = Color(0xFFF5F4EF);

class CommunityDetailsScreen extends StatefulWidget {
  const CommunityDetailsScreen({super.key, required this.communityId});

  final int communityId;

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class CommunityRequestsScreen extends StatefulWidget {
  const CommunityRequestsScreen({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.service,
  });

  final int communityId;
  final String communityName;
  final CommunitiesService service;

  @override
  State<CommunityRequestsScreen> createState() =>
      _CommunityRequestsScreenState();
}

class _CommunityRequestsScreenState extends State<CommunityRequestsScreen> {
  List<CommunityJoinRequest> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<int> _processingRequests = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final requests = await widget.service.fetchCommunityJoinRequests(
        widget.communityId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = requests;
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
        _errorMessage = 'No fue posible cargar las solicitudes.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRequestAction({
    required CommunityJoinRequest request,
    required bool approve,
  }) async {
    if (_processingRequests.contains(request.id)) {
      return;
    }

    setState(() {
      _processingRequests.add(request.id);
    });

    try {
      if (approve) {
        await widget.service.approveCommunityJoinRequest(
          communityId: widget.communityId,
          requestId: request.id,
        );
      } else {
        await widget.service.rejectCommunityJoinRequest(
          communityId: widget.communityId,
          requestId: request.id,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Solicitud aprobada correctamente.'
                : 'Solicitud rechazada correctamente.',
          ),
        ),
      );

      setState(() {
        _requests.removeWhere((element) => element.id == request.id);
      });
    } on CommunitiesException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'No fue posible aprobar la solicitud.'
                : 'No fue posible rechazar la solicitud.',
          ),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _processingRequests.remove(request.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitudes · ${widget.communityName}'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        color: kPrimaryColor,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return ListView(
        children: const [
          SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_requests.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(
            height: 200,
            child: Center(
              child: Text('No hay solicitudes pendientes para esta comunidad.'),
            ),
          ),
        ],
      );
    }

    final formatter = DateFormat('d MMM yyyy · HH:mm', 'es');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = _requests[index];
        final normalizedName = request.userName?.trim();
        final normalizedEmail = request.userEmail?.trim();
        final name = (normalizedName != null && normalizedName.isNotEmpty)
            ? normalizedName
            : (normalizedEmail != null && normalizedEmail.isNotEmpty)
            ? normalizedEmail
            : 'Solicitante #${request.id}';
        final email = request.userEmail;
        final createdAt = request.createdAt != null
            ? formatter.format(request.createdAt!.toLocal())
            : null;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: kPrimaryColor.withOpacity(0.2),
              child: Text(
                name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
                style: const TextStyle(color: kPrimaryColor),
              ),
            ),
            title: Text(name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (email != null && email.isNotEmpty) Text(email),
                if (createdAt != null)
                  Text(
                    createdAt,
                    style: const TextStyle(color: Colors.black54),
                  ),
                if (request.status != null && request.status!.isNotEmpty)
                  Text(
                    'Estado: ${request.status}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                if (request.status == null || request.status == 'PENDING')
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _processingRequests.contains(request.id)
                                ? null
                                : () => _handleRequestAction(
                                      request: request,
                                      approve: true,
                                    ),
                            icon: _processingRequests.contains(request.id)
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color?>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check, color: Colors.white),
                            label: const Text('Aceptar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _processingRequests.contains(request.id)
                                ? null
                                : () => _handleRequestAction(
                                      request: request,
                                      approve: false,
                                    ),
                            icon: _processingRequests.contains(request.id)
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color?>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.close, color: Colors.white),
                            label: const Text('Rechazar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen>
    with SingleTickerProviderStateMixin {
  late CommunitiesService _communitiesService;
  late EventService _eventService;
  CommunityDetail? _community;
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  List<Event> _communityEvents = [];
  bool _isEventsLoading = false;
  String? _eventsErrorMessage;
  String _selectedStatus = '';
  String _selectedVisibility = '';
  bool _upcomingOnly = false;
  bool _isJoinRequesting = false;
  bool _joinRequestSent = false;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _communitiesService = CommunitiesService();
    _eventService = EventService();
    _tabController = TabController(length: 3, vsync: this);
    _fetchCommunity();
    _initializeLocaleAndLoadEvents();
  }

  Future<void> _fetchCommunity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final community = await _communitiesService.fetchCommunityDetail(
        widget.communityId,
      );
      int? userId;
      try {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getInt(LoginStorageKeys.userId);
      } catch (_) {
        userId = null;
      }
      if (!mounted) {
        return;
      }
      final isOwner =
          userId != null &&
          community.createdById != null &&
          community.createdById == userId;
      developer.log(
        'fetchCommunity -> userId=$userId createdById=${community.createdById} isOwner=$isOwner',
        name: 'CommunityDetailsScreen',
      );
      setState(() {
        _community = community;
        _isLoading = false;
        _isOwner = isOwner;
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

  Future<void> _openRequests() async {
    final community = _community;
    if (community == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunityRequestsScreen(
          communityId: community.id,
          communityName: community.name,
          service: _communitiesService,
        ),
      ),
    );
  }

  Future<void> _requestJoinCommunity() async {
    if (_isJoinRequesting) {
      return;
    }
    setState(() {
      _isJoinRequesting = true;
    });

    try {
      final result = await _communitiesService.requestJoinCommunity(
        widget.communityId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (result.status == CommunityJoinRequestStatus.success ||
            result.status == CommunityJoinRequestStatus.alreadyRequested) {
          _joinRequestSent = true;
        }
      });
      final message =
          result.message ??
          (result.status == CommunityJoinRequestStatus.alreadyRequested
              ? 'Ya cuentas con una solicitud pendiente para esta comunidad.'
              : 'Solicitud enviada correctamente.');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on CommunitiesException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No fue posible enviar la solicitud.')),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isJoinRequesting = false;
      });
    }
  }

  Future<void> _initializeLocaleAndLoadEvents() async {
    try {
      await initializeDateFormatting('es');
    } catch (_) {}

    if (!mounted) {
      return;
    }

    await _loadCommunityEvents();
  }

  Future<void> _loadCommunityEvents() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isEventsLoading = true;
      _eventsErrorMessage = null;
    });

    try {
      final response = await _eventService.fetchCommunityEvents(
        widget.communityId,
        status: _selectedStatus.isNotEmpty ? _selectedStatus : null,
        visibility: _selectedVisibility.isNotEmpty ? _selectedVisibility : null,
        upcomingOnly: _upcomingOnly ? true : null,
        page: 1,
        limit: 20,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _communityEvents = response.events;
        _isEventsLoading = false;
      });
    } on EventException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _eventsErrorMessage = e.message;
        _isEventsLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _eventsErrorMessage =
            'No fue posible cargar los eventos de la comunidad.';
        _isEventsLoading = false;
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
                  child:
                      community.imageUrl != null &&
                          community.imageUrl!.isNotEmpty
                      ? Image.network(community.imageUrl!, fit: BoxFit.cover)
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
            _buildEventsTab(),
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
                  onPressed: _isOwner
                      ? _openRequests
                      : (_isJoinRequesting || _joinRequestSent)
                      ? null
                      : () => _requestJoinCommunity(),
                  icon: _isJoinRequesting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color?>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          _isOwner ? Icons.mail_outline : Icons.group_add,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isOwner
                        ? 'Ver solicitudes'
                        : _isJoinRequesting
                        ? 'Enviando solicitud...'
                        : _joinRequestSent
                        ? 'Solicitud enviada'
                        : 'Solicitar unirme',
                    style: const TextStyle(
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

  Widget _buildEventsTab() {
    return Column(
      children: [
        _buildEventFilters(),
        Expanded(
          child: RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: _loadCommunityEvents,
            child: _buildEventsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEventFilters() {
    final statusItems = const [
      DropdownMenuItem(value: '', child: Text('Todos los estados')),
      DropdownMenuItem(value: 'ACTIVE', child: Text('Activos')),
      DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelados')),
      DropdownMenuItem(value: 'FINISHED', child: Text('Finalizados')),
    ];

    final visibilityItems = const [
      DropdownMenuItem(value: '', child: Text('Todas las visibilidades')),
      DropdownMenuItem(value: 'PUBLIC', child: Text('Públicos')),
      DropdownMenuItem(value: 'PRIVATE', child: Text('Privados')),
    ];

    return Container(
      width: double.infinity,
      color: kBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: statusItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? '';
                    });
                    _loadCommunityEvents();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedVisibility,
                  decoration: const InputDecoration(
                    labelText: 'Visibilidad',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: visibilityItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedVisibility = value ?? '';
                    });
                    _loadCommunityEvents();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Solo próximos eventos'),
            value: _upcomingOnly,
            activeColor: kPrimaryColor,
            onChanged: (value) {
              setState(() {
                _upcomingOnly = value;
              });
              _loadCommunityEvents();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (_isEventsLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_eventsErrorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _eventsErrorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCommunityEvents,
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_communityEvents.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'No hay eventos que coincidan con los filtros seleccionados.',
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _communityEvents.length,
      itemBuilder: (context, index) {
        final event = _communityEvents[index];
        return _buildCommunityEventCard(event);
      },
    );
  }

  Widget _buildCommunityEventCard(Event event) {
    final formatter = DateFormat('EEE d MMM · HH:mm', 'es');
    final dateLabel = formatter.format(event.timeBegin);
    final placeName = event.place?.name ?? 'Ubicación por definir';
    final secondaryPlace = event.place?.direction ?? event.externalUrl;

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
              event.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(dateLabel),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    secondaryPlace?.isNotEmpty == true
                        ? '$placeName · $secondaryPlace'
                        : placeName,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(event.status),
                  backgroundColor: kPrimaryColor.withOpacity(0.15),
                  labelStyle: const TextStyle(color: kPrimaryColor),
                ),
                Chip(
                  label: Text(event.visibility),
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          ],
        ),
      ),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: kBackgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
