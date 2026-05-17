import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TokenSearchEngine extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isMultiSelect;
  final bool forceLowercase;
  final bool smallPills;
  final List<String> knownTokens;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onChanged;

  final bool isExpanded;
  final ValueChanged<bool> onToggle;

  const TokenSearchEngine({
    required this.title,
    required this.subtitle,
    required this.isMultiSelect,
    this.forceLowercase = false,
    this.smallPills = false,
    required this.knownTokens,
    required this.initialSelected,
    required this.onChanged,
    required this.isExpanded,
    required this.onToggle,
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

    // THE FIX: Centralized Focus Listener
    // We bind the scroll math directly to the focus state instead of a tap gesture.
    // Whether triggered by the '+' button or a manual tap after swiping down,
    // this guarantees the scroll always fires when the keyboard is summoned.
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
      // Just request focus. The listener in initState handles the scrolling automatically!
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
          _selectedTokens.remove(token);
        } else {
          _selectedTokens.add(token);
        }

        if (widget.isExpanded) {
          _searchController.clear();
          _focusNode.requestFocus();
        }
      } else {
        if (_selectedTokens.contains(token)) {
          _selectedTokens.clear();
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

  Widget _buildPill(String text, {bool isSelected = false, bool isCreate = false}) {
    final double vPad = widget.smallPills ? 4.0 : 8.0;
    final double hPad = widget.smallPills ? 8.0 : 12.0;
    final double fontSize = widget.smallPills ? 12.0 : 14.0;

    return GestureDetector(
      onTap: () => _toggleToken(text),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: isCreate ? AppTheme.primary.withValues(alpha: 0.1) : isSelected ? AppTheme.primary : AppTheme.background,
          border: isCreate ? Border.all(color: AppTheme.primary, width: 1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCreate) ...[const Icon(Icons.add, size: 16, color: AppTheme.primary), const SizedBox(width: 4)],
            Text(
              isCreate ? 'Create "$text"' : text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected || isCreate ? FontWeight.w700 : FontWeight.w600,
                color: isCreate ? AppTheme.primary : isSelected ? Colors.white : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 16, color: Colors.white),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: widget.isExpanded ? AppTheme.primary : AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 200),
        crossFadeState: widget.isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,

        firstChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    if (_selectedTokens.isEmpty) Text(widget.subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppTheme.primary, size: 28),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  onPressed: () => widget.onToggle(true),
                ),
              ],
            ),
            Builder(builder: (context) {
              final displayList = [
                ..._selectedTokens,
                ...widget.knownTokens.where((t) => !_selectedTokens.contains(t)),
              ];

              if (displayList.isEmpty) return const SizedBox();

              return Column(
                children: [
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: displayList.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildPill(t, isSelected: _selectedTokens.contains(t)),
                      )).toList(),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),

        secondChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleDone(),
              // NO onTap REQUIRED HERE ANYMORE
              decoration: InputDecoration(
                  hintText: 'Search or add ${widget.title.toLowerCase()}...',
                  isDense: true,
                  border: InputBorder.none
              ),
            ),
            const Divider(height: 24),

            Builder(builder: (context) {
              final matches = widget.knownTokens
                  .where((t) => t.toLowerCase().contains(_currentQuery.toLowerCase()))
                  .toList();

              matches.sort((a, b) {
                final aSelected = _selectedTokens.contains(a);
                final bSelected = _selectedTokens.contains(b);
                if (aSelected && !bSelected) return -1;
                if (!aSelected && bSelected) return 1;
                return 0;
              });

              final exactMatchExists = widget.knownTokens.any((t) => t.toLowerCase() == _currentQuery.toLowerCase());

              return Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  if (_currentQuery.isNotEmpty && !exactMatchExists)
                    _buildPill(_currentQuery, isCreate: true),

                  ...matches.map((t) => _buildPill(t, isSelected: _selectedTokens.contains(t))),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}