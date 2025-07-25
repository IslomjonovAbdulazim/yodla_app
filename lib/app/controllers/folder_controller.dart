import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/api_response_model.dart';
import '../models/folder_model.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/validators.dart';

class FolderController extends GetxController with FormValidationMixin {
  late ApiService _apiService;

  // Observable states
  final RxBool _isLoading = false.obs;
  final RxBool _isCreating = false.obs;
  final RxBool _isUpdating = false.obs;
  final RxBool _isDeleting = false.obs;
  final RxList<FolderResponse> _folders = <FolderResponse>[].obs;
  final Rx<FolderDetailResponse?> _currentFolderDetail = Rx<FolderDetailResponse?>(null);

  // Form controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Form validation
  final RxMap<String, String?> _validationErrors = <String, String?>{}.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isCreating => _isCreating.value;
  bool get isUpdating => _isUpdating.value;
  bool get isDeleting => _isDeleting.value;
  List<FolderResponse> get folders => _folders.toList();
  FolderDetailResponse? get currentFolderDetail => _currentFolderDetail.value;
  Map<String, String?> get validationErrors => _validationErrors;
  int get foldersCount => _folders.length;
  bool get hasFolders => _folders.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    loadFolders();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Load all folders
  Future<void> loadFolders() async {
    try {
      _isLoading.value = true;

      AppHelpers.logUserAction('load_folders_attempt');

      final response = await _apiService.get<FolderListResponse>(
        ApiEndpoints.folders,
        fromJson: (json) => FolderListResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        _folders.assignAll(response.data!.folders);

        AppHelpers.logUserAction('load_folders_success', {
          'folder_count': _folders.length,
        });
      } else {
        AppHelpers.logUserAction('load_folders_failed', {
          'error': response.error,
        });

        if (response.statusCode != 401) {
          AppHelpers.showErrorSnackbar(
            response.error ?? 'Failed to load folders',
            title: 'Load Error',
          );
        }
      }
    } catch (e) {
      AppHelpers.logUserAction('load_folders_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while loading folders',
        title: 'Load Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Create new folder
  Future<void> createFolder() async {
    try {
      if (_isCreating.value) return;

      // Validate form
      if (!_validateFolderForm()) {
        return;
      }

      _isCreating.value = true;
      _clearValidationErrors();

      final request = CreateFolderRequest(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      AppHelpers.logUserAction('create_folder_attempt', {
        'folder_name': request.name,
        'has_description': request.description != null,
      });

      final response = await _apiService.post<FolderResponse>(
        ApiEndpoints.folders,
        data: request.toJson(),
        fromJson: (json) => FolderResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Add to local list
        _folders.insert(0, response.data!);

        AppHelpers.logUserAction('create_folder_success', {
          'folder_id': response.data!.id,
          'folder_name': response.data!.name,
        });


        // Clear form and go back
        _clearForm();
        Get.back();
      } else {
        AppHelpers.logUserAction('create_folder_failed', {
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to create folder',
          title: 'Create Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('create_folder_exception', {
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while creating folder',
        title: 'Create Error',
      );
    } finally {
      _isCreating.value = false;
    }
  }

  /// Load folder details
  Future<void> loadFolderDetail(int folderId) async {
    try {
      _isLoading.value = true;

      AppHelpers.logUserAction('load_folder_detail_attempt', {
        'folder_id': folderId,
      });

      final response = await _apiService.get<FolderDetailResponse>(
        ApiEndpoints.folderDetail(folderId),
        fromJson: (json) => FolderDetailResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        _currentFolderDetail.value = response.data!;

        AppHelpers.logUserAction('load_folder_detail_success', {
          'folder_id': folderId,
          'word_count': response.data!.words.length,
        });
      } else {
        AppHelpers.logUserAction('load_folder_detail_failed', {
          'folder_id': folderId,
          'error': response.error,
        });

        if (response.statusCode == 404) {
          AppHelpers.showErrorSnackbar(
            'Folder not found',
            title: 'Not Found',
          );
          Get.back();
        } else if (response.statusCode != 401) {
          AppHelpers.showErrorSnackbar(
            response.error ?? 'Failed to load folder details',
            title: 'Load Error',
          );
        }
      }
    } catch (e) {
      AppHelpers.logUserAction('load_folder_detail_exception', {
        'folder_id': folderId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while loading folder details',
        title: 'Load Error',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update folder
  Future<void> updateFolder(int folderId) async {
    try {
      if (_isUpdating.value) return;

      // Validate form
      if (!_validateFolderForm()) {
        return;
      }

      _isUpdating.value = true;
      _clearValidationErrors();

      final request = UpdateFolderRequest(
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
      );

      AppHelpers.logUserAction('update_folder_attempt', {
        'folder_id': folderId,
        'new_name': request.name,
        'has_description': request.description != null,
      });

      final response = await _apiService.put<FolderResponse>(
        ApiEndpoints.updateFolder(folderId),
        data: request.toJson(),
        fromJson: (json) => FolderResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Update in local list
        final index = _folders.indexWhere((folder) => folder.id == folderId);
        if (index != -1) {
          _folders[index] = response.data!;
        }

        // Update current folder detail if it's the same folder
        if (_currentFolderDetail.value?.folder.id == folderId) {
          _currentFolderDetail.value = _currentFolderDetail.value!.copyWith(
            folder: FolderInfo(
              id: response.data!.id,
              name: response.data!.name,
              description: response.data!.description,
              wordCount: response.data!.wordCount,
              createdAt: response.data!.createdAt,
            ),
          );
        }

        AppHelpers.logUserAction('update_folder_success', {
          'folder_id': folderId,
          'new_name': response.data!.name,
        });

        // Clear form and go back
        _clearForm();
        Get.back();
      } else {
        AppHelpers.logUserAction('update_folder_failed', {
          'folder_id': folderId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to update folder',
          title: 'Update Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('update_folder_exception', {
        'folder_id': folderId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while updating folder',
        title: 'Update Error',
      );
    } finally {
      _isUpdating.value = false;
    }
  }

  /// Delete folder
  Future<void> deleteFolder(int folderId, String folderName) async {
    try {
      // Show confirmation dialog
      final confirmed = await AppHelpers.showConfirmationDialog(
        title: 'Delete Folder',
        message: 'Are you sure you want to delete "$folderName"? This will also delete all words in this folder. This action cannot be undone.',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        confirmColor: Colors.red,
      );

      if (!confirmed) return;

      _isDeleting.value = true;

      AppHelpers.logUserAction('delete_folder_attempt', {
        'folder_id': folderId,
        'folder_name': folderName,
      });

      final response = await _apiService.delete<DeleteFolderResponse>(
        ApiEndpoints.deleteFolder(folderId),
        fromJson: (json) => DeleteFolderResponse.fromJson(json),
      );

      if (response.success && response.data != null) {
        // Remove from local list
        _folders.removeWhere((folder) => folder.id == folderId);

        // Clear current folder detail if it's the same folder
        if (_currentFolderDetail.value?.folder.id == folderId) {
          _currentFolderDetail.value = null;
        }

        AppHelpers.logUserAction('delete_folder_success', {
          'folder_id': folderId,
          'deleted_words': response.data!.deletedWordsCount,
        });

        // Go back if we're on folder detail page
        if (Get.currentRoute.contains('folder-detail')) {
          Get.back();
        }
      } else {
        AppHelpers.logUserAction('delete_folder_failed', {
          'folder_id': folderId,
          'error': response.error,
        });

        AppHelpers.showErrorSnackbar(
          response.error ?? 'Failed to delete folder',
          title: 'Delete Failed',
        );
      }
    } catch (e) {
      AppHelpers.logUserAction('delete_folder_exception', {
        'folder_id': folderId,
        'error': e.toString(),
      });

      AppHelpers.showErrorSnackbar(
        'An unexpected error occurred while deleting folder',
        title: 'Delete Error',
      );
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Refresh folders list
  Future<void> refreshFolders() async {
    await loadFolders();

    AppHelpers.logUserAction('folders_refreshed');

  }

  /// Validate folder form
  bool _validateFolderForm() {
    final errors = validateFields({
      'name': CommonValidators.folderName,
      'description': [Validators.folderDescription],
    }, {
      'name': nameController.text,
      'description': descriptionController.text,
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
    nameController.clear();
    descriptionController.clear();
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
  void prepareForEdit(FolderResponse folder) {
    nameController.text = folder.name;
    descriptionController.text = folder.description ?? '';
    _clearValidationErrors();

    AppHelpers.logUserAction('folder_edit_prepared', {
      'folder_id': folder.id,
      'folder_name': folder.name,
    });
  }

  /// Check if folder can start quiz
  bool canStartQuiz(FolderResponse folder) {
    return folder.wordCount >= AppConstants.minWordsForQuiz;
  }

  /// Check if folder can start reading comprehension
  bool canStartReading(FolderResponse folder) {
    return folder.wordCount >= AppConstants.minWordsForReading;
  }

  /// Get folder by ID
  FolderResponse? getFolderById(int folderId) {
    try {
      return _folders.firstWhere((folder) => folder.id == folderId);
    } catch (e) {
      return null;
    }
  }

  /// Get folders sorted by name
  List<FolderResponse> get foldersSortedByName {
    final sorted = List<FolderResponse>.from(_folders);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  /// Get folders sorted by word count
  List<FolderResponse> get foldersSortedByWordCount {
    final sorted = List<FolderResponse>.from(_folders);
    sorted.sort((a, b) => b.wordCount.compareTo(a.wordCount));
    return sorted;
  }

  /// Get folders sorted by creation date
  List<FolderResponse> get foldersSortedByDate {
    final sorted = List<FolderResponse>.from(_folders);
    sorted.sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
    return sorted;
  }

  /// Search folders by name
  List<FolderResponse> searchFolders(String query) {
    if (query.isEmpty) return _folders;

    final lowercaseQuery = query.toLowerCase();
    return _folders.where((folder) {
      return folder.name.toLowerCase().contains(lowercaseQuery) ||
          (folder.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Get total words across all folders
  int get totalWordsInAllFolders {
    return _folders.fold(0, (sum, folder) => sum + folder.wordCount);
  }

  /// Get average words per folder
  double get averageWordsPerFolder {
    if (_folders.isEmpty) return 0.0;
    return totalWordsInAllFolders / _folders.length;
  }

  /// Get folders with no words
  List<FolderResponse> get emptyFolders {
    return _folders.where((folder) => folder.wordCount == 0).toList();
  }

  /// Get folders ready for quiz
  List<FolderResponse> get foldersReadyForQuiz {
    return _folders.where((folder) => canStartQuiz(folder)).toList();
  }

  /// Get folders ready for reading
  List<FolderResponse> get foldersReadyForReading {
    return _folders.where((folder) => canStartReading(folder)).toList();
  }

  /// Show folder options menu
  void showFolderOptionsMenu(FolderResponse folder) {
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
              folder.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.folderDetail, arguments: folder.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Folder'),
              onTap: () {
                Get.back();
                prepareForEdit(folder);
                Get.toNamed(AppRoutes.createFolder, arguments: {'edit': true, 'folderId': folder.id});
              },
            ),
            if (canStartQuiz(folder))
              ListTile(
                leading: const Icon(Icons.quiz),
                title: const Text('Start Quiz'),
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.quizHome, arguments: folder.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Words'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.addWord, arguments: folder.id);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Folder', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                deleteFolder(folder.id, folder.name);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to folder detail
  void navigateToFolderDetail(int folderId) {
    Get.toNamed(AppRoutes.folderDetail, arguments: folderId);
    AppHelpers.logUserAction('navigate_to_folder_detail', {
      'folder_id': folderId,
    });
  }

  /// Navigate to create folder
  void navigateToCreateFolder() {
    _clearForm();
    Get.toNamed(AppRoutes.createFolder);
    AppHelpers.logUserAction('navigate_to_create_folder');
  }

  /// Show folder statistics
  void showFolderStatistics() {
    Get.dialog(
      AlertDialog(
        title: const Text('Folder Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Folders: ${_folders.length}'),
            Text('Total Words: $totalWordsInAllFolders'),
            Text('Average Words per Folder: ${averageWordsPerFolder.toStringAsFixed(1)}'),
            Text('Empty Folders: ${emptyFolders.length}'),
            Text('Quiz-ready Folders: ${foldersReadyForQuiz.length}'),
            Text('Reading-ready Folders: ${foldersReadyForReading.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get folder creation date
  String getFolderCreationDate(FolderResponse folder) {
    try {
      final date = DateTime.parse(folder.createdAt);
      return AppHelpers.formatRelativeTime(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Check if folder name already exists
  bool doesFolderNameExist(String name, {int? excludeFolderId}) {
    return _folders.any((folder) =>
    folder.name.toLowerCase() == name.toLowerCase() &&
        (excludeFolderId == null || folder.id != excludeFolderId));
  }
}

extension FolderDetailResponseExtension on FolderDetailResponse {
  FolderDetailResponse copyWith({
    FolderInfo? folder,
    List<WordWithStats>? words,
  }) {
    return FolderDetailResponse(
      folder: folder ?? this.folder,
      words: words ?? this.words,
    );
  }
}