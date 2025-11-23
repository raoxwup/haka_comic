part of 'background_downloader.dart';

enum WorkerMessageType { pause, resume, delete, query }

class WorkerMessage {
  final WorkerMessageType type;
  final dynamic payload;

  const WorkerMessage({required this.payload, required this.type});
}

enum MainMessageType { addTask, updateStatus }

class MainMessage {
  final MainMessageType type;
  final dynamic payload;

  const MainMessage({required this.payload, required this.type});
}

/// 下载漫画
class DownloadComic {
  final String id;
  final String title;
  final String cover;

  const DownloadComic({
    required this.id,
    required this.title,
    required this.cover,
  });

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'cover': cover};

  factory DownloadComic.fromJson(Map<String, dynamic> json) => DownloadComic(
    id: json['id'] as String,
    title: json['title'] as String,
    cover: json['cover'] as String,
  );
}

/// 下载章节
class DownloadChapter {
  final List<ImageDetail> images = [];

  final String id;
  final String title;
  final int order;

  DownloadChapter({required this.id, required this.title, required this.order});
}

/// 漫画下载任务
class ComicDownloadTask {
  final DownloadComic comic;
  final List<DownloadChapter> chapters;

  int total = 0;
  int completed = 0;
  DownloadTaskStatus status = DownloadTaskStatus.queued;

  ComicDownloadTask({required this.comic, required this.chapters});
}

/// 下载任务状态
enum DownloadTaskStatus {
  queued('等待中'),

  downloading('下载中'),

  paused('已暂停'),

  completed('已完成'),

  error('下载出错');

  const DownloadTaskStatus(this.displayName);
  final String displayName;

  static DownloadTaskStatus fromName(String name) {
    return DownloadTaskStatus.values.firstWhere(
      (e) => e.name == name,
      orElse: () => throw Exception('Unknown status name: $name'),
    );
  }
}
