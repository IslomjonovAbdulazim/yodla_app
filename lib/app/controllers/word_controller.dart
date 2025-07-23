import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/api_response_model.dart';
import '../models/folder_model.dart';
import '../models/word_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';

class WordController extends GetxController with FormValidationMixin {
  late ApiService _apiService;
  late CameraService _cameraService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final RxBool _isAdding = false.obs;
  final RxBool _isUpdating = false.obs;
  final RxBool _isDeleting = false.obs;
  final RxBool _isGeneratingExample = false.obs;
  final RxBool _isProcessingOCR = false.obs;
  final RxList<WordWithStats> _words = <WordWithStats>[].obs;
  final Rx<WordDetailResponse?> _currentWordDetail = Rx<WordDetailResponse?>(null);
  final RxList<ExtractedWord> _ocrResults = <ExtractedWord>[].obs;
  final RxList<ExtractedWord> _selectedWords = <ExtractedWord>[].obs;

  // Form controllers
  final TextEditingController wordController = TextEditingController();
  final TextEditingController translationController = TextEditingController();
  final TextEditingController exampleController = TextEditingController();

  // Form validation
  final RxMap<String, String?> _validationErrors = <String, String?>{}.obs;

  // Search functionality
  final TextEditingController searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;

  // Filter states
  final Rx<WordCategory?> _categoryFilter = Rx<WordCategory?>(null);
  final RxBool _showIncompleteWordsOnly = false.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isAdding => _isAdding.value;
  bool get isUpdating => _isUpdating.value;
  bool get isDeleting => _isDeleting.value;
  bool get isGeneratingExample => _isGeneratingExample.value;
  bool get isProcessingOCR => _isProcessingOCR.value;
  List<WordWithStats> get words => _words.toList();
  WordDetailResponse? get currentWordDetail => _currentWordDetail.value;
  List<ExtractedWord> get ocrResults => _ocrResults.toList();
  List<ExtractedWord> get selectedWords => _selectedWords.toList();
  Map<String, String?> get validationErrors => _validationErrors;
  String get searchQuery => _searchQuery.value;
  WordCategory? get categoryFilter => _categoryFilter.value;
  bool get showIncompleteWordsOnly => _showIncompleteWordsOnly.value;

  // Computed properties
  List<WordWithStats> get filteredWords {
    var filtered = _words.toList();

    // Apply search filter
    if (_searchQuery.value.isNotEmpty) {
      final query = _searchQuery.value.toLowerCase();
      filtered = filtered.where((word) {
        return word.word.toLowerCase().contains(query) ||
            word.translation.toLowerCase().contains(query) ||
            (word.exampleSentence?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Apply category filter
    if (_categoryFilter.value != null) {
      filtered = filtered.where((word) {
        return word.stats.categoryEnum == _categoryFilter.value;
      }).toList();
    }

    // Apply incomplete words filter
    if (_showIncompleteWordsOnly.value) {
      filtered = filtered.where((word) => !word.isComplete).toList();
    }

    return filtered;
  }

  int get wordsCount => _words.length;
  int get completeWordsCount => _words.where((word) => word.isComplete).length;
  int get incompleteWordsCount => _words.where((word) => !word.isComplete).length;
  bool get hasWords => _words.isNotEmpty;
  bool get hasOCRResults => _ocrResults.isNotEmpty;
  bool get hasSelectedWords => _selectedWords.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _cameraService = Get.find<CameraService>();

    // Setup search listener
    searchController.addListener(() {
      _searchQuery.value = searchController.text;
    });
  }

  @override
  void onClose() {
    wordController.dispose();
    translationController.dispose();
    exampleController.dispose();
    searchController.dispose();
    super.onClose();
  }

  /// Load words for a folder (called from folder detail)
  void loadWordsFromFolderDetail(List<WordWithStats> folderWords) {
    _words.assignAll(folderWords);

    AppHelpers.logUserAction('words_loaded_from_folder', {
      'word_count': folderWords.length,
    });
  }

  /// Add word manually
  Future<void> addWord(int folderId) async {
    try {
      if (_isAdding.value) return;

      // Validate form
      if (!_validateWordForm()) {
        return;
      }

      _isAdding.value = true;
      _clearValidationErrors();

      final request = AddWordRequest(
        word: wordController.text.trim(),
        translation: translationController.text.trim(),
        exampleSentence: exampleController.text.trim().isEmpty
            ? null
            : exampleController.text.trim(),
      );

      AppHelpers.logUserAction('add_word_attempt', {
        'folder_id': folderId,
        'word': request.word,
        'has_example': request.exampleSentence != null,
      });

      final response = await _apiService.post<AddWordResponse>(
        ApiEndpoints.addWord(folderId),
        data: request.toJson(),
        fromJson: (json) => AddWordResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        AppHelpers.logUserAction('add_word_success', {
          'folder_id': folderId,
          'word_id': response.data!.word.id,
          'word': response.data!.word.word,
        });

        AppHelpers.showSuccessSnackbar(
          'Word "${response.data!.word.word}" added successfully',
          title: 'Word Added',
        );

        // Clear form and go back
        _clearForm();
        Get.back(result: true); // Indicate success to refresh folder detail
      } else {
        AppHelpers.logUserAction('add_word_failed', {
          'folder_id': folderId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to add word',
          title: 'Add Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('add_word_exception', {
        'folder_id': folderId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while adding word',
        title: 'Add Error',
      );
    } finally {
      _isAdding.value = false;
    }
  }

  /// Process OCR from camera/gallery
  Future<void> processOCR() async {
    try {
      _isProcessingOCR.value = true;
      _ocrResults.clear();
      _selectedWords.clear();

      AppHelpers.logUserAction('ocr_process_attempt');

      final result = await _cameraService.performOCRWorkflow();

      if (result != null && result.success && result.data != null) {
        _ocrResults.assignAll(result.data!.extractedWords);

        AppHelpers.logUserAction('ocr_process_success', {
          'extracted_count': result.data!.totalExtracted,
          'processing_time': result.data!.processingTime,
        });
      } else if (result != null) {
        AppHelpers.logUserAction('ocr_process_failed', {
          'error': result.error,
        });
      }
      // If result is null, user cancelled - no error needed
    } catch (e) {
      AppHelpers.logUserAction('ocr_process_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred during OCR processing',
        title: 'OCR Error',
      );
    } finally {
      _isProcessingOCR.value = false;
    }
  }

  /// Toggle word selection for OCR results
  void toggleWordSelection(ExtractedWord word) {
    if (_selectedWords.contains(word)) {
      _selectedWords.remove(word);
    } else {
      _selectedWords.add(word);
    }

    AppHelpers.logUserAction('ocr_word_toggled', {
      'word': word.word,
      'selected': _selectedWords.contains(word),
      'total_selected': _selectedWords.length,
    });
  }

  /// Select all OCR words
  void selectAllOCRWords() {
    _selectedWords.assignAll(_ocrResults);

    AppHelpers.logUserAction('ocr_select_all', {
      'selected_count': _selectedWords.length,
    });
  }

  /// Deselect all OCR words
  void deselectAllOCRWords() {
    _selectedWords.clear();

    AppHelpers.logUserAction('ocr_deselect_all');
  }

  /// Add selected OCR words to folder
  Future<void> addSelectedWordsToFolder(int folderId) async {
    try {
      if (_selectedWords.isEmpty) {
        AppHelpers.showWarningSnackbar(
          'Please select at least one word to add',
          title: 'No Words Selected',
        );
        return;
      }

      _isAdding.value = true;

      final words = _selectedWords.map((word) => AddWordRequest(
        word: word.word,
        translation: word.translation,
        exampleSentence: null, // OCR words don't have examples initially
      )).toList();

      final request = BulkAddRequest(words: words);

      AppHelpers.logUserAction('bulk_add_words_attempt', {
        'folder_id': folderId,
        'word_count': words.length,
      });

      final response = await _apiService.post<BulkAddResponse>(
        ApiEndpoints.bulkAddWords(folderId),
        data: request.toJson(),
        fromJson: (json) => BulkAddResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        AppHelpers.logUserAction('bulk_add_words_success', {
          'folder_id': folderId,
          'added_count': response.data!.addedCount,
          'requested_count': words.length,
        });

        AppHelpers.showSuccessSnackbar(
          '${response.data!.addedCount} words added successfully',
          title: 'Words Added',
        );

        // Clear OCR results and go back
        _ocrResults.clear();
        _selectedWords.clear();
        Get.back(result: true); // Indicate success to refresh folder detail
      } else {
        AppHelpers.logUserAction('bulk_add_words_failed', {
          'folder_id': folderId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to add words',
          title: 'Add Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('bulk_add_words_exception', {
        'folder_id': folderId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while adding words',
        title: 'Add Error',
      );
    } finally {
      _isAdding.value = false;
    }
  }

  /// Generate example sentence for word
  Future<void> generateExampleSentence() async {
    try {
      if (_isGeneratingExample.value) return;

      final word = wordController.text.trim();
      final translation = translationController.text.trim();

      if (word.isEmpty || translation.isEmpty) {
        AppHelpers.showWarningSnackbar(
          'Please enter both word and translation before generating example',
          title: 'Missing Information',
        );
        return;
      }

      _isGeneratingExample.value = true;

      final request = GenerateExampleRequest(
        word: word,
        translation: translation,
      );

      AppHelpers.logUserAction('generate_example_attempt', {
        'word': word,
        'translation': translation,
      });

      final response = await _apiService.post<GenerateExampleResponse>(
        ApiEndpoints.generateExample,
        data: request.toJson(),
        fromJson: (json) => GenerateExampleResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        exampleController.text = response.data!.exampleSentence;

        AppHelpers.logUserAction('generate_example_success', {
          'word': word,
          'example_length': response.data!.exampleSentence.length,
        });

        AppHelpers.showSuccessSnackbar(
          'Example sentence generated successfully',
          title: 'Example Generated',
        );
      } else {
        AppHelpers.logUserAction('generate_example_failed', {
          'word': word,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to generate example sentence',
          title: 'Generation Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('generate_example_exception', {
        'word': wordController.text.trim(),
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while generating example',
        title: 'Generation Error',
      );
    } finally {
      _isGeneratingExample.value = false;
    }
  }

  /// Load word details
  Future<void> loadWordDetail(int wordId) async {
    try {
      _isLoading.value = true;

      AppHelpers.logUserAction('load_word_detail_attempt', {
        'word_id': wordId,
      });

      final response = await _apiService.get<WordDetailResponse>(
        ApiEndpoints.wordDetail(wordId),
        fromJson: (json) => WordDetailResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        _currentWordDetail.value = response.data!;

        AppHelpers.logUserAction('load_word_detail_success', {
          'word_id': wordId,
          'word': response.data!.word.word,
        });
      } else {
        AppHelpers.logUserAction('load_word_detail_failed', {
          'word_id': wordId,
          'error': response.error,
        });

        if (response.statusCode == 404) {
          AppHelpers.showErrorSnackbar(
            'Word not found',
            title: 'Not Found',
          );
          Get.back();
        } else if (response.statusCode != 401) {
          AppHelpers.showErrorSnackbar(
            response.error ?? 'Failed to load word details',
            title: 'Load Error',
          );
        }
      }
    } catch (e) {
      AppHelpers.logUserAction('load_word_detail_exception', {
        'word_id': wordId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while loading word details',
        title: 'Load Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update word
  Future<void> updateWord(int wordId) async {
    try {
      if (_isUpdating.value) return;

      // Validate form
      if (!_validateWordForm()) {
        return;
      }

      _isUpdating.value = true;
      _clearValidationErrors();

      final request = UpdateWordRequest(
        word: wordController.text.trim(),
        translation: translationController.text.trim(),
        exampleSentence: exampleController.text.trim().isEmpty
            ? null
            : exampleController.text.trim(),
      );

      AppHelpers.logUserAction('update_word_attempt', {
        'word_id': wordId,
        'new_word': request.word,
        'has_example': request.exampleSentence != null,
      });

      final response = await _apiService.put<UpdateWordResponse>(
        ApiEndpoints.updateWord(wordId),
        data: request.toJson(),
        fromJson: (json) => UpdateWordResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        AppHelpers.logUserAction('update_word_success', {
          'word_id': wordId,
          'new_word': request.word,
        });

        AppHelpers.showSuccessSnackbar(
          'Word updated successfully',
          title: 'Word Updated',
        );

        // Update current word detail if it's the same word
        if (_currentWordDetail.value?.word.id == wordId) {
          await loadWordDetail(wordId);
        }

        // Clear form and go back
        _clearForm();
        Get.back(result: true);
      } else {
        AppHelpers.logUserAction('update_word_failed', {
          'word_id': wordId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to update word',
          title: 'Update Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('update_word_exception', {
        'word_id': wordId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while updating word',
        title: 'Update Error',
      );
    } finally {
      _isUpdating.value = false;
    }
  }

  /// Delete word
  Future<void> deleteWord(int wordId, String word) async {
    try {
      // Show confirmation dialog
      final confirmed = await AppHelpers.showConfirmationDialog(
        title: 'Delete Word',
        message: 'Are you sure you want to delete "$word"? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        confirmColor: Colors.red,
      );

      if (!confirmed) return;

      _isDeleting.value = true;

      AppHelpers.logUserAction('delete_word_attempt', {
        'word_id': wordId,
        'word': word,
      });

      final response = await _apiService.delete<DeleteWordResponse>(
        ApiEndpoints.deleteWord(wordId),
        fromJson: (json) => DeleteWordResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Remove from local list if present
        _words.removeWhere((w) => w.id == wordId);

        AppHelpers.logUserAction('delete_word_success', {
          'word_id': wordId,
          'word': word,
        });

        AppHelpers.showSuccessSnackbar(
          'Word deleted successfully',
          title: 'Word Deleted',
        );

        // Go back if we're on word detail page
        if (Get.currentRoute.contains('word-detail')) {
          Get.back(result: true);
        }
      } else {
        AppHelpers.logUserAction('delete_word_failed', {
          'word_id': wordId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to delete word',
          title: 'Delete Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('delete_word_exception', {
        'word_id': wordId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while deleting word',
        title: 'Delete Error',
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Bulk delete selected words
  Future<void> bulkDeleteWords(List<int> wordIds) async {
    try {
      if (wordIds.isEmpty) return;

      // Show confirmation dialog
      final confirmed = await AppHelpers.showConfirmationDialog(
        title: 'Delete Words',
        message: 'Are you sure you want to delete ${wordIds.length} word${wordIds.length == 1 ? '' : 's'}? This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        confirmColor: Colors.red,
      );

      if (!confirmed) return;

      _isDeleting.value = true;

      final request = BulkDeleteRequest(wordIds: wordIds);

      AppHelpers.logUserAction('bulk_delete_words_attempt', {
        'word_count': wordIds.length,
      });

      final response = await _apiService.post<BulkDeleteResponse>(
        ApiEndpoints.bulkDeleteWords,
        data: request.toJson(),
        fromJson: (json) => BulkDeleteResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Remove from local list
        _words.removeWhere((word) => wordIds.contains(word.id));

        AppHelpers.logUserAction('bulk_delete_words_success', {
          'deleted_count': response.data!.deletedCount,
          'requested_count': wordIds.length,
        });

        AppHelpers.showSuccessSnackbar(
          '${response.data!.deletedCount} words deleted successfully',
          title: 'Words Deleted',
        );
      } else {
        AppHelpers.logUserAction('bulk_delete_words_failed', {
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to delete words',
          title: 'Delete Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('bulk_delete_words_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while deleting words',
        title: 'Delete Error',
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Validate word form
  bool _validateWordForm() {
    final errors = validateFields({
      'word': CommonValidators.englishWord,
      'translation': CommonValidators.translation,
      'example': [Validators.exampleSentence],
    }, {
      'word': wordController.text,
      'translation': translationController.text,
      'example': exampleController.text,
    });

    _validationErrors.assignAll(errors);

    if (hasErrors(errors)) {
      final firstError = getFirstError(errors);
      if (firstError != null) {
        AppHelpers.showErrorSnackbar(firstError, title: 'Validation Error');
      }
      return false;
    }

    return true;
  }

  /// Clear validation errors
  void _clearValidationErrors() {
    _validationErrors.clear();
  }

  /// Clear form
  void _clearForm() {
    wordController.clear();
    translationController.clear();
    exampleController.clear();
    _clearValidationErrors();
  }

  /// Get validation error for field
  String? getFieldError(String fieldName) {
    return _validationErrors[fieldName];
  }

  /// Check if field has error
  bool hasFieldError(String fieldName) {
    return _validationErrors[fieldName] != null;
  }

  /// Prepare form for editing
  void prepareForEdit(WordWithStats word) {
    wordController.text = word.word;
    translationController.text = word.translation;
    exampleController.text = word.exampleSentence ?? '';
    _clearValidationErrors();

    AppHelpers.logUserAction('word_edit_prepared', {
      'word_id': word.id,
      'word': word.word,
    });
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    _searchQuery.value = '';

    AppHelpers.logUserAction('word_search_cleared');
  }

  /// Set category filter
  void setCategoryFilter(WordCategory? category) {
    _categoryFilter.value = category;

    AppHelpers.logUserAction('word_category_filter_set', {
      'category': category?.value,
    });
  }

  /// Toggle incomplete words filter
  void toggleIncompleteWordsFilter() {
    _showIncompleteWordsOnly.value = !_showIncompleteWordsOnly.value;

    AppHelpers.logUserAction('incomplete_words_filter_toggled', {
      'show_incomplete_only': _showIncompleteWordsOnly.value,
    });
  }

  /// Clear all filters
  void clearAllFilters() {
    clearSearch();
    _categoryFilter.value = null;
    _showIncompleteWordsOnly.value = false;

    AppHelpers.logUserAction('word_filters_cleared');
  }

  /// Get words by category
  List<WordWithStats> getWordsByCategory(WordCategory category) {
    return _words.where((word) => word.stats.categoryEnum == category).toList();
  }

  /// Get word statistics
  Map<String, dynamic> get wordStatistics {
    final notKnown = getWordsByCategory(WordCategory.notKnown).length;
    final normal = getWordsByCategory(WordCategory.normal).length;
    final strong = getWordsByCategory(WordCategory.strong).length;

    return {
      'total': _words.length,
      'complete': completeWordsCount,
      'incomplete': incompleteWordsCount,
      'not_known': notKnown,
      'normal': normal,
      'strong': strong,
    };
  }

  /// Navigate to word detail
  void navigateToWordDetail(int wordId) {
    Get.toNamed(AppRoutes.wordDetail, arguments: wordId);
    AppHelpers.logUserAction('navigate_to_word_detail', {
      'word_id': wordId,
    });
  }

  /// Navigate to add word
  void navigateToAddWord(int folderId) {
    _clearForm();
    Get.toNamed(AppRoutes.addWord, arguments: folderId);
    AppHelpers.logUserAction('navigate_to_add_word', {
      'folder_id': folderId,
    });
  }

  /// Navigate to OCR camera
  void navigateToOCRCamera(int folderId) {
    _ocrResults.clear();
    _selectedWords.clear();
    Get.toNamed(AppRoutes.ocrCamera, arguments: folderId);
    AppHelpers.logUserAction('navigate_to_ocr_camera', {
      'folder_id': folderId,
    });
  }

  /// Show word options menu
  void showWordOptionsMenu(WordWithStats word) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
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
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              word.translation,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Get.back();
                navigateToWordDetail(word.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Word'),
              onTap: () {
                Get.back();
                prepareForEdit(word);
                // Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Word'),
              onTap: () {
                Get.back();
                AppHelpers.copyToClipboard('${word.word} - ${word.translation}');
              },
            ),
            if (word.exampleSentence != null)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Example'),
                onTap: () {
                  Get.back();
                  AppHelpers.copyToClipboard(word.exampleSentence!);
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Word', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                deleteWord(word.id, word.word);
              },
            ),
          ],
        ),
      ),
    );
  }
}