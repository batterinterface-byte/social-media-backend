import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.note_alt,
      title: 'Smart Notes',
      description: 'Create beautiful notes with rich formatting, categories, and smart search.',
      color: Colors.blue,
    ),
    OnboardingPage(
      icon: Icons.checklist,
      title: 'Task Management',
      description: 'Organize your tasks with priorities, due dates, and completion tracking.',
      color: Colors.green,
    ),
    OnboardingPage(
      icon: Icons.folder,
      title: 'Document Vault',
      description: 'Scan and store all your documents in one secure place.',
      color: Colors.orange,
    ),
    OnboardingPage(
      icon: Icons.security,
      title: 'Privacy First',
      description: 'PIN lock, encrypted notes, and secure data storage protect your information.',
      color: Colors.purple,
    ),
    OnboardingPage(
      icon: Icons.cloud_sync,
      title: 'Cloud Backup',
      description: 'Export and backup your data securely to the cloud.',
      color: Colors.teal,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_run', false);
    await prefs.setBool('permissions_accepted', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final isDesktop = screenWidth >= 900;
    
    final iconSize = isDesktop ? 100.0 : (isTablet ? 90.0 : 80.0);
    final titleSize = isDesktop ? 36.0 : (isTablet ? 28.0 : 22.0);
    final descSize = isDesktop ? 20.0 : (isTablet ? 16.0 : 14.0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index], iconSize, titleSize, descSize),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 32 : 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? (isMobile ? 24 : 32) : (isMobile ? 8 : 12),
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 48 : 32),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _nextPage,
                        child: Text(
                          _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, double iconSize, double titleSize, double descSize) {
    return Padding(
      padding: EdgeInsets.all(iconSize * 0.4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: iconSize * 0.5, color: page.color),
          ),
          SizedBox(height: iconSize * 0.48),
          Text(
            page.title,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: titleSize * 0.5),
          Text(
            page.description,
            style: TextStyle(
              fontSize: descSize,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}