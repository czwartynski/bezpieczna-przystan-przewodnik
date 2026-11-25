import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

class NeutralCalculator extends StatefulWidget {
  const NeutralCalculator({
    super.key,
    required this.onUnlock,
    required this.doubleTapReturn,
    required this.returnKey,
    required this.recording,
    this.microphoneLabel,
    this.onMicrophone,
    this.error,
  });

  final VoidCallback onUnlock;
  final bool doubleTapReturn;
  final String returnKey;
  final bool recording;
  final String? microphoneLabel;
  final VoidCallback? onMicrophone;
  final String? error;

  @override
  State<NeutralCalculator> createState() => _NeutralCalculatorState();
}

class _NeutralCalculatorState extends State<NeutralCalculator> {
  static const _keys = [
    'AC',
    '±',
    '⌫',
    '÷',
    '7',
    '8',
    '9',
    '×',
    '4',
    '5',
    '6',
    '−',
    '1',
    '2',
    '3',
    '+',
    '0',
    ',',
    '=',
  ];

  String _display = '0';
  String? _operation;
  double? _left;
  bool _replace = true;

  double get _number => double.parse(_display.replaceAll(',', '.'));

  void _calculate() {
    final left = _left!;
    final right = _number;
    final result = switch (_operation) {
      '+' => left + right,
      '−' => left - right,
      '×' => left * right,
      '÷' => left / right,
      _ => right,
    };
    _display = result.isFinite
        ? (double.parse(
            result.toStringAsPrecision(12),
          )).toString().replaceFirst(RegExp(r'\.0$'), '').replaceAll('.', ',')
        : 'Błąd';
    _operation = null;
    _left = null;
    _replace = true;
  }

  void _press(String key) => setState(() {
    if (key == 'AC') {
      _display = '0';
      _operation = null;
      _left = null;
      _replace = true;
      return;
    }
    if ('+−×÷'.contains(key)) {
      if (_display == 'Błąd') return;
      if (_operation != null && !_replace) _calculate();
      if (_display == 'Błąd') return;
      _left = _number;
      _operation = key;
      _replace = true;
      return;
    }
    if (key == '=') {
      if (_operation != null && !_replace) _calculate();
      return;
    }
    if (key == '±') {
      if (_display == 'Błąd') return;
      if (_replace && _operation != null) _display = '0';
      _display = _display.startsWith('-')
          ? _display.substring(1)
          : '-$_display';
      _replace = false;
      return;
    }
    if (key == '⌫') {
      if (_replace || _display.contains('e')) return;
      _display = _display.substring(0, _display.length - 1);
      if (_display.isEmpty || _display == '-') _display = '0';
      return;
    }
    if (_replace) {
      _display = '0';
      _replace = false;
    }
    if (key == ',') {
      if (!_display.contains(',') && !_display.contains('e')) _display += ',';
    } else if (_display.length < 14 && !_display.contains('e')) {
      _display = switch (_display) {
        '0' => key,
        '-0' => key == '0' ? '-0' : '-$key',
        _ => '$_display$key',
      };
    }
  });

  KeyEventResult _keyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed &&
        keyboard.isShiftPressed &&
        event.logicalKey.keyLabel.toUpperCase() == widget.returnKey) {
      widget.onUnlock();
      return KeyEventResult.handled;
    }
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final key = switch (event.logicalKey) {
      LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter => '=',
      LogicalKeyboardKey.backspace => '⌫',
      LogicalKeyboardKey.escape || LogicalKeyboardKey.delete => 'AC',
      _ => switch (event.character) {
        '.' => ',',
        '-' => '−',
        '*' => '×',
        '/' => '÷',
        final character => character,
      },
    };
    if (key == null || !_keys.contains(key)) return KeyEventResult.ignored;
    _press(key);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Focus(
    autofocus: true,
    onKeyEvent: _keyEvent,
    child: Scaffold(
      backgroundColor: const Color(0xff171b24),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 392),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kalkulator',
                    style: TextStyle(
                      color: Color(0xffc7cfdf),
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: widget.doubleTapReturn
                        ? null
                        : widget.onUnlock,
                    onDoubleTap: widget.doubleTapReturn
                        ? widget.onUnlock
                        : null,
                    child: Container(
                      height: 108,
                      width: double.infinity,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xff252b37),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _display,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 52,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.microphoneLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: FilledButton.icon(
                        onPressed: widget.onMicrophone,
                        icon: Icon(widget.recording ? Icons.stop : Icons.mic),
                        label: Text(widget.microphoneLabel!),
                      ),
                    ),
                  if (widget.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  const SizedBox(height: 14),
                  for (var index = 0; index < _keys.length; index += 4)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          for (final key in _keys.skip(index).take(4))
                            Expanded(
                              flex: index == 16 && key == '0' ? 2 : 1,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: FilledButton(
                                  onPressed: () => _press(key),
                                  style: FilledButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: key == '='
                                        ? const Color(0xff365cb8)
                                        : '+−×÷'.contains(key)
                                        ? const Color(0xff374462)
                                        : const Color(0xff2a3242),
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(fontSize: 22),
                                  ),
                                  child: Text(key),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
