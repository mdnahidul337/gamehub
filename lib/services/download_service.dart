import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService extends ChangeNotifier {
  final Map<String, String> _taskForMod = {}; // modId -> taskId
  final Map<String, int> _progressForMod = {}; // modId -> progress 0-100
  final Map<String, Timer> _pollers = {};
  ReceivePort? _port;

  int progressFor(String modId) => _progressForMod[modId] ?? 0;

  Future<bool> _ensurePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    // iOS/macOS generally don't require explicit storage permission for app dirs
    return true;
  }

  Future<String> _getSaveDir() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      if (dir != null) return dir.path;
    }
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<void> initialize() async {
    try {
      await FlutterDownloader.initialize(debug: kDebugMode);
    } catch (_) {}
    // register a receive port to get callbacks from background isolate
    _port ??= ReceivePort();
    // register the port so the background isolate can lookup
    // IsolateNameServer is provided by the Flutter embedder for platform isolates.
    // ignore: undefined_identifier
    IsolateNameServer.registerPortWithName(
        _port!.sendPort, 'downloader_send_port');
    // listen for messages from the background callback
    _port!.listen((dynamic data) {
      try {
        if (data is List && data.length >= 3) {
          final String taskId = data[0] as String;
          final int status = data[1] as int;
          final int progress = data[2] as int;
          // find modId by task id
          final modEntry = _taskForMod.entries.firstWhere(
              (e) => e.value == taskId,
              orElse: () => MapEntry('', ''));
          final modId = modEntry.key;
          if (modId.isNotEmpty) {
            _progressForMod[modId] = progress;
            notifyListeners();
            // if complete or failed, stop tracking
            if (status == 3 || status == 4) {
              _pollers[modId]?.cancel();
              _pollers.remove(modId);
            }
            // if download completed, attempt to open the file (on supported platforms)
            // flutter_downloader uses integer status codes in the background callback
            // complete = 3, failed = 4 (these are stable across plugin versions)
            if (status == 3) {
              try {
                FlutterDownloader.open(taskId: taskId);
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    });
    // register background callback
    try {
      FlutterDownloader.registerCallback(_downloadCallback);
    } catch (_) {}
  }

  Future<void> download(String modId, String url, String fileName) async {
    if (url.isEmpty) throw ArgumentError('url empty');
    final ok = await _ensurePermission();
    if (!ok) throw Exception('Storage permission denied');
    final savedDir = await _getSaveDir();
    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: savedDir,
      fileName: fileName,
      showNotification: true,
      openFileFromNotification: true,
    );
    _taskForMod[modId] = taskId!;
    _progressForMod[modId] = 0;
    notifyListeners();
    _startPolling(modId, taskId);
  }

  /// Return a list of all known download tasks with basic metadata.
  Future<List<Map<String, dynamic>>> listAllTasks() async {
    final tasks = await FlutterDownloader.loadTasks();
    if (tasks == null) return [];
    final out = <Map<String, dynamic>>[];
    for (final t in tasks) {
      try {
        final tk = t as dynamic;
        out.add({
          'taskId': tk.taskId ?? '',
          'status': tk.status ?? 0,
          'progress': tk.progress ?? 0,
          'filename': tk.filename ?? tk.savedFileName ?? tk.taskId,
          'savedDir': tk.savedDir ?? '',
          'url': tk.url ?? '',
        });
      } catch (_) {}
    }
    return out;
  }

  /// Open a downloaded file by its taskId.
  Future<void> openTask(String taskId) async {
    await FlutterDownloader.open(taskId: taskId);
  }

  void _startPolling(String modId, String taskId) {
    // poll for task progress periodically
    _pollers[modId]?.cancel();
    _pollers[modId] =
        Timer.periodic(const Duration(milliseconds: 700), (t) async {
      final tasksRaw = await FlutterDownloader.loadTasksWithRawQuery(
          query: "SELECT * FROM task WHERE task_id='$taskId'");
      final tasks = tasksRaw ?? [];
      if (tasks.isEmpty) return;
      final tk = tasks.first;
      final progressVal = (tk as dynamic).progress ?? 0;
      _progressForMod[modId] = progressVal as int;
      notifyListeners();
      if (tk.status == DownloadTaskStatus.complete ||
          tk.status == DownloadTaskStatus.failed) {
        _pollers[modId]?.cancel();
        _pollers.remove(modId);
      }
    });
  }

  void disposeService() {
    for (var t in _pollers.values) t.cancel();
    _pollers.clear();
    try {
      // ignore: undefined_identifier
      IsolateNameServer.removePortNameMapping('downloader_send_port');
    } catch (_) {}
    try {
      _port?.close();
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void _downloadCallback(String id, int status, int progress) {
  // background isolate -> forward to main isolate via IsolateNameServer
  try {
    // ignore: undefined_identifier
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  } catch (_) {}
}
