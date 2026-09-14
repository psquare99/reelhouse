/// Action resolved by the Playback Source Resolution Engine.
enum PlaybackAction {
  /// Play from connected removable storage or network source.
  play,

  /// Play from the application-managed local device copy without external disks.
  playOffline,

  /// Storage is disconnected and no local copy exists; prompt user to connect disk.
  connectDisk,
}

/// The result of determining the best available physical source for playback.
class PlaybackResolution {
  final PlaybackAction action;
  final String? selectedSourceId;
  final String? storageName;
  final String? resolvedUri;

  const PlaybackResolution({
    required this.action,
    this.selectedSourceId,
    this.storageName,
    this.resolvedUri,
  });

  bool get isPlayable =>
      action == PlaybackAction.play || action == PlaybackAction.playOffline;

  String get buttonLabel {
    switch (action) {
      case PlaybackAction.play:
        return 'PLAY';
      case PlaybackAction.playOffline:
        return 'PLAY OFFLINE';
      case PlaybackAction.connectDisk:
        return storageName != null ? 'CONNECT $storageName' : 'CONNECT DISK';
    }
  }

  @override
  String toString() =>
      'PlaybackResolution(action: $action, sourceId: $selectedSourceId, storage: $storageName)';
}
