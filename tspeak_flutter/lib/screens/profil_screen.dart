import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/patterns_painter.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as models;

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  late Future<models.User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = context.read<UserService>().getUserProfile();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Se déconnecter ?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Tu devras te reconnecter pour accéder à ton profil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthService>().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
      }
    }
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<models.User>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  const Text('Erreur de profil'),
                  ElevatedButton(
                    onPressed: () => setState(() => _userFuture = context.read<UserService>().getUserProfile()),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }
        final user = snapshot.data!;
        return Scaffold(
          body: BackgroundWrapper(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar
                _buildSliverAppBar(user),
                // Content
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Hero Profile Card
                      _buildHeroCard(user),
                      const SizedBox(height: 20),

                      // Stats Row
                      _buildStatsRow(user),
                      const SizedBox(height: 28),

                      // About section (bio, country, goal, interests)
                      if (user.bio.isNotEmpty || user.country.isNotEmpty || user.learningGoal.isNotEmpty || user.interests.isNotEmpty) ...[
                        _buildSectionLabel('À PROPOS DE MOI'),
                        const SizedBox(height: 12),
                        _buildAboutCard(user),
                        const SizedBox(height: 28),
                      ],

                      // Performance Chart
                      _buildSectionLabel('ANALYSE DE PERFORMANCE'),
                      const SizedBox(height: 12),
                      _buildChartCard(),
                      const SizedBox(height: 28),

                      // Badges
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel('COLLECTION DE BADGES'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '8 / 24',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildBadgeGrid(),
                      const SizedBox(height: 28),

                      // Settings
                      _buildSectionLabel('PARAMÈTRES'),
                      const SizedBox(height: 12),
                      _buildSettingsCard(user),
                      const SizedBox(height: 16),

                      // Logout
                      _buildLogoutButton(),
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(models.User user) {
    return SliverToBoxAdapter(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/logo.png', width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(
                    'T.Speak',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showInfoSnackBar('Notifications bientôt disponibles'),
                    style: IconButton.styleFrom(backgroundColor: Colors.white, shape: const CircleBorder()),
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.onSurface),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showInfoSnackBar('Modifier le profil bientôt disponible'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        image: user.avatarUrl.isNotEmpty
                          ? DecorationImage(image: NetworkImage(user.avatarUrl), fit: BoxFit.cover)
                          : null,
                        color: user.avatarUrl.isEmpty ? AppColors.primary.withOpacity(0.1) : null,
                      ),
                      child: user.avatarUrl.isEmpty
                          ? Icon(Icons.person, color: AppColors.primary, size: 20)
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(models.User user) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(
                    user.avatarUrl.isNotEmpty
                        ? user.avatarUrl
                        : 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=200',
                  ),
                ),
              ),
              Positioned(
                bottom: -10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    'LVL ${user.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'SpaceMono',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            user.name,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 26),
          ),
          const SizedBox(height: 6),
          Text(
            _buildSubtitle(user),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          // Email chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mail_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  user.email,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (user.country.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00897B)),
                  const SizedBox(width: 6),
                  Text(
                    user.country,
                    style: const TextStyle(
                      color: Color(0xFF00897B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _buildSubtitle(models.User user) {
    final parts = <String>[];
    parts.add(_levelLabel(user.level));
    if (user.nativeLanguage.isNotEmpty) parts.add(user.nativeLanguage.toUpperCase());
    return parts.join(' • ');
  }

  String _levelLabel(int level) {
    switch (level) {
      case 1: return 'Apprenant';
      case 2: return 'Élémentaire';
      case 3: return 'Intermédiaire';
      case 4: return 'Avancé';
      case 5: return 'Polyglot Explorer';
      default: return 'Apprenant';
    }
  }

  Widget _buildStatsRow(models.User user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.play_circle_outline,
            label: 'Sessions',
            value: user.sessions.toString(),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department,
            label: 'Série',
            value: '${user.streak}j',
            color: const Color(0xFFFF5252),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.track_changes,
            label: 'Moy. Score',
            value: '${(user.averageScore * 100).toInt()}%',
            color: const Color(0xFF00897B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 22,
              fontFamily: 'SpaceMono',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.onSurface.withOpacity(0.4),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(models.User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (user.bio.isNotEmpty)
            _buildInfoRow(Icons.format_quote_rounded, 'Bio', user.bio),
          if (user.learningGoal.isNotEmpty) ...[
            if (user.bio.isNotEmpty) const Divider(height: 24),
            _buildInfoRow(Icons.flag_outlined, 'Objectif', _goalLabel(user.learningGoal)),
          ],
          if (user.interests.isNotEmpty) ...[
            if (user.bio.isNotEmpty || user.learningGoal.isNotEmpty) const Divider(height: 24),
            _buildInfoRow(Icons.interests_outlined, 'Intérêts', user.interests),
          ],
          if (user.ageRange.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.cake_outlined, 'Âge', user.ageRange),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: AppColors.onSurface.withOpacity(0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'travel': return 'Voyager et explorer';
      case 'work': return 'Opportunités professionnelles';
      case 'study': return 'Études à l\'étranger';
      case 'culture': return 'Découvrir une culture';
      case 'family': return 'Communication familiale';
      default: return goal;
    }
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.onSurface.withOpacity(0.4),
        letterSpacing: 2,
        fontWeight: FontWeight.w800,
        fontSize: 10,
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Analyse de\nPerformance', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, height: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Derniers 30 Jours',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.onSurface.withOpacity(0.6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _buildLineData(AppColors.primary, [30, 50, 40, 70, 60, 90]),
                  _buildLineData(const Color(0xFF00897B), [50, 40, 60, 50, 80, 70]),
                  _buildLineData(Colors.amber, [40, 55, 30, 60, 45, 75]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Prononciation', AppColors.primary),
              const SizedBox(width: 16),
              _buildLegend('Fluidité', const Color(0xFF00897B)),
              const SizedBox(width: 16),
              _buildLegend('Lexique', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineData(Color color, List<double> values) {
    return LineChartBarData(
      spots: values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildLegend(String text, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildBadgeGrid() {
    final badges = [
      _BadgeData('🏆', 'Lève-tôt', const Color(0xFFFFF3E0), const Color(0xFFE65100), true),
      _BadgeData('⚡', 'Série 7 jours', const Color(0xFFE0F2F1), const Color(0xFF00897B), true),
      _BadgeData('✨', 'Polyglotte', const Color(0xFFFCE4EC), const Color(0xFFC2185B), true),
      _BadgeData('🎙️', 'Orateur', const Color(0xFFE8EAF6), const Color(0xFF3949AB), true),
      _BadgeData('🏅', 'Élite 50', Colors.grey.shade100, Colors.grey.shade400, false),
      _BadgeData('🔍', 'Explorateur', Colors.grey.shade100, Colors.grey.shade400, false),
      _BadgeData('👨‍🏫', 'Mentor', Colors.grey.shade100, Colors.grey.shade400, false),
      _BadgeData('📝', 'Scribe', Colors.grey.shade100, Colors.grey.shade400, false),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) => _buildBadgeTile(badges[i]),
    );
  }

  Widget _buildBadgeTile(_BadgeData badge) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: badge.bg,
            shape: BoxShape.circle,
            boxShadow: badge.unlocked
                ? [BoxShadow(color: badge.fg.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: badge.unlocked
                ? Text(badge.emoji, style: const TextStyle(fontSize: 28))
                : Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          badge.label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: badge.unlocked ? badge.fg : Colors.grey.shade400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(models.User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsRow(
            icon: Icons.person_outline_rounded,
            label: 'Informations personnelles',
            onTap: () => _showPersonalInfoDialog(user),
          ),
          const Divider(height: 0, indent: 56),
          _buildSettingsRow(
            icon: Icons.settings_outlined,
            label: 'Préférences de l\'application',
            onTap: () => _showInfoSnackBar('Préférences disponibles prochainement'),
          ),
          const Divider(height: 0, indent: 56),
          _buildSettingsRow(
            icon: Icons.help_outline_rounded,
            label: 'Aide & Support',
            onTap: () => _showInfoSnackBar('Support disponible prochainement'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.onSurface.withOpacity(0.7), size: 20),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.onSurface.withOpacity(0.4)),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
        ),
        title: Text(
          'Se déconnecter',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.error),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.error.withOpacity(0.4)),
        onTap: _handleLogout,
      ),
    );
  }

  void _showPersonalInfoDialog(models.User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Informations personnelles', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogRow(Icons.person_outline, 'Nom complet', user.name),
            const SizedBox(height: 12),
            _dialogRow(Icons.mail_outline, 'Email', user.email),
            const SizedBox(height: 12),
            _dialogRow(Icons.location_on_outlined, 'Pays', user.country.isNotEmpty ? user.country : 'Non renseigné'),
            const SizedBox(height: 12),
            _dialogRow(Icons.cake_outlined, 'Tranche d\'âge', user.ageRange.isNotEmpty ? user.ageRange : 'Non renseigné'),
            const SizedBox(height: 12),
            _dialogRow(Icons.language_outlined, 'Langue native', user.nativeLanguage),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _BadgeData {
  final String emoji;
  final String label;
  final Color bg;
  final Color fg;
  final bool unlocked;
  _BadgeData(this.emoji, this.label, this.bg, this.fg, this.unlocked);
}
