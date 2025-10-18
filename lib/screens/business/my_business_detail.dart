import 'package:flutter/material.dart';
import 'package:hackathon_frontend/services/places_service.dart';
import 'package:hackathon_frontend/services/products_service.dart';

import '../auth/login.dart'; // Para los colores
//import 'create_event_screen.dart'; // Descomentar cuando la tengas
import 'products/create_products.dart';

// Modelos de datos (pueden vivir en sus propios archivos)
class BusinessPlan {
  final String title;
  final String status;
  final int peopleJoined;
  final int views;
  BusinessPlan({
    required this.title,
    required this.status,
    required this.peopleJoined,
    required this.views,
  });
}

class Review {
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;
  Review({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

// --- Pantalla de Detalle y Panel de Control de un Negocio Específico ---
class BusinessDetailsScreen extends StatefulWidget {
  final PlaceSummary place;

  const BusinessDetailsScreen({super.key, required this.place});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final ProductsService _productsService = ProductsService();
  final List<ProductSummary> _products = [];
  bool _isLoadingProducts = false;
  String? _productsError;

  // --- Datos de Ejemplo (en una app real, los buscarías usando widget.business.id) ---
  final List<BusinessPlan> _activePlans = [
    BusinessPlan(
      title: '2x1 en Mojitos los Jueves',
      status: 'Activo',
      peopleJoined: 45,
      views: 1200,
    ),
    BusinessPlan(
      title: 'Noche de Stand-Up Comedy',
      status: 'Activo',
      peopleJoined: 88,
      views: 3500,
    ),
    BusinessPlan(
      title: 'Música en Vivo - Viernes Acústico',
      status: 'Pausado',
      peopleJoined: 150,
      views: 5000,
    ),
  ];
  final List<Review> _recentReviews = [
    Review(
      userName: 'Ana R.',
      rating: 5,
      comment: '¡El ambiente es increíble! Los mojitos 10/10.',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Review(
      userName: 'Carlos V.',
      rating: 4,
      comment:
          'Buen lugar para ir con panas. A veces tardan un poco en atender.',
      date: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Panel de Negocio',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: kPrimaryColor),
            onPressed: () {},
            tooltip: 'Editar Perfil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildProductsSection(),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildPlansSection(),
            const SizedBox(height: 24),
            _buildReviewsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateEventScreen()));
          print('Crear nuevo plan para ${widget.place.name}');
        },
        backgroundColor: kPrimaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Plan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- Widgets de la UI (ahora usan widget.business) ---

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final result = await _productsService.fetchProducts(
        placeId: widget.place.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _products
          ..clear()
          ..addAll(result);
      });
    } on ProductsException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _productsError = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _productsError = 'No pudimos cargar los productos del negocio.';
      });
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  bool _isValidHttpUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    final scheme = uri.scheme.toLowerCase();
    return (scheme == 'http' || scheme == 'https') && uri.host.isNotEmpty;
  }

  Future<void> _openCreateProduct() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateProductScreen(placeId: widget.place.id),
      ),
    );

    if (created == true) {
      await _loadProducts();
    }
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: kPrimaryColor.withOpacity(0.2),
            backgroundImage:
                widget.place.imageUrl != null &&
                    widget.place.imageUrl!.isNotEmpty
                ? NetworkImage(widget.place.imageUrl!)
                : null,
            child:
                widget.place.imageUrl != null &&
                    widget.place.imageUrl!.isNotEmpty
                ? null
                : const Icon(
                    Icons.store_mall_directory,
                    color: kPrimaryColor,
                    size: 48,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.place.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.place.city}, ${widget.place.country}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusChip(widget.place.status),
              _buildInfoChip(
                Icons.people_outline,
                '${widget.place.capacity} de capacidad',
              ),
              _buildInfoChip(
                Icons.event_note_outlined,
                '${widget.place.eventsCount} eventos',
              ),
              _buildInfoChip(
                Icons.reviews_outlined,
                '${widget.place.reviewsCount} reseñas',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Productos destacados',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.topRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton(
                      onPressed: _isLoadingProducts ? null : _loadProducts,
                      icon: Icon(
                        Icons.refresh,
                        color:
                            _isLoadingProducts ? Colors.grey : kPrimaryColor,
                      ),
                      tooltip: 'Recargar productos',
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoadingProducts ? null : _openCreateProduct,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo producto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingProducts && _products.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (_productsError != null && _products.isEmpty)
          _buildProductsError()
        else if (_products.isEmpty)
          _buildProductsEmpty()
        else
          Column(
            children: [
              ..._products.map(_buildProductCard).toList(),
              if (_isLoadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildProductCard(ProductSummary product) {
    final hasValidImage = _isValidHttpUrl(product.image);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasValidImage
                  ? Image.network(
                      product.image!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: kPrimaryColor.withOpacity(0.1),
                      child: const Icon(
                        Icons.fastfood_outlined,
                        color: kPrimaryColor,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.promotions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: product.promotions
                          .map((promo) => _buildPromotionChip(promo))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromotionChip(ProductPromotion promo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_offer_outlined,
            size: 14,
            color: Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            '-${promo.discount}% ${promo.membership}'.trim(),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsError() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: Colors.redAccent.shade200, size: 40),
        const SizedBox(height: 12),
        Text(
          _productsError ?? 'Error al cargar productos',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _loadProducts,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.sentiment_dissatisfied, color: kPrimaryColor, size: 40),
          SizedBox(height: 12),
          Text(
            'Aún no has registrado productos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // (El resto de los widgets _build... se mantienen igual ya que usan datos de ejemplo)

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rendimiento del Mes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard(
              'Visitas al Perfil',
              '7,8k',
              Icons.visibility_outlined,
              Colors.blue,
            ),
            _buildStatCard(
              'Planes Activos',
              _activePlans.where((p) => p.status == 'Activo').length.toString(),
              Icons.event_available_outlined,
              Colors.green,
            ),
            _buildStatCard(
              'Nuevos Clientes',
              '125',
              Icons.person_add_alt_1_outlined,
              Colors.orange,
            ),
            _buildStatCard(
              'Nuevas Reseñas',
              '12',
              Icons.rate_review_outlined,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis Planes y Promociones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._activePlans.map((plan) => _buildPlanCard(plan)).toList(),
      ],
    );
  }

  Widget _buildPlanCard(BusinessPlan plan) {
    Color statusColor = plan.status == 'Activo' ? Colors.green : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          plan.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${plan.peopleJoined} asistieron • ${plan.views} vistas',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                plan.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {},
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Editar'),
                ),
                const PopupMenuItem<String>(
                  value: 'pause',
                  child: Text('Pausar'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reseñas Recientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._recentReviews.map((review) => _buildReviewCard(review)).toList(),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
        color = Colors.green;
        break;
      case 'PENDING':
        color = Colors.orange;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      default:
        color = kPrimaryColor;
        break;
    }

    return Chip(
      label: Text(
        status.isEmpty ? 'Sin estado' : status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kPrimaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: kPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
