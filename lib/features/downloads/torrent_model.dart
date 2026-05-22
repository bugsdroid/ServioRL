/// Status torrent dari Transmission API
enum TorrentStatus {
  stopped,       // 0
  checkWait,     // 1
  check,         // 2
  downloadWait,  // 3
  download,      // 4
  seedWait,      // 5
  seed,          // 6
  unknown;

  static TorrentStatus fromInt(int v) {
    return switch (v) {
      0 => stopped,
      1 => checkWait,
      2 => check,
      3 => downloadWait,
      4 => download,
      5 => seedWait,
      6 => seed,
      _ => unknown,
    };
  }

  String get label => switch (this) {
        stopped      => 'Stopped',
        checkWait    => 'Queue Check',
        check        => 'Checking',
        downloadWait => 'Queue Download',
        download     => 'Downloading',
        seedWait     => 'Queue Seed',
        seed         => 'Seeding',
        unknown      => 'Unknown',
      };

  bool get isDownloading => this == download || this == downloadWait;
  bool get isSeeding     => this == seed || this == seedWait;
  bool get isStopped     => this == stopped;
  bool get isStalled     => isDownloading; // dipakai bersama peersConnected == 0
}

class Torrent {
  final int id;
  final String name;
  final TorrentStatus status;
  final double percentDone;   // 0.0 – 1.0
  final int rateDownload;     // bytes/s
  final int rateUpload;       // bytes/s
  final int peersConnected;
  final int totalSize;        // bytes
  final int error;            // 0 = no error
  final String errorString;
  final int eta;              // seconds, -1 = unknown
  final bool isFinished;

  const Torrent({
    required this.id,
    required this.name,
    required this.status,
    required this.percentDone,
    required this.rateDownload,
    required this.rateUpload,
    required this.peersConnected,
    required this.totalSize,
    required this.error,
    required this.errorString,
    required this.eta,
    required this.isFinished,
  });

  factory Torrent.fromJson(Map<String, dynamic> j) => Torrent(
        id:             j['id']             as int,
        name:           j['name']           as String,
        status:         TorrentStatus.fromInt(j['status'] as int),
        percentDone:    (j['percentDone']   as num).toDouble(),
        rateDownload:   j['rateDownload']   as int,
        rateUpload:     j['rateUpload']     as int,
        peersConnected: j['peersConnected'] as int,
        totalSize:      j['totalSize']      as int,
        error:          j['error']          as int,
        errorString:    j['errorString']    as String,
        eta:            j['eta']            as int,
        isFinished:     j['isFinished']     as bool,
      );

  /// Torrent stalled = sedang download tapi 0 peers
  bool get isStalled =>
      status.isDownloading && peersConnected == 0 && !isFinished;
}
