package pl.bezpiecznaprzystan.app

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingStart: MethodChannel.Result? = null
    private var player: MediaPlayer? = null
    private var playing: String? = null
    private val filename = Regex("(\\d+)-(\\d+)\\.m4a")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pl.bezpiecznaprzystan/app")
            .setMethodCallHandler { call, result ->
                val id = call.arguments as? String
                try {
                    when (call.method) {
                        "start" -> {
                            pause()
                            requestStart(result)
                        }
                        "stop" -> if (RecordingService.started == null) {
                            result.success(null)
                        } else {
                            send(RecordingService.STOP, result)
                        }
                        "status" -> result.success(status())
                        "play" -> {
                            play(checkNotNull(id))
                            result.success(null)
                        }
                        "pause" -> {
                            pause()
                            result.success(null)
                        }
                        "delete" -> {
                            val file = recording(checkNotNull(id))
                            if (playing == id) pause()
                            check(!file.exists() || file.delete())
                            result.success(null)
                        }
                        "loadNeutral" -> result.success(data().getBoolean("neutral", false).toString())
                        "saveNeutral" -> {
                            check(data().edit().putBoolean("neutral", id == "true").commit())
                            result.success(null)
                        }
                        "load" -> result.success(data().getString("document", null))
                        "save" -> {
                            check(data().edit().putString("document", checkNotNull(id)).commit())
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    val message = when (call.method) {
                        "play" -> "Nie udało się odtworzyć nagrania."
                        "delete" -> "Nie udało się usunąć nagrania."
                        "save" -> "Nie udało się zapisać danych."
                        else -> "Operacja się nie powiodła."
                    }
                    result.error("operation", message, null)
                }
            }
    }

    private fun data() = getSharedPreferences("przystan", Context.MODE_PRIVATE)

    private fun requestStart(result: MethodChannel.Result) {
        if (pendingStart != null) {
            result.error("pending", "Poczekaj na decyzję o uprawnieniach.", null)
            return
        }
        val permissions = mutableListOf<String>()
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.RECORD_AUDIO)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        if (permissions.isEmpty()) {
            startIfAllowed(result)
        } else {
            pendingStart = result
            requestPermissions(permissions.toTypedArray(), 700)
        }
    }

    override fun onRequestPermissionsResult(code: Int, permissions: Array<out String>, results: IntArray) {
        super.onRequestPermissionsResult(code, permissions, results)
        if (code != 700) return
        val reply = pendingStart ?: return
        pendingStart = null
        // Waiting until the permission dialog closes keeps the start tied to the visible activity.
        Handler(Looper.getMainLooper()).post { startIfAllowed(reply) }
    }

    private fun startIfAllowed(result: MethodChannel.Result) {
        val manager = getSystemService(NotificationManager::class.java)
        val channel = manager.getNotificationChannel("recording")
        val message = when {
            checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED ->
                "Zezwól na dostęp do mikrofonu w ustawieniach Androida."
            !manager.areNotificationsEnabled() || channel?.importance == NotificationManager.IMPORTANCE_NONE ->
                "Włącz powiadomienia aplikacji, aby podczas nagrywania był widoczny status."
            else -> null
        }
        if (message != null) {
            result.error("permission", message, null)
            return
        }
        try {
            send(RecordingService.START, result)
        } catch (error: Exception) {
            result.error("start", "Uruchom nagrywanie przy otwartej aplikacji.", null)
        }
    }

    private fun send(action: String, result: MethodChannel.Result) {
        val reply = object : ResultReceiver(Handler(Looper.getMainLooper())) {
            override fun onReceiveResult(code: Int, values: Bundle?) {
                if (code == 0) result.success(null)
                else result.error("recorder", values?.getString("message"), null)
            }
        }
        val intent = Intent(this, RecordingService::class.java).setAction(action)
            .putExtra(RecordingService.REPLY, reply)
        if (action == RecordingService.START) startForegroundService(intent) else startService(intent)
    }

    private fun recording(id: String): File {
        require(filename.matches(id))
        return File(RecordingService.directory(this), id)
    }

    private fun status(): String {
        val recordings = JSONArray()
        RecordingService.directory(this).listFiles().orEmpty()
            .sortedByDescending { it.name }
            .forEach { file ->
                val match = filename.matchEntire(file.name) ?: return@forEach
                recordings.put(JSONObject()
                    .put("id", file.name)
                    .put("created", match.groupValues[1].toLong())
                    .put("duration", match.groupValues[2].toLong()))
            }
        return JSONObject().put("recordings", recordings)
            .put("started", RecordingService.started ?: JSONObject.NULL)
            .put("playing", playing ?: JSONObject.NULL)
            .toString()
    }

    private fun play(id: String) {
        check(RecordingService.started == null)
        pause()
        val playback = MediaPlayer()
        player = playback
        try {
            playback.setAudioAttributes(AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build())
            playback.setDataSource(recording(id).absolutePath)
            playback.setOnCompletionListener { pause() }
            playback.setOnErrorListener { _, _, _ -> pause(); true }
            playback.prepare()
            playback.start()
            playing = id
        } catch (error: Exception) {
            pause()
            throw error
        }
    }

    private fun pause() {
        player?.release()
        player = null
        playing = null
    }

    override fun onDestroy() {
        pause()
        pendingStart?.error("interrupted", "Uruchom nagrywanie ponownie.", null)
        pendingStart = null
        super.onDestroy()
    }
}
