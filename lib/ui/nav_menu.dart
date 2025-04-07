import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                  onPressed: () {
                    context.go(ScreenPaths.home);
                  },
                  child: Text("Home")),TextButton(
                  onPressed: () {
                    context.go(ScreenPaths.parts);
                  },
                  child: Text("Parts")),
              ...snapshot.data
                      ?.map((e) => TextButton(
                          onPressed: () {
                            context.go(ScreenPaths.mocPage(e.id), extra: e);
                          },
                          child: Text(e.name)))
                      .toList() ??
                  []
            ]),
          );
        });
  }
}
