import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/screens/group_setup_screen.dart';
import 'package:brick_collector/screens/moc_list_screen.dart';
import 'package:brick_collector/screens/moc_screen.dart';
import 'package:brick_collector/screens/part_group_screen.dart';
import 'package:brick_collector/screens/part_summary_screen.dart';
import 'package:brick_collector/screens/parts_filter_screen.dart';
import 'package:brick_collector/screens/preset_list_screen.dart';
import 'package:brick_collector/screens/preset_screen.dart';
import 'package:brick_collector/model/collectable_part.dart';
import 'package:brick_collector/services/group_service.dart';
import 'package:brick_collector/ui/app_colors.dart';
import 'package:brick_collector/ui/back_button.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:flutter/cupertino.dart';
import 'package:brick_collector/common_libs.dart';

/// Shared paths / urls used across the app
class ScreenPaths {
  static const String splash = '/';
  static const String setup = '/setup';
  static const String home = '/home';
  static const String parts = '/parts';
  static const String settings = '/settings';
  static const String collected = '/collected';
  static const String detail = '/moc/:id';

  static String partGroup(String partNum) => '/partgroup/$partNum';

  static String partSummary(String partNum) => '/partsummary/$partNum';

  static String mocPage(String? id) => '/moc/${id ?? 'new'}';

  static String partFilterPage(int id) => '/filter/$id';

  static String partFilterEditPage(int id) => '/filter/edit/$id';

  static String presetPage(int id) => '/preset/$id';
}

class PartRouteData {
  final CollectablePartGroup group;
  final Moc moc;

  PartRouteData(this.group, this.moc);
}

/// Routing table, matches string paths to UI Screens, optionally parses params from the paths
final appRouter = GoRouter(
  redirect: _handleRedirect,
  routes: [
    AppRoute(ScreenPaths.splash, (_) => Container(color: AppColors.bg)),
    AppRoute(ScreenPaths.setup, (_) => const GroupSetupScreen()),
    AppRoute(ScreenPaths.home, (_) => const MocListScreen()),
    AppRoute(ScreenPaths.parts, (_) => const PresetListScreen()),
    AppRoute('/partgroup/:partNum', (s) {
      final data = s.extra! as PartRouteData;
      return PartGroupScreen(data.group, data.moc);
    }, useFade: true),
    AppRoute('/partsummary/:partNum', (s) {
      final part = s.extra! as CollectablePart;
      return PartSummaryScreen(part);
    }, useFade: true),
    AppRoute('/filter/:id', (s) {
      final filterId = s.pathParameters["id"];
      final preset = partsLogic.getPresetById(int.parse(filterId!));
      return PartsFilterScreen(preset);
    }, useFade: true),
    AppRoute('/filter/edit/:id', (s) {
      final filterId = s.pathParameters["id"];
      final preset = partsLogic.getPresetById(int.parse(filterId!));
      return PartsFilterScreen(preset);
    }, useFade: true),
    AppRoute('/preset/:id', (s) {
      final id = int.parse(s.pathParameters["id"]!);
      return PresetScreen(id);
    }, useFade: true),
    AppRoute(ScreenPaths.detail, (s) {
      final moc = s.extra! as Moc;
      return MocScreen(moc);
    }, useFade: true),
  ],
);

/// Custom GoRoute sub-class to make the router declaration easier to read
class AppRoute extends GoRoute {
  AppRoute(String path, Widget Function(GoRouterState s) builder, {List<GoRoute> routes = const [], this.useFade = false})
      : super(
    path: path,
    routes: routes,
    pageBuilder: (context, state) {
      final pageContent = Scaffold(
        body: builder(state),
        resizeToAvoidBottomInset: false,
      );
      if (useFade) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: pageContent,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      }
      return MaterialPage(child: pageContent);
    },
  );
  final bool useFade;
}

String? _handleRedirect(BuildContext context, GoRouterState state) {
  // Prevent anyone from navigating away from `/` if app is starting up.
  if (!appLogic.isBootstrapComplete && state.matchedLocation != ScreenPaths.splash) {
    return ScreenPaths.splash;
  }

  // If no group is set up, redirect to setup screen.
  if (appLogic.isBootstrapComplete && !GroupService.instance.hasGroup && state.matchedLocation != ScreenPaths.setup) {
    return ScreenPaths.setup;
  }

  debugPrint('Navigate to: ${state.matchedLocation}');
  return null; // do nothing
}
