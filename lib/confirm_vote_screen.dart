import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'candidate_selection_screen.dart';
import 'change_candidate_screen.dart';
import 'vote_success_screen.dart';

class ConfirmVoteScreen extends StatefulWidget {
  final String voterId;
  final String voterName;
  final int candidateId;
  final String candidateName;
  final String partyName;
  final String candidateSymbol;

  const ConfirmVoteScreen({
    super.key,
    required this.voterId,
    required this.voterName,
    required this.candidateId,
    required this.candidateName,
    required this.partyName,
    required this.candidateSymbol,
  });

  @override
  State<ConfirmVoteScreen> createState() =>
      _ConfirmVoteScreenState();
}

class _ConfirmVoteScreenState
    extends State<ConfirmVoteScreen> {
  CameraController? _cameraController;

  Map<String, dynamic>? _voterDetails;

  bool _isCameraReady = false;
  bool _isVerifying = false;
  bool _hasCaptured = false;
  bool _isSubmitting = false;
  bool _isChangingCandidate = false;

  String _statusMessage = 'Preparing camera...';

  double? _similarity;

  @override
  void initState() {
    super.initState();

    _loadVoterDetails();
    _initializeCamera();
  }

  // ------------------------------------------------------------
  // LOAD VOTER DETAILS
  // ------------------------------------------------------------

  Future<void> _loadVoterDetails() async {
    try {
      final voter =
      await ApiService.getVoter(widget.voterId);

      if (!mounted) return;

      setState(() {
        _voterDetails = voter;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _voterDetails = {};
      });
    }
  }

  // ------------------------------------------------------------
  // CAMERA INITIALIZATION
  // ------------------------------------------------------------

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

      CameraDescription frontCamera =
          cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection ==
            CameraLensDirection.front) {
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
        'Look directly at the camera to verify your identity.';
      });

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (mounted &&
          !_hasCaptured &&
          !_isChangingCandidate) {
        await _captureAndVerify();
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isCameraReady = false;
        _statusMessage =
        'Unable to start camera. Please check camera permission.';
      });
    }
  }

  // ------------------------------------------------------------
  // FINAL FACE VERIFICATION
  // ------------------------------------------------------------

  Future<void> _captureAndVerify() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isVerifying ||
        _isSubmitting ||
        _hasCaptured ||
        _isChangingCandidate) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _hasCaptured = true;
      _similarity = null;
      _statusMessage =
      'Verifying your face using InsightFace ML...';
    });

    try {
      final XFile capturedImage =
      await _cameraController!.takePicture();

      final result = await ApiService.verifyFace(
        File(capturedImage.path),
        widget.voterId,
      );

      if (!mounted) return;

      final bool verified =
          result['verified'] == true;

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

      if (verified) {
        setState(() {
          _statusMessage =
          'Face verified successfully.';
        });

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) return;

        await _submitVoteAutomatically();

        return;
      }

      setState(() {
        _isVerifying = false;
        _hasCaptured = false;
        _statusMessage =
        'Face verification failed. Please look at the camera and try again.';
      });

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (mounted &&
          !_hasCaptured &&
          !_isChangingCandidate) {
        await _captureAndVerify();
      }
    } catch (_) {
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

      if (mounted &&
          !_hasCaptured &&
          !_isChangingCandidate) {
        await _captureAndVerify();
      }
    }
  }

  // ------------------------------------------------------------
  // CHANGE CANDIDATE
  // ------------------------------------------------------------

  Future<void> _openChangeCandidatePage() async {
    if (_isSubmitting ||
        _isVerifying ||
        _isChangingCandidate) {
      return;
    }

    setState(() {
      _isChangingCandidate = true;
    });

    final bool? shouldChange =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const ChangeCandidateScreen(),
      ),
    );

    if (!mounted) return;

    if (shouldChange == true) {
      await _cameraController?.dispose();

      _cameraController = null;
      _isCameraReady = false;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CandidateSelectionScreen(
                voterId: widget.voterId,
                voterName: widget.voterName,
              ),
        ),
      );

      return;
    }

    // NO selected
    setState(() {
      _isChangingCandidate = false;
      _statusMessage =
      'Look directly at the camera to verify your identity.';
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (mounted &&
        !_hasCaptured &&
        !_isVerifying &&
        !_isSubmitting &&
        !_isChangingCandidate) {
      await _captureAndVerify();
    }
  }

  // ------------------------------------------------------------
  // AUTOMATIC VOTE SUBMISSION
  // ------------------------------------------------------------

  Future<void> _submitVoteAutomatically() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _isVerifying = false;
      _statusMessage =
      'Face verified. Registering your vote...';
    });

    try {
      final response =
      await ApiService.submitVote(
        voterId: widget.voterId,
        candidateId: widget.candidateId,
      );

      if (!mounted) return;

      final String referenceId =
      (response['reference_id'] ?? '')
          .toString();

      if (referenceId.isEmpty) {
        throw Exception(
          'Vote registration reference ID was not received.',
        );
      }

      setState(() {
        _statusMessage =
        'Vote registered successfully.';
      });

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VoteSuccessScreen(
                voterId: widget.voterId,
                voterName: widget.voterName,
                candidateName:
                widget.candidateName,
                partyName: widget.partyName,
                referenceId: referenceId,
              ),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _isVerifying = false;
        _hasCaptured = false;
        _statusMessage =
        'Unable to register the vote. Please try again.';
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor:
          const Color(0xFFD92D20),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (mounted &&
          !_hasCaptured &&
          !_isChangingCandidate) {
        await _captureAndVerify();
      }
    }
  }

  // ------------------------------------------------------------
  // PARTY SYMBOL
  // ------------------------------------------------------------

  Widget _buildPartySymbol() {
    final String party =
    widget.partyName.trim().toUpperCase();

    // IMPORTANT:
    // ADMK must be checked BEFORE DMK
    // because "ADMK" contains "DMK".

    // ADMK - Leaf
    if (party.contains('ADMK')) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF8EF),
          borderRadius:
          BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            '🍃',
            style: TextStyle(
              fontSize: 40,
            ),
          ),
        ),
      );
    }

    // DMK - Sun
    if (party.contains('DMK')) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius:
          BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            '☀️',
            style: TextStyle(
              fontSize: 40,
            ),
          ),
        ),
      );
    }

    // TVK - Red + Yellow Flag
    if (party.contains('TVK')) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE0E7EF),
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 18,
              decoration:
              const BoxDecoration(
                color: Color(0xFFE53935),
                borderRadius:
                BorderRadius.only(
                  topLeft:
                  Radius.circular(5),
                  topRight:
                  Radius.circular(5),
                ),
              ),
            ),
            Container(
              width: 48,
              height: 18,
              decoration:
              const BoxDecoration(
                color: Color(0xFFFFD600),
                borderRadius:
                BorderRadius.only(
                  bottomLeft:
                  Radius.circular(5),
                  bottomRight:
                  Radius.circular(5),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Backend symbol fallback
    if (widget.candidateSymbol
        .trim()
        .isNotEmpty) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1F8),
          borderRadius:
          BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            widget.candidateSymbol,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.bold,
              color:
              Color(0xFF102A43),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F8),
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.how_to_vote_rounded,
        size: 40,
        color: Color(0xFF102A43),
      ),
    );
  }

  // ------------------------------------------------------------
  // DETAIL VALUE
  // ------------------------------------------------------------

  String _detailValue(String key) {
    final value =
    _voterDetails?[key];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return '-';
    }

    return value.toString();
  }

  // ------------------------------------------------------------
  // DETAIL ROW
  // ------------------------------------------------------------

  Widget _buildDetailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF64748B),
              ),
            ),
          ),
          const Text(
            ':',
            style: TextStyle(
              color:
              Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF334E68),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Confirm Your Vote',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // SELECTED CANDIDATE
              // ------------------------------------------------

              Container(
                padding:
                const EdgeInsets.all(20),
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(20),
                  border: Border.all(
                    color:
                    const Color(0xFFE1EAF2),
                  ),
                ),
                child: Column(
                  children: [
                    _buildPartySymbol(),

                    const SizedBox(height: 14),

                    const Text(
                      'Selected Candidate',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      widget.candidateName,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        fontSize: 21,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      widget.partyName,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        fontSize: 14,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // VOTER DETAILS
              // ------------------------------------------------

              Container(
                padding:
                const EdgeInsets.all(17),
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(16),
                  border: Border.all(
                    color:
                    const Color(0xFFE1EAF2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 21,
                          color:
                          Color(0xFF102A43),
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Voter Details',
                          style:
                          TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w800,
                            color:
                            Color(0xFF102A43),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    _buildDetailRow(
                      'Voter ID',
                      widget.voterId,
                    ),

                    _buildDetailRow(
                      'Name',
                      widget.voterName,
                    ),

                    _buildDetailRow(
                      'District',
                      _detailValue(
                        'district',
                      ),
                    ),

                    _buildDetailRow(
                      'Taluk',
                      _detailValue(
                        'taluk',
                      ),
                    ),

                    _buildDetailRow(
                      'Block',
                      _detailValue(
                        'block',
                      ),
                    ),

                    _buildDetailRow(
                      'Panchayat',
                      _detailValue(
                        'panchayat',
                      ),
                    ),

                    _buildDetailRow(
                      'Ward',
                      _detailValue(
                        'ward',
                      ),
                    ),

                    _buildDetailRow(
                      'Booth',
                      _detailValue(
                        'booth',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // CHANGE CANDIDATE
              // ------------------------------------------------

              OutlinedButton.icon(
                onPressed:
                (_isVerifying ||
                    _isSubmitting ||
                    _isChangingCandidate)
                    ? null
                    : _openChangeCandidatePage,
                icon: const Icon(
                  Icons.swap_horiz_rounded,
                ),
                label: const Text(
                  'Change Candidate',
                ),
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  const Color(
                    0xFF102A43,
                  ),
                  side: const BorderSide(
                    color:
                    Color(0xFF102A43),
                  ),
                  minimumSize:
                  const Size(
                    double.infinity,
                    50,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------
              // FINAL FACE VERIFICATION
              // ------------------------------------------------

              Container(
                padding:
                const EdgeInsets.all(16),
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(18),
                  border: Border.all(
                    color:
                    const Color(0xFFE1EAF2),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Final Face Verification',
                      style:
                      TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF102A43),
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Verify your identity to register the selected vote.',
                      textAlign:
                      TextAlign.center,
                      style:
                      TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: 230,
                      height: 285,
                      decoration:
                      BoxDecoration(
                        color: Colors.black,
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),
                        border: Border.all(
                          color:
                          const Color(
                            0xFF102A43,
                          ),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior:
                      Clip.antiAlias,
                      child:
                      _isCameraReady &&
                          _cameraController !=
                              null
                          ? CameraPreview(
                        _cameraController!,
                      )
                          : const Center(
                        child:
                        CircularProgressIndicator(
                          color:
                          Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_isVerifying ||
                        _isSubmitting)
                      const CircularProgressIndicator(
                        color:
                        Color(0xFF102A43),
                      ),

                    if (_isVerifying ||
                        _isSubmitting)
                      const SizedBox(
                        height: 12,
                      ),

                    Text(
                      _statusMessage,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Color(0xFF334E68),
                      ),
                    ),

                    if (_similarity != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Similarity: ${_similarity!.toStringAsFixed(4)}',
                        style:
                        const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    const Text(
                      'Keep your face clearly visible and look directly at the camera.',
                      textAlign:
                      TextAlign.center,
                      style:
                      TextStyle(
                        fontSize: 11,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // INFO
              // ------------------------------------------------

              Container(
                padding:
                const EdgeInsets.all(15),
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFFFFF8E7),
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                    color:
                    const Color(0xFFF4D06F),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons
                          .verified_user_outlined,
                      color:
                      Color(0xFFB7791F),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After successful face verification, the selected vote will be registered automatically.',
                        style:
                        TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color:
                          Color(0xFF806A2A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
}