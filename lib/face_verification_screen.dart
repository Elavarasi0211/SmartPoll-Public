import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'confirm_vote_screen.dart';
import 'voter_profile_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  final String voterId;
  final String voterName;

  // Candidate details are null during voter login verification.
  final int? candidateId;
  final String? candidateName;
  final String? partyName;
  final String? candidateSymbol;

  const FaceVerificationScreen({
    super.key,
    required this.voterId,
    required this.voterName,
    this.candidateId,
    this.candidateName,
    this.partyName,
    this.candidateSymbol,
  });

  @override
  State<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends State<FaceVerificationScreen> {
  CameraController? _cameraController;

  bool _isCameraReady = false;
  bool _isVerifying = false;
  bool _hasCaptured = false;

  String _statusMessage = 'Preparing camera...';
  double? _similarity;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // =====================================================
  // INITIALIZE CAMERA
  // =====================================================

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (!mounted) return;

        setState(() {
          _statusMessage = 'Camera not available.';
        });

        return;
      }

      CameraDescription frontCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
        _statusMessage =
        'Look directly at the camera and keep your face clearly visible.';
      });

      // Give the camera a short time to stabilize.
      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (mounted && !_hasCaptured) {
        await _captureAndVerify();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _statusMessage =
        'Unable to start camera. Please try again.';
      });
    }
  }

  // =====================================================
  // LIVE FACE CAPTURE + REAL ML VERIFICATION
  // =====================================================

  Future<void> _captureAndVerify() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isVerifying ||
        _hasCaptured) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _hasCaptured = true;
      _statusMessage =
      'Verifying your face using secure face recognition...';
      _similarity = null;
    });

    try {
      // -------------------------------------------------
      // LIVE CAMERA CAPTURE
      // -------------------------------------------------

      final XFile capturedImage =
      await _cameraController!.takePicture();

      // -------------------------------------------------
      // REAL BACKEND FACE VERIFICATION
      // -------------------------------------------------

      final result = await ApiService.verifyFace(
        File(capturedImage.path),
        widget.voterId,
      );

      if (!mounted) return;

      // -------------------------------------------------
      // GET SIMILARITY
      // -------------------------------------------------

      final dynamic similarityValue =
      result['similarity_score'];

      double? similarity;

      if (similarityValue != null) {
        similarity = double.tryParse(
          similarityValue.toString(),
        );
      }

      setState(() {
        _similarity = similarity;
      });

      // =================================================
      // MATCH RESULT
      //
      // Backend may return:
      //
      // verified: true
      //
      // OR:
      //
      // result: "MATCH"
      //
      // OR:
      //
      // match: "MATCH"
      //
      // We accept MATCH without changing the existing flow.
      // =================================================

      final dynamic verifiedValue =
      result['verified'];

      final dynamic resultValue =
      result['result'];

      final dynamic matchValue =
      result['match'];

      final bool verified =
          verifiedValue == true ||
              verifiedValue.toString().toUpperCase() == 'MATCH' ||
              resultValue.toString().toUpperCase() == 'MATCH' ||
              matchValue.toString().toUpperCase() == 'MATCH';

      // =================================================
      // FACE VERIFIED / MATCH
      // =================================================

      if (verified) {
        setState(() {
          _isVerifying = false;
          _statusMessage =
          'Face Match successful.';
        });

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) return;

        // =================================================
        // LOGIN VERIFICATION
        //
        // Voter Login
        //      ↓
        // Face Verification
        //      ↓
        // Voter Profile
        // =================================================

        if (widget.candidateId == null ||
            widget.candidateName == null ||
            widget.candidateName!.trim().isEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => VoterProfileScreen(
                voterId: widget.voterId,
                voterName: widget.voterName,
              ),
            ),
          );

          return;
        }

        // =================================================
        // CANDIDATE VERIFICATION
        //
        // Candidate Selection
        //      ↓
        // Live Face Verification
        //      ↓
        // Confirm Vote
        // =================================================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmVoteScreen(
              voterId: widget.voterId,
              voterName: widget.voterName,
              candidateId: widget.candidateId!,
              candidateName: widget.candidateName!,
              partyName: widget.partyName ?? '',
              candidateSymbol:
              widget.candidateSymbol ?? '',
            ),
          ),
        );

        return;
      }

      // =================================================
      // FACE VERIFICATION FAILED / NO MATCH
      // =================================================

      setState(() {
        _isVerifying = false;
        _hasCaptured = false;
        _statusMessage =
        'Face No Match. Please look at the camera and try again.';
      });

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (mounted && !_hasCaptured) {
        await _captureAndVerify();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _hasCaptured = false;
        _statusMessage =
        'Face verification failed. Please try again.';
      });

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (mounted && !_hasCaptured) {
        await _captureAndVerify();
      }
    }
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // =====================================================
  // SIMILARITY TEXT
  // =====================================================

  String _similarityText() {
    if (_similarity == null) {
      return '';
    }

    return 'Similarity: ${_similarity!.toStringAsFixed(4)}';
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),

      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        title: const Text(
          'Face Verification',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            // =================================================
            // TITLE
            // =================================================

            const Text(
              'Live Face Verification',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102A43),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Voter ID: ${widget.voterId}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 22),

            // =================================================
            // CAMERA
            // =================================================

            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 360,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF102A43),
                      width: 1.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isCameraReady &&
                      _cameraController != null
                      ? CameraPreview(
                    _cameraController!,
                  )
                      : const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // =================================================
            // VERIFYING INDICATOR
            // =================================================

            if (_isVerifying)
              const CircularProgressIndicator(
                color: Color(0xFF102A43),
              ),

            const SizedBox(height: 12),

            // =================================================
            // STATUS
            // =================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF333333),
                ),
              ),
            ),

            // =================================================
            // SIMILARITY
            // =================================================

            if (_similarity != null) ...[
              const SizedBox(height: 6),
              Text(
                _similarityText(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // =================================================
            // INSTRUCTION
            // =================================================

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 30,
              ),
              child: Text(
                'Look directly at the camera and keep your face clearly visible.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}