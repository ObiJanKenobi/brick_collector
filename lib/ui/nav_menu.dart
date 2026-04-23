import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:brick_collector/services/collection_sync_service.dart';
import 'package:brick_collector/services/group_service.dart';
import 'package:brick_collector/ui/modals/sync_progress_modal.dart';
import 'package:brick_collector/util/rebrickable_url_parser.dart';

import '../common_libs.dart';

class NavMenu extends StatefulWidget {
  const NavMenu({super.key});

  @override
  State<StatefulWidget> createState() => NavMenuState();
}

class NavMenuState extends State<NavMenu> {
  NavMenuState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Moc>>(
        stream: mocLogic.outMocs,
        builder: (context, snapshot) {
          final group = GroupService.instance;
          return SafeArea(
            child: Column(children: [
              const SizedBox(height: 24),
              // App title
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.widgets, color: AppColors.highlightColor, size: 28),
                    SizedBox(width: 10),
                    Text('Brick Collector', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (group.hasGroup) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: group.groupCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.activeEntry?.displayName ?? 'Group',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(children: [
                            Text(
                              group.groupCode,
                              style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700,
                                letterSpacing: 4, color: AppColors.highlightColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.copy, size: 14, color: AppColors.textSecondary),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Divider(height: 1),
              _navItem(context, Icons.home_outlined, 'MOCs', () => context.go(ScreenPaths.home)),
              _navItem(context, Icons.filter_list, 'Presets', () => context.go(ScreenPaths.parts)),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4, right: 12),
                child: Row(
                  children: [
                    Text('MY MOCs',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary.withValues(alpha: 0.6), letterSpacing: 1)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _addMoc(context),
                      child: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.highlightColor),
                    ),
                  ],
                ),
              ),
              if (snapshot.data != null && snapshot.data!.isNotEmpty)
                ...snapshot.data!.map((e) => _navItem(
                  context, Icons.widgets_outlined, e.name,
                  () => context.go(ScreenPaths.mocPage(e.firestoreId), extra: e),
                )),
              const Spacer(),
              const Divider(height: 1),
              _accountItem(context),
              _syncItem(context),
            ]),
          );
        });
  }

  void _addMoc(BuildContext context) async {
    Navigator.of(context).pop(); // close drawer first

    final text = await showTextInputDialog(
      context: context,
      textFields: const [
        DialogTextField(hintText: 'Name or Rebrickable URL'),
      ],
      title: 'Create a new Collection',
    );

    if (text == null || text.isEmpty == true || text.first.trim().isEmpty) {
      return;
    }

    final input = text.first.trim();
    final parsed = RebrickableUrlParser.tryParse(input);

    if (parsed != null) {
      final moc = await mocLogic.addNewMoc(
        parsed.displayName,
        sourceUrl: parsed.originalUrl,
        imageUrl: parsed.imageUrl,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Created '${parsed.displayName}'")),
      );

      final result = await showOkCancelAlertDialog(
        context: context,
        title: 'Import Parts',
        message: 'Import parts CSV now?',
      );

      if (result == OkCancelResult.ok && context.mounted) {
        await appLogic.addPartsToMoc(moc);
      }

      if (context.mounted) {
        context.go(ScreenPaths.mocPage(moc.firestoreId), extra: moc);
      }
    } else if (RebrickableUrlParser.looksLikeUrl(input)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unrecognized URL. Please enter a name or a Rebrickable MOC URL.')),
      );
    } else {
      await mocLogic.addNewMoc(input);
    }
  }

  Widget _accountItem(BuildContext context) {
    final loggedIn = appLogic.loggedIn;
    final username = appLogic.username;
    final statusColor = loggedIn ? const Color(0xFF7BC043) : AppColors.textSecondary;
    final statusLabel = loggedIn ? (username ?? 'Logged in') : 'Not logged in';

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.account_circle_outlined, color: AppColors.textSecondary, size: 20),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
        ],
      ),
      title: Text(
        loggedIn ? 'Rebrickable' : 'Login to Rebrickable',
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      ),
      subtitle: Text(
        statusLabel,
        style: TextStyle(color: statusColor, fontSize: 11),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: loggedIn
          ? const Icon(Icons.logout, size: 18, color: AppColors.textSecondary)
          : const Icon(Icons.login, size: 18, color: AppColors.highlightColor),
      dense: true,
      onTap: () async {
        Navigator.of(context).pop();
        if (appLogic.loggedIn) {
          final confirm = await showOkCancelAlertDialog(
            context: context,
            title: 'Log out',
            message: 'Log out and clear the local inventory cache?',
            okLabel: 'Log out',
            isDestructiveAction: true,
          );
          if (confirm != OkCancelResult.ok) return;
          await appLogic.logout();
        } else {
          await loginUser(context);
        }
        if (mounted) setState(() {});
      },
    );
  }

  Widget _syncItem(BuildContext context) {
    return FutureBuilder<DateTime?>(
      future: collectionSyncService.getLastSyncAt(),
      builder: (context, snapshot) {
        final last = snapshot.data;
        final subtitle = last == null ? 'Never synced' : 'Last: ${_formatSyncTime(last)}';
        return ListTile(
          leading: const Icon(Icons.sync, color: AppColors.textSecondary, size: 20),
          title: const Text('Sync Collection', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          dense: true,
          onTap: () async {
            Navigator.of(context).pop();
            await showSyncProgressModal(context);
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  String _formatSyncTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
      dense: true,
      visualDensity: const VisualDensity(vertical: -1),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}
