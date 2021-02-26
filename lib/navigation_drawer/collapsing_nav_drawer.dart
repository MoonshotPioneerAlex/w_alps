import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:w_alps/table/LoginHelper.dart';

import 'collapsing_nav_item.dart';
import 'navigation_model.dart';
import '../theme.dart';

class CollapsingNavigationDrawer extends StatefulWidget {
  final Function onListItemPress;

  CollapsingNavigationDrawer({this.onListItemPress});

  @override
  CollapsingNavigationDrawerState createState() {
    return new CollapsingNavigationDrawerState();
  }
}

class CollapsingNavigationDrawerState extends State<CollapsingNavigationDrawer> with SingleTickerProviderStateMixin {
  double maxWidth = 200;
  double minWidth = 70;
  bool isCollapsed = true;
  AnimationController _animationController;
  Animation<double> widthAnimation;
  int currentSelectedIndex = 0;

  TextEditingController pinController = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 50));
    widthAnimation = Tween<double>(begin: maxWidth, end: minWidth).animate(_animationController);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, widget) => getWidget(context, widget),
    );
  }

  Widget getWidget(context, widget) {
    return Material(
      elevation: 1.0,
      child: Container(
        width: widthAnimation.value,
        color: drawerBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ListView.separated(
                separatorBuilder: (context, counter) {
                  return Divider(height: 1.0);
                },
                itemBuilder: (context, counter) {
                  return CollapsingListTile(
                    onTap: () {
                      setState(() {
                        currentSelectedIndex = counter;
                        this.widget.onListItemPress(currentSelectedIndex);
                      });
                    },
                    isSelected: currentSelectedIndex == counter,
                    title: navigationItems[counter].title,
                    icon: navigationItems[counter].icon,
                    animationController: _animationController,
                  );
                },
                itemCount: navigationItems.length,
              ),
            ),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
                if (snapshot.hasData) {
                  return Visibility(
                    visible: !isCollapsed,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      child: FlatButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: Colors.white,
                                child: Container(
                                  width: 200,
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(
                                        Icons.lock,
                                        size: 36,
                                      ),
                                      TextFormField(
                                        controller: pinController,
                                        obscureText: true,
                                        textAlign: TextAlign.center,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Password',
                                          alignLabelWithHint: true,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: MaterialButton(
                                          onPressed: () {
                                            if (LoginHelper.checkPassword(pinController.text)) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text("ADMIN MODE ACTIVE"),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );

                                              Navigator.pop(context);

                                              setState(() {
                                                LoginHelper.adminModeActive = true;
                                              });
                                            }
                                          },
                                          child: Text("Login"),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        child: Text(
                          "Version " + snapshot.data.version + " Build " + snapshot.data.buildNumber,
                          style: TextStyle(color: Colors.black54, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                } else {
                  return SizedBox();
                }
              },
            ),
            Divider(
              height: 1.0,
              thickness: 1,
              color: Colors.black26,
            ),
            Padding(
              padding: EdgeInsets.all(24),
              child: InkWell(
                onTap: () {
                  setState(() {
                    isCollapsed = !isCollapsed;
                    isCollapsed ? _animationController.forward() : _animationController.reverse();
                  });
                },
                child: AnimatedIcon(
                  icon: AnimatedIcons.close_menu,
                  progress: _animationController,
                  size: 20.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
