import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/patterns_painter.dart';
import '../widgets/top_app_bar.dart';
import 'simulation_active_screen.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  String _selectedFilter = 'Tous';
  final List<String> _filters = ['Tous', 'Business', 'Entretiens', 'Social'];

  final List<Map<String, dynamic>> _simulations = [
    {
      'id': '1',
      'title': 'Négociation de Contrat',
      'category': 'Business',
      'difficulty': 'Intermédiaire',
      'duration': 15,
      'rating': 4.9,
      'imageUrl': 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?w=600',
      'isPremium': true,
    },
    {
      'id': '2',
      'title': 'Entretien Tech Lead',
      'category': 'Entretiens',
      'difficulty': 'Expert',
      'duration': 12,
      'rating': 4.7,
      'imageUrl': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=600',
      'isPremium': false,
    },
    {
      'id': '3',
      'title': 'Cocktail Networking',
      'category': 'Social',
      'difficulty': 'Intermédiaire',
      'duration': 10,
      'rating': 4.8,
      'imageUrl': 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=600',
      'isPremium': false,
    },
    {
      'id': '4',
      'title': 'Startup Pitch',
      'category': 'Business',
      'difficulty': 'Avancé',
      'duration': 8,
      'rating': 5.0,
      'imageUrl': 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=600',
      'isPremium': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: TopAppBar(
                showLogo: true,
                actions: [
                  IconButton(
                    onPressed: () {},
                    style: IconButton.styleFrom(backgroundColor: Colors.white, shape: const CircleBorder()),
                    icon: const Icon(Icons.search_rounded, color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simule le',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: AppColors.onSurface),
                    ),
                    Text(
                      'vrai monde 🌍',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFilterRow(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 24,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildSimulationCard(_simulations[index]),
                  childCount: _simulations.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(color: AppColors.secondary.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(
                  filter,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? Colors.white : AppColors.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSimulationCard(Map<String, dynamic> sim) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SimulationActiveScreen())),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 12)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(sim['imageUrl'], fit: BoxFit.cover),
                  if (sim['isPremium'])
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.tertiary, borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text('PREMIUM', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sim['category'].toUpperCase(), style: const TextStyle(color: AppColors.secondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'SpaceMono')),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.tertiary, size: 16),
                            const SizedBox(width: 4),
                            Text(sim['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'SpaceMono')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(sim['title'], style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Row(
                      children: [
                        _buildTag(sim['difficulty']),
                        const SizedBox(width: 8),
                        _buildTag('${sim['duration']} min'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'SpaceMono')),
    );
  }
}
