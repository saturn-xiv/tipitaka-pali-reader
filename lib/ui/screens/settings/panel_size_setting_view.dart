import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:streaming_shared_preferences/streaming_shared_preferences.dart';
import 'package:tipitaka_pali/services/rx_prefs.dart';

class PanelSizeControlView extends StatefulWidget {
  const PanelSizeControlView({Key? key}) : super(key: key);

  @override
  State<PanelSizeControlView> createState() => _PanelSizeControlViewState();
}

class _PanelSizeControlViewState extends State<PanelSizeControlView> {
  late final StreamingSharedPreferences rxPrefs;
  final mininalSize = 200.0;
  late double size;
  @override
  void initState() {
    super.initState();
    rxPrefs = Provider.of<StreamingSharedPreferences>(context, listen: false);
    size = rxPrefs
        .getDouble(panelSizeKey, defaultValue: defaultPanelSize)
        .getValue();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      return Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: Text('left panel width'),
            ),
          ),
          IconButton(
            onPressed: () async{
              setState(() {
                size = size - 10;
                if (size < 100) size = mininalSize;
                // todo show message to user
              });
                await rxPrefs.setDouble(panelSizeKey, size);
            },
            icon: const Icon(Icons.remove),
          ),
          Text(
            size.toInt().toString(),
          ),
          IconButton(
            onPressed: () async{
              setState(() {
                size = size + 10;
              });
                await rxPrefs.setDouble(panelSizeKey, size);
            },
            icon: const Icon(Icons.add),
          ),
        ],
      );
    });
  }
}
