import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/app_colors.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom App Bar with user greeting
                _buildAppBar(),

                const SizedBox(height: 24),

                // Welcome Section
                _buildWelcomeSection(),

                const SizedBox(height: 24),

                // Stats Cards
                _buildStatsSection(),

                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActionsSection(),

                const SizedBox(height: 24),

                // Recent Folders
                _buildRecentFoldersSection(),

                const SizedBox(height: 24),

                // Learning Progress
                _buildLearningProgressSection(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAppBar() {
    final authController = Get.find<AuthController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // User Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.person, size: 20, color: AppColors.primary),
          ),

          const SizedBox(width: 12),

          // User greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                Obx(
                      () => Text(
                    authController.currentUser?.nickname ?? 'Learner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notifications button
          IconButton(
            onPressed: () {
              // TODO: Navigate to notifications
            },
            icon: Icon(
              Icons.notifications_outlined,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),

          // Profile button
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.profile),
            icon: Icon(
              Icons.settings_outlined,
              size: 24,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to learn?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Continue your English vocabulary journey',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: () => Get.toNamed(AppRoutes.folders),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Start Learning',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.school_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Obx(
                () => Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Words',
                    value:
                    controller.userStats.value?.totalWords.toString() ??
                        '0',
                    icon: Icons.book_outlined,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildStatCard(
                    title: 'Folders',
                    value:
                    controller.userStats.value?.totalFolders.toString() ??
                        '0',
                    icon: Icons.folder_outlined,
                    color: AppColors.secondary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _buildStatCard(
                    title: 'Quizzes',
                    value:
                    controller.userStats.value?.totalQuizzes.toString() ??
                        '0',
                    icon: Icons.quiz_outlined,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.add,
                  title: 'New Folder',
                  subtitle: 'Create folder',
                  onTap: () => Get.toNamed(AppRoutes.createFolder),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.camera_alt_outlined,
                  title: 'Scan Text',
                  subtitle: 'Add words with OCR',
                  onTap: () {
                    // Need to select folder first
                    _showFolderSelectionForOCR();
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.quiz_outlined,
                  title: 'Take Quiz',
                  subtitle: 'Test your knowledge',
                  onTap: () {
                    // Show quiz options
                    _showQuizOptions();
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.mic_outlined,
                  title: 'Voice Chat',
                  subtitle: 'Practice speaking',
                  onTap: () => Get.toNamed(AppRoutes.voiceAgents),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFoldersSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Folders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.folders),
                child: Text(
                  'View All',
                  style: TextStyle(fontSize: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recent folders will be loaded by HomeController
          Obx(() {
            if (controller.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (controller.recentFolders.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.recentFolders.length,
              itemBuilder: (context, index) {
                final folder = controller.recentFolders[index];
                return _buildFolderCard(folder);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFolderCard(dynamic folder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder, size: 20, color: AppColors.secondary),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder.name ?? 'Untitled Folder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                if (folder.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    folder.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 4),

                Text(
                  '${folder.wordCount ?? 0} words',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.folder_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),

          const SizedBox(height: 16),

          Text(
            'No folders yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Create your first folder to start organizing vocabulary',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () => Get.toNamed(AppRoutes.createFolder),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text('Create Folder', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningProgressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Weekly Goal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    Text(
                      '12 / 20 words',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                LinearProgressIndicator(
                  value: 0.6, // 12/20 = 0.6
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 8,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.orange,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      '5 day streak',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '60% progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () {},
              ),

              _buildNavItem(
                icon: Icons.folder,
                label: 'Folders',
                isActive: false,
                onTap: () => Get.toNamed(AppRoutes.folders),
              ),

              _buildNavItem(
                icon: Icons.quiz,
                label: 'Quiz',
                isActive: false,
                onTap: () => _showQuizOptions(),
              ),

              _buildNavItem(
                icon: Icons.mic,
                label: 'Voice',
                isActive: false,
                onTap: () => Get.toNamed(AppRoutes.voiceAgents),
              ),

              _buildNavItem(
                icon: Icons.person,
                label: 'Profile',
                isActive: false,
                onTap: () => Get.toNamed(AppRoutes.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showFolderSelectionForOCR() {
    // TODO: Show folder selection bottom sheet
    Get.snackbar(
      'Select Folder',
      'Please create a folder first to add words with OCR',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showQuizOptions() {
    // TODO: Show quiz options bottom sheet
    Get.snackbar(
      'Quiz Options',
      'Please create folders with words first to take quizzes',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}