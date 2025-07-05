import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';

class FindReplaceDialog extends StatefulWidget {
  final TextEditingController codeController;
  final Function(int) onFindResult;
  final VoidCallback onClose;

  const FindReplaceDialog({
    super.key,
    required this.codeController,
    required this.onFindResult,
    required this.onClose,
  });

  @override
  State<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<FindReplaceDialog> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  final FocusNode _replaceFocusNode = FocusNode();

  List<Match> _matches = [];
  int _currentMatchIndex = -1;
  bool _caseSensitive = false;
  bool _wholeWord = false;
  bool _showReplace = false;

  @override
  void initState() {
    super.initState();
    _findController.addListener(_onFindTextChanged);

    // Auto-focus on the find field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _findController.removeListener(_onFindTextChanged);
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    _replaceFocusNode.dispose();
    super.dispose();
  }

  void _onFindTextChanged() {
    _performSearch();
  }

  void _performSearch() {
    String searchText = _findController.text;
    if (searchText.isEmpty) {
      setState(() {
        _matches = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    String codeText = widget.codeController.text;

    // Prepare search pattern
    String pattern = searchText;
    if (!_caseSensitive) {
      codeText = codeText.toLowerCase();
      pattern = pattern.toLowerCase();
    }

    if (_wholeWord) {
      pattern = '\\b$pattern\\b';
    }

    // Find all matches
    RegExp regex = RegExp(pattern);
    _matches = regex.allMatches(codeText).toList();

    setState(() {
      _currentMatchIndex = _matches.isNotEmpty ? 0 : -1;
    });

    if (_matches.isNotEmpty) {
      _highlightCurrentMatch();
    }
  }

  void _highlightCurrentMatch() {
    if (_currentMatchIndex >= 0 && _currentMatchIndex < _matches.length) {
      Match match = _matches[_currentMatchIndex];
      widget.codeController.selection = TextSelection(
        baseOffset: match.start,
        extentOffset: match.end,
      );
      widget.onFindResult(match.start);
    }
  }

  void _findNext() {
    if (_matches.isNotEmpty) {
      setState(() {
        _currentMatchIndex = (_currentMatchIndex + 1) % _matches.length;
      });
      _highlightCurrentMatch();
    }
  }

  void _findPrevious() {
    if (_matches.isNotEmpty) {
      setState(() {
        _currentMatchIndex =
            (_currentMatchIndex - 1 + _matches.length) % _matches.length;
      });
      _highlightCurrentMatch();
    }
  }

  void _replace() {
    if (_currentMatchIndex >= 0 && _currentMatchIndex < _matches.length) {
      Match match = _matches[_currentMatchIndex];
      String newText = widget.codeController.text.replaceRange(
        match.start,
        match.end,
        _replaceController.text,
      );

      widget.codeController.text = newText;

      // Update cursor position
      int newCursorPos = match.start + _replaceController.text.length;
      widget.codeController.selection = TextSelection.fromPosition(
        TextPosition(offset: newCursorPos),
      );

      // Refresh search results
      _performSearch();
    }
  }

  void _replaceAll() {
    if (_matches.isEmpty) return;

    String searchText = _findController.text;
    String replaceText = _replaceController.text;
    String codeText = widget.codeController.text;

    String pattern = searchText;
    if (_wholeWord) {
      pattern = '\\b$pattern\\b';
    }

    RegExp regex = RegExp(
      pattern,
      caseSensitive: _caseSensitive,
    );

    String newText = codeText.replaceAll(regex, replaceText);
    widget.codeController.text = newText;

    // Refresh search results
    _performSearch();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Replaced ${_matches.length} occurrences'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PythonCompilerProvider>(
      builder: (context, provider, child) {
        final isDark = provider.isDarkMode;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF2D2D30) : Colors.white,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D30) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border:
                  isDark ? Border.all(color: const Color(0xFF3E3E42)) : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showReplace ? 'Find and Replace' : 'Find',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Find field
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _findController,
                        focusNode: _findFocusNode,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Find',
                          labelStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF3E3E42)
                                  : Colors.grey,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark
                                  ? const Color(0xFF3E3E42)
                                  : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: isDark ? Colors.blue[300]! : Colors.blue,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          suffixText: _matches.isNotEmpty
                              ? '${_currentMatchIndex + 1}/${_matches.length}'
                              : _findController.text.isNotEmpty
                                  ? '0/0'
                                  : null,
                          suffixStyle: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        onSubmitted: (_) => _findNext(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_up,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: _matches.isNotEmpty ? _findPrevious : null,
                      tooltip: 'Previous (Shift+Enter)',
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      onPressed: _matches.isNotEmpty ? _findNext : null,
                      tooltip: 'Next (Enter)',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Replace field (if shown)
                if (_showReplace) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replaceController,
                          focusNode: _replaceFocusNode,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Replace',
                            labelStyle: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF3E3E42)
                                    : Colors.grey,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark
                                    ? const Color(0xFF3E3E42)
                                    : Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: isDark ? Colors.blue[300]! : Colors.blue,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          ),
                          onSubmitted: (_) => _replace(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          Icons.find_replace,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        onPressed: _matches.isNotEmpty ? _replace : null,
                        tooltip: 'Replace',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.find_replace_outlined,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        onPressed: _matches.isNotEmpty ? _replaceAll : null,
                        tooltip: 'Replace All',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Options
                Row(
                  children: [
                    Checkbox(
                      value: _caseSensitive,
                      activeColor: isDark ? Colors.blue[300] : Colors.blue,
                      checkColor: isDark ? Colors.black : Colors.white,
                      onChanged: (value) {
                        setState(() {
                          _caseSensitive = value ?? false;
                        });
                        _performSearch();
                      },
                    ),
                    Text(
                      'Case sensitive',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Checkbox(
                      value: _wholeWord,
                      activeColor: isDark ? Colors.blue[300] : Colors.blue,
                      checkColor: isDark ? Colors.black : Colors.white,
                      onChanged: (value) {
                        setState(() {
                          _wholeWord = value ?? false;
                        });
                        _performSearch();
                      },
                    ),
                    Text(
                      'Whole word',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        _showReplace ? Icons.search : Icons.find_replace,
                        color: isDark ? Colors.blue[300] : Colors.blue,
                      ),
                      label: Text(
                        _showReplace ? 'Find Only' : 'Replace',
                        style: TextStyle(
                          color: isDark ? Colors.blue[300] : Colors.blue,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _showReplace = !_showReplace;
                        });
                        if (_showReplace) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _replaceFocusNode.requestFocus();
                          });
                        }
                      },
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isDark ? Colors.blue[700] : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _matches.isNotEmpty ? _findNext : null,
                          child: const Text('Find Next'),
                        ),
                        const SizedBox(width: 8),
                        if (_showReplace)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isDark ? Colors.green[700] : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _matches.isNotEmpty ? _replace : null,
                            child: const Text('Replace'),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
