import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/voice_stream_controller.dart';
import '../models/voice_stream_model.dart';
import '../utils/app_colors.dart';

/// A page that displays either a list of available voice agents or, once
/// connected, an embedded ElevenLabs conversational AI widget. This
/// implementation adds error handling around the WebView to gracefully
/// handle cases where the platform WebView may not be registered or
/// supported. If the WebView fails to initialize, a fallback UI will
/// prompt the user to open the conversation externally.
class VoiceStreamPage extends StatelessWidget {
  const VoiceStreamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VoiceStreamController>(
      init: VoiceStreamController(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Obx(() {
              // Show agent selection when not connected
              if (controller.connectionStateRx.value !=
                  VoiceConnectionState.connected) {
                return _buildAgentSelection(controller);
              }
              // Show ElevenLabs widget when connected
              return _buildElevenLabsWidget(controller);
            }),
          ),
        );
      },
    );
  }

  Widget _buildAgentSelection(VoiceStreamController controller) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.mic,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Voice Chat',
                  style: GoogleFonts.armata(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Agent list or loading
        Expanded(
          child: Obx(() {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.agents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.voice_over_off,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No voice agents available',
                      style: GoogleFonts.armata(
                          fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: controller.refreshAgents,
                      child: Text('Refresh',
                          style: GoogleFonts.armata(
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.agents.length,
              itemBuilder: (context, index) {
                final agent = controller.agents[index];
                return _buildAgentCard(agent, controller);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAgentCard(VoiceAgent agent, VoiceStreamController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            agent.title[0].toUpperCase(),
            style: GoogleFonts.armata(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          agent.title,
          style: GoogleFonts.armata(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              agent.description,
              style: GoogleFonts.armata(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                agent.topic.toUpperCase(),
                style: GoogleFonts.armata(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'Connect',
            style: GoogleFonts.armata(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => controller.connectToAgent(agent),
      ),
    );
  }

  Widget _buildElevenLabsWidget(VoiceStreamController controller) {
    return Column(
      children: [
        // Header with close button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: controller.disconnect,
                color: AppColors.primary,
                iconSize: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.currentAgent?.title ?? 'Voice Chat',
                      style: GoogleFonts.armata(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'ElevenLabs ConvAI Active',
                      style: GoogleFonts.armata(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Connection indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connected',
                      style: GoogleFonts.armata(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ElevenLabs WebView or fallback
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _ElevenLabsWebView(
                agentId: controller.currentAgent?.agentId ?? '',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A stateful widget that tries to load the ElevenLabs ConvAI widget inside a
/// WebView. On some platforms (particularly iOS) the WebView plugin may not
/// be registered correctly. In that case, we catch the exception and
/// display a fallback UI instead of crashing the app. The fallback simply
/// informs the user that the widget failed to load and suggests trying
/// again later or updating the app.
class _ElevenLabsWebView extends StatefulWidget {
  final String agentId;

  const _ElevenLabsWebView({required this.agentId});

  @override
  State<_ElevenLabsWebView> createState() => _ElevenLabsWebViewState();
}

class _ElevenLabsWebViewState extends State<_ElevenLabsWebView> {
  WebViewController? _controller;
  bool _initializationFailed = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// Initializes the embedded WebView and attempts to load our
  /// conversational AI widget. The method is asynchronous so that
  /// exceptions thrown by `loadHtmlString` can be caught. Without awaiting
  /// the future returned by `loadHtmlString`, platform exceptions
  /// originating from native code may escape our try/catch and crash the
  /// app. If initialization fails for any reason, the `_initializationFailed`
  /// flag is set and a fallback UI will be shown instead of the WebView.
  Future<void> _initializeWebView() async {
    // Create HTML content with ElevenLabs ConvAI widget
    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                margin: 0;
                padding: 0;
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: #f8f9fa;
                display: flex;
                align-items: center;
                justify-content: center;
                min-height: 100vh;
            }
            .container {
                text-align: center;
                background: white;
                padding: 20px;
                border-radius: 16px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.1);
                max-width: 400px;
                width: 100%;
            }
            .title {
                font-size: 20px;
                font-weight: bold;
                color: #333;
                margin-bottom: 10px;
            }
            .subtitle {
                font-size: 14px;
                color: #666;
                margin-bottom: 20px;
            }
            elevenlabs-convai {
                width: 100%;
                height: 300px;
                border-radius: 12px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="title">Voice Conversation</div>
            <div class="subtitle">Click the widget below to start talking</div>
            <!-- ElevenLabs ConvAI Widget -->
            <elevenlabs-convai agent-id="${widget.agentId}"></elevenlabs-convai>
            <!-- Load ElevenLabs ConvAI Widget Script -->
            <script src="https://unpkg.com/@elevenlabs/convai-widget-embed" async type="text/javascript"></script>
        </div>
    </body>
    </html>
    ''';

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              // Allow all navigation for the widget
              return NavigationDecision.navigate;
            },
          ),
        );
      // Await the load operation to catch asynchronous errors thrown
      // by the native WebView implementation.
      await controller.loadHtmlString(htmlContent);
      setState(() {
        _controller = controller;
        _initializationFailed = false;
      });
    } catch (e) {
      // If instantiating the controller or loading the HTML fails (e.g. plugin
      // not registered), mark initialization as failed. The UI will display a
      // fallback.
      setState(() {
        _initializationFailed = true;
        _controller = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationFailed || _controller == null) {
      // When the WebView cannot be created, show a simple fallback message.
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Failed to load the voice chat widget. Please ensure the WebView plugin is properly configured or try again later.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.armata(fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return WebViewWidget(controller: _controller!);
  }
}