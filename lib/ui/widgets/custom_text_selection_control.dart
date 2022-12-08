import 'package:flutter/material.dart';

typedef OffsetValue = void Function(int start, int end);

class CustomTextSelectionControls extends MaterialTextSelectionControls {
  // Padding between the toolbar and the anchor.
  static const double _kToolbarContentDistanceBelow = 20.0;
  static const double _kToolbarContentDistance = 8.0;
  CustomTextSelectionControls({required this.shareButton});

  /// Custom
  final OffsetValue shareButton;
}

class MyTextSelectionToolbar extends StatefulWidget {
  const MyTextSelectionToolbar({
    required Key key,
    required this.anchorAbove,
    required this.anchorBelow,
    required this.clipboardStatus,
    required this.handleCopy,
    required this.handleCut,
    required this.handlePaste,
    required this.handleSelectAll,

    /// Custom
    required this.shareButton,
  }) : super(key: key);

  final Offset anchorAbove;
  final Offset anchorBelow;
  final ClipboardStatusNotifier clipboardStatus;
  final VoidCallback handleCopy;
  final VoidCallback handleCut;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;

  /// Custom
  final VoidCallback shareButton;

  @override
  MyTextSelectionToolbarState createState() => MyTextSelectionToolbarState();
}

class MyTextSelectionToolbarState extends State<MyTextSelectionToolbar> {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus.addListener(_onChangedClipboardStatus);
    widget.clipboardStatus.update();
  }

  @override
  void didUpdateWidget(MyTextSelectionToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatus != oldWidget.clipboardStatus) {
      widget.clipboardStatus.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
    widget.clipboardStatus.update();
  }

  @override
  void dispose() {
    super.dispose();
    if (!widget.clipboardStatus.disposed) {
      widget.clipboardStatus.removeListener(_onChangedClipboardStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);

    final List<_TextSelectionToolbarItemData> itemDatas =
        <_TextSelectionToolbarItemData>[
      if (widget.handleCut != null)
        _TextSelectionToolbarItemData(
          label: localizations.cutButtonLabel,
          onPressed: widget.handleCut,
        ),
      if (widget.handleCopy != null)
        _TextSelectionToolbarItemData(
          label: localizations.copyButtonLabel,
          onPressed: widget.handleCopy,
        ),
      if (widget.handlePaste != null &&
          widget.clipboardStatus.value == ClipboardStatus.pasteable)
        _TextSelectionToolbarItemData(
          label: localizations.pasteButtonLabel,
          onPressed: widget.handlePaste,
        ),
      if (widget.handleSelectAll != null)
        _TextSelectionToolbarItemData(
          label: localizations.selectAllButtonLabel,
          onPressed: widget.handleSelectAll,
        ),

      /// Custom
      _TextSelectionToolbarItemData(
        onPressed: widget.shareButton,
        label: 'Share',
      ),
    ];

    int childIndex = 0;
    return TextSelectionToolbar(
      anchorAbove: widget.anchorAbove,
      anchorBelow: widget.anchorBelow,
      toolbarBuilder: (BuildContext context, Widget child) {
        return Card(child: child);
      },
      children: itemDatas.map((_TextSelectionToolbarItemData itemData) {
        return TextSelectionToolbarTextButton(
          padding: TextSelectionToolbarTextButton.getPadding(
              childIndex++, itemDatas.length),
          onPressed: itemData.onPressed,
          child: Text(itemData.label),
        );
      }).toList(),
    );
  }
}

class _TextSelectionToolbarItemData {
  const _TextSelectionToolbarItemData({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
}
