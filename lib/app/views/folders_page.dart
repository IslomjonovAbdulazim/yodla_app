// lib/app/views/folders_page.dart - Optimized Beautiful & Minimalist Design
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/folder_controller.dart';
import '../models/folder_model.dart';
import '../utils/app_colors.dart';

// Constants for consistent styling
class _FoldersPageConstants {
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(24, 16, 24, 8);
  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(24, 8, 24, 100);
  static const EdgeInsets emptyStatePadding = EdgeInsets.all(48);
  static const EdgeInsets dialogPadding = EdgeInsets.all(24);
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 12.0;
  static const double iconSize = 20.0;
  static const double fabIconSize = 28.0;
  static const double headerButtonSize = 40.0;
  static const double menuButtonSize = 32.0;
  static const int maxTitleLines = 1;
}

class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});

  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  late final FolderController controller;
  final Map<String, String> _timeAgoCache = {};

  @override
  void initState() {
    super.initState();
    controller = Get.put(FolderController());
  }

  @override
  void dispose() {
    _timeAgoCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _MinimalHeader(controller: controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading) {
                  return const _LoadingState();
                }

                if (!controller.hasFolders) {
                  return _EmptyState(onCreateFolder: _showCreateFolderDialog);
                }

                return _FoldersList(
                  controller: controller,
                  onFolderTap: controller.navigateToFolderDetail,
                  onFolderMenu: _showFolderMenu,
                  timeAgoCache: _timeAgoCache,
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: _OptimizedFAB(onPressed: _showCreateFolderDialog),
    );
  }

  void _showCreateFolderDialog() {
    controller.nameController.clear();
    controller.descriptionController.clear(); // Clear but don't show
    _showFolderDialog('Create folder', 'Create', () async {
      // Force close dialog if it's still open (backup safety)
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      await controller.createFolder();


    });
  }

  void _showEditFolderDialog(FolderResponse folder) {
    controller.prepareForEdit(folder);
    _showFolderDialog('Edit folder', 'Save', () async {
      // Force close dialog if it's still open (backup safety)
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Call updateFolder and wait for completion
      await controller.updateFolder(folder.id);


    });
  }

  void _showFolderDialog(
    String title,
    String submitText,
    Future<void> Function() onSubmit,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FolderDialog(
        title: title,
        submitText: submitText,
        controller: controller,
        onSubmit: onSubmit,
      ),
    );
  }

  void _showFolderMenu(FolderResponse folder) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FolderMenuSheet(
        onEdit: () => _showEditFolderDialog(folder),
        onDelete: () => controller.deleteFolder(folder.id, folder.name),
      ),
    );
  }
}

// Extracted Widgets for Better Performance
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class _MinimalHeader extends StatelessWidget {
  final FolderController controller;

  const _MinimalHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _FoldersPageConstants.headerPadding,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Folders',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                Obx(
                  () => Text(
                    controller.hasFolders
                        ? '${controller.foldersCount} folders'
                        : 'No folders yet',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => controller.hasFolders
                ? _HeaderButton(
                    icon: Icons.refresh_rounded,
                    onTap: controller.refreshFolders,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _FoldersPageConstants.headerButtonSize,
        height: _FoldersPageConstants.headerButtonSize,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            _FoldersPageConstants.buttonBorderRadius,
          ),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(
          icon,
          size: _FoldersPageConstants.iconSize,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _OptimizedFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const _OptimizedFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          _FoldersPageConstants.cardBorderRadius,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            _FoldersPageConstants.cardBorderRadius,
          ),
        ),
        child: const Icon(
          Icons.add_rounded,
          size: _FoldersPageConstants.fabIconSize,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateFolder;

  const _EmptyState({required this.onCreateFolder});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: _FoldersPageConstants.emptyStatePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 40,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No folders yet',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first folder to organize\nyour vocabulary by topics',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _CreateButton(text: 'Create folder', onTap: onCreateFolder),
          ],
        ),
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _CreateButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(
            _FoldersPageConstants.buttonBorderRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FoldersList extends StatelessWidget {
  final FolderController controller;
  final Function(int) onFolderTap;
  final Function(FolderResponse) onFolderMenu;
  final Map<String, String> timeAgoCache;

  const _FoldersList({
    required this.controller,
    required this.onFolderTap,
    required this.onFolderMenu,
    required this.timeAgoCache,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => controller.refreshFolders(),
      color: AppColors.primary,
      child: ListView.separated(
        padding: _FoldersPageConstants.listPadding,
        itemCount: controller.folders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final folder = controller.folders[index];
          return _OptimizedFolderCard(
            folder: folder,
            onTap: () => onFolderTap(folder.id),
            onMenu: () => onFolderMenu(folder),
            timeAgo: _getCachedTimeAgo(folder.createdAt),
          );
        },
      ),
    );
  }

  String _getCachedTimeAgo(String dateString) {
    // Cache time calculations to avoid recalculating on every rebuild
    if (!timeAgoCache.containsKey(dateString)) {
      timeAgoCache[dateString] = _calculateTimeAgo(dateString);
    }
    return timeAgoCache[dateString]!;
  }

  String _calculateTimeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return 'now';
      }
    } catch (e) {
      return 'recently';
    }
  }
}

class _OptimizedFolderCard extends StatelessWidget {
  final FolderResponse folder;
  final VoidCallback onTap;
  final VoidCallback onMenu;
  final String timeAgo;

  const _OptimizedFolderCard({
    required this.folder,
    required this.onTap,
    required this.onMenu,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(
            _FoldersPageConstants.cardBorderRadius,
          ),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FolderCardHeader(folder: folder, onMenu: onMenu),
            const SizedBox(height: 16),
            _FolderCardStats(folder: folder, timeAgo: timeAgo),
          ],
        ),
      ),
    );
  }
}

class _FolderCardHeader extends StatelessWidget {
  final FolderResponse folder;
  final VoidCallback onMenu;

  const _FolderCardHeader({required this.folder, required this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.folder_rounded,
            size: _FoldersPageConstants.iconSize,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            folder.name,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: _FoldersPageConstants.maxTitleLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _MenuButton(onTap: onMenu),
      ],
    );
  }
}

class _MenuButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MenuButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _FoldersPageConstants.menuButtonSize,
        height: _FoldersPageConstants.menuButtonSize,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _FolderCardStats extends StatelessWidget {
  final FolderResponse folder;
  final String timeAgo;

  const _FolderCardStats({required this.folder, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          value: '${folder.wordCount}',
          label: 'words',
          color: folder.wordCount >= 5 ? AppColors.success : AppColors.warning,
        ),
        const SizedBox(width: 20),
        _StatItem(
          value: timeAgo,
          label: 'created',
          color: AppColors.textSecondary,
        ),
        const Spacer(),
        if (folder.wordCount >= 5) const _QuizBadge(),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _QuizBadge extends StatelessWidget {
  const _QuizBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Quiz ready',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.success,
        ),
      ),
    );
  }
}

class _FolderMenuSheet extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _FolderMenuSheet({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          InkWell(
            onTap: () {
              Get.back();
              onEdit();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_rounded,
                    size: _FoldersPageConstants.iconSize,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Edit',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Get.back();
              onDelete();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_rounded,
                    size: _FoldersPageConstants.iconSize,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Delete',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: _FoldersPageConstants.iconSize,
              color: isDestructive ? Colors.red : AppColors.textPrimary,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderDialog extends StatelessWidget {
  final String title;
  final String submitText;
  final FolderController controller;
  final Future<void> Function() onSubmit;

  const _FolderDialog({
    required this.title,
    required this.submitText,
    required this.controller,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: _FoldersPageConstants.dialogPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _CustomTextField(
              controller: controller.nameController,
              label: 'Folder name',
              hint: 'e.g., Business English',
            ),
            const SizedBox(height: 24),
            _DialogActions(
              controller: controller,
              submitText: submitText,
              onSubmit: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _FoldersPageConstants.buttonBorderRadius,
              ),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _FoldersPageConstants.buttonBorderRadius,
              ),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _DialogActions extends StatelessWidget {
  final FolderController controller;
  final String submitText;
  final Future<void> Function() onSubmit;

  const _DialogActions({
    required this.controller,
    required this.submitText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(
                  _FoldersPageConstants.buttonBorderRadius,
                ),
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
            () => _DialogButton(
              text: submitText,
              onTap: controller.isCreating || controller.isUpdating
                  ? null
                  : () async {
                      await onSubmit();
                    },
              isPrimary: true,
              isLoading: controller.isCreating || controller.isUpdating,
            ),
          ),
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String text;
  final Future<void> Function()? onTap;
  final bool isPrimary;
  final bool isLoading;

  const _DialogButton({
    required this.text,
    required this.onTap,
    required this.isPrimary,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null && !isLoading
          ? () async {
              await onTap!();
            }
          : null,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary
              ? (isLoading || onTap == null
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.primary)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(
            _FoldersPageConstants.buttonBorderRadius,
          ),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                    color: isPrimary ? Colors.white : AppColors.textSecondary,
                  ),
                ),
        ),
      ),
    );
  }
}
