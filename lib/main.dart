import 'package:material_ui/material_ui.dart';

import 'scenario.dart';

void main() => runApp(
  MaterialApp(
    title: 'Przewodnik po wsparciu',
    debugShowCheckedModeBanner: false,
    locale: const Locale('pl'),
    supportedLocales: const [Locale('pl')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff7148a3)),
    ),
    home: const Guide(),
  ),
);

class Guide extends StatefulWidget {
  const Guide({super.key});

  @override
  State<Guide> createState() => _GuideState();
}

class _GuideState extends State<Guide> {
  final _scroll = ScrollController();
  final List<Choice> _answers = [];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _select(Choice choice) {
    setState(() => _answers.add(choice));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _reset() {
    _scroll.jumpTo(0);
    setState(_answers.clear);
  }

  Widget _bubble(String message, {bool answer = false}) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: answer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        margin: EdgeInsets.only(
          bottom: 10,
          left: answer ? 36 : 0,
          right: answer ? 0 : 36,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: answer ? colors.primary : colors.secondaryContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: answer ? colors.onPrimary : colors.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topic = _answers.isEmpty ? Topic.start : _answers.last.next;
    return Scaffold(
      appBar: AppBar(title: const Text('Przewodnik po wsparciu')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(20),
              children: [
                const Text('To przewodnik z gotowymi odpowiedziami.'),
                const SizedBox(height: 16),
                _bubble(scenario[Topic.start]!.message),
                for (final answer in _answers) ...[
                  _bubble(answer.label, answer: true),
                  _bubble(scenario[answer.next]!.message),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final choice in scenario[topic]!.choices)
                      OutlinedButton(
                        onPressed: () => _select(choice),
                        child: Text(choice.label),
                      ),
                    if (_answers.isNotEmpty)
                      TextButton(
                        onPressed: _reset,
                        child: const Text('Zmień temat'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
