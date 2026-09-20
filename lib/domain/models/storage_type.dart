/// The category of a storage location registered with MATINEE.
enum StorageType {
  /// External removable storage (USB HDD, USB-OTG drive, SD card).
  removableVolume,

  /// Internal device storage dedicated to MATINEE application-managed offline media.
  deviceLocalStorage,

  /// Network-attached share (SMB/NFS/CIFS mount).
  networkShare;

  static StorageType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'REMOVABLE_VOLUME':
      case 'REMOVABLESTORAGE':
        return StorageType.removableVolume;
      case 'DEVICE_LOCAL_STORAGE':
      case 'LOCALDEVICE':
        return StorageType.deviceLocalStorage;
      case 'NETWORK_SHARE':
        return StorageType.networkShare;
      default:
        return StorageType.removableVolume;
    }
  }

  String toDbString() {
    switch (this) {
      case StorageType.removableVolume:
        return 'REMOVABLE_VOLUME';
      case StorageType.deviceLocalStorage:
        return 'DEVICE_LOCAL_STORAGE';
      case StorageType.networkShare:
        return 'NETWORK_SHARE';
    }
  }

  String get displayName {
    switch (this) {
      case StorageType.removableVolume:
        return 'Removable Disk';
      case StorageType.deviceLocalStorage:
        return 'This Device';
      case StorageType.networkShare:
        return 'Network Share';
    }
  }
}
