# Code Review: TW-2874 Fix Distorted Images — Issues & Proposed Fixes

**Date:** 2026-02-27
**Branch:** `TW-2874/Distorted-images`
**Commits:** `3a0910cc..94cb2152` (9 fixup commits)
**Scope:** 15 files, +151/-250 lines

---

## Issue 1: VideoWidget FutureBuilder re-fires on every rebuild [CRITICAL]

**File:** `lib/pages/chat/events/sending_video_widget.dart:158-159`

**Problem:** `FutureBuilder.future` is created inside `build()`. Every parent rebuild triggers a new `getPlaceholderMatrixImageFile()` call → `generateVideoThumbnail()` → FFmpeg + temp file write + blurhash generation.

**Proposed Fix:** Convert `VideoWidget` to `StatefulWidget`. Store the future in `initState`:

```dart
class VideoWidget extends StatefulWidget {
  // ... same fields
}

class _VideoWidgetState extends State<VideoWidget> {
  late final Future<MatrixImageFile?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.event.getPlaceholderMatrixImageFile(
      getIt.get<UploadManager>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _thumbnailFuture,
      // ... rest unchanged
    );
  }
}
```

---

## Issue 2: generateVideoThumbnail loads entire video bytes into memory [CRITICAL]

**File:** `lib/presentation/extensions/send_file_web_extension.dart:457`

**Problem:** When `getPlaceholderMatrixImageFile` gets a `MatrixVideoFile`, it passes the whole object to `generateVideoThumbnail`, which writes `originalFile.bytes` to a temp file then runs FFmpeg. The entire video is held in memory.

**Proposed Fix:** Add a `filePath`-based thumbnail generation path that avoids loading bytes:

```dart
Future<MatrixImageFile?> getPlaceholderMatrixImageFile(
  UploadManager uploadManager,
) async {
  final matrixFile = await getPlaceholderMatrixFile(uploadManager);
  if (matrixFile is MatrixImageFile) {
    return matrixFile;
  } else if (matrixFile is MatrixVideoFile) {
    // Prefer file path over bytes to avoid OOM
    // Use VideoThumbnail.thumbnailData directly from filePath
    // instead of loading full video into generateVideoThumbnail
    final filePath = /* get from event content or matrixFile */;
    if (filePath != null) {
      final result = await VideoThumbnail.thumbnailData(
        video: filePath,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );
      return MatrixImageFile(bytes: result, name: 'thumbnail.jpg');
    }
    // Only fall back to bytes-based if no file path available
    return await room.generateVideoThumbnail(matrixFile);
  }
  return null;
}
```

Alternative: Since `VideoFileInfo.filePath` is always set in the mobile picker flow, pass it through the event content `info` so the sending widget can use it directly without touching video bytes.

---

## Issue 3: FileImage full decode for image dimensions [IMPORTANT]

**File:** `lib/presentation/extensions/file_extension.dart:13-17`

**Problem:** `FileImage` decodes the **entire image bitmap** into memory just to read width/height. For a 30MB HEIC photo → ~100MB+ decoded bitmap. 10 photos shared = ~1GB memory spike.

Old code used `assetEntity.orientatedWidth/Height` which reads EXIF metadata — O(1), ~0 memory. The issue was it returned wrong values sometimes.

**Proposed Fix:** Use header-only decoding instead of full decode:

### Root Cause Analysis

Investigated `photo_manager` 3.7.1 source (`entity.dart`):

```dart
// entity.dart line 803-810
/// The orientation of the asset.
///  * Android: `MediaStore.MediaColumns.ORIENTATION`, could be 0, 90, 180, 270.
///  * iOS/macOS: Always 0.          // <-- THE ROOT CAUSE
final int orientation;

// entity.dart line 466-472
bool get _isFlipping => orientation == 90 || orientation == 270;
int get orientatedWidth => _isFlipping ? height : width;   // never swaps on iOS
int get orientatedHeight => _isFlipping ? width : height;   // never swaps on iOS
```

**On iOS, `orientation` is hardcoded to `0`.** So `orientatedWidth/Height` **never swaps dimensions**.

But iOS stores photos in native sensor orientation (landscape) with EXIF tag for rotation. A portrait iPhone photo has:
- Raw sensor: `4032×3024` (landscape)
- EXIF orientation: 6 (rotate 90° CW)
- `photo_manager.orientation`: `0` (iOS always 0)
- `orientatedWidth` → `4032` (WRONG — should be `3024`)
- `orientatedHeight` → `3024` (WRONG — should be `4032`)

Also: `width`/`height` "could be 0 in cases that EXIF info is failed to parse" (line 457).

**This is iOS-only.** Android `orientation` works correctly.

**Key insight:** `loadFile(isOrigin: true)` on iOS exports the file with rotation **already applied to pixels** (iOS Photos framework does this during export). So the exported file's actual pixel dimensions are correct (`3024×4032` for portrait). The current `FileImage` approach gets correct dimensions — the problem is only the memory overhead.

### Proposed Fix (Revised)

Since `orientatedWidth/Height` is fundamentally broken on iOS (known `photo_manager` limitation, not a bug in our code), we must read dimensions from the exported file. But `FileImage` is overkill.

**Recommended: Use `instantiateImageCodec`** — avoids the full Flutter `Image` widget pipeline (`ImageProvider` → `ImageStream` → `ImageCache`), still requires `readAsBytes` but skips `FileImage` overhead:

```dart
extension FileExtension on File {
  Future<Size?> getImageDimensions() async {
    Codec? codec;
    try {
      final bytes = await readAsBytes();
      codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final size = Size(frame.image.width.toDouble(), frame.image.height.toDouble());
      frame.image.dispose();
      return size;
    } catch (e, s) {
      Logs().e('getImageDimensions error:', e, s);
      return null;
    } finally {
      codec?.dispose();
    }
  }
}
```

> **Note:** Still calls `readAsBytes()` — unavoidable without platform channels. But avoids `ImageProvider`/`ImageStream`/`ImageCache` overhead entirely. For truly zero-byte-loading, would need native platform channels (iOS `CGImageSourceCopyPropertiesAtIndex` / Android `BitmapFactory.Options.inJustDecodeBounds`), which is significant effort.

**For future optimization (separate ticket):** Platform channel approach using:
- iOS: `CGImageSourceCopyPropertiesAtIndex` — reads EXIF from file path, ~0 memory
- Android: `BitmapFactory.Options.inJustDecodeBounds = true` — reads header only from file path

---

## Issue 4: Codec not disposed in Uint8listExtension.imageSize [MEDIUM]

**File:** `lib/presentation/extensions/uint8list_extension.dart:10-13`

**Problem:** `codec` from `instantiateImageCodec` is never disposed → native memory leak per call.

**Proposed Fix:**
```dart
extension Uint8listExtension on Uint8List {
  Future<Size?> imageSize() async {
    Codec? codec;
    try {
      codec = await instantiateImageCodec(this);
      final FrameInfo frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();
      return size;
    } catch (e) {
      Logs().e('Uint8listExtension::imageSize: Error getting image size', e);
      return null;
    } finally {
      codec?.dispose();
    }
  }
}
```

---

## Issue 5: Video dimensions missing from VideoAssetEntity → visual jank [MINOR]

**File:** `lib/presentation/model/file/video_asset_entity.dart:17-21`

**Problem:** `VideoFileInfo` created with no width/height. Bubble renders at default size, potentially resizes when thumbnail dimensions arrive later.

**Proposed Fix:** Keep `assetEntity.orientatedWidth/Height` as initial estimate for videos (video dimension distortion is less critical than image), then correct via thumbnail if needed:

```dart
return VideoFileInfo(
  file.path.split('/').last,
  filePath: file.path,
  width: assetEntity.orientatedWidth,
  height: assetEntity.orientatedHeight,
  duration: assetEntity.videoDuration,
);
```

The downstream code already handles the fallback: if width/height are 0 or null, it uses thumbnail dimensions. So using `orientatedWidth/Height` as initial guess is safe — even if slightly wrong, it prevents jank and gets corrected later.

---

## Issue 6: ImageConfiguration with no size constraints [MINOR]

**File:** `lib/presentation/extensions/file_extension.dart:17`

**Problem:** `const ImageConfiguration()` means Flutter decodes at full resolution. For a 4000×3000 image, this allocates a ~48MB bitmap just to read 2 integers.

**Proposed Fix:** Moot if we switch to header-only reading (Issue 3). If keeping `FileImage`, there's no way to set a decode size via `ImageConfiguration` for `FileImage` — the only fix is to not use `FileImage` at all.

---

## Issue 7: send_file_web_extension.dart is a misnomer and architectural mess [IMPORTANT — Refactor]

**Files:**
- `lib/presentation/extensions/send_file_extension.dart` (906 lines) — mobile send flow
- `lib/presentation/extensions/send_file_web_extension.dart` (527 lines) — supposed to be "web" but contains `generateVideoThumbnail` used by **mobile** code

**Problem:** `send_file_web_extension.dart` contains shared/mobile logic despite "web" in the name. Mobile code (`event_extension.dart:648`) calls `room.generateVideoThumbnail()` which lives in the "web" extension. Both files are `extension on Room` with 1433 combined lines, overlapping concerns, duplicated patterns (`sendFakeFileEvent` vs `sendFakeFileInfoEvent`, `generateThumbnail` vs `_generateThumbnail`, `_generateBlurHash` duplicated in both).

**Current layout (broken):**
```
send_file_extension.dart (906 lines) — "mobile"
├── sendFileEventMobile()
├── sendFakeFileInfoEvent()
├── _generateThumbnail()          ← image thumbnail (mobile)
├── _getThumbnailVideo()           ← video thumbnail (mobile) — uses VideoThumbnail.thumbnailFile
├── _generateBlurHashFromBytes()
└── sendPlaceholdersForImagePickerFiles()

send_file_web_extension.dart (527 lines) — "web" but actually shared
├── sendFileOnWebEvent()
├── sendFakeFileEvent()
├── generateThumbnail()            ← image thumbnail (web+shared)
├── generateVideoThumbnail()       ← video thumbnail — USED BY MOBILE via event_extension.dart
├── _getVideoDuration()
└── _generateBlurHash()
```

**Proposed refactoring — split by concern, not platform:**

```
send-file-extension.dart (~300 lines) — orchestration
├── sendFileEventMobile()
├── sendFileOnWebEvent()
└── sendPlaceholdersForImagePickerFiles()

send-file-fake-sync-extension.dart (~150 lines) — fake event/sync helpers
├── sendFakeFileInfoEvent()
├── sendFakeFileEvent()
├── handleFakeSync()
└── _updateFakeSync()

media-thumbnail-extension.dart (~200 lines) — all thumbnail logic
├── generateImageThumbnail()        ← merged from both files
├── generateVideoThumbnail()        ← the problematic one, now clearly shared
├── generateVideoThumbnailFromPath() ← NEW: file-path based, no bytes in memory
├── _generateBlurHash()             ← single copy, not duplicated
└── _getVideoDuration()

send-file-upload-extension.dart (~200 lines) — upload/encryption
├── _resolveBytes()
├── _uploadFileToServer()
├── encryption helpers
└── _copyFileInMemToAppDownloadsFolder()
```

**Key benefits:**
1. `generateVideoThumbnail` lives in `media-thumbnail-extension.dart` — no more "why is mobile calling web?"
2. Single `_generateBlurHash` — no duplication
3. Each file under 300 lines — manageable context
4. Can add `generateVideoThumbnailFromPath()` that takes a file path directly, solving Issue 2's OOM without touching video bytes

**Migration steps:**
1. Create `media-thumbnail-extension.dart`, move all thumbnail/blurhash functions
2. Create `send-file-fake-sync-extension.dart`, move fake sync helpers
3. Clean up `send_file_extension.dart` and `send_file_web_extension.dart` to only contain orchestration
4. Update all imports (grep for both filenames)
5. Verify compilation

**Effort:** High (2-4 hours) — but prevents ongoing confusion and makes Issue 2 fix clean.

---

## Priority Order

| # | Issue | Severity | Effort |
|---|-------|----------|--------|
| 1 | VideoWidget FutureBuilder re-fires | CRITICAL | Low (10 min) |
| 2 | generateVideoThumbnail OOM risk | CRITICAL | Medium (30 min) |
| 3 | FileImage full decode for dimensions | IMPORTANT | Medium (30 min) |
| 4 | Codec not disposed | MEDIUM | Low (5 min) |
| 5 | Video dimensions missing → jank | MINOR | Low (5 min) |
| 6 | ImageConfiguration no constraints | MINOR | N/A (solved by #3) |
| 7 | send_file_web_extension misnomer + refactor | IMPORTANT | High (2-4h) |

---

## Unresolved Questions

1. ~~Why was `orientatedWidth/Height` wrong?~~ **RESOLVED:** `photo_manager` returns `orientation = 0` on iOS always. `orientatedWidth/Height` never swaps. This is a known `photo_manager` limitation, not fixable from our side.
2. Does `instantiateImageCodec` actually decode the full bitmap, or just the header? Needs verification — affects whether the `readAsBytes` overhead is the only cost or if there's additional decode cost.
3. For Issue 2, is `VideoFileInfo.filePath` always available when the sending widget renders? If so, we can skip `MatrixVideoFile.bytes` entirely.
4. Should we open a separate ticket for the platform-channel approach (iOS `CGImageSource` / Android `BitmapFactory.inJustDecodeBounds`) as a long-term zero-memory solution?
