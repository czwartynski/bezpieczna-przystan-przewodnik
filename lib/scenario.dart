enum Topic { start, recognize, control, threats, plan, help }

typedef Choice = ({String label, Topic next});
typedef GuideStep = ({String message, List<Choice> choices});

const Map<Topic, GuideStep> scenario = {
  Topic.start: (
    message: 'Co najlepiej opisuje Twoją sytuację?',
    choices: [
      (label: 'Nie wiem, czy to przemoc', next: Topic.recognize),
      (label: 'Chcę przygotować plan', next: Topic.plan),
      (label: 'Szukam kontaktu do pomocy', next: Topic.help),
    ],
  ),
  Topic.recognize: (
    message: 'Co chcesz sprawdzić?',
    choices: [
      (label: 'Kontrolowanie i izolowanie', next: Topic.control),
      (label: 'Groźby i poniżanie', next: Topic.threats),
    ],
  ),
  Topic.control: (
    message: 'Kontrolowanie kontaktów i odcinanie od bliskich mogą być formami przemocy psychicznej. Który temat chcesz otworzyć dalej?',
    choices: [
      (label: 'Chcę przygotować plan', next: Topic.plan),
      (label: 'Szukam kontaktu do pomocy', next: Topic.help),
    ],
  ),
  Topic.threats: (
    message: 'Groźby, ciągłe wyzwiska i poniżanie mogą być formami przemocy psychicznej. Który temat chcesz otworzyć dalej?',
    choices: [
      (label: 'Chcę przygotować plan', next: Topic.plan),
      (label: 'Szukam kontaktu do pomocy', next: Topic.help),
    ],
  ),
  Topic.plan: (
    message: 'W Bezpiecznej Przystani otwórz moduł „Plan bezpieczeństwa”. Możesz tam zapisać m.in. zaufane osoby, bezpieczne miejsce i sposób dotarcia.',
    choices: [(label: 'Szukam kontaktu do pomocy', next: Topic.help)],
  ),
  Topic.help: (
    message: 'W Bezpiecznej Przystani otwórz moduł „Znajdź pomoc”. Znajdziesz tam kontakty i informacje o możliwościach uzyskania pomocy w Polsce.',
    choices: [(label: 'Chcę przygotować plan', next: Topic.plan)],
  ),
};
