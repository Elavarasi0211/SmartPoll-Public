import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'api_service.dart';

class AdminFaceVerificationScreen extends StatefulWidget {
  const AdminFaceVerificationScreen({super.key});

  @override
  State<AdminFaceVerificationScreen> createState() =>
      _AdminFaceVerificationScreenState();
}

class _AdminFaceVerificationScreenState
    extends State<AdminFaceVerificationScreen> {
  CameraController? cameraController;

  bool cameraReady = false;
  bool verifying = false;
  bool verificationStarted = false;
  bool verificationSuccess = false;

  Timer? autoVerifyTimer;

  String statusMessage = 'Preparing admin face verification...';
  String similarityMessage = '';

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          statusMessage = 'No camera found.';
        });

        return;
      }

      CameraDescription selectedCamera;

      try {
        selectedCamera = cameras.firstWhere(
              (camera) =>
          camera.lensDirection == CameraLensDirection.front,
        );
      } catch (_) {
        selectedCamera = cameras.first;
      }

      cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await cameraController!.initialize();

      if (!mounted) return;

      setState(() {
        cameraReady = true;
        statusMessage = 'Look directly at the camera.';
      });

      await Future.delayed(
        const Duration(milliseconds: 1200),
      );

      if (!mounted) return;

      startAutomaticVerification();
    } catch (e) {
      debugPrint(
        'Camera initialization error: $e',
      );

      if (!mounted) return;

      setState(() {
        statusMessage = 'Unable to access camera.';
      });
    }
  }

  void startAutomaticVerification() {
    if (!cameraReady ||
        cameraController == null ||
        verificationStarted) {
      return;
    }

    verificationStarted = true;

    verifyAdminFace();
  }

  Future<void> verifyAdminFace() async {
    if (!cameraReady ||
        cameraController == null ||
        !cameraController!.value.isInitialized ||
        verificationSuccess) {
      return;
    }

    if (verifying) return;

    setState(() {
      verifying = true;
      statusMessage = 'Verifying admin face...';
      similarityMessage = '';
    });

    try {
      final XFile capturedImage =
      await cameraController!.takePicture();

      final result = await ApiService.verifyAdminFace(
        File(capturedImage.path),
      );

      if (!mounted) return;

      final bool verified =
          result['verified'] == true;

      double? similarity;

      if (result['similarity'] is num) {
        similarity =
            (result['similarity'] as num).toDouble();
      } else if (result['similarity_score'] is num) {
        similarity =
            (result['similarity_score'] as num).toDouble();
      }

      if (verified) {
        verificationSuccess = true;

        setState(() {
          verifying = false;
          statusMessage =
          'Admin face verified successfully.';

          similarityMessage = similarity != null
              ? 'Similarity: ${similarity.toStringAsFixed(4)}'
              : 'Face match confirmed.';
        });

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
            const AdminDashboardScreen(),
          ),
        );

        return;
      }

      setState(() {
        verifying = false;
        statusMessage =
        'Face not matched. Looking again...';

        similarityMessage = similarity != null
            ? 'Similarity: ${similarity.toStringAsFixed(4)}'
            : 'No matching admin face found.';
      });

      autoVerifyTimer?.cancel();

      autoVerifyTimer = Timer(
        const Duration(seconds: 2),
            () {
          if (!mounted ||
              verificationSuccess ||
              verifying) {
            return;
          }

          verifyAdminFace();
        },
      );
    } catch (e) {
      debugPrint(
        'Admin face verification error: $e',
      );

      if (!mounted) return;

      setState(() {
        verifying = false;
        statusMessage =
        'Verification error. Trying again...';
        similarityMessage = '';
      });

      autoVerifyTimer?.cancel();

      autoVerifyTimer = Timer(
        const Duration(seconds: 3),
            () {
          if (!mounted ||
              verificationSuccess ||
              verifying) {
            return;
          }

          verifyAdminFace();
        },
      );
    }
  }

  @override
  void dispose() {
    autoVerifyTimer?.cancel();
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          'Admin Face Verification',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    'Verify Admin Identity',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Live face verification is automatically '
                        'performed before opening the admin dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Container(
                    width: double.infinity,
                    height: 360,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF102A43),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: cameraReady &&
                        cameraController != null
                        ? CameraPreview(
                      cameraController!,
                    )
                        : const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: verifying
                          ? const Color(0xFF102A43)
                          : verificationSuccess
                          ? const Color(0xFF2E7D32)
                          : Colors.black87,
                    ),
                  ),

                  if (similarityMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      similarityMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFD5E2EE),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF102A43),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: verifying
                              ? const Padding(
                            padding: EdgeInsets.all(10),
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : Icon(
                            verificationSuccess
                                ? Icons.check_circle
                                : Icons.face,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                verifying
                                    ? 'Face verification in progress'
                                    : verificationSuccess
                                    ? 'Face verification successful'
                                    : 'Automatic face verification',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF102A43),
                                ),
                              ),

                              const SizedBox(height: 4),

                              const Text(
                                'InsightFace ML verification is '
                                    'performed automatically.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFF102A43),
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            'Keep your face clearly visible '
                                'and look directly at the camera. '
                                'The system will verify your face automatically.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 16,
                        color: Color(0xFF2E7D32),
                      ),

                      SizedBox(width: 6),

                      Text(
                        'Real ML biometric verification',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'SmartPoll • Admin Security',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}