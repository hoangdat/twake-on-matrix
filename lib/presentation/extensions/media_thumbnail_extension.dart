import 'dart:async';
import 'dart:io';
import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:dartz/dartz.dart' hide id;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/extension/web_url_creation_extension.dart';
import 'package:fluffychat/utils/js_window/non_js_window.dart'
    if (dart.library.js) 'package:fluffychat/utils/js_window/js_window.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_state.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/run_benchmarked.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

extension MediaThumbnailExtension on Room {
  Future<MatrixImageFile?> generateThumbnail(
    MatrixImageFile originalFile, {
    StreamController<Either<Failure, Success>>? uploadStreamController,
  }) async {
    try {
      uploadStreamController?.add(const Right(GeneratingThumbnailState()));
      final result = await FlutterImageCompress.compressWithList(
        originalFile.bytes,
        quality: AppConfig.thumbnailQuality,
        format: AppConfig.imageCompressFormmat,
      );

      final blurHash = await runBenchmarked(
        '_generateBlurHash',
        () => generateBlurHash(result),
      );

      uploadStreamController?.add(const Right(GenerateThumbnailSuccess()));

      return MatrixImageFile(
        bytes: result,
        name: '${originalFile.name}.${AppConfig.imageCompressFormmat.name}',
        mimeType: originalFile.mimeType,
        width: originalFile.width,
        height: originalFile.height,
        blurhash: blurHash,
      );
    } catch (e) {
      uploadStreamController?.add(Left(GenerateThumbnailFailed(exception: e)));
      Logs().e('Error while generating thumbnail', e);
      return null;
    }
  }

  Future<MatrixImageFile?> generateVideoThumbnail(
    MatrixVideoFile originalFile, {
    StreamController<Either<Failure, Success>>? uploadStreamController,
  }) async {
    try {
      uploadStreamController?.add(const Right(GeneratingThumbnailState()));
      late String url;
      if (PlatformInfos.isWeb) {
        url = originalFile.bytes.toWebUrl(mimeType: originalFile.mimeType);
      } else {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${originalFile.name}');
        await tempFile.writeAsBytes(originalFile.bytes);
        url = tempFile.path;
      }

      final result = await VideoThumbnail.thumbnailData(
        video: url,
        imageFormat: AppConfig.videoThumbnailFormat,
        quality: AppConfig.thumbnailQuality,
      );
      final thumbnailBitmap = await convertUint8ListToBitmap(result);
      final blurHash = await runBenchmarked(
        '_generateBlurHash',
        () => generateBlurHash(result),
      );

      uploadStreamController?.add(const Right(GenerateThumbnailSuccess()));

      final thumbnailFileName = _getVideoThumbnailFileName(originalFile);

      if (PlatformInfos.isMobile) await File(url).delete();

      return MatrixImageFile(
        bytes: result,
        name: thumbnailFileName,
        mimeType: lookupMimeType(thumbnailFileName) ?? 'image/jpeg',
        width: thumbnailBitmap?.width,
        height: thumbnailBitmap?.height,
        blurhash: blurHash,
      );
    } catch (e) {
      uploadStreamController?.add(Left(GenerateThumbnailFailed(exception: e)));
      Logs().e('Error while generating thumbnail', e);
      return null;
    }
  }

  Future<MatrixImageFile?> generateVideoThumbnailFromPath(
    String filePath, {
    String? videoFileName,
  }) async {
    try {
      final result = await VideoThumbnail.thumbnailData(
        video: filePath,
        imageFormat: AppConfig.videoThumbnailFormat,
        quality: AppConfig.thumbnailQuality,
      );
      final thumbnailBitmap = await convertUint8ListToBitmap(result);
      final blurHash = await runBenchmarked(
        '_generateBlurHash',
        () => generateBlurHash(result),
      );

      final baseName = videoFileName ?? filePath.split('/').last;
      final thumbnailFileName =
          '$baseName.${AppConfig.videoThumbnailFormat.name.toLowerCase()}';

      return MatrixImageFile(
        bytes: result,
        name: thumbnailFileName,
        mimeType: lookupMimeType(thumbnailFileName) ?? 'image/jpeg',
        width: thumbnailBitmap?.width,
        height: thumbnailBitmap?.height,
        blurhash: blurHash,
      );
    } catch (e) {
      Logs().e('Error while generating thumbnail from path', e);
      return null;
    }
  }

  String _getVideoThumbnailFileName(MatrixVideoFile originalFile) =>
      '${originalFile.name}.${AppConfig.videoThumbnailFormat.name.toLowerCase()}';

  Future<int?> getVideoDuration(MatrixVideoFile originalFile) async {
    VideoPlayerController? videoPlayerController;
    try {
      final url = originalFile.bytes.toWebUrl(mimeType: originalFile.mimeType);
      videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
      await videoPlayerController.initialize();
      final duration = videoPlayerController.value.duration.inMilliseconds;
      return duration;
    } catch (e) {
      Logs().e('Error while getting video duration', e);
      return null;
    } finally {
      videoPlayerController?.dispose();
    }
  }

  Future<String?> generateBlurHash(Uint8List data) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        data,
        minHeight: AppConfig.blurHashSize,
        minWidth: AppConfig.blurHashSize,
      );
      final blurHash = await compute((imageData) {
        final image = img.decodeJpg(imageData);
        if (image == null) return null;
        return BlurHash.encode(image).hash;
      }, result);
      return blurHash;
    } catch (e) {
      Logs().e('generateBlurHash::error', e);
      return null;
    }
  }
}
