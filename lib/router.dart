import 'package:brick_collector/model/CollectablePartGroup.dart';
import 'package:brick_collector/screens/all_parts_screen.dart';
import 'package:brick_collector/screens/group_setup_screen.dart';
import 'package:brick_collector/screens/moc_list_screen.dart';
import 'package:brick_collector/screens/moc_screen.dart';
import 'package:brick_collector/screens/my_sets_screen.dart';
import 'package:brick_collector/screens/part_group_screen.dart';
import 'package:brick_collector/screens/part_summary_screen.dart';
import 'package:brick_collector/screens/parts_filter_screen.dart';
import 'package:brick_collector/screens/piece_counter_screen.dart';
import 'package:brick_collector/screens/preset_list_screen.dart';
import 'package:brick_collector/screens/preset_screen.dart';
import 'package:brick_collector/screens/set_screen.dart';
import 'package:brick_collector/model/cached_source.dart';
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
  static const String allParts = '/allparts';
  static const String mySets = '/sets';
  static const String pieceCounter = '/count';
  static const String settings = '/settings';
  static const String collected = '/collected';
  static const String detail = '/moc/:id';

  static String partGroup(String partNum) => '/partgroup/$partNum';

  static String partSummary(String partNum) => '/partsummary/$partNum';

  static String mocPage(String? id) => '/moc/${id ?? 'new'}';

  static String partFilterPage(String id) => '/filter/$id';

  static String partFilterEditPage(String id) => '/filter/edit/$id';

  static String presetPage(String id) => '/preset/$id';

  static String setPage(String setNum) => '/set/$setNum';
}

class PartRouteData {
  /// A MOC's part: collectable and editable, saved with the MOC.
  PartRouteData(this.group, this.moc)
      : onSave = null,
        collectable = true,
        editable = true;

  /// A set's part, shown through an unsaved [moc]: changes go to [onSave],
  /// never into the MOC list. Not editable, as a set's parts come from
  /// Rebrickable.
  PartRouteData.forSet(this.group, this.moc, {required VoidCallback this.onSave, required this.collectable})
      : editable = false;

  final CollectablePartGroup group;
  final Moc moc;

  /// Persists changes made on the part screen; null saves [moc] as a MOC.
  final VoidCallback? onSave;

  /// Whether colours can be collected (a set outside Verkauf can't).
  final bool collectable;

  /// Whether colours can be added, edited and deleted.
  final bool editable;
}

/// Routing table, matches string paths to UI Screens, optionally parses params from the paths
final appRouter = GoRouter(
  redirect: _handleRedirect,
  routes: [
    AppRoute(ScreenPaths.splash, (_) => Container(color: AppColors.bg)),
    AppRoute(ScreenPaths.setup, (_) => const GroupSetupScreen()),
    AppRoute(ScreenPaths.home, (_) => const MocListScreen()),
    AppRoute(ScreenPaths.parts, (_) => const PresetListScreen()),
    AppRoute(ScreenPaths.allParts, (_) => const AllPartsScreen()),
    AppRoute(ScreenPaths.mySets, (_) => const MySetsScreen()),
    AppRoute(ScreenPaths.pieceCounter, (_) => const PieceCounterScreen()),
    AppRoute('/partgroup/:partNum', (s) {
      return PartGroupScreen(s.extra! as PartRouteData);
    }, useFade: true),
    AppRoute('/partsummary/:partNum', (s) {
      final part = s.extra! as CollectablePart;
      final qp = s.uri.queryParameters;
      final colorsParam = qp['colors'];
      final allColors = qp['all'] == '1';
      Set<int>? initial;
      if (colorsParam != null && colorsParam.isNotEmpty) {
        initial = colorsParam
            .split(',')
            .map((e) => int.tryParse(e.trim()))
            .whereType<int>()
            .toSet();
        if (initial.isEmpty) initial = null;
      } else if (!allColors) {
        // Legacy single-color entry (e.g. tapping a specific colour chip): the
        // part's own colour drives the filter.
        final cid = int.tryParse(part.color ?? '');
        if (cid != null) initial = {cid};
      }
      return PartSummaryScreen(part, initialColorIds: initial);
    }, useFade: true),
    AppRoute('/filter/:id', (s) {
      final filterId = s.pathParameters["id"]!;
      return PartsFilterScreen(filterId);
    }, useFade: true),
    AppRoute('/filter/edit/:id', (s) {
      final filterId = s.pathParameters["id"]!;
      return PartsFilterScreen(filterId);
    }, useFade: true),
    AppRoute('/preset/:id', (s) {
      final id = s.pathParameters["id"]!;
      return PresetScreen(id);
    }, useFade: true),
    AppRoute('/set/:setNum', (s) {
      // extra only gives the name a head start; the screen loads by number.
      final extra = s.extra;
      return SetScreen(s.pathParameters['setNum']!, initial: extra is CachedSource ? extra : null);
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
