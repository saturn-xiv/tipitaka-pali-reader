import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:tipitaka_pali/data/constants.dart';
import 'package:tipitaka_pali/providers/navigation_provider.dart';
import 'package:tipitaka_pali/services/prefs.dart';
import 'package:tipitaka_pali/services/rx_prefs.dart';

import '../../../data/flex_theme_data.dart';
import '../../widgets/my_vertical_divider.dart';
import '../reader/reader_container.dart';
import 'dekstop_navigation_bar.dart';
import 'navigation_pane.dart';

class DesktopHomeView extends StatefulWidget {
  const DesktopHomeView({super.key});

  @override
  State<DesktopHomeView> createState() => _DesktopHomeViewState();
}

class _DesktopHomeViewState extends State<DesktopHomeView>
    with SingleTickerProviderStateMixin {
  late double panelWidth;

  late final AnimationController _animationController;
  late final Tween<double> _tween;
  late final Animation<double> _animation;

  late final NavigationProvider navigationProvider;

  @override
  void initState() {
    super.initState();
    // width = Prefs.panelSize.toDouble();
    panelWidth = Prefs.panelWidth;
    navigationProvider = context.read<NavigationProvider>();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: Prefs.animationSpeed.round()),
    );

    _tween = Tween(begin: 1.0, end: 0.0);
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );

    navigationProvider.addListener(_openCloseChangedListener);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _openCloseChangedListener() {
    final isOpened = navigationProvider.isNavigationPaneOpened;
    debugPrint('isOpened: $isOpened');
    debugPrint('is animation complete: ${_animationController.isCompleted}');
    debugPrint('animation value: ${_animationController.value}');
    debugPrint('tween value: ${_tween.evaluate(_animation)}');
    if (isOpened) {
      _animationController.reverse();
    } else {
      _animationController.forward();
      // _animatedIconController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // RydMike: Avoid things like this, prefer using themes correctly!
    //   But OK sometimes needed, but rarely. Not sure why this is used in
    //   conditional build below. Looks like some temp experiment. :)
    return Stack(
      children: [
        Row(
          children: [
            // Navigation Rail
            Container(
              decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey))),
              child: const DeskTopNavigationBar(),
            ),
            // Navigation Pane
            SizeTransition(
              sizeFactor: _tween.animate(_animation),
              axis: Axis.horizontal,
              axisAlignment: 1,
              child: SizedBox(
                width: panelWidth,
                child: const DetailNavigationPane(navigationCount: 7),
              ),
            ),
// drag bar
            MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  setState(() {
                    panelWidth += details.primaryDelta ?? 0;
                    panelWidth =
                        panelWidth.clamp(200.0, 600); // min, max of panel width
                    Prefs.panelWidth = panelWidth;
                  });
                },
                child: Container(
                  color: Colors.grey,
                  width: 3,
                ),
              ),
            ),
            // reader view
            const Expanded(child: ReaderContainer()),
          ],
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: SizedBox(
            width: navigationBarWidth,
            height: 64,
            child: Center(
              child: IconButton(
                  onPressed: () =>
                      context.read<NavigationProvider>().toggleNavigationPane(),
                  icon: AnimatedIcon(
                    icon: AnimatedIcons.arrow_menu,
                    // progress: _animatedIconController,
                    progress: _animationController.view,
                  )),
            ),
          ),
        )
      ],
    );
  }
}
