import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/ui/back_button.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final bool showNav;

  const AppHeader(this.title, this.showNav, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: Colors.white,
      title: Text(title),
      automaticallyImplyLeading: true,
      leading: showNav ? null : const MyBackButton(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2.0),
        child: Container(
          height: 2,
          decoration: const BoxDecoration(color: AppColors.highlightColor
              // gradient: LinearGradient(
              //   colors: <Color>[Color(0xFFF2542D), Colors.red],
              // ),
              ),
        ),
      ),
    );
  }
}
