import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:provider/provider.dart';
import '../providers/provider.dart';
import 'find_replace_dialog.dart';

class CodeError {
  final int line;
  final int column;
  final String message;
  final String type;

  CodeError({
    required this.line,
    required this.column,
    required this.message,
    required this.type,
  });
}

class CodeEditorWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;

  const CodeEditorWidget({
    super.key,
    required this.controller,
    this.hintText = 'Enter your Python code here...',
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  String _previousText = '';
  final List<String> _history = [];
  int _historyIndex = -1;
  bool _isUndoRedoOperation = false;

  // Bracket matching
  int? _matchingBracketStart;
  int? _matchingBracketEnd;

  // Auto-completion
  OverlayEntry? _autocompleteOverlay;
  List<String> _suggestions = [];
  String _currentWord = '';
  int _selectedSuggestionIndex = 0;

  // Find and replace
  bool _showFindReplace = false;

  // Error detection
  final List<CodeError> _syntaxErrors = [];

  // Python keywords and built-in functions
  static const List<String> _pythonKeywords = [
    'and',
    'as',
    'assert',
    'break',
    'class',
    'continue',
    'def',
    'del',
    'elif',
    'else',
    'except',
    'False',
    'finally',
    'for',
    'from',
    'global',
    'if',
    'import',
    'in',
    'is',
    'lambda',
    'None',
    'not',
    'or',
    'pass',
    'raise',
    'return',
    'True',
    'try',
    'while',
    'with',
    'yield',
    'print',
    'input',
    'len',
    'range',
    'str',
    'int',
    'float',
    'list',
    'dict',
    'tuple',
    'set',
    'bool',
    'type',
    'isinstance',
    'hasattr',
    'getattr',
    'setattr',
    'enumerate',
    'zip',
    'map',
    'filter',
    'sum',
    'min',
    'max',
    'abs',
    'round',
    'sorted',
    'reversed',
    'any',
    'all',
    'open',
    'file'
  ];

  // Auto-closing pairs map
  static const Map<String, String> _closingPairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
  };

  // Bracket pairs for matching
  static const Map<String, String> _bracketPairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    ')': '(',
    ']': '[',
    '}': '{',
  };

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _previousText = widget.controller.text;
    _addToHistory(widget.controller.text);
  }

  @override
  void dispose() {
    _hideAutocomplete();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _showFindReplaceDialog() {
    setState(() {
      _showFindReplace = true;
    });
  }

  void _hideFindReplaceDialog() {
    setState(() {
      _showFindReplace = false;
    });
  }

  void _onFindResult(int position) {
    // Callback when find dialog wants to scroll to a position
    // The text selection is already handled by the dialog
    setState(() {}); // Trigger rebuild to update UI
  }

  void _formatCode() {
    String text = widget.controller.text;
    if (text.trim().isEmpty) return;

    List<String> lines = text.split('\n');
    List<String> formattedLines = [];
    int indentLevel = 0;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      String trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) {
        formattedLines.add('');
        continue;
      }

      // Handle closing brackets/keywords that reduce indentation
      if (trimmedLine.startsWith('except') ||
          trimmedLine.startsWith('elif') ||
          trimmedLine.startsWith('else:') ||
          trimmedLine.startsWith('finally:') ||
          trimmedLine.startsWith('}') ||
          trimmedLine.startsWith(']') ||
          trimmedLine.startsWith(')')) {
        indentLevel = (indentLevel - 1).clamp(0, double.infinity).toInt();
      }

      // Format the line
      String formattedLine = _formatSingleLine(trimmedLine, indentLevel);
      formattedLines.add(formattedLine);

      // Handle opening brackets/keywords that increase indentation
      if (trimmedLine.endsWith(':') ||
          trimmedLine.endsWith('{') ||
          trimmedLine.endsWith('[') ||
          trimmedLine.endsWith('(')) {
        indentLevel++;
      }
    }

    String formattedText = formattedLines.join('\n');

    // Preserve cursor position approximately
    int cursorPos = widget.controller.selection.baseOffset;
    double positionRatio = text.isNotEmpty ? cursorPos / text.length : 0;
    int newCursorPos = (formattedText.length * positionRatio)
        .round()
        .clamp(0, formattedText.length);

    widget.controller.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.fromPosition(
        TextPosition(offset: newCursorPos),
      ),
    );

    // Add to history
    _addToHistory(formattedText);
  }

  String _formatSingleLine(String line, int indentLevel) {
    // Apply indentation
    String indentation = '    ' * indentLevel; // 4 spaces per level

    // Basic formatting rules
    line = _formatOperators(line);
    line = _formatCommas(line);
    line = _formatImports(line);
    line = _formatFunctions(line);

    return indentation + line;
  }

  String _formatOperators(String line) {
    // Add spaces around operators
    line = line.replaceAllMapped(RegExp(r'([^=!<>])=([^=])'),
        (match) => '${match.group(1)} = ${match.group(2)}');
    line = line.replaceAllMapped(
        RegExp(r'([^=!<>])\+='), (match) => '${match.group(1)} +=');
    line = line.replaceAllMapped(
        RegExp(r'([^=!<>])-='), (match) => '${match.group(1)} -=');
    line = line.replaceAllMapped(
        RegExp(r'([^=!<>])\*='), (match) => '${match.group(1)} *=');
    line = line.replaceAllMapped(
        RegExp(r'([^=!<>])/='), (match) => '${match.group(1)} /=');

    // Comparison operators
    line = line.replaceAll(RegExp(r'=='), ' == ');
    line = line.replaceAll(RegExp(r'!='), ' != ');
    line = line.replaceAll(RegExp(r'<='), ' <= ');
    line = line.replaceAll(RegExp(r'>='), ' >= ');
    line = line.replaceAllMapped(RegExp(r'([^<>])(<)([^<=])'),
        (match) => '${match.group(1)} < ${match.group(3)}');
    line = line.replaceAllMapped(RegExp(r'([^<>])(>)([^>=])'),
        (match) => '${match.group(1)} > ${match.group(3)}');

    // Arithmetic operators
    line = line.replaceAllMapped(RegExp(r'([^\s])\+([^\s+=])'),
        (match) => '${match.group(1)} + ${match.group(2)}');
    line = line.replaceAllMapped(RegExp(r'([^\s])-([^\s-=])'),
        (match) => '${match.group(1)} - ${match.group(2)}');
    line = line.replaceAllMapped(RegExp(r'([^\s])\*([^\s*=])'),
        (match) => '${match.group(1)} * ${match.group(2)}');
    line = line.replaceAllMapped(RegExp(r'([^\s])/([^\s/=])'),
        (match) => '${match.group(1)} / ${match.group(2)}');

    // Clean up extra spaces
    line = line.replaceAll(RegExp(r'\s+'), ' ');

    return line;
  }

  String _formatCommas(String line) {
    // Add space after commas
    line = line.replaceAllMapped(
        RegExp(r',([^\s])'), (match) => ', ${match.group(1)}');
    return line;
  }

  String _formatImports(String line) {
    // Format import statements
    if (line.startsWith('import ') || line.startsWith('from ')) {
      line = line.replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
    }
    return line;
  }

  String _formatFunctions(String line) {
    // Format function definitions and calls
    if (line.contains('def ')) {
      line = line.replaceAllMapped(
          RegExp(r'def\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\('),
          (match) => 'def ${match.group(1)}(');
    }

    // Format function calls - remove space before parentheses
    line = line.replaceAllMapped(RegExp(r'([a-zA-Z_][a-zA-Z0-9_]*)\s+\('),
        (match) => '${match.group(1)}(');

    return line;
  }

  void _findMatchingBracket() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    _matchingBracketStart = null;
    _matchingBracketEnd = null;

    if (cursorPos <= 0 || cursorPos > text.length) return;

    // Check character at cursor and before cursor
    String? charAtCursor = cursorPos < text.length ? text[cursorPos] : null;
    String? charBeforeCursor = cursorPos > 0 ? text[cursorPos - 1] : null;

    int? bracketPos;
    String? bracket;

    // Determine which bracket to match
    if (charAtCursor != null && _bracketPairs.containsKey(charAtCursor)) {
      bracketPos = cursorPos;
      bracket = charAtCursor;
    } else if (charBeforeCursor != null &&
        _bracketPairs.containsKey(charBeforeCursor)) {
      bracketPos = cursorPos - 1;
      bracket = charBeforeCursor;
    }

    if (bracketPos == null || bracket == null) return;

    // Find matching bracket
    String matchingBracket = _bracketPairs[bracket]!;
    bool isOpenBracket = ['(', '[', '{'].contains(bracket);

    int direction = isOpenBracket ? 1 : -1;
    int start = bracketPos + direction;
    int end = isOpenBracket ? text.length : -1;
    int depth = 0;

    for (int i = start; i != end; i += direction) {
      String char = text[i];

      if (char == bracket) {
        depth++;
      } else if (char == matchingBracket) {
        if (depth == 0) {
          _matchingBracketStart = bracketPos;
          _matchingBracketEnd = i;
          return;
        }
        depth--;
      }
    }
  }

  void _updateAutocomplete() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    if (cursorPos <= 0 || cursorPos > text.length) {
      _hideAutocomplete();
      return;
    }

    // Find the current word being typed
    int wordStart = cursorPos - 1;
    while (wordStart >= 0 && _isWordCharacter(text[wordStart])) {
      wordStart--;
    }
    wordStart++; // Move to the start of the word

    int wordEnd = cursorPos;
    while (wordEnd < text.length && _isWordCharacter(text[wordEnd])) {
      wordEnd++;
    }

    _currentWord = text.substring(wordStart, wordEnd);

    if (_currentWord.length < 2) {
      _hideAutocomplete();
      return;
    }

    // Filter suggestions
    _suggestions = _pythonKeywords
        .where((keyword) =>
            keyword.toLowerCase().startsWith(_currentWord.toLowerCase()))
        .where(
            (keyword) => keyword != _currentWord) // Don't suggest exact matches
        .take(8) // Limit suggestions
        .toList();

    if (_suggestions.isEmpty) {
      _hideAutocomplete();
      return;
    }

    _selectedSuggestionIndex = 0;
    _showAutocomplete();
  }

  bool _isWordCharacter(String char) {
    return char.contains(RegExp(r'[a-zA-Z0-9_]'));
  }

  void _showAutocomplete() {
    _hideAutocomplete(); // Remove any existing overlay

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final position = renderBox.localToGlobal(Offset.zero);

    _autocompleteOverlay = OverlayEntry(
      builder: (overlayContext) => Consumer<PythonCompilerProvider>(
        builder: (context, provider, child) {
          final isDark = provider.isDarkMode;

          return Positioned(
            left: position.dx + 62, // Account for line numbers width
            top: position.dy + 50, // Position below current line
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: isDark ? const Color(0xFF2D2D30) : Colors.white,
              child: Container(
                width: 200,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D30) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF3E3E42) : Colors.grey[300]!,
                  ),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _suggestions[index];
                    final isSelected = index == _selectedSuggestionIndex;

                    return Container(
                      color: isSelected
                          ? (isDark
                              ? Colors.blue[800]?.withValues(alpha: 0.3)
                              : Colors.blue[50])
                          : null,
                      child: ListTile(
                        dense: true,
                        title: Text(
                          suggestion,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () => _insertSuggestion(suggestion),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(_autocompleteOverlay!);
  }

  void _hideAutocomplete() {
    _autocompleteOverlay?.remove();
    _autocompleteOverlay = null;
    _suggestions.clear();
  }

  void _insertSuggestion(String suggestion) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;

    // Find the current word being typed
    int wordStart = cursorPos - 1;
    while (wordStart >= 0 && _isWordCharacter(text[wordStart])) {
      wordStart--;
    }
    wordStart++; // Move to the start of the word

    int wordEnd = cursorPos;
    while (wordEnd < text.length && _isWordCharacter(text[wordEnd])) {
      wordEnd++;
    }

    // Replace the current word with the suggestion
    final newText =
        text.substring(0, wordStart) + suggestion + text.substring(wordEnd);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.fromPosition(
        TextPosition(offset: wordStart + suggestion.length),
      ),
    );

    _hideAutocomplete();
  }

  void _addToHistory(String text) {
    if (_isUndoRedoOperation) return;

    // Remove any history after current index (when we make new changes after undo)
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(text);
    _historyIndex = _history.length - 1;

    // Keep history reasonable size
    if (_history.length > 100) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void _undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _isUndoRedoOperation = true;
      widget.controller.text = _history[_historyIndex];
      _isUndoRedoOperation = false;
    }
  }

  void _redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _isUndoRedoOperation = true;
      widget.controller.text = _history[_historyIndex];
      _isUndoRedoOperation = false;
    }
  }

  void _selectAll() {
    widget.controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.controller.text.length,
    );
  }

  void _toggleComment() {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (text.isEmpty) return;

    // Find the current line or selected lines
    int start = selection.baseOffset;
    int end = selection.extentOffset;

    if (start > end) {
      int temp = start;
      start = end;
      end = temp;
    }

    // Find line boundaries
    int lineStart = text.lastIndexOf('\n', start - 1) + 1;
    int lineEnd = text.indexOf('\n', end);
    if (lineEnd == -1) lineEnd = text.length;

    String lineContent = text.substring(lineStart, lineEnd);
    String trimmedLine = lineContent.trimLeft();

    String newLineContent;
    int cursorOffset = 0;

    if (trimmedLine.startsWith('# ')) {
      // Remove comment
      newLineContent = lineContent.replaceFirst('# ', '');
      cursorOffset = -2;
    } else if (trimmedLine.startsWith('#')) {
      // Remove comment (no space)
      newLineContent = lineContent.replaceFirst('#', '');
      cursorOffset = -1;
    } else {
      // Add comment
      int indentLength = lineContent.length - trimmedLine.length;
      newLineContent =
          '${lineContent.substring(0, indentLength)}# $trimmedLine';
      cursorOffset = 2;
    }

    String newText =
        text.substring(0, lineStart) + newLineContent + text.substring(lineEnd);

    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.fromPosition(
        TextPosition(offset: start + cursorOffset),
      ),
    );
  }

  void _detectSyntaxErrors() {
    String text = widget.controller.text;
    _syntaxErrors.clear();

    if (text.trim().isEmpty) return;

    List<String> lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      int lineNumber = i + 1;

      // Check for mismatched brackets
      _checkBracketMatching(line, lineNumber);

      // Check for unclosed strings
      _checkUnClosedStrings(line, lineNumber);

      // Check for invalid indentation
      _checkIndentation(line, lineNumber);

      // Check for basic syntax patterns
      _checkBasicSyntax(line, lineNumber);
    }
  }

  void _checkBracketMatching(String line, int lineNumber) {
    Map<String, int> openBrackets = {'(': 0, '[': 0, '{': 0};

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (openBrackets.containsKey(char)) {
        openBrackets[char] = openBrackets[char]! + 1;
      } else if (char == ')') {
        if (openBrackets['(']! > 0) {
          openBrackets['('] = openBrackets['(']! - 1;
        } else {
          _syntaxErrors.add(CodeError(
            line: lineNumber,
            column: i + 1,
            message: 'Unmatched closing parenthesis',
            type: 'bracket',
          ));
        }
      } else if (char == ']') {
        if (openBrackets['[']! > 0) {
          openBrackets['['] = openBrackets['[']! - 1;
        } else {
          _syntaxErrors.add(CodeError(
            line: lineNumber,
            column: i + 1,
            message: 'Unmatched closing bracket',
            type: 'bracket',
          ));
        }
      } else if (char == '}') {
        if (openBrackets['{']! > 0) {
          openBrackets['{'] = openBrackets['{']! - 1;
        } else {
          _syntaxErrors.add(CodeError(
            line: lineNumber,
            column: i + 1,
            message: 'Unmatched closing brace',
            type: 'bracket',
          ));
        }
      }
    }
  }

  void _checkUnClosedStrings(String line, int lineNumber) {
    bool inSingleQuote = false;
    bool inDoubleQuote = false;

    for (int i = 0; i < line.length; i++) {
      String char = line[i];

      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
      } else if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
      }
    }

    if (inSingleQuote || inDoubleQuote) {
      _syntaxErrors.add(CodeError(
        line: lineNumber,
        column: line.length,
        message: 'Unclosed string literal',
        type: 'string',
      ));
    }
  }

  void _checkIndentation(String line, int lineNumber) {
    if (line.trim().isEmpty) return;

    int spaces = 0;
    for (int i = 0; i < line.length; i++) {
      if (line[i] == ' ') {
        spaces++;
      } else if (line[i] == '\t') {
        _syntaxErrors.add(CodeError(
          line: lineNumber,
          column: i + 1,
          message: 'Use spaces instead of tabs for indentation',
          type: 'indentation',
        ));
        return;
      } else {
        break;
      }
    }

    // Check if indentation is multiple of 4
    if (spaces % 4 != 0) {
      _syntaxErrors.add(CodeError(
        line: lineNumber,
        column: 1,
        message: 'Indentation should be a multiple of 4 spaces',
        type: 'indentation',
      ));
    }
  }

  void _checkBasicSyntax(String line, int lineNumber) {
    String trimmedLine = line.trim();

    // Check for colon after control structures
    List<String> controlStructures = [
      'if ',
      'elif ',
      'else',
      'for ',
      'while ',
      'def ',
      'class ',
      'try',
      'except',
      'finally',
      'with '
    ];

    for (String structure in controlStructures) {
      if (trimmedLine.startsWith(structure) && !trimmedLine.endsWith(':')) {
        // Special case for else, try, finally which should just be the keyword
        if ((structure == 'else' ||
                structure == 'try' ||
                structure == 'finally') &&
            trimmedLine == structure.trim()) {
          _syntaxErrors.add(CodeError(
            line: lineNumber,
            column: line.length + 1,
            message: 'Missing colon after ${structure.trim()}',
            type: 'syntax',
          ));
        } else if (structure != 'else' &&
            structure != 'try' &&
            structure != 'finally') {
          _syntaxErrors.add(CodeError(
            line: lineNumber,
            column: line.length + 1,
            message: 'Missing colon after ${structure.trim()}',
            type: 'syntax',
          ));
        }
      }
    }

    // Check for common syntax errors
    if (trimmedLine.contains('=') &&
        !trimmedLine.contains('==') &&
        !trimmedLine.contains('!=') &&
        !trimmedLine.contains('<=') &&
        !trimmedLine.contains('>=')) {
      // Check if it's in an if/while statement (likely should be ==)
      if (trimmedLine.startsWith('if ') ||
          trimmedLine.startsWith('elif ') ||
          trimmedLine.startsWith('while ')) {
        RegExp assignmentInCondition = RegExp(r'\b\w+\s*=\s*\w+');
        if (assignmentInCondition.hasMatch(trimmedLine)) {
          Match? match = assignmentInCondition.firstMatch(trimmedLine);
          if (match != null) {
            _syntaxErrors.add(CodeError(
              line: lineNumber,
              column: match.start + 1,
              message: 'Assignment in condition, did you mean == ?',
              type: 'syntax',
            ));
          }
        }
      }
    }
  }

  void _onTextChanged() {
    if (!_isUndoRedoOperation) {
      _addToHistory(widget.controller.text);
    }
    _findMatchingBracket(); // Update bracket matching
    _updateAutocomplete(); // Update auto-completion
    _detectSyntaxErrors(); // Detect syntax errors
    setState(() {}); // Rebuild to update line numbers and bracket highlighting
  }

  void _handleTextChange(String newText) {
    final currentCursor = widget.controller.selection.baseOffset;

    // Check if text was added (not deleted)
    if (newText.length > _previousText.length && currentCursor > 0) {
      final insertedChar = newText[currentCursor - 1];

      // Handle auto-closing pairs
      if (_closingPairs.containsKey(insertedChar)) {
        final closingChar = _closingPairs[insertedChar]!;

        // For quotes, check if we're not already closing a quote
        if ((insertedChar == '"' || insertedChar == "'")) {
          // Don't auto-close if the next character is the same quote
          if (currentCursor < newText.length &&
              newText[currentCursor] == insertedChar) {
            _updatePreviousState(newText, currentCursor);
            return;
          }
        }

        // Insert the closing character
        final beforeCursor = newText.substring(0, currentCursor);
        final afterCursor = newText.substring(currentCursor);
        final updatedText = beforeCursor + closingChar + afterCursor;

        // Update the controller with the new text and cursor position
        widget.controller.value = TextEditingValue(
          text: updatedText,
          selection: TextSelection.fromPosition(
            TextPosition(offset: currentCursor),
          ),
        );

        _updatePreviousState(updatedText, currentCursor);
        return;
      }

      // Handle Enter key for auto-indentation
      if (insertedChar == '\n') {
        final indentedText = _handleEnterPress(newText, currentCursor - 1);
        if (indentedText != newText) {
          // Find the new cursor position (after the added indentation)
          final afterEnter = newText.substring(currentCursor);
          final indentToAdd = indentedText.substring(
              currentCursor, indentedText.length - afterEnter.length);

          widget.controller.value = TextEditingValue(
            text: indentedText,
            selection: TextSelection.fromPosition(
              TextPosition(offset: currentCursor + indentToAdd.length),
            ),
          );

          _updatePreviousState(
              indentedText, currentCursor + indentToAdd.length);
          return;
        }
      }
    }

    _updatePreviousState(newText, currentCursor);
  }

  void _updatePreviousState(String text, int cursor) {
    _previousText = text;
  }

  String _handleEnterPress(String text, int enterIndex) {
    // Find the start of the current line
    int lineStart = text.lastIndexOf('\n', enterIndex - 1) + 1;
    String currentLine = text.substring(lineStart, enterIndex);

    // Calculate current indentation
    int indentLevel = 0;
    for (int i = 0; i < currentLine.length; i++) {
      if (currentLine[i] == ' ') {
        indentLevel++;
      } else {
        break;
      }
    }

    // Check if the line ends with ':' (function, class, if, etc.)
    String trimmedLine = currentLine.trim();
    bool shouldIndent = trimmedLine.endsWith(':') ||
        trimmedLine.startsWith('if ') ||
        trimmedLine.startsWith('elif ') ||
        trimmedLine.startsWith('else:') ||
        trimmedLine.startsWith('for ') ||
        trimmedLine.startsWith('while ') ||
        trimmedLine.startsWith('def ') ||
        trimmedLine.startsWith('class ') ||
        trimmedLine.startsWith('try:') ||
        trimmedLine.startsWith('except ') ||
        trimmedLine.startsWith('finally:') ||
        trimmedLine.startsWith('with ');

    // Add appropriate indentation
    String indent = ' ' * (shouldIndent ? indentLevel + 4 : indentLevel);

    return text.substring(0, enterIndex + 1) +
        indent +
        text.substring(enterIndex + 1);
  }

  Widget _buildLineNumbers() {
    return Consumer<PythonCompilerProvider>(
      builder: (context, provider, child) {
        final isDark = provider.isDarkMode;
        String text = widget.controller.text;
        int lineCount = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;

        return Container(
          width: 50,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D30) : Colors.grey[50],
            border: Border(
              right: BorderSide(
                color: isDark ? const Color(0xFF3E3E42) : Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(lineCount, (index) {
                int lineNumber = index + 1;
                bool hasError =
                    _syntaxErrors.any((error) => error.line == lineNumber);

                return Container(
                  height: 19.6, // Match line height
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasError)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(right: 4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        '$lineNumber',
                        style: TextStyle(
                          fontSize: 12,
                          color: hasError
                              ? Colors.red[700]
                              : (isDark ? Colors.grey[400] : Colors.grey[600]),
                          fontFamily: 'monospace',
                          height: 1.4,
                          fontWeight:
                              hasError ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBracketHighlights() {
    if (_matchingBracketStart == null || _matchingBracketEnd == null) {
      return const SizedBox.shrink();
    }

    const textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      height: 1.4,
      letterSpacing: 0.0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: CustomPaint(
        painter: BracketHighlightPainter(
          text: widget.controller.text,
          bracketStart: _matchingBracketStart!,
          bracketEnd: _matchingBracketEnd!,
          textStyle: textStyle,
        ),
      ),
    );
  }

  Widget _buildSyntaxHighlightedEditor() {
    return Consumer<PythonCompilerProvider>(
      builder: (context, provider, child) {
        final isDark = provider.isDarkMode;

        final textStyle = TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          height: 1.4,
          letterSpacing: 0.0,
          color: isDark ? Colors.white : Colors.black,
        );

        const padding = EdgeInsets.fromLTRB(12, 12, 12, 12);

        return Stack(
          children: [
            // Syntax highlighted display
            Container(
              width: double.infinity,
              padding: padding,
              child: widget.controller.text.isEmpty
                  ? Text(
                      widget.hintText,
                      style: textStyle.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    )
                  : HighlightView(
                      widget.controller.text,
                      language: 'python',
                      theme: isDark ? vs2015Theme : githubTheme,
                      textStyle: textStyle,
                      padding: EdgeInsets.zero,
                    ),
            ),

            // Bracket highlights overlay
            _buildBracketHighlights(),

            // Invisible text field for input handling
            TextFormField(
              controller: widget.controller,
              maxLines: null,
              minLines: 10,
              style: textStyle.copyWith(color: Colors.transparent),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: padding,
                isDense: false, // Use default density for consistent spacing
                isCollapsed: false,
              ),
              textAlign: TextAlign.left,
              textAlignVertical: TextAlignVertical.top,
              cursorColor: isDark ? Colors.white : Colors.black,
              cursorWidth: 1.0,
              cursorRadius: const Radius.circular(0),
              showCursor: true,
              onChanged: (newValue) {
                _handleTextChange(newValue);
              },
              onTap: () {
                // Update bracket matching when user clicks
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _findMatchingBracket();
                  setState(() {});
                });
              },
              inputFormatters: [
                // Convert tabs to 4 spaces
                TextInputFormatter.withFunction((oldValue, newValue) {
                  return newValue.copyWith(
                    text: newValue.text.replaceAll('\t', '    '),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PythonCompilerProvider>(
      builder: (context, provider, child) {
        final isDark = provider.isDarkMode;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? const Color(0xFF3E3E42) : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) {
                    final isCtrlPressed =
                        HardwareKeyboard.instance.isControlPressed;
                    final isShiftPressed =
                        HardwareKeyboard.instance.isShiftPressed;
                    final isAltPressed = HardwareKeyboard.instance.isAltPressed;

                    // Handle autocomplete navigation
                    if (_suggestions.isNotEmpty) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() {
                          _selectedSuggestionIndex =
                              (_selectedSuggestionIndex + 1) %
                                  _suggestions.length;
                        });
                        _showAutocomplete(); // Refresh the overlay
                        return KeyEventResult.handled;
                      }

                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        setState(() {
                          _selectedSuggestionIndex = (_selectedSuggestionIndex -
                                  1 +
                                  _suggestions.length) %
                              _suggestions.length;
                        });
                        _showAutocomplete(); // Refresh the overlay
                        return KeyEventResult.handled;
                      }

                      if (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.tab) {
                        _insertSuggestion(
                            _suggestions[_selectedSuggestionIndex]);
                        return KeyEventResult.handled;
                      }

                      if (event.logicalKey == LogicalKeyboardKey.escape) {
                        _hideAutocomplete();
                        return KeyEventResult.handled;
                      }
                    }

                    // Handle Shift+Alt+F (Format Code)
                    if (event.logicalKey == LogicalKeyboardKey.keyF &&
                        isShiftPressed &&
                        isAltPressed) {
                      _formatCode();
                      return KeyEventResult.handled;
                    }

                    // Handle Ctrl+F (Find and Replace)
                    if (event.logicalKey == LogicalKeyboardKey.keyF &&
                        isCtrlPressed) {
                      _showFindReplaceDialog();
                      return KeyEventResult.handled;
                    }

                    // Handle Ctrl+Z (Undo)
                    if (event.logicalKey == LogicalKeyboardKey.keyZ &&
                        isCtrlPressed) {
                      _undo();
                      return KeyEventResult.handled;
                    }

                    // Handle Ctrl+Y (Redo) or Ctrl+Shift+Z
                    if ((event.logicalKey == LogicalKeyboardKey.keyY &&
                            isCtrlPressed) ||
                        (event.logicalKey == LogicalKeyboardKey.keyZ &&
                            isCtrlPressed &&
                            HardwareKeyboard.instance.isShiftPressed)) {
                      _redo();
                      return KeyEventResult.handled;
                    }

                    // Handle Ctrl+A (Select All)
                    if (event.logicalKey == LogicalKeyboardKey.keyA &&
                        isCtrlPressed) {
                      _selectAll();
                      return KeyEventResult.handled;
                    }

                    // Handle Ctrl+/ (Toggle Comment)
                    if (event.logicalKey == LogicalKeyboardKey.slash &&
                        isCtrlPressed) {
                      _toggleComment();
                      return KeyEventResult.handled;
                    }

                    // Update bracket matching on arrow key presses
                    if ([
                      LogicalKeyboardKey.arrowLeft,
                      LogicalKeyboardKey.arrowRight,
                      LogicalKeyboardKey.arrowUp,
                      LogicalKeyboardKey.arrowDown
                    ].contains(event.logicalKey)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _findMatchingBracket();
                        setState(() {});
                      });
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Line numbers
                      _buildLineNumbers(),

                      // Code editor with syntax highlighting
                      Expanded(
                        child: _buildSyntaxHighlightedEditor(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Find and Replace Dialog
            if (_showFindReplace)
              FindReplaceDialog(
                codeController: widget.controller,
                onFindResult: _onFindResult,
                onClose: _hideFindReplaceDialog,
              ),

            // Error Panel
            if (_syntaxErrors.isNotEmpty)
              Consumer<PythonCompilerProvider>(
                builder: (context, provider, child) {
                  final isDark = provider.isDarkMode;
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.red[900]?.withValues(alpha: 0.3)
                            : Colors.red[50],
                        border: Border(
                          top: BorderSide(
                            color: isDark ? Colors.red[400]! : Colors.red[300]!,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.red[800]?.withValues(alpha: 0.4)
                                  : Colors.red[100],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: isDark
                                        ? Colors.red[300]
                                        : Colors.red[700],
                                    size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Syntax Errors (${_syntaxErrors.length})',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.red[300]
                                        : Colors.red[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _syntaxErrors.length,
                              itemBuilder: (context, index) {
                                CodeError error = _syntaxErrors[index];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          'Line ${error.line}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.red[400]
                                                : Colors.red[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          error.message,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.red[200]
                                                : Colors.red[800],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.red[700]
                                              : Colors.red[200],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          error.type,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark
                                                ? Colors.red[100]
                                                : Colors.red[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class BracketHighlightPainter extends CustomPainter {
  final String text;
  final int bracketStart;
  final int bracketEnd;
  final TextStyle textStyle;

  BracketHighlightPainter({
    required this.text,
    required this.bracketStart,
    required this.bracketEnd,
    required this.textStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Calculate position for start bracket
    final beforeStart = text.substring(0, bracketStart);
    textPainter.text = TextSpan(text: beforeStart, style: textStyle);
    textPainter.layout();
    final startX = textPainter.width;
    final startY = textPainter.height;

    // Calculate position for end bracket
    final beforeEnd = text.substring(0, bracketEnd);
    textPainter.text = TextSpan(text: beforeEnd, style: textStyle);
    textPainter.layout();
    final endX = textPainter.width;
    final endY = textPainter.height;

    // Draw highlight rectangles
    final paint = Paint()
      ..color = Colors.lightBlue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const charWidth = 8.4; // Approximate monospace character width
    const charHeight = 19.6;

    // Highlight start bracket
    canvas.drawRect(
      Rect.fromLTWH(startX, startY - charHeight, charWidth, charHeight),
      paint,
    );

    // Highlight end bracket
    canvas.drawRect(
      Rect.fromLTWH(endX, endY - charHeight, charWidth, charHeight),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
