import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/scan_controller.dart';
import '../controllers/folder_controller.dart';
import '../models/folder_model.dart';
import '../models/ocr_model.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScanController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Text'),
        backgroundColor: CupertinoColors.systemBackground,
        elevation: 0,
        actions: [
          Obx(() => controller.currentStep.value == 'selecting'
              ? CupertinoButton(
            child: const Icon(CupertinoIcons.refresh),
            onPressed: controller.resetScanState,
          )
              : const SizedBox.shrink()),
        ],
      ),
      body: Obx(() {
        switch (controller.currentStep.value) {
          case 'ready':
            return _buildInitialView(controller);
          case 'processing':
            return _buildProcessingView(controller);
          case 'selecting':
            return _buildWordSelectionView(controller);
          case 'adding':
            return _buildAddingWordsView();
          default:
            return _buildInitialView(controller);
        }
      }),
    );
  }

  /// Initial view with camera/gallery options
  Widget _buildInitialView(ScanController controller) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CupertinoColors.systemBackground,
            CupertinoColors.secondarySystemBackground,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hero icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.doc_text_viewfinder,
                  size: 80,
                  color: CupertinoColors.systemBlue,
                ),
              ),

              const SizedBox(height: 32),

              // Title and description
              const Text(
                'Extract Words from Images',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              const Text(
                'Take a photo or choose an image to extract English words with AI-powered translation to Uzbek',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Action buttons - DIRECT ACTIONS
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: CupertinoIcons.camera,
                      title: 'Take Photo',
                      subtitle: 'Use camera',
                      color: CupertinoColors.systemBlue,
                      onTap: controller.openCamera, // DIRECT CAMERA
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: CupertinoIcons.photo,
                      title: 'Choose Image',
                      subtitle: 'From gallery',
                      color: CupertinoColors.systemGreen,
                      onTap: controller.openGallery, // DIRECT GALLERY
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Info card
              _buildInfoCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// Processing view with progress indicator
  Widget _buildProcessingView(ScanController controller) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CupertinoColors.systemBackground,
            CupertinoColors.secondarySystemBackground,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Selected image preview
              if (controller.selectedImage.value != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      controller.selectedImage.value!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Loading animation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const CupertinoActivityIndicator(radius: 16),

                    const SizedBox(height: 24),

                    const Text(
                      'Processing Image',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Obx(() => Text(
                      controller.processingStatus.value.isNotEmpty
                          ? controller.processingStatus.value
                          : 'Please wait...',
                      style: const TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      textAlign: TextAlign.center,
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Using AI to extract and translate text...',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.tertiaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Word selection view
  Widget _buildWordSelectionView(ScanController controller) {
    return Column(
      children: [
        // Header with image preview and controls
        Container(
          color: CupertinoColors.secondarySystemBackground,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Image preview
                if (controller.selectedImage.value != null)
                  Container(
                    height: 120,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        controller.selectedImage.value!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Controls row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Found ${controller.extractedWords.length} words',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),

                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: controller.selectAllWords,
                      child: const Text('Select All'),
                    ),

                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: controller.deselectAllWords,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Words list
        Expanded(
          child: controller.extractedWords.isNotEmpty
              ? ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.extractedWords.length,
            itemBuilder: (context, index) {
              final word = controller.extractedWords[index];
              return _buildWordTile(word, controller);
            },
          )
              : const Center(
            child: Text(
              'No words found in the image',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 16,
              ),
            ),
          ),
        ),

        // Bottom action bar
        if (controller.selectedWords.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${controller.selectedWords.length} words selected',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label,
                          ),
                        ),
                        const Text(
                          'Choose a folder to add these words',
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),

                  CupertinoButton.filled(
                    onPressed: () => _showFolderSelection(controller),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.folder, size: 18),
                        SizedBox(width: 8),
                        Text('Add to Folder'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Adding words view
  Widget _buildAddingWordsView() {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(radius: 16),
            SizedBox(height: 24),
            Text(
              'Adding Words to Folder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please wait...',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Action button widget
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Info card widget
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemYellow.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: CupertinoColors.systemYellow,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Best results with clear text on contrasting backgrounds. Supports JPG, PNG (max 5MB)',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Word tile widget
  Widget _buildWordTile(ExtractedWord word, ScanController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: word.isSelected
              ? CupertinoColors.systemBlue
              : CupertinoColors.separator,
          width: word.isSelected ? 2 : 1,
        ),
        boxShadow: word.isSelected ? [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : [],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => controller.toggleWordSelection(word),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: word.isSelected
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.separator,
                    width: 2,
                  ),
                  color: word.isSelected
                      ? CupertinoColors.systemBlue
                      : CupertinoColors.systemBackground,
                ),
                child: word.isSelected
                    ? const Icon(
                  CupertinoIcons.check_mark,
                  color: CupertinoColors.white,
                  size: 14,
                )
                    : null,
              ),

              const SizedBox(width: 12),

              // Word content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      word.translation,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),

              // Confidence badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: controller.getConfidenceColor(word.confidence).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.getConfidenceText(word.confidence),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: controller.getConfidenceColor(word.confidence),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show folder selection dialog
  void _showFolderSelection(ScanController scanController) {
    Get.dialog(
      CupertinoAlertDialog(
        title: const Text('Select Folder'),
        content: SizedBox(
          width: double.maxFinite,
          child: _FolderSelectionWidget(scanController: scanController),
        ),
      ),
    );
  }
}

/// Folder Selection Widget
class _FolderSelectionWidget extends StatelessWidget {
  final ScanController scanController;

  const _FolderSelectionWidget({required this.scanController});

  @override
  Widget build(BuildContext context) {
    final folderController = Get.find<FolderController>();

    return Container(
      height: 300,
      child: Obx(() {
        if (folderController.isLoading) {
          return const Center(
            child: CupertinoActivityIndicator(),
          );
        }

        if (!folderController.hasFolders) {
          return const Center(
            child: Text(
              'No folders found.\nCreate a folder first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: folderController.folders.length,
          itemBuilder: (context, index) {
            final folder = folderController.folders[index];
            return CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.folder,
                    color: CupertinoColors.systemBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        Text(
                          '${folder.wordCount} words',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              onPressed: () {
                final targetFolder = Folder(
                  id: folder.id,
                  userId: 0,
                  name: folder.name,
                  description: folder.description,
                  wordCount: folder.wordCount,
                  createdAt: DateTime.parse(folder.createdAt),
                );

                scanController.setTargetFolder(targetFolder);
                Get.back(); // Close dialog
                scanController.addSelectedWords();
              },
            );
          },
        );
      }),
    );
  }
}