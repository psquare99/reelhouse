import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

import 'platform_storage_adapter.dart';

typedef _GetVolumeInformationWNative = Int32 Function(
  Pointer<Utf16> lpRootPathName,
  Pointer<Utf16> lpVolumeNameBuffer,
  Uint32 nVolumeNameSize,
  Pointer<Uint32> lpVolumeSerialNumber,
  Pointer<Uint32> lpMaximumComponentLength,
  Pointer<Uint32> lpFileSystemFlags,
  Pointer<Utf16> lpFileSystemNameBuffer,
  Uint32 nFileSystemNameSize,
);

typedef _GetVolumeInformationWDart = int Function(
  Pointer<Utf16> lpRootPathName,
  Pointer<Utf16> lpVolumeNameBuffer,
  int nVolumeNameSize,
  Pointer<Uint32> lpVolumeSerialNumber,
  Pointer<Uint32> lpMaximumComponentLength,
  Pointer<Uint32> lpFileSystemFlags,
  Pointer<Utf16> lpFileSystemNameBuffer,
  int nFileSystemNameSize,
);

typedef _GetDiskFreeSpaceExWNative = Int32 Function(
  Pointer<Utf16> lpDirectoryName,
  Pointer<Uint64> lpFreeBytesAvailableToCaller,
  Pointer<Uint64> lpTotalNumberOfBytes,
  Pointer<Uint64> lpTotalNumberOfFreeBytes,
);

typedef _GetDiskFreeSpaceExWDart = int Function(
  Pointer<Utf16> lpDirectoryName,
  Pointer<Uint64> lpFreeBytesAvailableToCaller,
  Pointer<Uint64> lpTotalNumberOfBytes,
  Pointer<Uint64> lpTotalNumberOfFreeBytes,
);

/// Windows implementation using Win32 Volume APIs and local paths.
class WindowsStorageAdapter implements PlatformStorageAdapter {
  DynamicLibrary? _kernel32;
  _GetVolumeInformationWDart? _getVolumeInformationW;
  _GetDiskFreeSpaceExWDart? _getDiskFreeSpaceExW;

  WindowsStorageAdapter() {
    if (Platform.isWindows) {
      try {
        _kernel32 = DynamicLibrary.open('kernel32.dll');
        _getVolumeInformationW = _kernel32!
            .lookupFunction<
              _GetVolumeInformationWNative,
              _GetVolumeInformationWDart
            >('GetVolumeInformationW');
        _getDiskFreeSpaceExW = _kernel32!
            .lookupFunction<
              _GetDiskFreeSpaceExWNative,
              _GetDiskFreeSpaceExWDart
            >('GetDiskFreeSpaceExW');
      } catch (_) {
        // Fallback if DLL lookup fails
      }
    }
  }

  String _normalizeRoot(String path) {
    var root = p.rootPrefix(path);
    if (root.isEmpty) {
      root = path;
    }
    if (!root.endsWith('\\')) {
      root = '$root\\';
    }
    return root;
  }

  @override
  Future<bool> isStorageConnected(String rootUri) async {
    try {
      final dir = Directory(rootUri);
      return dir.existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> getFilesystemIdentifier(String rootUri) async {
    if (!Platform.isWindows || _getVolumeInformationW == null) {
      return null;
    }

    final rootPath = _normalizeRoot(rootUri);
    final rootUtf16 = rootPath.toNativeUtf16();
    final volumeNameBuffer = calloc<Uint16>(260).cast<Utf16>();
    final serialNumberPtr = calloc<Uint32>();

    try {
      final result = _getVolumeInformationW!(
        rootUtf16,
        volumeNameBuffer,
        260,
        serialNumberPtr,
        nullptr,
        nullptr,
        nullptr,
        0,
      );

      if (result != 0) {
        final serial = serialNumberPtr.value;
        final hex = serial.toRadixString(16).toUpperCase().padLeft(8, '0');
        return '0x$hex';
      }
    } catch (_) {
      // Fall through to null
    } finally {
      calloc.free(rootUtf16);
      calloc.free(volumeNameBuffer);
      calloc.free(serialNumberPtr);
    }
    return null;
  }

  @override
  Future<String> getStorageDisplayName(String rootUri) async {
    if (!Platform.isWindows || _getVolumeInformationW == null) {
      return p.basename(rootUri);
    }

    final rootPath = _normalizeRoot(rootUri);
    final rootUtf16 = rootPath.toNativeUtf16();
    final volumeNameBuffer = calloc<Uint16>(260).cast<Utf16>();
    final serialNumberPtr = calloc<Uint32>();

    try {
      final result = _getVolumeInformationW!(
        rootUtf16,
        volumeNameBuffer,
        260,
        serialNumberPtr,
        nullptr,
        nullptr,
        nullptr,
        0,
      );

      if (result != 0) {
        final label = volumeNameBuffer.toDartString().trim();
        if (label.isNotEmpty) {
          return label;
        }
      }
    } catch (_) {
      // Fallback
    } finally {
      calloc.free(rootUtf16);
      calloc.free(volumeNameBuffer);
      calloc.free(serialNumberPtr);
    }

    final base = p.basename(rootUri);
    return base.isNotEmpty ? base : rootUri;
  }

  @override
  Future<int> getAvailableBytes(String rootUri) async {
    if (!Platform.isWindows || _getDiskFreeSpaceExW == null) {
      return 50 * 1024 * 1024 * 1024;
    }

    final rootPath = _normalizeRoot(rootUri);
    final rootUtf16 = rootPath.toNativeUtf16();
    final freeBytesPtr = calloc<Uint64>();
    final totalBytesPtr = calloc<Uint64>();
    final totalFreeBytesPtr = calloc<Uint64>();

    try {
      final result = _getDiskFreeSpaceExW!(
        rootUtf16,
        freeBytesPtr,
        totalBytesPtr,
        totalFreeBytesPtr,
      );
      if (result != 0) {
        return freeBytesPtr.value;
      }
    } catch (_) {
      // Fallback
    } finally {
      calloc.free(rootUtf16);
      calloc.free(freeBytesPtr);
      calloc.free(totalBytesPtr);
      calloc.free(totalFreeBytesPtr);
    }

    return 50 * 1024 * 1024 * 1024;
  }

  @override
  Future<int> getTotalBytes(String rootUri) async {
    if (!Platform.isWindows || _getDiskFreeSpaceExW == null) {
      return 100 * 1024 * 1024 * 1024;
    }

    final rootPath = _normalizeRoot(rootUri);
    final rootUtf16 = rootPath.toNativeUtf16();
    final freeBytesPtr = calloc<Uint64>();
    final totalBytesPtr = calloc<Uint64>();
    final totalFreeBytesPtr = calloc<Uint64>();

    try {
      final result = _getDiskFreeSpaceExW!(
        rootUtf16,
        freeBytesPtr,
        totalBytesPtr,
        totalFreeBytesPtr,
      );
      if (result != 0) {
        return totalBytesPtr.value;
      }
    } catch (_) {
      // Fallback
    } finally {
      calloc.free(rootUtf16);
      calloc.free(freeBytesPtr);
      calloc.free(totalBytesPtr);
      calloc.free(totalFreeBytesPtr);
    }

    return 100 * 1024 * 1024 * 1024;
  }

  @override
  Future<bool> fileExists(String rootUri, String relativePath) async {
    try {
      final fullPath = p.join(rootUri, relativePath);
      return File(fullPath).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int> getFileSizeBytes(String rootUri, String relativePath) async {
    try {
      final fullPath = p.join(rootUri, relativePath);
      final file = File(fullPath);
      if (file.existsSync()) {
        return await file.length();
      }
    } catch (_) {}
    return 0;
  }

  @override
  Future<String> resolvePlaybackUri(String rootUri, String relativePath) async {
    return p.join(rootUri, relativePath);
  }
}
