import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Result of a local file pick, before it's uploaded to the backend. Holds raw bytes rather
/// than a dart:io File so previews (Image.memory) and uploads work identically on every
/// platform — web has no real filesystem path to read from, so this is the one approach that
/// works everywhere rather than a web-only workaround.
class PickedAsset {
  final Uint8List bytes;
  final String fileName;

  const PickedAsset({required this.bytes, required this.fileName});
}

/// Wraps image_picker (camera/gallery) and file_picker (PDF/transparent PNG designs).
class UploadPickerService {
  UploadPickerService._internal();
  static final UploadPickerService instance = UploadPickerService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  // Caps resolution at what the backend actually uses (it downsizes everything to a max
  // dimension of 2048px before passing images to any AI service) — sending full 12MP+ camera
  // photos wastes upload time on bytes the backend throws away anyway.
  static const double _maxUploadDimension = 2048;

  Future<PickedAsset?> pickFromCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: _maxUploadDimension,
      maxHeight: _maxUploadDimension,
    );
    if (image == null) return null;
    return PickedAsset(bytes: await image.readAsBytes(), fileName: image.name);
  }

  Future<PickedAsset?> pickFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: _maxUploadDimension,
      maxHeight: _maxUploadDimension,
    );
    if (image == null) return null;
    return PickedAsset(bytes: await image.readAsBytes(), fileName: image.name);
  }

  /// For embroidery designs: allows PNG / JPEG / PDF, including transparent PNGs.
  Future<PickedAsset?> pickDesignFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
      withData:
          true, // ensures `bytes` is populated on every platform, incl. web
    );
    final picked = result?.files.single;
    if (picked?.bytes == null) return null;
    return PickedAsset(bytes: picked!.bytes!, fileName: picked.name);
  }
}
