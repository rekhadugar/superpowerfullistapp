import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TokenSearchEngine extends StatefulWidget {
  final String title;
  final bool isMultiSelect;
  final bool forceLowercase;
  final bool smallPills;
  final List<String> knownTokens;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onChanged;

  final bool isExpanded;
  final ValueChanged<bool> onToggle;

  final bool hasError;
  final String emptyPlaceholder;
  final bool removable; // NEW: Controls if a selected item can be deselected

  const TokenSearchEngine({
    required this.title,
    required this.isMultiSelect,
    this.forceLowercase = false,
    this.smallPills = false,
    required this.knownTokens,
    required this.initialSelected,
    required this.onChanged,
    required this.isExpanded,
    required this.onToggle,
    this.hasError = false,
    this.emptyPlaceholder = 'None',
    this.removable = true, // Defaults to true for all standard tags
    super.key,
  });

  @override
  State<TokenSearchEngine> createState() => _TokenSearchEngineState();
}

class _TokenSearchEngineState extends State<TokenSearchEngine> {
  late List<String> _selectedTokens;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedTokens = List.from(widget.initialSelected);

    _searchController.addListener(() {
      setState(() {
        _currentQuery = widget.forceLowercase
            ? _searchController.text.toLowerCase()
            : _searchController.text;
      });
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: 0.9,
            );
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(TokenSearchEngine oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isExpanded && !oldWidget.isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
    else if (!widget.isExpanded && oldWidget.isExpanded) {
      _focusNode.unfocus();
      _searchController.clear();
      setState(() => _currentQuery = '');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleToken(String token) {
    setState(() {
      if (widget.isMultiSelect) {
        if (_selectedTokens.contains(token)) {
          if (widget.removable) _selectedTokens.remove(token);
        } else {
          _selectedTokens.add(token);
        }
        if (widget.isExpanded) {
          _searchController.clear();
          _focusNode.requestFocus();
        }
      } else {
        if (_selectedTokens.contains(token)) {
          if (widget.removable) _selectedTokens.clear();
        } else {
          _selectedTokens = [token];
          widget.onToggle(false);
        }
      }
    });
    widget.onChanged(_selectedTokens);
  }

  void _handleDone() {
    if (_currentQuery.trim().isNotEmpty) {
      _toggleToken(_currentQuery.trim());
    }
    widget.onToggle(false);
  }

  Widget _buildPill(String text, {bool isSelected = false, bool isCreate = false, bool isPlaceholder = false}) {
    // CHANGED: Slightly reduced pill text sizes for a cleaner look
    final double vPad = widget.smallPills ? 4.0 : 8.0;
    final double hPad = widget.smallPills ? 8.0 : 12.0;
    final double fontSize = widget.smallPills ? 11.0 : 13.0;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isPlaceholder) {
      bgColor = Colors.transparent;
      borderColor = AppTheme.primary;
      textColor = AppTheme.primary;
    } else if (isCreate) {
      bgColor = AppTheme.primary.withValues(alpha: 0.1);
      borderColor = AppTheme.primary;
      textColor = AppTheme.primary;
    } else if (isSelected) {
      bgColor = AppTheme.primary;
      borderColor = AppTheme.primary;
      textColor = Colors.white;
    } else {
      bgColor = AppTheme.background;
      borderColor = Colors.grey.shade300;
      textColor = Colors.black87;
    }

    return GestureDetector(
      onTap: isPlaceholder ? null : () => _toggleToken(text),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCreate) ...[const Icon(Icons.add, size: 14, color: AppTheme.primary), const SizedBox(width: 4)],
            Text(
              isCreate ? 'Create "$text"' : text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected || isCreate || isPlaceholder ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
            // CHANGED: The 'x' only shows if the pill is selected AND it is allowed to be removed
            if (isSelected && widget.removable) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 14, color: Colors.white),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? Colors.red
        : (widget.isExpanded ? AppTheme.primary : AppTheme.border);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: borderColor, width: widget.hasError ? 1.5 : 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onToggle(!widget.isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    widget.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.hasError ? Colors.red : Colors.black
                    )
                ),
                Icon(
                    widget.isExpanded ? Icons.remove_circle_outline : Icons.add_circle,
                    color: widget.hasError ? Colors.red : AppTheme.primary,
                    size: 28
                ),
              ],
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: widget.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,

            firstChild: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _selectedTokens.isEmpty
                          ? [_buildPill(widget.emptyPlaceholder, isPlaceholder: true)]
                          : _selectedTokens.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildPill(t, isSelected: true),
                      )).toList(),
                    ),
                  ),

                  Builder(builder: (context) {
                    final availableTokens = widget.knownTokens
                        .where((t) => !_selectedTokens.contains(t))
                        .toList();

                    if (availableTokens.isEmpty) return const SizedBox();

                    return Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: availableTokens.map((t) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _buildPill(t, isSelected: false),
                          )).toList(),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleDone(),
                    decoration: InputDecoration(
                        hintText: 'Search or add ${widget.title.toLowerCase()}...',
                        isDense: true,
                        border: InputBorder.none
                    ),
                  ),
                  const Divider(height: 16),

                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _selectedTokens.isEmpty
                        ? [_buildPill(widget.emptyPlaceholder, isPlaceholder: true)]
                        : _selectedTokens.map((t) => _buildPill(t, isSelected: true)).toList(),
                  ),

                  const SizedBox(height: 16),
                  const Text('Available', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),

                  Builder(builder: (context) {
                    final knownMatches = widget.knownTokens
                        .where((t) => t.toLowerCase().contains(_currentQuery.toLowerCase()) && !_selectedTokens.contains(t))
                        .toList();

                    final exactMatchExists = widget.knownTokens.any((t) => t.toLowerCase() == _currentQuery.toLowerCase()) ||
                        _selectedTokens.any((t) => t.toLowerCase() == _currentQuery.toLowerCase());

                    return Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        if (_currentQuery.isNotEmpty && !exactMatchExists)
                          _buildPill(_currentQuery, isCreate: true),

                        ...knownMatches.map((t) => _buildPill(t, isSelected: false)),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}