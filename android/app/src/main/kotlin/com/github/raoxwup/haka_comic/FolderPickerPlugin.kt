package com.github.raoxwup.haka_comic

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

class FolderPickerPlugin(
    private val activity: FlutterFragmentActivity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        private const val CHANNEL = "haka_comic/folder_picker"
        private const val REQUEST_CODE_PICK_DIRECTORY = 0xF017
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private var pendingResult: MethodChannel.Result? = null
    private var recursive = true

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickDirectorySnapshot" -> startPickDirectory(call, result)
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE_PICK_DIRECTORY) {
            return false
        }

        val pending = pendingResult ?: return false
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pending.success(null)
            return true
        }

        val treeUri = data.data ?: run {
            pending.success(null)
            return true
        }

        val grantedFlags = data.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION
        val permissionFlags = if (grantedFlags != 0) {
            grantedFlags
        } else {
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        }

        try {
            activity.contentResolver.takePersistableUriPermission(treeUri, permissionFlags)
        } catch (_: SecurityException) {
            // Some providers do not offer persistable permissions. Immediate reads still work.
        }

        try {
            val rootDocumentUri = DocumentsContract.buildDocumentUriUsingTree(
                treeUri,
                DocumentsContract.getTreeDocumentId(treeUri),
            )
            val folderName = queryDisplayName(rootDocumentUri).orEmpty().ifBlank { "folder" }
            val snapshot = createSnapshot(
                treeUri = treeUri,
                rootDocumentUri = rootDocumentUri,
                folderName = folderName,
                recursive = recursive,
            )
            pending.success(snapshot)
        } catch (e: Exception) {
            pending.error(
                "snapshot_failed",
                e.message ?: "Failed to create folder snapshot.",
                null,
            )
        }

        return true
    }

    private fun startPickDirectory(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Another folder picker request is already running.", null)
            return
        }

        recursive = call.argument<Boolean>("recursive") ?: true
        pendingResult = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PREFIX_URI_PERMISSION)
        }
        activity.startActivityForResult(intent, REQUEST_CODE_PICK_DIRECTORY)
    }

    private fun createSnapshot(
        treeUri: Uri,
        rootDocumentUri: Uri,
        folderName: String,
        recursive: Boolean,
    ): Map<String, Any> {
        val snapshotsRoot = File(activity.cacheDir, "folder_picker")
        if (!snapshotsRoot.exists()) {
            snapshotsRoot.mkdirs()
        }

        val snapshotDir = File(
            snapshotsRoot,
            "${System.currentTimeMillis()}_${UUID.randomUUID()}_${sanitizeForPath(folderName)}",
        )
        if (!snapshotDir.mkdirs()) {
            throw IllegalStateException("Failed to create snapshot directory.")
        }

        val files = mutableListOf<Map<String, Any?>>()
        copyChildren(
            treeUri = treeUri,
            parentDocumentUri = rootDocumentUri,
            destinationDir = snapshotDir,
            snapshotRoot = snapshotDir,
            recursive = recursive,
            files = files,
        )

        return mapOf(
            "name" to folderName,
            "localPath" to snapshotDir.absolutePath,
            "files" to files,
        )
    }

    private fun copyChildren(
        treeUri: Uri,
        parentDocumentUri: Uri,
        destinationDir: File,
        snapshotRoot: File,
        recursive: Boolean,
        files: MutableList<Map<String, Any?>>,
    ) {
        for (entry in queryChildren(treeUri, parentDocumentUri)) {
            val destination = File(destinationDir, entry.displayName)
            if (entry.isDirectory) {
                if (!recursive) {
                    continue
                }
                if (!destination.exists()) {
                    destination.mkdirs()
                }
                copyChildren(
                    treeUri = treeUri,
                    parentDocumentUri = entry.documentUri,
                    destinationDir = destination,
                    snapshotRoot = snapshotRoot,
                    recursive = true,
                    files = files,
                )
                continue
            }

            copyUriToFile(entry.documentUri, destination)
            files.add(
                mapOf(
                    "name" to entry.displayName,
                    "relativePath" to relativePath(snapshotRoot, destination),
                    "localPath" to destination.absolutePath,
                    "size" to entry.size,
                    "mimeType" to entry.mimeType,
                ),
            )
        }
    }

    private fun queryChildren(treeUri: Uri, parentDocumentUri: Uri): List<DocumentEntry> {
        val resolver = activity.contentResolver
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getDocumentId(parentDocumentUri),
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_MIME_TYPE,
            DocumentsContract.Document.COLUMN_SIZE,
        )

        val result = mutableListOf<DocumentEntry>()
        resolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            val documentIdIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
            val displayNameIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
            val mimeTypeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_MIME_TYPE)
            val sizeIndex = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_SIZE)

            while (cursor.moveToNext()) {
                val documentId = cursor.getString(documentIdIndex)
                val displayName = cursor.getString(displayNameIndex) ?: continue
                val mimeType = cursor.getString(mimeTypeIndex)
                val size = if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) {
                    cursor.getLong(sizeIndex)
                } else {
                    0L
                }
                val documentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, documentId)
                result.add(
                    DocumentEntry(
                        documentUri = documentUri,
                        displayName = displayName,
                        mimeType = mimeType,
                        size = size,
                        isDirectory = mimeType == DocumentsContract.Document.MIME_TYPE_DIR,
                    ),
                )
            }
        }

        return result
    }

    private fun queryDisplayName(documentUri: Uri): String? {
        val projection = arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
        activity.contentResolver.query(documentUri, projection, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
                if (index >= 0) {
                    return cursor.getString(index)
                }
            }
        }
        return null
    }

    private fun copyUriToFile(sourceUri: Uri, destination: File) {
        destination.parentFile?.mkdirs()
        activity.contentResolver.openInputStream(sourceUri)?.use { input ->
            FileOutputStream(destination).use { output ->
                input.copyTo(output)
            }
        } ?: throw IllegalStateException("Unable to open input stream for $sourceUri")
    }

    private fun relativePath(root: File, target: File): String {
        val rootPath = root.absolutePath
        val targetPath = target.absolutePath
        if (!targetPath.startsWith(rootPath)) {
            return target.name
        }
        return targetPath
            .removePrefix(rootPath)
            .trimStart(File.separatorChar)
            .replace(File.separatorChar, '/')
    }

    private fun sanitizeForPath(name: String): String {
        return name.replace(Regex("""[\\/:*?"<>|]"""), "_")
    }

    private data class DocumentEntry(
        val documentUri: Uri,
        val displayName: String,
        val mimeType: String?,
        val size: Long,
        val isDirectory: Boolean,
    )
}
