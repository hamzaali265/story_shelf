package com.example.story_shelf

import android.content.ContentUris
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity
import java.io.File
import java.io.FileOutputStream

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.storyshelf.app/mediastore"
    private val TAG = "StoryShelfScan"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanAudiobooks" -> {
                    try {
                        Log.d(TAG, "MethodChannel call received: scanAudiobooks")
                        val books = scanAllAudiobooks()
                        Log.d(TAG, "Scan completed. Found ${books.size} audiobook files")
                        result.success(books)
                    } catch (e: Exception) {
                        Log.e(TAG, "Scan error: ${e.message}", e)
                        result.error("SCAN_ERROR", e.localizedMessage, e.stackTraceToString())
                    }
                }
                "extractCoverArt" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("ARG_ERROR", "Path cannot be null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val coverPath = getOrExtractCover(path)
                        result.success(coverPath)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scanAllAudiobooks(): List<Map<String, Any?>> {
        val bookMapList = mutableMapOf<String, Map<String, Any?>>()

        // 1. Query MediaStore Audio Media
        queryAudioMedia(bookMapList)
        Log.d(TAG, "After queryAudioMedia: ${bookMapList.size} audiobooks found")

        // 2. Query MediaStore Files
        queryFilesMedia(bookMapList)
        Log.d(TAG, "After queryFilesMedia: ${bookMapList.size} audiobooks found")

        // 3. Fallback direct filesystem scan in targeted Audiobooks folders
        fallbackFilesystemScan(bookMapList)
        Log.d(TAG, "After fallbackFilesystemScan: ${bookMapList.size} audiobooks found")

        return bookMapList.values.toList()
    }

    private fun queryAudioMedia(bookMapList: MutableMap<String, Map<String, Any?>>) {
        try {
            val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
            } else {
                MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
            }

            val projection = arrayOf(
                MediaStore.Audio.Media._ID,
                MediaStore.Audio.Media.DATA,
                MediaStore.Audio.Media.DISPLAY_NAME,
                MediaStore.Audio.Media.TITLE,
                MediaStore.Audio.Media.ARTIST,
                MediaStore.Audio.Media.ALBUM,
                MediaStore.Audio.Media.DURATION,
                MediaStore.Audio.Media.SIZE,
                MediaStore.Audio.Media.DATE_MODIFIED
            )

            contentResolver.query(collection, projection, null, null, "${MediaStore.Audio.Media.DATE_MODIFIED} DESC")?.use { cursor ->
                val idCol = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
                val dataCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
                val nameCol = cursor.getColumnIndex(MediaStore.Audio.Media.DISPLAY_NAME)
                val titleCol = cursor.getColumnIndex(MediaStore.Audio.Media.TITLE)
                val artistCol = cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST)
                val albumCol = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM)
                val durationCol = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)
                val sizeCol = cursor.getColumnIndex(MediaStore.Audio.Media.SIZE)
                val dateModifiedCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATE_MODIFIED)

                while (cursor.moveToNext()) {
                    val path = if (dataCol >= 0) cursor.getString(dataCol) else null
                    val displayName = if (nameCol >= 0) cursor.getString(nameCol) else ""
                    val targetName = if (!path.isNullOrEmpty()) path else displayName

                    if (!isAudiobookFile(targetName)) continue

                    val id = if (idCol >= 0) cursor.getLong(idCol) else targetName.hashCode().toLong()
                    val title = if (titleCol >= 0) cursor.getString(titleCol) else null
                    val artist = if (artistCol >= 0) cursor.getString(artistCol) else null
                    val album = if (albumCol >= 0) cursor.getString(albumCol) else null
                    val duration = if (durationCol >= 0) cursor.getLong(durationCol) else 0L
                    val size = if (sizeCol >= 0) cursor.getLong(sizeCol) else 0L
                    val dateModified = if (dateModifiedCol >= 0) cursor.getLong(dateModifiedCol) else System.currentTimeMillis() / 1000

                    val finalPath = if (!path.isNullOrEmpty()) path else "mediastore_$id"
                    val nameWithoutExt = if (displayName.contains(".")) displayName.substring(0, displayName.lastIndexOf(".")) else displayName

                    val bookMap = mapOf(
                        "id" to id.toString(),
                        "path" to finalPath,
                        "title" to (if (!title.isNullOrEmpty()) title else (if (nameWithoutExt.isNotEmpty()) nameWithoutExt else "Audiobook")),
                        "artist" to (if (artist == "<unknown>") null else artist),
                        "album" to (if (album == "<unknown>") null else album),
                        "duration" to duration,
                        "size" to size,
                        "dateModified" to dateModified
                    )
                    bookMapList[finalPath] = bookMap
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "queryAudioMedia failed: ${e.message}", e)
        }
    }

    private fun queryFilesMedia(bookMapList: MutableMap<String, Map<String, Any?>>) {
        try {
            val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL)
            } else {
                MediaStore.Files.getContentUri("external")
            }

            val projection = arrayOf(
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.DISPLAY_NAME,
                MediaStore.Files.FileColumns.TITLE,
                MediaStore.Files.FileColumns.SIZE,
                MediaStore.Files.FileColumns.DATE_MODIFIED
            )

            contentResolver.query(collection, projection, null, null, "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC")?.use { cursor ->
                val idCol = cursor.getColumnIndex(MediaStore.Files.FileColumns._ID)
                val dataCol = cursor.getColumnIndex(MediaStore.Files.FileColumns.DATA)
                val nameCol = cursor.getColumnIndex(MediaStore.Files.FileColumns.DISPLAY_NAME)
                val titleCol = cursor.getColumnIndex(MediaStore.Files.FileColumns.TITLE)
                val sizeCol = cursor.getColumnIndex(MediaStore.Files.FileColumns.SIZE)
                val dateCol = cursor.getColumnIndex(MediaStore.Files.FileColumns.DATE_MODIFIED)

                while (cursor.moveToNext()) {
                    val path = if (dataCol >= 0) cursor.getString(dataCol) else null
                    val displayName = if (nameCol >= 0) cursor.getString(nameCol) else ""
                    val targetName = if (!path.isNullOrEmpty()) path else displayName

                    if (!isAudiobookFile(targetName)) continue

                    val finalPath = if (!path.isNullOrEmpty()) path else "file_${cursor.getLong(idCol)}"
                    if (bookMapList.containsKey(finalPath)) continue

                    val id = if (idCol >= 0) cursor.getLong(idCol) else targetName.hashCode().toLong()
                    val title = if (titleCol >= 0) cursor.getString(titleCol) else null
                    val size = if (sizeCol >= 0) cursor.getLong(sizeCol) else 0L
                    val dateModified = if (dateCol >= 0) cursor.getLong(dateCol) else System.currentTimeMillis() / 1000

                    val nameWithoutExt = if (displayName.contains(".")) displayName.substring(0, displayName.lastIndexOf(".")) else displayName

                    val bookMap = mapOf(
                        "id" to "file_$id",
                        "path" to finalPath,
                        "title" to (if (!title.isNullOrEmpty()) title else (if (nameWithoutExt.isNotEmpty()) nameWithoutExt else "Audiobook")),
                        "artist" to null,
                        "album" to null,
                        "duration" to 0L,
                        "size" to size,
                        "dateModified" to dateModified
                    )
                    bookMapList[finalPath] = bookMap
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "queryFilesMedia failed: ${e.message}", e)
        }
    }

    private fun fallbackFilesystemScan(bookMapList: MutableMap<String, Map<String, Any?>>) {
        val targetedPaths = arrayOf(
            "/storage/emulated/0/Audiobooks",
            "/storage/emulated/0/Audiobook",
            "/storage/emulated/0/Download/Audiobooks",
            "/sdcard/Audiobooks",
            "/sdcard/Audiobook"
        )

        for (path in targetedPaths) {
            try {
                val dir = File(path)
                if (dir.exists() && dir.isDirectory) {
                    scanDirectoryRecursively(dir, bookMapList, 0)
                }
            } catch (e: Exception) {}
        }
    }

    private fun scanDirectoryRecursively(dir: File, bookMapList: MutableMap<String, Map<String, Any?>>, depth: Int) {
        if (depth > 4) return
        val files = try { dir.listFiles() } catch (e: Exception) { null } ?: return

        for (file in files) {
            if (file.isDirectory) {
                if (!file.name.startsWith(".") && !file.name.equals("Android", ignoreCase = true)) {
                    scanDirectoryRecursively(file, bookMapList, depth + 1)
                }
            } else if (file.isFile && isAudiobookFile(file.absolutePath)) {
                val path = file.absolutePath
                if (!bookMapList.containsKey(path)) {
                    val bookMap = mapOf(
                        "id" to "fs_${file.hashCode()}",
                        "path" to path,
                        "title" to file.nameWithoutExtension,
                        "artist" to null,
                        "album" to null,
                        "duration" to 0L,
                        "size" to file.length(),
                        "dateModified" to file.lastModified() / 1000
                    )
                    bookMapList[path] = bookMap
                }
            }
        }
    }

    private fun isAudiobookFile(path: String): Boolean {
        val lower = path.lowercase()

        // 1. Strictly include all .m4b files
        if (lower.endsWith(".m4b")) return true

        // 2. Include .m4a files ONLY if located in an Audiobook directory
        if (lower.endsWith(".m4a") && (lower.contains("/audiobook/") || lower.contains("/audiobooks/"))) {
            return true
        }

        return false
    }

    private fun getOrExtractCover(filePath: String): String? {
        val file = File(filePath)
        if (!file.exists()) return null

        val cacheDir = File(cacheDir, "covers")
        if (!cacheDir.exists()) cacheDir.mkdirs()

        val coverFile = File(cacheDir, "${file.name.hashCode()}_cover.jpg")
        if (coverFile.exists() && coverFile.length() > 0) {
            return coverFile.absolutePath
        }

        val mmr = MediaMetadataRetriever()
        try {
            mmr.setDataSource(filePath)
            val artBytes = mmr.embeddedPicture
            if (artBytes != null && artBytes.isNotEmpty()) {
                FileOutputStream(coverFile).use { fos ->
                    fos.write(artBytes)
                }
                return coverFile.absolutePath
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            try {
                mmr.release()
            } catch (ignored: Exception) {}
        }
        return null
    }
}
