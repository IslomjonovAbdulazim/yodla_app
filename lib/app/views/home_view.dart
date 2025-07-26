// lib/app/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:yodla_app/app/views/folders_page.dart';

import '../controllers/voice_stream_controller.dart';
import '../utils/app_colors.dart';
import '../widgets/speak_page.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const SpeakPage(),

    Center(
      child: Text(
        'Create Page',
        style: GoogleFonts.armata(fontSize: 24, color: Color(0xFF7AB2D3)),
      ),
    ),

    FoldersPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Load voice agents when Speak tab is selected
          if (index == 0) {
            _loadVoiceAgentsIfNeeded();
          }
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF7AB2D3),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.armata(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.armata(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Speak',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy),
            label: 'Folders',
          ),
        ],
      ),
    );
  }

  void _loadVoiceAgentsIfNeeded() {
    try {
      // Use the new VoiceStreamController
      final voiceController = Get.find<VoiceStreamController>();

      // Load agents if not already loaded
      if (voiceController.agents.isEmpty && !voiceController.isLoading) {
        voiceController.loadAgents();
      }
    } catch (e) {
      print('Error loading voice agents: $e');
      // Handle case where VoiceStreamController is not available
      Get.snackbar(
        'Error',
        'Voice features are not available. Please restart the app.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}