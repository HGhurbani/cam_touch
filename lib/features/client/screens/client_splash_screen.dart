// lib/features/client/screens/client_splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // Import for page indicator
import 'dart:async'; // Import for Timer

import '../../../core/services/auth_service.dart';
import '../../../routes/app_router.dart';
import '../../shared/widgets/custom_button.dart';

class ClientSplashScreen extends StatefulWidget {
  const ClientSplashScreen({super.key});

  @override
  State<ClientSplashScreen> createState() => _ClientSplashScreenState();
}

class _ClientSplashScreenState extends State<ClientSplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // List of splash screen content for the flipping effect
  final List<Map<String, String>> _splashContent = [
    {
      'title': 'مرحباً بك في Cam Touch',
      'description':
      'متخصصون في توثيق الفعاليات والمناسبات باحترافية عالية، وعدسة تلتقط أكثر من مجرد صورة — تخلّد لحظة، وتحكي قصة. بجودة لا تُضاهى وفريق مبدع، نمنح كل مناسبة طابعاً فنياً يبقى في الذاكرة.',
    },
    {
      'title': 'لحظاتك، قصتنا',
      'description':
      'نؤمن بأن كل لحظة تستحق أن تُروى. فريقنا من المصورين المحترفين هنا لضمان أن تبقى ذكرياتك حية ونابضة بالحياة، من خلال صور وفيديوهات عالية الجودة.',
    },
    {
      'title': 'سهولة الحجز، جودة لا تضاهى',
      'description':
      'مع Cam Touch، أصبح حجز مصور لفعاليتك أسهل من أي وقت مضى. تصفح، احجز، ودعنا نعتني بالباقي. تجربة احترافية تبدأ من هنا.',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Start auto-scrolling the PageView
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _splashContent.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    _pageController.dispose(); // Dispose the page controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;
    final secondaryColor = Theme.of(context).colorScheme.secondary;

    // Redirect if already logged in (existing logic)
    if (authService.currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authService.userRole == UserRole.client) {
          Navigator.of(context).pushReplacementNamed(AppRouter.clientDashboardRoute);
        } else if (authService.userRole == UserRole.photographer) {
          Navigator.of(context).pushReplacementNamed(AppRouter.photographerDashboardRoute);
        } else if (authService.userRole == UserRole.admin) {
          Navigator.of(context).pushReplacementNamed(AppRouter.adminDashboardRoute);
        }
      });
      return const CircularProgressIndicator();
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Use a linear gradient with the primary and secondary colors
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor.withOpacity(0.8)], // Slight opacity for secondary
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _splashContent.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Image.asset('assets/img/white_logo.png', height: 150), // Larger logo
                        const SizedBox(height: 40),
                        // Title
                        Text(
                          _splashContent[index]['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32, // Larger font size
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        // Description
                        Text(
                          _splashContent[index]['description']!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            height: 1.5, // Increase line height for readability
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page Indicator
            SmoothPageIndicator(
              controller: _pageController,
              count: _splashContent.length,
              effect: ExpandingDotsEffect(
                dotColor: Colors.white38,
                activeDotColor: Colors.white,
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
              ),
            ),
            const SizedBox(height: 40),
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  CustomButton(
                    text: 'إنشاء حساب',
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRouter.registerRoute,
                        arguments: UserRole.client,
                      );
                    },
                    color: secondaryColor, // Use secondary color for primary action
                    textColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.loginRoute);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white, // Text color for the button
                      side: const BorderSide(color: Colors.white, width: 1.5), // White border
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), // Rounded corners
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                      minimumSize: const Size(double.infinity, 50), // Ensure full width
                    ),
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // More space at the bottom
          ],
        ),
      ),
    );
  }
}