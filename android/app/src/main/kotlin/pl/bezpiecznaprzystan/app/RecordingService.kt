package pl.bezpiecznaprzystan.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaRecorder
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.os.ResultReceiver
import android.os.SystemClock
import java.io.File

class RecordingService : Service() {
    companion object {
        const val START = "record.start"
        const val STOP = "record.stop"
        const val REPLY = "record.reply"
        private const val CHANNEL = "recording"
        private const val NOTIFICATION = 701

        var started: Long? = null
            private set

        fun directory(context: Context) = File(context.filesDir, "recordings").apply { mkdirs() }
    }

    private var recorder: MediaRecorder? = null
    private var temporary: File? = null
    private var startedElapsed = 0L

    override fun onBind(intent: Intent?): IBinder? = null

    @Suppress("DEPRECATION")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val reply = intent?.getParcelableExtra<ResultReceiver>(REPLY)
        try {
            when (intent?.action) {
                START -> begin()
                STOP -> finishRecording()
                else -> stopSelf()
            }
            reply?.send(0, null)
        } catch (error: Exception) {
            clearCapture()
            stopSelf()
            val message = if (intent?.action == START) {
                "Nie udało się rozpocząć nagrywania. Sprawdź dostęp do mikrofonu."
            } else {
                "Nie udało się zapisać nagrania."
            }
            reply?.send(1, Bundle().apply { putString("message", message) })
            if (reply == null) {
                android.widget.Toast.makeText(this, message, android.widget.Toast.LENGTH_LONG).show()
            }
        }
        return START_NOT_STICKY
    }

    @Suppress("DEPRECATION")
    private fun begin() {
        if (recorder != null) return
        val notification = notification()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            startForeground(NOTIFICATION, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
        } else {
            startForeground(NOTIFICATION, notification)
        }
        val directory = directory(this)
        directory.listFiles()?.filter { it.extension == "part" }?.forEach { it.delete() }
        val target = File.createTempFile("recording-", ".part", directory)
        temporary = target
        val capture = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(this) else MediaRecorder()
        recorder = capture
        capture.setAudioSource(MediaRecorder.AudioSource.MIC)
        capture.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
        capture.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
        capture.setOutputFile(target.absolutePath)
        capture.setOnErrorListener { _, _, _ ->
            clearCapture()
            stopSelf()
            android.widget.Toast.makeText(this, "Nagrywanie zostało przerwane.", android.widget.Toast.LENGTH_LONG).show()
        }
        capture.prepare()
        capture.start()
        startedElapsed = SystemClock.elapsedRealtime()
        started = System.currentTimeMillis()
    }

    private fun finishRecording() {
        try {
            val capture = recorder ?: return
            val target = checkNotNull(temporary)
            val duration = SystemClock.elapsedRealtime() - startedElapsed
            capture.stop()
            val output = File(target.parentFile, "${started}-$duration.m4a")
            check(target.length() > 0 && target.renameTo(output))
        } finally {
            clearCapture()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun clearCapture() {
        recorder?.release()
        recorder = null
        temporary?.delete()
        temporary = null
        started = null
    }

    private fun notification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(CHANNEL, "Nagrywanie dźwięku", NotificationManager.IMPORTANCE_LOW)
        )
        val open = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val stop = PendingIntent.getService(
            this, 1, Intent(this, RecordingService::class.java).setAction(STOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        return Notification.Builder(this, CHANNEL)
            .setSmallIcon(R.drawable.ic_lotus)
            .setContentTitle("Trwa nagrywanie dźwięku")
            .setContentText("Dotknij, aby otworzyć aplikację.")
            .setContentIntent(open)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .addAction(Notification.Action.Builder(null, "Zatrzymaj", stop).build())
            .build()
    }

    override fun onDestroy() {
        clearCapture()
        super.onDestroy()
    }
}
