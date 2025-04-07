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

  void _addMoc() async {
    final text = await showTextInputDialog(context: context, textFields: const [DialogTextField()], title: "Create a new MOC");

    if (text == null || text.isEmpty == true) {
      return;
    }

    await mocLogic.addNewMoc(text.first);
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
        title: Text("Collections"),
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
            stream: mocLogic.outMocs,
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
                    return MocCard(snapshot.data![index]);
                  },
                  childCount: snapshot.data!.length,
                ),
              );
            })
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF2542D),
        onPressed: _addMoc,
        tooltip: 'Create a new Collection',
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
}
