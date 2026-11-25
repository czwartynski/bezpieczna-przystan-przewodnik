import 'package:flutter/services.dart';

const _channel = MethodChannel('pl.bezpiecznaprzystan/app');

Future<String?> call(String method, [String? argument]) =>
    _channel.invokeMethod<String>(method, argument);
