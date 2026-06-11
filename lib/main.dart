import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/model_manager.dart';
import 'services/image_service.dart';
import 'services/local_db_service.dart';
import 'viewmodels/chat_view_model.dart';
import 'viewmodels/scan_receipt_view_model.dart';
import 'viewmodels/ledger_view_model.dart';   // LedgerViewModel lives here
import 'viewmodels/onboarding_view_model.dart';
import 'viewmodels/describe_transaction_view_model.dart';  // DescribeTransactionViewModel lives here
import 'viewmodels/theme_view_model.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'services/biometric_service.dart';
import 'views/screens/home_page.dart';
import 'views/screens/onboarding_screen.dart';
import 'views/screens/model_download_screen.dart';
import 'views/screens/describe_transaction_screen.dart';
import 'views/screens/lock_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {}

  FlutterGemma.initialize(maxDownloadRetries: 10);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: true,
  ));

  // Seed default categories and exchange rates on first boot
  await LocalDbService.instance.initializeDatabase();

  final pinEnabled = await BiometricService.instance.isPinEnabled();

  final hasProfile = await LocalDbService.instance.hasProfile();
  final modelExists = await _checkModelOnDisk();

  final prefs = await SharedPreferences.getInstance();
  final skipSetup = prefs.getBool('velo_skip_model_setup') ?? false;

  final targetRoute = !hasProfile
      ? '/onboarding'
      : (modelExists || skipSetup)
          ? '/home'
          : '/model-setup';

  runApp(VeloApp(
    initialRoute: pinEnabled ? '/lock' : targetRoute,
    targetRouteAfterLock: targetRoute,
    initialSetupSkipped: skipSetup,
  ));
}

Future<bool> _checkModelOnDisk() async {
  try {
    final dir = await _docDir();
    final gemma4File = File('$dir/gemma-4-E2B-it.litertlm');
    final gemma3File = File('$dir/gemma-3n-E2B-it-int4.litertlm');
    return (gemma4File.existsSync() && await gemma4File.length() > 100000) ||
           (gemma3File.existsSync() && await gemma3File.length() > 100000);
  } catch (_) {
    return false;
  }
}

Future<String> _docDir() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

class VeloApp extends StatelessWidget {
  final String initialRoute;
  final String targetRouteAfterLock;
  final bool initialSetupSkipped;
  const VeloApp({
    super.key,
    required this.initialRoute,
    required this.targetRouteAfterLock,
    required this.initialSetupSkipped,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeViewModel()),
        ChangeNotifierProvider(
          create: (_) => ModelManager(initialSetupSkipped: initialSetupSkipped),
        ),
        Provider(create: (_) => ImageService()),
        Provider.value(value: LocalDbService.instance),

        // Core Finance ViewModel — ledger, accounts, health scores
        ChangeNotifierProvider(
          create: (ctx) => LedgerViewModel(ctx.read<LocalDbService>())..init(),
        ),

        // AI Chat with context injection
        ChangeNotifierProxyProvider<ModelManager, ChatViewModel>(
          create: (ctx) => ChatViewModel(
            ctx.read<ModelManager>(),
            ctx.read<ImageService>(),
          ),
          update: (_, mm, prev) => prev!,
        ),

        // Natural language → transaction parser
        ChangeNotifierProvider(
          create: (ctx) => DescribeTransactionViewModel(
            ctx.read<ModelManager>(),
            ctx.read<LocalDbService>(),
          ),
        ),

        // Receipt / PDF scanner
        ChangeNotifierProvider<ScanReceiptViewModel>(
          create: (ctx) => ScanReceiptViewModel(
            ctx.read<ModelManager>(),
            ctx.read<ImageService>(),
            ctx.read<LocalDbService>(),
          ),
        ),

        // Onboarding wizard
        ChangeNotifierProvider(
          create: (ctx) => OnboardingViewModel(ctx.read<LocalDbService>()),
        ),
      ],
      child: Consumer<ThemeViewModel>(
        builder: (context, themeVm, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Velo',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeVm.themeMode,
            initialRoute: initialRoute,
            routes: {
              '/lock':          (context) => LockScreen(targetRoute: targetRouteAfterLock),
              '/onboarding':    (context) => const OnboardingScreen(),
              '/home':          (context) => const HomePage(),
              '/model-setup':   (context) => const ModelDownloadSetupScreen(),
              '/describe-tx':   (context) => const DescribeTransactionScreen(),
            },
          );
        },
      ),
    );
  }
}
