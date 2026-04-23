import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/ui/moc_card.dart';
import 'package:brick_collector/ui/nav_menu.dart';

class MocListScreen extends StatefulWidget {
  const MocListScreen({super.key});

  @override
  State<StatefulWidget> createState() => MocListScreenState();
}

class MocListScreenState extends State<MocListScreen> {
  MocListScreenState();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final factor = size.width % 350;

    final double maxCardWidth = 350 + factor;
    print("Width: ${size.width} | Cardw: $maxCardWidth");

    return Scaffold(
      appBar: AppBar(
        title: const Text("MOCs"),
        automaticallyImplyLeading: true,
      ),
      drawer: const Drawer(child: NavMenu()),
      body: CustomScrollView(slivers: [
        StreamBuilder(
            stream: mocLogic.outMocs,
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData == false || snapshot.data?.isEmpty == true) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.widgets_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text("No Collections", style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxCardWidth,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return MocCard(snapshot.data![index]);
                  },
                  childCount: snapshot.data!.length,
                ),
              ));
            })
      ]),
    );
  }

}
