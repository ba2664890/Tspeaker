import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import '../utils/safe_ui.dart';
import '../widgets/patterns_painter.dart';
import '../services/auth_service.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isHotReloading = false;

  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();
  
  String _selectedCountry = 'Sénégal';
  final List<String> _selectedPassions = [];

  String _selectedLanguage = 'Pulaar';
  String _selectedLevel = 'Intermédiaire';
  String _selectedAgeRange = '18-24';
  String _selectedGoal = 'Social';

  final List<String> _languages = ['Wolof', 'Pulaar', 'Bambara', 'Serer', 'Diola', 'Soninké'];
  final List<String> _ageRanges = ['13-17', '18-24', '25-34', '35-44', '45+'];
  final List<String> _countries = ['Sénégal', 'Guinée', 'Mali', 'Côte d\'Ivoire', 'France', 'États-Unis', 'Autre'];
  final List<String> _passions = ['Mode', 'Tech', 'Foot', 'Musique', 'Cuisine', 'Sport', 'Lecture', 'Voyages'];
  
  final List<Map<String, dynamic>> _goals = [
    {'id': 'Business', 'label': '💼', 'title': 'Business', 'desc': 'Carrière & Pro'},
    {'id': 'Voyage', 'label': '✈️', 'title': 'Voyage', 'desc': 'Tourisme & Découverte'},
    {'id': 'Social', 'label': '🤝', 'title': 'Social', 'desc': 'Amis & Famille'},
    {'id': 'Examen', 'label': '🎓', 'title': 'Examen', 'desc': 'Études & Certifs'},
  ];

  final List<Map<String, dynamic>> _levels = [
    {'title': 'Débutant', 'key': 'beginner', 'desc': 'Quelques mots simples'},
    {'title': 'Intermédiaire', 'key': 'intermediate', 'desc': 'Discussion quotidienne'},
    {'title': 'Avancé', 'key': 'advanced', 'desc': 'Aisance & Précision'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      _handleRegister();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isHotReloading = true);
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _isHotReloading = false);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: BackgroundWrapper(
        child: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    children: [
                      _buildStepAccount(),
                      _buildStepLinguistic(),
                      _buildStepProfile(),
                      _buildStepGoals(),
                    ],
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.onSurface),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo.png', width: 32, height: 32),
                const SizedBox(width: 8),
                Text(
                  'T.SPEAK',
                  style: AppTextStyles.labelUppercase(color: AppColors.primary).copyWith(
                    fontSize: 12,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 24),
      child: Stack(
        children: [
          Container(
            height: 2,
            width: double.infinity,
            color: AppColors.onSurface.withOpacity(0.05),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            height: 2,
            width: (MediaQuery.of(context).size.width - 128) * ((_currentStep + 1) / 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepAccount() {
    return _buildStepWrapper(
      title: 'Identité',
      subtitle: 'Comment devons-nous t\'appeler dans l\'aventure ?',
      children: [
        _buildCapsuleInput(_firstNameController, 'Ton prénom', Icons.person_rounded),
        const SizedBox(height: 16),
        _buildCapsuleInput(_lastNameController, 'Ton nom', Icons.badge_rounded),
        const SizedBox(height: 16),
        _buildCapsuleInput(_emailController, 'Ton email', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildCapsuleInput(
          _passwordController, 
          'Ton mot de passe', 
          Icons.vpn_key_rounded, 
          isPassword: true,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
          obscureText: _obscurePassword,
        ),
        const SizedBox(height: 32),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface.withOpacity(0.6)),
                children: [
                  const TextSpan(text: 'Déjà un compte ? '),
                  TextSpan(
                    text: 'Se connecter',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepLinguistic() {
    return _buildStepWrapper(
      title: 'Linguistique',
      subtitle: 'Adaptation de l\'IA à ton héritage et tes acquis.',
      children: [
        _buildGlassSectionHeader('Quelle est ta langue maternelle ?'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _languages.map((lang) => _buildModernChip(lang, _selectedLanguage, (v) {
            setState(() => _selectedLanguage = lang);
          })).toList(),
        ),
        const SizedBox(height: 48),
        _buildGlassSectionHeader('Ton niveau en anglais'),
        const SizedBox(height: 20),
        ..._levels.map((l) => _buildModernLevelCard(l)),
      ],
    );
  }

  Widget _buildStepProfile() {
    return _buildStepWrapper(
      title: 'Profil',
      subtitle: 'Quelques détails pour personnaliser tes sessions.',
      children: [
        _buildGlassSectionHeader('Ton pays de résidence'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _countries.map((c) => _buildModernChip(c, _selectedCountry, (v) {
            setState(() => _selectedCountry = c);
          })).toList(),
        ),
        const SizedBox(height: 40),
        _buildGlassSectionHeader('Ta tranche d\'âge'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _ageRanges.map((age) => _buildModernChip(age, _selectedAgeRange, (v) {
            setState(() => _selectedAgeRange = age);
          })).toList(),
        ),
        const SizedBox(height: 40),
        _buildCapsuleInput(_bioController, 'Parle-nous de toi en quelques mots', Icons.auto_awesome_rounded, maxLines: 3),
      ],
    );
  }

  Widget _buildStepGoals() {
    return _buildStepWrapper(
      title: 'Objectifs',
      subtitle: 'Visualise ta réussite avec T.Speak.',
      children: [
        _buildGlassSectionHeader('Pourquoi apprends-tu l\'anglais ?'),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: _goals.map((g) => _buildModernGoalCard(g)).toList(),
        ),
        const SizedBox(height: 40),
        _buildGlassSectionHeader('Tes passions'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: _passions.map((p) {
            final isSelected = _selectedPassions.contains(p);
            return _buildModernChip(p, isSelected ? p : '', (v) {
              setState(() {
                if (isSelected) {
                  _selectedPassions.remove(p);
                } else {
                  _selectedPassions.add(p);
                }
              });
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepWrapper({required String title, required String subtitle, required List<Widget> children}) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            title, 
            textAlign: TextAlign.center, 
            style: AppTextStyles.headlineExtraBold(color: AppColors.onSurface).copyWith(
              fontSize: 42,
              height: 1,
            )
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOut),
          const SizedBox(height: 16),
          Text(
            subtitle, 
            textAlign: TextAlign.center, 
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            )
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, curve: Curves.easeOut),
          const SizedBox(height: 48),
          ...children.asMap().entries.map((entry) {
            return entry.value.animate()
              .fadeIn(delay: (200 + entry.key * 50).ms)
              .slideY(begin: 0.1, curve: Curves.easeOut);
          }),
        ],
      ),
    );
  }

  Widget _buildCapsuleInput(
    TextEditingController controller, 
    String hint, 
    IconData icon, 
    {bool isPassword = false, int maxLines = 1, VoidCallback? onToggleVisibility, bool obscureText = false, TextInputType? keyboardType}
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && obscureText,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.onSurface.withOpacity(0.35)),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.primary.withOpacity(0.5),
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ) : const SizedBox(width: 44),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              border: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelUppercase(color: AppColors.primary).copyWith(
          letterSpacing: 2,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildModernChip(String label, String selected, Function(bool) onSelected) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onSelected(true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.onSurface,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildModernLevelCard(Map<String, dynamic> level) {
    final isSelected = _selectedLevel == level['title'];
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = level['title']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.onSurface : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.onSurface : Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              level['title'],
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: isSelected ? Colors.white : AppColors.onSurface,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              level['desc'],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white.withOpacity(0.6) : AppColors.onSurface.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernGoalCard(Map<String, dynamic> goal) {
    final isSelected = _selectedGoal == goal['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = goal['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(goal['label'], style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              goal['title'],
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: isSelected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
            Text(
              goal['desc'],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary.withOpacity(0.6) : AppColors.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
                    ),
                    child: Text(
                      _currentStep == 3 ? 'FINALISER L\'HÉRITAGE' : 'CONTINUER',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ).animate(
                    target: _isHotReloading ? 0 : 1,
                    onPlay: (c) => c.repeat(reverse: true),
                ).shimmer(
                    duration: 3.seconds, 
                    color: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez renseigner votre identité.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final user = await authService.register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text.isNotEmpty ? _passwordController.text : 'demo123456',
        nativeLanguage: _selectedLanguage.toLowerCase(),
        level: _levels.firstWhere((l) => l['title'] == _selectedLevel)['key'],
        bio: _bioController.text,
        country: _selectedCountry,
        learningGoal: _selectedGoal,
        interests: _selectedPassions.join(', '),
        ageRange: _selectedAgeRange,
        gdprConsent: true,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          SafeUI.navigate(context, (ctx) {
            if (mounted) {
              Navigator.pushReplacementNamed(ctx, '/home');
            }
          }, extended: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Échec de la synchronisation.')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Critique: $e')));
      }
    }
  }
}
