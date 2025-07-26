// lib/app/views/scan_page.dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/scan_controller.dart';
import '../controllers/word_controller.dart';
import '../models/ocr_model.dart';
import '../utils/app_colors.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ScanController>();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Scan Text'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () {
            controller.resetScanState();
            Get.back();
          },
        ),
      ),
      child: SafeArea(
        child: Obx(() {
          switch (controller.currentStep.value) {
            case 'ready':
              return _buildInitialView(controller);
            case 'processing':
              return _buildProcessingView(controller);
            case 'selecting':
              return _buildWordSelectionView(controller);
            default:
              return _buildInitialView(controller);
          }
        }),
      ),
    );
  }

  /// Initial capture view
  Widget _buildInitialView(ScanController controller) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Title
          Text(
            'Scan Text from Image',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          Text(
            'Point your camera at text or choose from gallery to extract words',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  onTap: controller.openCamera,
                  icon: CupertinoIcons.camera_fill,
                  title: 'Camera',
                  subtitle: 'Take photo',
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildActionButton(
                  onTap: controller.openGallery,
                  icon: CupertinoIcons.photo_fill,
                  title: 'Gallery',
                  subtitle: 'Choose image',
                  color: CupertinoColors.systemPurple,
                ),
              ),
            ],
          ),

          const Spacer(),

          _buildInfoCard(),
        ],
      ),
    );
  }

  /// Processing view with loading animation
  Widget _buildProcessingView(ScanController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image preview
            if (controller.selectedImage.value != null)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const CupertinoActivityIndicator(radius: 16),
                  const SizedBox(height: 24),
                  Text(
                    'Processing Image',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    controller.processingStatus.value.isNotEmpty
                        ? controller.processingStatus.value
                        : 'Please wait...',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  )),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Using AI to extract and translate text...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Word selection view with wrap layout
  Widget _buildWordSelectionView(ScanController controller) {
    return Column(
      children: [
        // Header with image preview and controls
        Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Image preview
              if (controller.selectedImage.value != null)
                Container(
                  height: 100,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
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

              // Stats and controls
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Found ${controller.extractedWords.length} words',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Tap words to add them to your vocabulary',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    onPressed: () => controller.resetScanState(),
                    child: Text(
                      'Rescan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Words wrap layout
        Expanded(
          child: controller.extractedWords.isNotEmpty
              ? SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.extractedWords.map((word) {
                return _buildWordChip(word, controller);
              }).toList(),
            ),
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 64,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No words found in the image',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try taking another photo with clearer text',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Action button widget
  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
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
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.info_circle,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Best results with clear text on contrasting backgrounds. Supports JPG, PNG (max 5MB)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern word chip widget - compact and tap-friendly
  Widget _buildWordChip(ExtractedWord word, ScanController controller) {
    final isSelected = word.isSelected;

    return GestureDetector(
      onTap: () => _showAddWordDialog(word, controller),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.word,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show add word dialog - similar to the uploaded dialog
  void _showAddWordDialog(ExtractedWord word, ScanController scanController) {
    final wordController = Get.find<WordController>();

    // Clear the form first
    wordController.wordController.clear();
    wordController.translationController.clear();
    wordController.exampleController.clear();

    // Pre-fill the word
    wordController.wordController.text = word.word;

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add "${word.word}" to vocabulary',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // English word field (read-only)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'English word',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      word.word,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Translation field with translate button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Uzbek translation',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Obx(
                            () => GestureDetector(
                          onTap: wordController.isTranslating
                              ? null
                              : () => wordController.translateWord(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: wordController.isTranslating
                                ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                                : Text(
                              'Translate',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: wordController.translationController,
                    decoration: InputDecoration(
                      hintText: 'e.g., chiroyli',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Example sentence field with generate button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Example sentence (optional)',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Obx(
                            () => GestureDetector(
                          onTap: wordController.isGeneratingExample
                              ? null
                              : () => wordController.generateExampleSentence(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: wordController.isGeneratingExample
                                ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                                : Text(
                              'Generate',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: wordController.exampleController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g., She is very beautiful.',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                          () => GestureDetector(
                        onTap: wordController.isAdding
                            ? null
                            : () async {
                          await _addSingleWord(word, scanController);
                        },
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: wordController.isAdding
                                ? AppColors.primary.withOpacity(0.5)
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: wordController.isAdding
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                                : Text(
                              'Add word',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Text(
                "Zehnly can make mistakes. Check important info.",
                style: GoogleFonts.armata(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Add single word from dialog
  Future<void> _addSingleWord(ExtractedWord word, ScanController scanController) async {
    final wordController = Get.find<WordController>();

    try {
      // Get default folder ID
      int folderId = await scanController.getDefaultFolderId();

      // Mark word as selected in scan controller
      word.isSelected = true;
      scanController.extractedWords.refresh();

      // Add the word using word controller with folder ID
      await wordController.addWord(folderId);

      // Close dialog
      Get.back();

      // Show success message
      Get.snackbar(
        'Success',
        'Word "${word.word}" added to your vocabulary!',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add word: ${e.toString()}',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red.shade700,
      );
    }
  }
}