// lib/app/controllers/scan_controller.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/api_response_model.dart';
import '../models/ocr_model.dart';
import '../models/folder_model.dart';
import '../controllers/folder_controller.dart';
import '../services/scan_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ScanController extends GetxController {
  final ScanService _scanService = Get.find<ScanService>();
  final ApiService _apiService = Get.find<ApiService>();

  // UI State
  final RxBool isLoading = false.obs;
  final RxString currentStep = 'ready'.obs; // ready, processing, selecting, adding

  // Image and OCR results
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxList<ExtractedWord> extractedWords = <ExtractedWord>[].obs;
  final RxList<ExtractedWord> selectedWords = <ExtractedWord>[].obs;

  // Folder selection for adding words
  final Rx<Folder?> targetFolder = Rx<Folder?>(null);

  // Processing state
  final RxString processingStatus = ''.obs;

  // Individual word adding state
  final RxBool isAddingWord = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Listen to scan service state
    ever(_scanService.isProcessing, (bool processing) {
      if (processing) {
        currentStep.value = 'processing';
      }
    });

    ever(_scanService.processingStatus, (String status) {
      processingStatus.value = status;
    });
  }

  /// Direct camera capture
  Future<void> openCamera() async {
    try {
      final imageFile = await _scanService.takePhoto();
      if (imageFile != null) {
        selectedImage.value = imageFile;
        await processImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to take photo: ${e.toString()}');
    }
  }

  /// Direct gallery selection
  Future<void> openGallery() async {
    try {
      final imageFile = await _scanService.pickImage();
      if (imageFile != null) {
        selectedImage.value = imageFile;
        await processImage(imageFile);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to select image: ${e.toString()}');
    }
  }

  /// Process selected image with OCR
  Future<void> processImage(File imageFile) async {
    try {
      currentStep.value = 'processing';
      isLoading.value = true;

      final response = await _scanService.processImage(imageFile);

      if (response.success && response.data != null) {
        extractedWords.value = response.data!.extractedWords;
        selectedWords.clear();

        // Don't auto-select words anymore - let user choose
        for (final word in extractedWords) {
          word.isSelected = false;
        }

        currentStep.value = 'selecting';

        _showSuccessSnackbar(
          'Found ${extractedWords.length} words. Tap any word to add it to your vocabulary.',
        );
      } else {
        currentStep.value = 'ready';
        selectedImage.value = null;

        _showErrorSnackbar(
          response.error ?? 'Failed to extract text from image',
        );
      }
    } catch (e) {
      currentStep.value = 'ready';
      selectedImage.value = null;

      _showErrorSnackbar('An error occurred while processing the image');
    } finally {
      isLoading.value = false;
    }
  }

  /// Add a single word to default folder or prompt for folder selection
  Future<void> addSingleWord(ExtractedWord word, {
    String? translation,
    String? example,
    int? folderId,
  }) async {
    try {
      isAddingWord.value = true;

      // Use default folder if none provided
      int targetFolderId = folderId ?? await getDefaultFolderId();

      final wordData = {
        'word': word.word,
        'translation': translation ?? word.translation,
        'example_sentence': example,
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.addWord(targetFolderId),
        data: wordData,
        fromJson: (json) => json,
      );

      if (response.success) {
        // Mark word as selected visually
        word.isSelected = true;
        extractedWords.refresh();

        _showSuccessSnackbar('Word "${word.word}" added successfully!');
      } else {
        _showErrorSnackbar(
          response.error ?? 'Failed to add word',
        );
      }
    } catch (e) {
      _showErrorSnackbar('Failed to add word: ${e.toString()}');
    } finally {
      isAddingWord.value = false;
    }
  }

  /// Get default folder ID (first folder or create one if none exists)
  Future<int> getDefaultFolderId() async {
    final folderController = Get.find<FolderController>();

    if (folderController.folders.isEmpty) {
      await folderController.loadFolders();
    }

    if (folderController.folders.isNotEmpty) {
      return folderController.folders.first.id;
    } else {
      // Create a default folder if none exists
      return await _createDefaultFolder();
    }
  }

  /// Create default folder for scanned words
  Future<int> _createDefaultFolder() async {
    try {
      final response = await _apiService.post<FolderResponse>(
        ApiEndpoints.folders,
        data: {
          'name': 'Scanned Words',
          'description': 'Words added from image scanning',
        },
        fromJson: (json) => FolderResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Reload folders to get the updated list
        final folderController = Get.find<FolderController>();
        await folderController.loadFolders();

        return response.data!.id;
      } else {
        throw Exception('Failed to create default folder');
      }
    } catch (e) {
      throw Exception('Failed to create default folder: ${e.toString()}');
    }
  }

  /// Toggle word selection (for future bulk operations if needed)
  void toggleWordSelection(ExtractedWord word) {
    final index = extractedWords.indexWhere((w) => w.word == word.word);
    if (index != -1) {
      extractedWords[index].isSelected = !extractedWords[index].isSelected;

      if (extractedWords[index].isSelected) {
        if (!selectedWords.contains(word)) {
          selectedWords.add(extractedWords[index]);
        }
      } else {
        selectedWords.removeWhere((w) => w.word == word.word);
      }

      // Force UI update
      extractedWords.refresh();
      selectedWords.refresh();
    }
  }

  /// Select all words (for future bulk operations)
  void selectAllWords() {
    selectedWords.clear();
    for (final word in extractedWords) {
      word.isSelected = true;
      selectedWords.add(word);
    }
    extractedWords.refresh();
    selectedWords.refresh();
  }

  /// Deselect all words
  void deselectAllWords() {
    for (final word in extractedWords) {
      word.isSelected = false;
    }
    selectedWords.clear();
    extractedWords.refresh();
    selectedWords.refresh();
  }

  /// Set target folder for adding words
  void setTargetFolder(FolderResponse folder) {
    // Convert FolderResponse to Folder if needed, or work with FolderResponse directly
    targetFolder.value = folder.toFolder();
  }

  /// Add selected words to the target folder (bulk operation)
  Future<void> addSelectedWords() async {
    if (targetFolder.value == null) {
      _showErrorSnackbar('Please select a folder to add words to');
      return;
    }

    if (selectedWords.isEmpty) {
      _showErrorSnackbar('Please select at least one word to add');
      return;
    }

    try {
      currentStep.value = 'adding';
      isLoading.value = true;

      // Convert selected words to bulk add request
      final bulkRequest = {
        'words': selectedWords.map((word) => BulkAddWordRequest.fromExtractedWord(word).toJson()).toList(),
      };

      final response = await _apiService.post<Map<String, dynamic>>(
        ApiEndpoints.bulkAddWords(targetFolder.value!.id),
        data: bulkRequest,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final addedCount = response.data!['added_count'] ?? 0;

        _showSuccessSnackbar(
          'Added $addedCount words to "${targetFolder.value!.name}"',
        );

        // Reset state
        resetScanState();

        // Navigate back
        Get.back();
      } else {
        _showErrorSnackbar(
          response.error ?? 'An error occurred while adding words',
        );
        currentStep.value = 'selecting';
      }
    } catch (e) {
      _showErrorSnackbar('Failed to add words: ${e.toString()}');
      currentStep.value = 'selecting';
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset scan state
  void resetScanState() {
    currentStep.value = 'ready';
    selectedImage.value = null;
    extractedWords.clear();
    selectedWords.clear();
    targetFolder.value = null;
    isLoading.value = false;
    isAddingWord.value = false;
    processingStatus.value = '';
  }

  /// Get confidence color for UI
  Color getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return CupertinoColors.systemGreen;
    } else if (confidence >= 0.6) {
      return CupertinoColors.systemOrange;
    } else {
      return CupertinoColors.systemRed;
    }
  }

  /// Get confidence text for UI
  String getConfidenceText(double confidence) {
    final percentage = (confidence * 100).round();
    return '$percentage%';
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: CupertinoColors.systemGreen.withOpacity(0.1),
      colorText: CupertinoColors.systemGreen.darkColor,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: CupertinoColors.systemRed.withOpacity(0.1),
      colorText: CupertinoColors.systemRed.darkColor,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  /// Show folder selection bottom sheet (for future use)
  void showFolderSelection() {
    final folderController = Get.find<FolderController>();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: CupertinoColors.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const Text(
              'Select Folder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            ...folderController.folders.map((folderResponse) {
              return ListTile(
                title: Text(folderResponse.name),
                subtitle: Text('${folderResponse.wordCount} words'),
                onTap: () {
                  setTargetFolder(folderResponse);
                  Get.back();
                  addSelectedWords();
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    resetScanState();
    super.onClose();
  }
}