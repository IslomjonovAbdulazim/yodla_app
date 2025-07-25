// lib/app/widgets/folder_card.dart - Fixed to work with FolderResponse model
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../models/folder_model.dart';
import '../utils/helpers.dart';

class FolderCard extends StatelessWidget {
  final FolderResponse folder;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FolderCard({
    super.key,
    required this.folder,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with folder icon and menu
              Row(
                children: [
                  // Folder icon with dynamic color
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Folder name and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: GoogleFonts.armata(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (folder.description?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            folder.description!,
                            style: GoogleFonts.armata(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Menu button
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Edit',
                              style: GoogleFonts.armata(),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: GoogleFonts.armata(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Statistics row
              Row(
                children: [
                  // Word count
                  _buildStatItem(
                    icon: Icons.book,
                    label: 'Words',
                    value: '${folder.wordCount}',
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 24),

                  // Creation date
                  _buildStatItem(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    value: _getFormattedDate(),
                    color: AppColors.textSecondary,
                  ),

                  const Spacer(),

                  // Quick action buttons
                  Row(
                    children: [
                      // Add words button
                      _buildActionButton(
                        icon: Icons.add,
                        tooltip: 'Add Words',
                        color: AppColors.success,
                        onTap: () {
                          _showSnackbar('Add words to ${folder.name}');
                        },
                      ),

                      const SizedBox(width: 8),

                      // Start quiz button (only if enough words)
                      if (folder.wordCount >= 5)
                        _buildActionButton(
                          icon: Icons.quiz,
                          tooltip: 'Start Quiz',
                          color: Colors.orange,
                          onTap: () {
                            _showSnackbar('Starting quiz for ${folder.name}');
                          },
                        ),
                    ],
                  ),
                ],
              ),

              // Quiz eligibility indicator
              if (folder.wordCount > 0) ...[
                const SizedBox(height: 12),
                _buildQuizEligibilityIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.armata(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.armata(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildQuizEligibilityIndicator() {
    final canQuiz = folder.wordCount >= 5; // AppConstants.minWordsForQuiz

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (canQuiz ? AppColors.success : AppColors.warning).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            canQuiz ? Icons.check_circle : Icons.info,
            size: 16,
            color: canQuiz ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 6),
          Text(
            canQuiz
                ? 'Quiz Ready'
                : 'Need ${5 - folder.wordCount} more words for quiz',
            style: GoogleFonts.armata(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: canQuiz ? AppColors.success : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    try {
      final date = DateTime.parse(folder.createdAt);
      return AppHelpers.formatRelativeTime(date);
    } catch (e) {
      return 'Recently';
    }
  }

  void _showSnackbar(String message) {
    // Simple print for now - in real app this would show a proper snackbar
    print(message);
  }
}