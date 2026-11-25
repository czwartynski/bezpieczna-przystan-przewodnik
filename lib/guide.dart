import 'package:material_ui/material_ui.dart';

import 'scenario.dart';

class Guide extends StatefulWidget {
  const Guide({super.key, required this.onOpenPlan, required this.onFindHelp});

  final VoidCallback onOpenPlan;
  final VoidCallback onFindHelp;

  @override
  State<Guide> createState() => _GuideState();
}

class _GuideState extends State<Guide> {
  final _choices = GlobalKey();
  final List<Choice> _answers = [];

  void _select(Choice choice) {
    setState(() => _answers.add(choice));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _choices.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 180),
        );
      }
    });
  }

  void _reset() => setState(_answers.clear);

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wybierz temat', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('To przewodnik z gotowymi odpowiedziami.'),
        const SizedBox(height: 16),
        if (_answers.isNotEmpty) _bubble(scenario[Topic.start]!.message),
        for (final answer in _answers) ...[
          _bubble(answer.label, answer: true),
          _bubble(scenario[answer.next]!.message),
        ],
        Wrap(
          key: _choices,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (topic == Topic.plan)
              FilledButton(
                onPressed: widget.onOpenPlan,
                child: const Text('Otwórz mój plan'),
              ),
            if (topic == Topic.help)
              FilledButton(
                onPressed: widget.onFindHelp,
                child: const Text('Znajdź pomoc'),
              ),
            for (final choice in scenario[topic]!.choices)
              OutlinedButton(
                onPressed: () => _select(choice),
                child: Text(choice.label),
              ),
            if (_answers.isNotEmpty)
              TextButton(onPressed: _reset, child: const Text('Zmień temat')),
          ],
        ),
      ],
    );
  }
}
