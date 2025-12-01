package com.github.raoxwup.haka_comic

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Build
import android.os.Environment
import android.content.ContentValues
import android.provider.MediaStore
import android.content.Intent
import android.net.Uri
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "haka_comic/download_saver"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveFileToDownloads" -> {
                    val sourcePath = call.argument<String>("sourceFilePath")!!
                    val fileName = call.argument<String>("fileName")!!
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"

                    val success = saveFileByPath(sourcePath, fileName, mimeType)
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("SAVE_FAILED", "无法保存文件到下载目录", null)
                    }
                }

                "getAndroidVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun saveFileByPath(
        sourcePath: String,
        fileName: String,
        mimeType: String,
    ): Boolean {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) return false

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                // Android 10+：用 MediaStore + InputStream 流式写入
                val resolver = contentResolver
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                    put(MediaStore.Downloads.MIME_TYPE, mimeType)
                    put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/HaKa")
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }

                val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                    ?: return false

                resolver.openOutputStream(uri)?.use { output ->
                    sourceFile.inputStream().use { input ->
                        input.copyTo(output)   // ← 流式复制，内存极低
                    }
                } ?: return false

                values.clear()
                values.put(MediaStore.Downloads.IS_PENDING, 0)
                resolver.update(uri, values, null, null)
                true

            } else {
                // Android 9 及以下：直接复制文件
                val targetDir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "HaKa")
                targetDir.mkdirs()

                val targetFile = generateUniqueFile(targetDir, fileName)

                sourceFile.inputStream().use { input ->
                    FileOutputStream(targetFile).use { output ->
                        input.copyTo(output)   // ← 流式复制
                    }
                }

                // 媒体扫描
                val intent = Intent(Intent.ACTION_MEDIA_SCANNER_SCAN_FILE)
                intent.data = Uri.fromFile(targetFile)
                sendBroadcast(intent)
                true
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    // 辅助函数：避免重名
    private fun generateUniqueFile(dir: File, fileName: String): File {
        var file = File(dir, fileName)
        var i = 1
        while (file.exists()) {
            val nameNoExt = fileName.substringBeforeLast(".")
            val ext = if (fileName.contains(".")) ".${fileName.substringAfterLast(".")}" else ""
            file = File(dir, "$nameNoExt($i)$ext")
            i++
        }
        return file
    }
}
