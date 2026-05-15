import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'services/user_service.dart';
import 'services/notification_service.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  await NotificationService.initialize();

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZooWallet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _foxAnim;
  late Animation<double> _catAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Con mèo chạy từ phải vào giữa
    _catAnim = Tween<double>(begin: 1.5, end: 0.0)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6,
          curve: Curves.easeOut),
    ));

    // Con cáo chạy theo sau
    _foxAnim = Tween<double>(begin: 2.0, end: 0.3)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.7,
          curve: Curves.easeOut),
    ));

    // Text fade in
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0,
          curve: Curves.easeIn),
    ));

    _controller.forward();
    _checkUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkUser() async {
    await Future.delayed(
        const Duration(milliseconds: 1800));
    if (!mounted) return;

    final hasUser = await UserService.hasUser();
    if (!mounted) return;

    if (hasUser) {
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance
              .signInAnonymously();
        } catch (_) {}
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasUser
            ? const HomeScreen()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Mascot animation ──
            SizedBox(
              height: 140,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Con mèo (chạy trước)
                      Positioned(
                        left: w * 0.5 +
                            _catAnim.value * w * 0.5 -
                            50,
                        bottom: 10,
                        child: Image.asset(
                          'assets/mascots/cat.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Con cáo (đuổi theo)
                      Positioned(
                        left: w * 0.5 +
                            _foxAnim.value * w * 0.5 -
                            50,
                        bottom: 10,
                        child: Image.asset(
                          'assets/mascots/fox.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── App name fade in ──
            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (context, child) => Opacity(
                opacity: _fadeAnim.value,
                child: child,
              ),
              child: const Text(
                'ZooWallet',
                style: AppTextStyles.heading2,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (context, child) => Opacity(
                opacity: _fadeAnim.value,
                child: child,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}