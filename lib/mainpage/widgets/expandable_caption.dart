import 'package:flutter/material.dart';

class ExpandableCaption extends StatefulWidget {
  final String text;
  final bool isExpanded;
  final VoidCallback onToggle;
  final int stepLimit;

  const ExpandableCaption({
    super.key,
    required this.text,
    required this.isExpanded,
    required this.onToggle,
    this.stepLimit = 250,
  });

  @override
  State<ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<ExpandableCaption> {
  late int _currentLimit;

  @override
  void initState() {
    super.initState();
    _currentLimit = widget.stepLimit;
  }

  void _showMore() {
    setState(() {
      _currentLimit += widget.stepLimit;
    });
  }

  void _showLess() {
    setState(() {
      _currentLimit = widget.stepLimit;
    });
  }

  String _breakWord(String text) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(RegExp(r"(\S{30})"), (match) {
      return "${match.group(1)}\u200B";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    int textLength = widget.text.length;
    bool hasMore = _currentLimit < textLength;

    String displayText = widget.text;
    if (hasMore) {
      displayText = "${widget.text.substring(0, _currentLimit)}...";
    }

    final safeText = _breakWord(displayText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: Text(
            safeText,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (hasMore)
          InkWell(
            onTap: _showMore,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "Baca selengkapnya",
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else if (_currentLimit > widget.stepLimit &&
            textLength > widget.stepLimit)
          InkWell(
            onTap: _showLess,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                "Sembunyikan",
                style: TextStyle(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
