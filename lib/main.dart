import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/logic/db_logic.dart';
import 'package:brick_collector/logic/moc_logic.dart';
import 'package:brick_collector/logic/parts_logic.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/services/group_service.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_lib/logic/brick_converter_logic.dart';
import 'package:brick_lib/service/rebrickable_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:brick_collector/firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

const String? _userPrefill = bool.hasEnvironment('USER_ID') ? String.fromEnvironment('USER_ID') : null;
const String? _userPasswordPrefill = bool.hasEnvironment('USER_PASSWORD') ? String.fromEnvironment('USER_PASSWORD') : null;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GroupService.instance.initialize();

  registerSingletons();

  runApp(MyApp());
  await appLogic.bootstrap();

  FlutterNativeSplash.remove();
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _authComplete = false;

  @override
  void initState() {
    super.initState();
    _signIn();
  }

  Future<void> _signIn() async {
    try {
      await GroupService.instance.ensureSignedIn();
    } catch (e) {
      debugPrint('Auth error (continuing without auth): $e');
    }
    if (mounted) setState(() => _authComplete = true);
  }

  ThemeData _buildTheme() {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.highlightColor,
        brightness: Brightness.dark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: AppColors.surface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.highlightColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surface,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceLight,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: AppColors.textSecondary),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textSecondary),
        labelLarge: TextStyle(color: AppColors.textPrimary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.highlightColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.highlightColor;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.highlightColor.withValues(alpha: 0.4);
          return AppColors.surfaceLight;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authComplete) {
      return MaterialApp(
        title: 'Brick Collector',
        theme: _buildTheme(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'Brick Collector',
      theme: _buildTheme(),
    );
  }
}

/// Create singletons (logic and services) that can be shared across the app.
void registerSingletons() {
  GetIt.I.registerLazySingleton<AppLogic>(() => AppLogic());
  GetIt.I.registerLazySingleton<DbLogic>(() => DbLogic());
  GetIt.I.registerLazySingleton<MocLogic>(() => MocLogic());
  GetIt.I.registerLazySingleton<PartsLogic>(() => PartsLogic());
  GetIt.I.registerLazySingleton<BrickConverterLogic>(() => BrickConverterLogic());
  GetIt.I.registerLazySingleton<RebrickableService>(() => RebrickableService());
  GetIt.I.registerLazySingleton<CollectionSyncService>(() => CollectionSyncService());
}

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
AppLogic get appLogic => GetIt.I.get<AppLogic>();

BrickConverterLogic get brickConverterLogic => GetIt.I.get<BrickConverterLogic>();

DbLogic get dbLogic => GetIt.I.get<DbLogic>();

MocLogic get mocLogic => GetIt.I.get<MocLogic>();
PartsLogic get partsLogic => GetIt.I.get<PartsLogic>();

RebrickableService get rbService => GetIt.I.get<RebrickableService>();

String getLabel(PartSort e) {
  switch (e) {
    case PartSort.nameDesc:
      return "Name descending";
    case PartSort.nameAsc:
      return "Name ascending";
    case PartSort.collectedDesc:
      return "Collected count descending";
    case PartSort.collectedAsc:
      return "Collected count ascending";
    case PartSort.quantityDesc:
      return "Quantity descending";
    case PartSort.quantityAsc:
      return "Quantity ascending";
  }
}

Future<void> loginUser(BuildContext context) async {
  if (appLogic.loggedIn) return;

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const _LoginDialog(),
  );

  if (!context.mounted) return;
  if (ok == null) return;

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(ok ? "Login successful" : "Login failed"),
  ));

  if (!ok) return;

  final lastSync = await collectionSyncService.getLastSyncAt();
  if (lastSync != null) return;
  if (!context.mounted) return;

  final result = await showOkCancelAlertDialog(
    context: context,
    title: 'Sync collection?',
    message: 'Your sets and part lists have not been synced yet. Sync now?',
    okLabel: 'Sync now',
    cancelLabel: 'Later',
  );
  if (result == OkCancelResult.ok && context.mounted) {
    await showSyncProgressModal(context);
  }
}

class _LoginDialog extends StatefulWidget {
  const _LoginDialog();

  @override
  State<_LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<_LoginDialog> {
  late final _emailController = TextEditingController(text: _userPrefill ?? '');
  late final _passwordController = TextEditingController(text: _userPasswordPrefill ?? '');
  bool _submitting = false;

  Future<void> _submit() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) return;

    setState(() => _submitting = true);
    final ok = await appLogic.loginUser(username, password);
    if (!mounted) return;
    Navigator.of(context).pop(ok);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: AlertDialog(
        title: const Text('Login', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Enter your Rebrickable credentials', style: TextStyle(color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                floatingLabelStyle: TextStyle(color: AppColors.highlightColor),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                floatingLabelStyle: TextStyle(color: AppColors.highlightColor),
              ),
              onSubmitted: (_) => _submitting ? null : _submit(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(null),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.highlightColor,
                    ),
                  )
                : const Text('Login', style: TextStyle(color: AppColors.highlightColor)),
          ),
        ],
      ),
    );
  }
}
