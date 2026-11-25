import 'dart:convert';

import 'audio_android.dart'
    if (dart.library.js_interop) 'audio_web.dart'
    as platform;

class Recording {
  const Recording(this.id, this.created, this.duration);
  final String id;
  final DateTime created;
  final Duration duration;

  factory Recording.fromJson(Map<String, dynamic> json) => Recording(
    json['id'] as String,
    DateTime.fromMillisecondsSinceEpoch(json['created'] as int),
    Duration(milliseconds: json['duration'] as int),
  );
}

class Audio {
  Future<void> start() async => platform.call('start');
  Future<void> stop() async => platform.call('stop');
  Future<void> play(String id) async => platform.call('play', id);
  Future<void> pause() async => platform.call('pause');
  Future<void> delete(String id) async => platform.call('delete', id);
  Future<bool> loadNeutral() async =>
      await platform.call('loadNeutral') == 'true';
  Future<void> saveNeutral(bool active) async =>
      platform.call('saveNeutral', active.toString());
  Future<String?> load() => platform.call('load');
  Future<void> save(String data) async => platform.call('save', data);

  Future<({List<Recording> recordings, int? started, String? playing})>
  status() async {
    final data =
        jsonDecode((await platform.call('status'))!) as Map<String, dynamic>;
    return (
      recordings: (data['recordings'] as List)
          .map((item) => Recording.fromJson(item as Map<String, dynamic>))
          .toList(),
      started: data['started'] as int?,
      playing: data['playing'] as String?,
    );
  }
}
