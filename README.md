# Bezpieczna Przystań · Demo przewodnika

Pełna aplikacja Flutter z ekranem powitalnym, menu i przewodnikiem w module „Porozmawiaj ze wsparciem”. Przewodnik działa według gotowych ścieżek z pliku `lib/scenario.dart`. Wybory pozostają w pamięci bieżącego widoku.

## Demo

[Otwórz demo HTTPS](https://czwartynski.github.io/bezpieczna-przystan-przewodnik/). W przeglądarce używaj wyłącznie danych testowych. Dziennik, plan i nagrania w demo są dostępne do odświeżenia lub zamknięcia karty.

GitHub Actions publikuje wersję Web po aktualizacji gałęzi `main`.

## Uruchomienie lokalne

Projekt używa Flutter 3.50.1.

```sh
flutter pub get
flutter analyze
flutter run -d chrome
```

[Informacje o przemocy domowej i możliwościach pomocy na Gov.pl](https://www.gov.pl/web/gov/skorzystaj-z-pomocy-dla-osob-dotknietych-przemoca-w-rodzinie)
