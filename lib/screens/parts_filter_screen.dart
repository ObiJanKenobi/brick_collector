import 'package:brick_collector/common_libs.dart';
import 'package:brick_collector/model/filter_preset.dart';
import 'package:brick_collector/ui/moc_card.dart';
import 'package:brick_collector/ui/nav_menu.dart';
import 'package:brick_lib/model/rebrickable_part_category.dart';

class PartsFilterScreen extends StatefulWidget {
  const PartsFilterScreen(this.preset, {super.key});

  final FilterPreset preset;

  @override
  State<StatefulWidget> createState() => PartsFilterScreenState();
}

class PartsFilterScreenState extends State<PartsFilterScreen> {
  PartsFilterScreenState();

  @override
  void initState() {
    super.initState();
  }

  Widget buildAppBar(String title) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: AppColors.seedColor,
      title: Text(title),
      actions: [IconButton(onPressed: userClick, icon: const Icon(Icons.person)), const SizedBox(width: 30, height: 0)],
      // bottom: PreferredSize(
      //   preferredSize: const Size.fromHeight(2.0),
      //   child: Container(
      //     height: 2,
      //     decoration: const BoxDecoration(color: AppColors.highlightColor
      //         // gradient: LinearGradient(
      //         //   colors: <Color>[Color(0xFFF2542D), Colors.red],
      //         // ),
      //         ),
      //   ),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text("Parts"),
      //   automaticallyImplyLeading: true,
      // ),
      drawer: const Drawer(child: NavMenu()),
      body: CustomScrollView(slivers: [
        SliverMainAxisGroup(slivers: [
          buildAppBar("Part Categories"),
          StreamBuilder(
              stream: partsLogic.outPartCategories,
              builder: (BuildContext context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasData == false || snapshot.data?.isEmpty == true) {
                  return const SliverToBoxAdapter(child: Text("No Parts"));
                }

                return SliverList.builder(
                  itemBuilder: (context, index) => buildCategoryDisplay(snapshot.data![index]),
                  itemCount: snapshot.data?.length,
                );
              }),
        ]),
        SliverMainAxisGroup(slivers: [
          buildAppBar("Colors"),
          StreamBuilder(
              stream: partsLogic.outColors,
              builder: (BuildContext context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasData == false || snapshot.data?.isEmpty == true) {
                  return const SliverToBoxAdapter(child: Text("No Parts"));
                }

                return SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 6.0,
                    crossAxisSpacing: 6.0,
                    childAspectRatio: 2.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final rebrickableColor = snapshot.data![index];
                      return Container(
                        color: HexColor.fromHex(
                          "#${rebrickableColor.rgb}",
                        ),
                        child: Center(
                          child: Text("${rebrickableColor.name} (${rebrickableColor.id})"),
                        ),
                      );
                    },
                    childCount: snapshot.data!.length,
                  ),
                );
              })
        ]),
        const SliverToBoxAdapter(
          child: SizedBox(width: 0, height: 150),
        )
      ]),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: const Color(0xFFF2542D),
      //   onPressed: () {},
      //   tooltip: 'Create a new part filter',
      //   child: const Icon(Icons.add),
      // ),
      // // This trailing comma makes auto-formatting nicer for build methods.
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
      bottomNavigationBar: BottomAppBar(
          color: AppColors.navItemBgColor,
          shape: CircularNotchedRectangle(),
          notchMargin: 10,
          child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                onPressed: savePreset,
                icon: const Icon(
                  Icons.save,
                  color: Colors.white,
                )),
            IconButton(
                onPressed: executePreset,
                icon: const Icon(
                  Icons.remove_red_eye,
                  color: Colors.white,
                )),
          ])),
    );
  }

  void userClick() async {
    if (!appLogic.loggedIn) {
      await loginUser(context);
    }
  }

  Widget buildCategoryDisplay(RebrickablePartCategory data) {
    return ListTile(
      title: Text(data.name),
      trailing: Switch(
          value: _isCategorySelected(data.id),
          onChanged: (val) {
            if (val) {
              setState(() {
                widget.preset.addCategory(data);
              });
            } else {
              setState(() {
                widget.preset.categories?.removeWhere((e) => e.id == data.id);
              });
            }
          }),
    );
  }

  void savePreset() async {
    await partsLogic.savePreset(widget.preset);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Filter preset saved")));
  }

  bool _isCategorySelected(int id) {
    return widget.preset.categories?.any((e) => e.id == id) ?? false;
  }

  void executePreset() {}
}
