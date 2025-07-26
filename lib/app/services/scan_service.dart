import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/api_response_model.dart';
import '../models/ocr_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class ScanService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  final ImagePicker _imagePicker = ImagePicker();

  // Observable state
  final RxBool isProcessing = false.obs;
  final RxString processingStatus = ''.obs;

  /// Check and request camera permission
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Show dialog to go to settings
      await _showPermissionDialog(
        'Camera Permission Required',
        'Please enable camera permission in settings to take photos.',
      );
      return false;
    }

    return false;
  }

  /// Check and request photo library permission
  Future<bool> checkPhotoPermission() async {
    final status = await Permission.photos.status;

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.photos.request();
      return result.isGranted || result.isLimited;
    }

    if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        'Photo Access Required',
        'Please enable photo access in settings to select images.',
      );
      return false;
    }

    return false;
  }

  /// Take photo from camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo == null) return null;

      final file = File(photo.path);
      final fileSize = await file.length();

      if (fileSize > AppConstants.maxImageSize) {
        Get.snackbar(
          'File Too Large',
          'Image must be smaller than 5MB.',
          backgroundColor: CupertinoColors.systemRed.withOpacity(0.1),
          colorText: CupertinoColors.systemRed.darkColor,
        );
        return null;
      }

      return file;
    } catch (e) {
      Get.snackbar(
        'Camera Error',
        'Failed to take photo: $e',
        backgroundColor: CupertinoColors.systemRed.withOpacity(0.1),
        colorText: CupertinoColors.systemRed.darkColor,
      );
      return null;
    }
  }

  /// Pick image from gallery
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return null;

      final file = File(image.path);
      final fileSize = await file.length();

      if (fileSize > AppConstants.maxImageSize) {
        Get.snackbar(
          'File Too Large',
          'Image must be smaller than 5MB.',
          backgroundColor: CupertinoColors.systemRed.withOpacity(0.1),
          colorText: CupertinoColors.systemRed.darkColor,
        );
        return null;
      }

      final fileName = image.name.toLowerCase();
      final isValidType = AppConstants.allowedImageTypes.any(
            (type) => fileName.endsWith('.$type'),
      );

      if (!isValidType) {
        Get.snackbar(
          'Invalid File Type',
          'Only JPG, JPEG, and PNG images are supported.',
          backgroundColor: CupertinoColors.systemRed.withOpacity(0.1),
          colorText: CupertinoColors.systemRed.darkColor,
        );
        return null;
      }

      return file;
    } catch (e) {
      Get.snackbar(
        'Gallery Error',
        'Failed to pick image: $e',
        backgroundColor: CupertinoColors.systemRed.withOpacity(0.1),
        colorText: CupertinoColors.systemRed.darkColor,
      );
      return null;
    }
  }


  /// Process image with OCR
  Future<ApiResponse<OCRResponse>> processImage(File imageFile) async {
    try {
      isProcessing.value = true;
      processingStatus.value = 'Uploading image...';

      final fileSize = await imageFile.length();
      final fileName = imageFile.path.split('/').last;

      // Upload and process image
      final response = await _apiService.uploadFile<OCRResponse>(
        ApiEndpoints.uploadPhoto,
        file: imageFile,
        fileKey: 'file', // Backend expects 'file' parameter
        fromJson: (json) => OCRResponse.fromJson(json),
        onProgress: (sent, total) {
          final progress = (sent / total * 100).round();
          processingStatus.value = 'Uploading... $progress%';
        },
      );

      if (response.success && response.data != null) {
        processingStatus.value = 'Processing completed!';

        Get.snackbar(
          'OCR Complete',
          'Extracted ${response.data!.totalExtracted} words in ${response.data!.processingTime.toStringAsFixed(1)}s',
          backgroundColor: CupertinoColors.systemGreen.withOpacity(0.1),
          colorText: CupertinoColors.systemGreen.darkColor,
          duration: const Duration(seconds: 3),
        );
      } else {
        processingStatus.value = 'Processing failed';

        Get.snackbar(
          'OCR Failed',
          response.error ?? 'Failed to process image',
          backgroundColor: CupertinoColors.systemRed.withOpacity(0.1),
          colorText: CupertinoColors.systemRed.darkColor,
        );
      }

      return response;
    } catch (e) {
      processingStatus.value = 'Error occurred';

      return ApiResponse.error(
        error: 'Failed to process image: ${e.toString()}',
      );
    } finally {
      isProcessing.value = false;
      // Clear status after delay
      Future.delayed(const Duration(seconds: 2), () {
        processingStatus.value = '';
      });
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
              subtitle: const Text('Choose from photos'),
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

  /// Show permission dialog
  Future<void> _showPermissionDialog(String title, String content) async {
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  /// Validate image file
  bool validateImageFile(File file) {
    final fileName = file.path.toLowerCase();
    return AppConstants.allowedImageTypes.any(
          (type) => fileName.endsWith('.$type'),
    );
  }
}