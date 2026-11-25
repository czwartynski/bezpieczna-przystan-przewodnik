import 'dart:js_interop';

@JS('przystanAudio')
external JSPromise<JSString?> _invoke(JSString method, JSString? argument);

Future<String?> call(String method, [String? argument]) async =>
    (await _invoke(method.toJS, argument?.toJS).toDart)?.toDart;
