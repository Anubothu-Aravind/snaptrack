import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/camera_provider.dart';

class CameraWidget extends StatefulWidget {
  const CameraWidget({super.key});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CameraProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Initializing Camera...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (provider.cameraType == 'phone' && provider.controller != null) {
          return _buildPhoneCameraView(provider);
        } else if (provider.cameraType == 'ip') {
          return _buildIPCameraView(provider);
        }

        return const Center(
          child: Text(
            'No camera available',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      },
    );
  }

  Widget _buildPhoneCameraView(CameraProvider provider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: provider.controller!.value.previewSize?.height ?? 0,
          height: provider.controller!.value.previewSize?.width ?? 0,
          child: CameraPreview(provider.controller!),
        ),
      ),
    );
  }

  Widget _buildIPCameraView(CameraProvider provider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: provider.isRecording
          ? FutureBuilder<String>(
              future: provider.getVideoFeedUrl(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Error loading camera feed URL',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasData) {
                  return Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Cannot connect to camera feed',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(
                    child: Text(
                      'No camera URL available',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                }
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Camera feed stopped',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
    );
  }
}