import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

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
  int _previousCursorPosition = 0;
  final List<String> _history = [];
  int _historyIndex = -1;
  bool _isUndoRedoOperation = false;

  // Auto-closing pairs map
  static const Map<String, String> _closingPairs = {
    '(': ')',
    '[': ']',
    '{': '}',
    '"': '"',
    "'": "'",
  };

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _previousText = widget.controller.text;
    _previousCursorPosition = widget.controller.selection.baseOffset;
    _addToHistory(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
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
          lineContent.substring(0, indentLength) + '# ' + trimmedLine;
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

  void _onTextChanged() {
    if (!_isUndoRedoOperation) {
      _addToHistory(widget.controller.text);
    }
    setState(() {}); // Rebuild to update line numbers
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
          final beforeEnter = newText.substring(0, currentCursor - 1);
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
    _previousCursorPosition = cursor;
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
    String text = widget.controller.text;
    int lineCount = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;

    return Container(
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(lineCount, (index) {
            return Container(
              height: 19.6, // Match line height
              alignment: Alignment.centerRight,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontFamily: 'monospace',
                  height: 1.4,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSyntaxHighlightedEditor() {
    const textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 14,
      height: 1.4,
      letterSpacing: 0.0, // Ensure consistent character spacing
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
                  style: textStyle.copyWith(color: Colors.grey[400]),
                )
              : HighlightView(
                  widget.controller.text,
                  language: 'python',
                  theme: githubTheme,
                  textStyle: textStyle,
                  padding: EdgeInsets.zero,
                ),
        ),

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
          cursorColor: Colors.black,
          cursorWidth: 1.0,
          cursorRadius: const Radius.circular(0),
          showCursor: true,
          onChanged: (newValue) {
            _handleTextChange(newValue);
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
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            final isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

            // Handle Ctrl+Z (Undo)
            if (event.logicalKey == LogicalKeyboardKey.keyZ && isCtrlPressed) {
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
            if (event.logicalKey == LogicalKeyboardKey.keyA && isCtrlPressed) {
              _selectAll();
              return KeyEventResult.handled;
            }

            // Handle Ctrl+/ (Toggle Comment)
            if (event.logicalKey == LogicalKeyboardKey.slash && isCtrlPressed) {
              _toggleComment();
              return KeyEventResult.handled;
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
    );
  }
}
