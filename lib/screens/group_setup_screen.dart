import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/services/group_service.dart';

class GroupSetupScreen extends StatefulWidget {
  const GroupSetupScreen({super.key});

  @override
  State<GroupSetupScreen> createState() => _GroupSetupScreenState();
}

class _GroupSetupScreenState extends State<GroupSetupScreen> {
  final _codeController = TextEditingController();
  final _aliasController = TextEditingController();
  bool _isLoading = false;
  String? _createdCode;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final alias = _aliasController.text.trim();
      final code = await GroupService.instance.createGroup(
        alias: alias.isNotEmpty ? alias : null,
      );
      if (mounted) {
        setState(() {
          _createdCode = code;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error creating group: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinGroup() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final alias = _aliasController.text.trim();
      final success = await GroupService.instance.joinGroup(
        code,
        alias: alias.isNotEmpty ? alias : null,
      );
      if (!success) {
        if (mounted) {
          setState(() {
            _error = 'Group not found.';
            _isLoading = false;
          });
        }
        return;
      }
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error joining group: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_createdCode != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: AppColors.highlightColor),
                const SizedBox(height: 24),
                Text(
                  'Group Created!',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'Share this code to access your collections on other devices:',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _createdCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.highlightColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _createdCode!,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 8,
                            color: AppColors.highlightColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.copy, color: AppColors.highlightColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.go('/home'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.highlightColor),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.widgets, size: 64, color: AppColors.highlightColor),
              const SizedBox(height: 24),
              Text(
                'Brick Collector',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new group or join an existing one to sync your collections across devices.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _aliasController,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: 'Alias (optional)',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _createGroup,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Group'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.highlightColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'CODE',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _joinGroup,
                  icon: const Icon(Icons.group_add),
                  label: const Text('Join Group'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.highlightColor,
                    side: const BorderSide(color: AppColors.highlightColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
