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
        foregroundColor: Colors.white,
        title: Text("Presets"),
        automaticallyImplyLeading: true,
        actions: [IconButton(onPressed: userClick, icon: Icon(Icons.person)), const SizedBox(width: 30, height: 0)],
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
                return const SliverToBoxAdapter(child: Text("No Collections"));
              }

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxCardWidth,
                  mainAxisSpacing: 6.0,
                  crossAxisSpacing: 6.0,
                  childAspectRatio: 2.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return _buildPreset(snapshot.data![index]);
                  },
                  childCount: snapshot.data!.length,
                ),
              );
            })
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF2542D),
        onPressed: _addPreset,
        tooltip: 'Create a new filter preset',
        child: const Icon(Icons.add),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
      bottomNavigationBar: const BottomAppBar(
        color: AppColors.navItemBgColor,
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
      ),
    );
  }

  void userClick() async {
    if (!appLogic.loggedIn) {
      await loginUser(context);
    }
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
