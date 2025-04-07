import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/logic/db_logic.dart';
import 'package:brick_collector/logic/moc_logic.dart';
import 'package:brick_collector/logic/parts_logic.dart';
import 'package:brick_lib/logic/brick_converter_logic.dart';
import 'package:brick_lib/service/rebrickable_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

const String? _userPrefill = bool.hasEnvironment('USER_ID') ? String.fromEnvironment('USER_ID') : null;
const String? _userPasswordPrefill = bool.hasEnvironment('USER_ID') ? String.fromEnvironment('USER_PASSWORD') : null;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep native splash screen up until app is finished bootstrapping
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Start app
  registerSingletons();

  runApp(MyApp());
  await appLogic.bootstrap();

  // Remove splash screen when bootstrap is complete
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget with GetItMixin {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // routeInformationProvider: appRouter.routeInformationProvider,
      // routeInformationParser: appRouter.routeInformationParser,
      // routerDelegate: appRouter.routerDelegate,
      routerConfig: appRouter,
      title: 'MOC Part Collector',
      theme: ThemeData.from(
              useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seedColor, secondary: AppColors.contentColor))
          .copyWith(
              appBarTheme: AppBarTheme.of(context).copyWith(backgroundColor: AppColors.navItemBgColor),
              floatingActionButtonTheme: Theme.of(context).floatingActionButtonTheme.copyWith(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100.0)),
                  ),
              // backgroundColor: const Color(0xFFEBEBEB),
              scaffoldBackgroundColor: const Color(0xFFEBEBEB)),
    );
  }
}

/// Create singletons (logic and services) that can be shared across the app.
void registerSingletons() {
  // Top level app controller
  GetIt.I.registerLazySingleton<AppLogic>(() => AppLogic());
  GetIt.I.registerLazySingleton<DbLogic>(() => DbLogic());
  GetIt.I.registerLazySingleton<MocLogic>(() => MocLogic());
  GetIt.I.registerLazySingleton<PartsLogic>(() => PartsLogic());
  GetIt.I.registerLazySingleton<BrickConverterLogic>(() => BrickConverterLogic());
  GetIt.I.registerLazySingleton<RebrickableService>(() => RebrickableService());
}

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
/// We deliberately do not create shortcuts for services, to discourage their use directly in the view/widget layer.
AppLogic get appLogic => GetIt.I.get<AppLogic>();

BrickConverterLogic get brickConverterLogic => GetIt.I.get<BrickConverterLogic>();

DbLogic get dbLogic => GetIt.I.get<DbLogic>();

MocLogic get mocLogic => GetIt.I.get<MocLogic>();
PartsLogic get partsLogic => GetIt.I.get<PartsLogic>();

RebrickableService get rbService => GetIt.I.get<RebrickableService>();

String getLabel(PartSort e) {
  switch (e) {
    // case PartSort.color:
    //   return "By Color";
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
  if (!appLogic.loggedIn) {
    final text = await showTextInputDialog(
      context: context,
      textFields: [
        const DialogTextField(
          hintText: 'Email',
          initialText: _userPrefill,
        ),
        const DialogTextField(
          hintText: 'Password',
          initialText: _userPasswordPrefill,
          obscureText: true,
        ),
      ],
      title: 'Login',
      message: 'Enter your credentials',
    );
    if (text == null) return;

    final username = text[0];
    final password = text[1];

    await appLogic.loginUser(username, password);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Successfull")));
  }
}
