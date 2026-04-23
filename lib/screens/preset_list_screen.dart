import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/ui/moc_card.dart';
import 'package:brick_collector/ui/nav_menu.dart';

class PresetListScreen extends StatefulWidget {
  const PresetListScreen({super.key});

  @override
  State<StatefulWidget> createState() => PresetListScreenState();
}

class PresetListScreenState extends State<PresetListScreen> {
  PresetListScreenState();

  @override
  void initState() {
    super.initState();
  }

  void _addPreset() async {
    final text = await showTextInputDialog(context: context, textFields: const [DialogTextField()], title: "Create a new filter preset");

    if (text == null || text.isEmpty == true) {
      return;
    }

    final preset = await partsLogic.addNewPreset(text.first);
    appRouter.go(ScreenPaths.partFilterPage(preset.id));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final factor = size.width % 350;

    final double maxCardWidth = 350 + factor;
    print("Width: ${size.width} | Cardw: $maxCardWidth");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Presets"),
        automaticallyImplyLeading: true,
      ),
      drawer: const Drawer(child: NavMenu()),
      body: CustomScrollView(slivers: [
        StreamBuilder(
            stream: partsLogic.outPresets,
            builder: (BuildContext context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasData == false || snapshot.data?.isEmpty == true) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text("No Presets", style: TextStyle(color: AppColors.textSecondary)),
                  )),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList.builder(
                  itemBuilder: (context, index) => _buildPreset(snapshot.data![index]),
                  itemCount: snapshot.data!.length,
                ),
              );
            })
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPreset,
        tooltip: 'Create a new filter preset',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
      ),
    );
  }


  Widget _buildPreset(FilterPreset filterPreset) {
    return ListTile(
      onTap: () {
        appRouter.go(ScreenPaths.partFilterEditPage(filterPreset.id));
      },
      title: Text(filterPreset.name),
      trailing: IconButton(
          onPressed: () {
            appRouter.go(ScreenPaths.partFilterPage(filterPreset.id));
          },
          icon: Icon(Icons.edit)),
    );
  }
}
