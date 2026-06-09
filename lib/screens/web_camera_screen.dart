import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/web_camera_provider.dart';

class WebCameraScreen extends StatefulWidget {
  const WebCameraScreen({super.key});

  @override
  State<WebCameraScreen> createState() => _WebCameraScreenState();
}

class _WebCameraScreenState extends State<WebCameraScreen> {
  final String _viewType =
      'web-camera-view-${DateTime.now().millisecondsSinceEpoch}';

  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      Provider.of<WebCameraProvider>(context, listen: false).reset();
      _initializeCamera();
    });
  }

  Future<void> _initializeCamera() async {
    final cameraProvider =
        Provider.of<WebCameraProvider>(context, listen: false);

    try {
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '22px'
        ..style.backgroundColor = 'black';

      ui_web.platformViewRegistry.registerViewFactory(
        _viewType,
        (int viewId) => _videoElement!,
      );

      final mediaDevices = html.window.navigator.mediaDevices;

      if (mediaDevices == null) {
        cameraProvider.setError('Camera is not available in this browser.');
        return;
      }

      final stream = await mediaDevices.getUserMedia({
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 640},
        },
        'audio': false,
      });

      _mediaStream = stream;
      _videoElement!.srcObject = stream;

      await _videoElement!.play();

      if (!mounted) return;

      cameraProvider.setReady(true);
    } catch (_) {
      if (!mounted) return;

      cameraProvider.setError(
        'Could not open camera. Please allow camera permission in Chrome.',
      );
    }
  }

  Future<void> _capturePhoto() async {
    final cameraProvider =
        Provider.of<WebCameraProvider>(context, listen: false);

    final video = _videoElement;

    if (video == null || !cameraProvider.isCameraReady) return;

    final width = video.videoWidth > 0 ? video.videoWidth : 640;
    final height = video.videoHeight > 0 ? video.videoHeight : 640;

    final canvas = html.CanvasElement(width: width, height: height);
    final canvasContext = canvas.context2D;

    canvasContext.drawImageScaled(video, 0, 0, width, height);

    final dataUrl = canvas.toDataUrl('image/png');
    final base64Data = dataUrl.split(',').last;
    final bytes = Uint8List.fromList(base64Decode(base64Data));

    if (!mounted) return;

    Navigator.pop(context, bytes);
  }

  void _stopCamera() {
    final tracks = _mediaStream?.getTracks() ?? [];

    for (final track in tracks) {
      track.stop();
    }

    _videoElement?.srcObject = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<WebCameraProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 22,
            isMobile ? 16 : 22,
            isMobile ? 16 : 22,
            isMobile ? 18 : 22,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF0F172A),
                      const Color(0xFF1E1B4B),
                      const Color(0xFF312E81),
                    ]
                  : [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFEDE9FE),
                      const Color(0xFFFDF2F8),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              _header(isDark: isDark, isMobile: isMobile),
              SizedBox(height: isMobile ? 14 : 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 720),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
                    child: cameraProvider.errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 18 : 24),
                              child: Text(
                                cameraProvider.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                        : cameraProvider.isCameraReady
                            ? HtmlElementView(viewType: _viewType)
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 22),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SizedBox(
                  width: double.infinity,
                  height: isMobile ? 54 : 58,
                  child: ElevatedButton.icon(
                    onPressed: cameraProvider.isCameraReady
                        ? _capturePhoto
                        : null,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      'Capture Photo',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isMobile ? 15 : 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D5DFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 18 : 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header({
    required bool isDark,
    required bool isMobile,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 14 : 18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.82)
              : Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(isMobile ? 22 : 26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Take Profile Photo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 21 : 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
