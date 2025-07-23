import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/api_response_model.dart';
import '../models/word_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'api_service.dart';

class CameraService extends GetxService {
  late ApiService _apiService;
  late ImagePicker _imagePicker;

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;

  final RxBool _isInitialized = false.obs;
  final RxBool _isProcessing = false.obs;

  bool get isInitialized => _isInitialized.value;
  bool get isProcessing => _isProcessing.value;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _imagePicker = ImagePicker();
    _initializeCameras();
  }

  @override
  void onClose() {
    _cameraController?.dispose();
    super.onClose();
  }

  /// Initialize available cameras
  Future<void> _initializeCameras() async {
    try {
      _cameras = availableCameras;
      AppHelpers.logUserAction('cameras_initialized', {
        'camera_count': _cameras.length,
      });
    } catch (e) {
      AppHelpers.logUserAction('camera_init_error', {
        'error': e.toString(),
      });
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();

      AppHelpers.logUserAction('camera_permission_requested', {
        'status': status.toString(),
      });

      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        AppHelpers.showErrorSnackbar(
          'Camera permission is required for OCR functionality. Please enable it in Settings.',
          title: 'Permission Required',
        );
        await openAppSettings();
      } else {
        AppHelpers.showErrorSnackbar(
          'Camera permission is required to scan text from images.',
          title: 'Permission Denied',
        );
      }

      return false;
    } catch (e) {
      AppHelpers.logUserAction('camera_permission_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to request camera permission',
        title: 'Permission Error',
      );

      return false;
    }
  }

  /// Initialize camera controller
  Future<bool> initializeCamera({CameraLensDirection direction = CameraLensDirection.back}) async {
    try {
      if (_cameras.isEmpty) {
        await _initializeCameras();
      }

      if (_cameras.isEmpty) {
        AppHelpers.showErrorSnackbar('No cameras available on this device');
        return false;
      }

      // Find camera with specified direction
      CameraDescription? camera;
      try {
        camera = _cameras.firstWhere(
              (cam) => cam.lensDirection == direction,
        );
      } catch (e) {
        // Fallback to first available camera
        camera = _cameras.first;
      }

      // Dispose existing controller
      await _cameraController?.dispose();

      // Create new controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // Initialize controller
      await _cameraController!.initialize();

      _isInitialized.value = true;

      AppHelpers.logUserAction('camera_controller_initialized', {
        'direction': direction.toString(),
        'resolution': ResolutionPreset.high.toString(),
      });

      return true;
    } catch (e) {
      AppHelpers.logUserAction('camera_controller_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to initialize camera: ${e.toString()}',
        title: 'Camera Error',
      );

      return false;
    }
  }

  /// Get camera controller
  CameraController? get cameraController => _cameraController;

  /// Capture image from camera
  Future<File?> captureImage() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        AppHelpers.showErrorSnackbar('Camera not initialized');
        return null;
      }

      _isProcessing.value = true;

      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);

      // Validate file
      if (!await file.exists()) {
        throw Exception('Captured image file not found');
      }

      final fileSize = await file.length();
      if (!AppHelpers.isValidImageFile(imageFile.name, fileSize)) {
        throw Exception('Invalid image file or file too large');
      }

      AppHelpers.logUserAction('image_captured', {
        'file_size': fileSize,
        'file_path': imageFile.path,
      });

      return file;
    } catch (e) {
      AppHelpers.logUserAction('capture_image_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to capture image: ${e.toString()}',
        title: 'Capture Error',
      );

      return null;
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      _isProcessing.value = true;

      final XFile? imageFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );

      if (imageFile == null) {
        return null; // User cancelled
      }

      final File file = File(imageFile.path);

      // Validate file
      final fileSize = await file.length();
      if (!AppHelpers.isValidImageFile(imageFile.name, fileSize)) {
        AppHelpers.showErrorSnackbar(
          'Invalid image file or file too large (max ${AppHelpers.formatFileSize(AppConstants.maxImageSize)})',
          title: 'Invalid File',
        );
        return null;
      }

      AppHelpers.logUserAction('image_picked_from_gallery', {
        'file_size': fileSize,
        'file_path': imageFile.path,
      });

      return file;
    } catch (e) {
      AppHelpers.logUserAction('pick_image_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to pick image: ${e.toString()}',
        title: 'Pick Error',
      );

      return null;
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Process image with OCR
  Future<ApiResponse<OCRResponse>> processImageOCR(File imageFile) async {
    try {
      _isProcessing.value = true;

      // Validate file
      final fileSize = await imageFile.length();
      final fileName = imageFile.path.split('/').last;

      if (!AppHelpers.isValidImageFile(fileName, fileSize)) {
        return ApiResponse.error(
          error: 'Invalid image file or file too large (max ${AppHelpers.formatFileSize(AppConstants.maxImageSize)})',
        );
      }

      AppHelpers.logUserAction('ocr_processing_started', {
        'file_size': fileSize,
        'file_name': fileName,
      });

      // Upload and process image
      final response = await _apiService.uploadFile<OCRResponse>(
        ApiEndpoints.uploadPhoto,
        file: imageFile,
        fileKey: 'photo',
        fromJson: (json) => OCRResponse.fromJson(json),
        onProgress: (sent, total) {
          final progress = (sent / total * 100).round();
          AppHelpers.logUserAction('ocr_upload_progress', {
            'progress': progress,
          });
        },
      );

      if (response.success && response.data != null) {
        AppHelpers.logUserAction('ocr_processing_completed', {
          'extracted_words': response.data!.totalExtracted,
          'processing_time': response.data!.processingTime,
        });

        AppHelpers.showSuccessSnackbar(
          'Extracted ${response.data!.totalExtracted} words in ${response.data!.processingTime}s',
          title: 'OCR Complete',
        );
      } else {
        AppHelpers.logUserAction('ocr_processing_failed', {
          'error': response.error,
        });
      }

      return response;
    } catch (e) {
      AppHelpers.logUserAction('ocr_processing_error', {
        'error': e.toString(),
      });

      return ApiResponse.error(
        error: 'Failed to process image: ${e.toString()}',
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  /// Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog() async {
    final result = await Get.dialog<ImageSource>(
      AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              subtitle: const Text('Take a new photo'),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              subtitle: const Text('Choose from gallery'),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    return result;
  }

  /// Get image from user selection
  Future<File?> getImageFromUser() async {
    try {
      final source = await showImageSourceDialog();
      if (source == null) return null;

      switch (source) {
        case ImageSource.camera:
        // Check camera permission
          final hasPermission = await requestCameraPermission();
          if (!hasPermission) return null;

          // Initialize camera if needed
          if (!isInitialized) {
            final initialized = await initializeCamera();
            if (!initialized) return null;
          }

          return await captureImage();

        case ImageSource.gallery:
          return await pickImageFromGallery();
      }
    } catch (e) {
      AppHelpers.logUserAction('get_image_from_user_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'Failed to get image: ${e.toString()}',
        title: 'Image Error',
      );

      return null;
    }
  }

  /// Complete OCR workflow (get image + process)
  Future<ApiResponse<OCRResponse>?> performOCRWorkflow() async {
    try {
      // Show loading
      AppHelpers.showLoadingDialog(message: 'Getting image...');

      // Get image from user
      final imageFile = await getImageFromUser();

      // Hide loading
      AppHelpers.hideLoadingDialog();

      if (imageFile == null) {
        return null; // User cancelled or error occurred
      }

      // Show processing dialog
      AppHelpers.showLoadingDialog(message: 'Processing image...');

      // Process with OCR
      final result = await processImageOCR(imageFile);

      // Hide loading
      AppHelpers.hideLoadingDialog();

      // Clean up temporary file
      try {
        await imageFile.delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      return result;
    } catch (e) {
      AppHelpers.hideLoadingDialog();

      AppHelpers.logUserAction('ocr_workflow_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'OCR workflow failed: ${e.toString()}',
        title: 'OCR Error',
      );

      return ApiResponse.error(
        error: 'OCR workflow failed: ${e.toString()}',
      );
    }
  }

  /// Switch camera (front/back)
  Future<bool> switchCamera() async {
    try {
      if (_cameras.length < 2) {
        AppHelpers.showInfoSnackbar('Only one camera available');
        return false;
      }

      final currentDirection = _cameraController?.description.lensDirection;
      final newDirection = currentDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;

      return await initializeCamera(direction: newDirection);
    } catch (e) {
      AppHelpers.logUserAction('switch_camera_error', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar('Failed to switch camera');
      return false;
    }
  }

  /// Toggle flash
  Future<void> toggleFlash() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      final currentFlashMode = _cameraController!.value.flashMode;
      final newFlashMode = currentFlashMode == FlashMode.off
          ? FlashMode.auto
          : FlashMode.off;

      await _cameraController!.setFlashMode(newFlashMode);

      AppHelpers.logUserAction('flash_toggled', {
        'new_mode': newFlashMode.toString(),
      });

    } catch (e) {
      AppHelpers.logUserAction('toggle_flash_error', {
        'error': e.toString(),
      });
    }
  }

  /// Get current flash mode
  FlashMode? get currentFlashMode {
    return _cameraController?.value.flashMode;
  }

  /// Check if device has flash
  bool get hasFlash {
    return _cameraController?.description.lensDirection == CameraLensDirection.back;
  }

  /// Dispose camera controller
  Future<void> disposeCamera() async {
    try {
      await _cameraController?.dispose();
      _cameraController = null;
      _isInitialized.value = false;

      AppHelpers.logUserAction('camera_disposed');
    } catch (e) {
      AppHelpers.logUserAction('dispose_camera_error', {
        'error': e.toString(),
      });
    }
  }

  /// Get available cameras
  List<CameraDescription> get availableCameras => _cameras;

  /// Check if multiple cameras available
  bool get hasMultipleCameras => _cameras.length > 1;

  /// Get camera preview aspect ratio
  double? get previewAspectRatio {
    return _cameraController?.value.aspectRatio;
  }

  /// Check camera state
  bool get isCameraReady {
    return _cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_isProcessing.value;
  }
}

/// Camera state for UI
enum CameraState {
  uninitialized,
  initializing,
  ready,
  capturing,
  processing,
  error,
}

/// Image source options
enum ImageSourceOption {
  camera,
  gallery,
  both,
}

/// OCR processing result
class OCRResult {
  final bool success;
  final OCRResponse? data;
  final String? error;
  final File? originalFile;

  OCRResult({
    required this.success,
    this.data,
    this.error,
    this.originalFile,
  });

  factory OCRResult.success(OCRResponse data, {File? originalFile}) {
    return OCRResult(
      success: true,
      data: data,
      originalFile: originalFile,
    );
  }

  factory OCRResult.failure(String error, {File? originalFile}) {
    return OCRResult(
      success: false,
      error: error,
      originalFile: originalFile,
    );
  }

  @override
  String toString() {
    return 'OCRResult{success: $success, wordsExtracted: ${data?.totalExtracted ?? 0}, error: $error}';
  }
}