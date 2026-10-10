import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'confirm_vote_screen.dart';

class CandidateSelectionScreen extends StatefulWidget {
  final String voterId;
  final String voterName;

  const CandidateSelectionScreen({
    super.key,
    required this.voterId,
    required this.voterName,
  });

  @override
  State<CandidateSelectionScreen> createState() =>
      _CandidateSelectionScreenState();
}

class _CandidateSelectionScreenState
    extends State<CandidateSelectionScreen> {
  List<dynamic> _candidates = [];

  CameraController? _cameraController;

  bool _isLoading = true;
  bool _isCameraReady = false;
  bool _isVerifying = false;
  bool _hasCaptured = false;
  bool _faceVerified = false;
  bool _isOpeningConfirm = false;

  String? _selectedCandidateId;

  String _statusMessage =
      'Select a candidate to start face verification.';

  String _errorMessage = '';

  double? _similarity;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  // =====================================================
  // LOAD CANDIDATES
  // =====================================================

  Future<void> _loadCandidates() async {
    try {
      final candidates = await ApiService.getCandidates(
        widget.voterId,
      );

      if (!mounted) return;

      setState(() {
        _candidates = candidates;
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // =====================================================
  // SELECT CANDIDATE
  // =====================================================

  void _selectCandidate(dynamic candidate) {
    if (_isVerifying || _isOpeningConfirm) {
      return;
    }

    final String candidateId =
    candidate['id'].toString();

    setState(() {
      _selectedCandidateId = candidateId;
      _faceVerified = false;
      _similarity = null;
      _hasCaptured = false;
      _statusMessage =
      'Candidate selected. Face verification will start automatically.';
    });

    _startFaceVerification();
  }

  // =====================================================
  // START FACE VERIFICATION
  // =====================================================

  Future<void> _startFaceVerification() async {
    if (_selectedCandidateId == null ||
        _isVerifying ||
        _faceVerified) {
      return;
    }

    try {
      if (!_isCameraReady) {
        await _initializeCamera();
      }

      if (!mounted) return;

      if (!_isCameraReady ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        setState(() {
          _statusMessage =
          'Camera is not ready. Please try again.';
        });
        return;
      }

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (!mounted ||
          _selectedCandidateId == null ||
          _faceVerified ||
          _hasCaptured) {
        return;
      }

      await _captureAndVerify();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _hasCaptured = false;
        _statusMessage =
        'Unable to start face verification. Please try again.';
      });
    }
  }

  // =====================================================
  // INITIALIZE CAMERA
  // =====================================================

  Future<void> _initializeCamera() async {
    if (_isCameraReady &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return;
    }

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
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCameraReady = false;
        _statusMessage =
        'Unable to start camera. Please check camera permission.';
      });
    }
  }

  // =====================================================
  // CAPTURE + REAL INSIGHTFACE VERIFICATION
  // =====================================================

  Future<void> _captureAndVerify() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isVerifying ||
        _faceVerified ||
        _hasCaptured ||
        _selectedCandidateId == null) {
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

      // =================================================
      // VERIFIED
      // =================================================

      if (verified) {
        setState(() {
          _faceVerified = true;
          _isVerifying = false;
          _statusMessage =
          'Face verified successfully.';
        });

        await Future.delayed(
          const Duration(milliseconds: 700),
        );

        if (!mounted) return;

        await _openConfirmScreen();

        return;
      }

      // =================================================
      // FAILED
      // =================================================

      setState(() {
        _isVerifying = false;
        _hasCaptured = false;
        _faceVerified = false;
        _statusMessage =
        'Face verification failed. Please look directly at the camera and try again.';
      });

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (mounted &&
          !_hasCaptured &&
          !_faceVerified &&
          _selectedCandidateId != null) {
        await _captureAndVerify();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
        _hasCaptured = false;
        _faceVerified = false;
        _statusMessage =
        'Face verification failed. Please try again.';
      });

      await Future.delayed(
        const Duration(seconds: 2),
      );

      if (mounted &&
          !_hasCaptured &&
          !_faceVerified &&
          _selectedCandidateId != null) {
        await _captureAndVerify();
      }
    }
  }

  // =====================================================
  // OPEN CONFIRM PAGE
  // =====================================================

  Future<void> _openConfirmScreen() async {
    if (_isOpeningConfirm ||
        _selectedCandidateId == null) {
      return;
    }

    setState(() {
      _isOpeningConfirm = true;
    });

    try {
      final dynamic selectedCandidate =
      _candidates.firstWhere(
            (candidate) =>
        candidate['id'].toString() ==
            _selectedCandidateId,
      );

      final int candidateId = int.parse(
        selectedCandidate['id'].toString(),
      );

      final String candidateName =
          selectedCandidate['candidate_name']
              ?.toString() ??
              'Candidate';

      final String partyName =
          selectedCandidate['party_name']
              ?.toString() ??
              '';

      final String symbol =
          selectedCandidate['symbol']
              ?.toString() ??
              selectedCandidate['election_symbol']
                  ?.toString() ??
              '';

      await _cameraController?.dispose();

      _cameraController = null;
      _isCameraReady = false;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ConfirmVoteScreen(
            voterId: widget.voterId,
            voterName: widget.voterName,
            candidateId: candidateId,
            candidateName: candidateName,
            partyName: partyName,
            candidateSymbol: symbol,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isOpeningConfirm = false;
        _statusMessage =
        'Unable to open vote confirmation. Please try again.';
      });
    }
  }

  // =====================================================
  // RETRY
  // =====================================================

  void _retryFaceVerification() {
    if (_selectedCandidateId == null ||
        _isVerifying ||
        _faceVerified) {
      return;
    }

    setState(() {
      _hasCaptured = false;
      _similarity = null;
      _statusMessage =
      'Look directly at the camera. Verification will start automatically.';
    });

    _startFaceVerification();
  }

  // =====================================================
  // GET SELECTED CANDIDATE
  // =====================================================

  dynamic _getSelectedCandidate() {
    if (_selectedCandidateId == null) {
      return null;
    }

    try {
      return _candidates.firstWhere(
            (candidate) =>
        candidate['id'].toString() ==
            _selectedCandidateId,
      );
    } catch (_) {
      return null;
    }
  }

  // =====================================================
  // PARTY SYMBOL
  // =====================================================

  Widget _buildPartySymbol(
      String partyName,
      String backendSymbol,
      ) {
    final String party =
    partyName.trim().toUpperCase();

    // ===================================================
    // TVK → RED + YELLOW FLAG
    // ===================================================

    if (party == 'TVK') {
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFE0E7EF),
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 15,
              decoration:
              const BoxDecoration(
                color: Color(0xFFE53935),
                borderRadius:
                BorderRadius.only(
                  topLeft:
                  Radius.circular(4),
                  topRight:
                  Radius.circular(4),
                ),
              ),
            ),
            Container(
              width: 38,
              height: 15,
              decoration:
              const BoxDecoration(
                color: Color(0xFFFFD600),
                borderRadius:
                BorderRadius.only(
                  bottomLeft:
                  Radius.circular(4),
                  bottomRight:
                  Radius.circular(4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ===================================================
    // DMK → SUN
    // ===================================================

    if (party == 'DMK') {
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color:
          const Color(0xFFFFF3E0),
          borderRadius:
          BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            '☀️',
            style: TextStyle(
              fontSize: 34,
            ),
          ),
        ),
      );
    }

    // ===================================================
    // ADMK → LEAF
    // ===================================================

    if (party == 'ADMK') {
      return Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color:
          const Color(0xFFEAF8EF),
          borderRadius:
          BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            '🍃',
            style: TextStyle(
              fontSize: 34,
            ),
          ),
        ),
      );
    }

    // ===================================================
    // OTHER PARTIES
    // ===================================================

    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color:
        const Color(0xFFEAF1F8),
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          backendSymbol.isNotEmpty
              ? backendSymbol
              : '🗳️',
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
          ),
        ),
      ),
    );
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
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          'Select Candidate',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor:
        Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  // =====================================================
  // BODY
  // =====================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xFF102A43),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (_candidates.isEmpty) {
      return const Center(
        child: Text(
          'No candidates available for your location.',
          textAlign:
          TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Column(
      children: [
        // =================================================
        // HEADER
        // =================================================

        Padding(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            22,
            20,
            8,
          ),
          child: Column(
            children: [
              const Text(
                'Choose Your Candidate',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFF102A43),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_candidates.length} candidates available for your location',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // =================================================
        // CANDIDATE LIST
        // =================================================

        Expanded(
          child:
          ListView.builder(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              10,
            ),
            itemCount:
            _candidates.length,
            itemBuilder:
                (context, index) {
              final candidate =
              _candidates[index];

              return _buildCandidateCard(
                candidate,
              );
            },
          ),
        ),

        // =================================================
        // LIVE FACE VERIFICATION
        // =================================================

        _buildFaceVerificationSection(),

        const SizedBox(height: 16),
      ],
    );
  }

  // =====================================================
  // CANDIDATE CARD
  // =====================================================

  Widget _buildCandidateCard(
      dynamic candidate,
      ) {
    final String candidateId =
    candidate['id'].toString();

    final bool isSelected =
        _selectedCandidateId ==
            candidateId;

    final String candidateName =
        candidate['candidate_name']
            ?.toString() ??
            'Unknown Candidate';

    final String partyName =
        candidate['party_name']
            ?.toString() ??
            'Independent';

    final String backendSymbol =
        candidate['symbol']
            ?.toString() ??
            candidate['election_symbol']
                ?.toString() ??
            '';

    return GestureDetector(
      onTap: () {
        _selectCandidate(candidate);
      },
      child:
      AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 200,
        ),
        margin:
        const EdgeInsets.only(
          bottom: 16,
        ),
        padding:
        const EdgeInsets.all(18),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(
              0xFFFFB703,
            )
                : const Color(
              0xFFE0E7EF,
            ),
            width:
            isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black
                  .withOpacity(0.05),
              blurRadius: 12,
              offset:
              const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.center,
          children: [
            // SYMBOL
            _buildPartySymbol(
              partyName,
              backendSymbol,
            ),

            const SizedBox(width: 16),

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    candidateName,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xFF102A43),
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    partyName,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      color:
                      Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            // RADIO
            Container(
              width: 28,
              height: 28,
              decoration:
              BoxDecoration(
                shape:
                BoxShape.circle,
                border:
                Border.all(
                  color: isSelected
                      ? const Color(
                    0xFFFFB703,
                  )
                      : Colors
                      .grey
                      .shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child:
                Container(
                  width: 14,
                  height: 14,
                  decoration:
                  const BoxDecoration(
                    shape:
                    BoxShape
                        .circle,
                    color:
                    Color(
                      0xFFFFB703,
                    ),
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // FACE VERIFICATION SECTION
  // =====================================================

  Widget _buildFaceVerificationSection() {
    final selectedCandidate =
    _getSelectedCandidate();

    return Container(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 20,
      ),
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
            'Live Face Verification',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF102A43),
            ),
          ),

          const SizedBox(height: 5),

          Text(
            selectedCandidate == null
                ? 'Select your candidate to begin face verification.'
                : 'Verify your identity for the selected candidate.',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              fontSize: 12,
              height: 1.4,
              color:
              Color(0xFF64748B),
            ),
          ),

          if (selectedCandidate !=
              null) ...[
            const SizedBox(
              height: 10,
            ),

            Text(
              selectedCandidate[
              'candidate_name']
                  ?.toString() ??
                  '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF102A43),
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // CAMERA
            Container(
              width: 190,
              height: 220,
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

            const SizedBox(
              height: 14,
            ),

            if (_isVerifying)
              const CircularProgressIndicator(
                color:
                Color(0xFF102A43),
              ),

            if (_isVerifying)
              const SizedBox(
                height: 12,
              ),

            Text(
              _statusMessage,
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                _faceVerified
                    ? FontWeight.w700
                    : FontWeight.normal,
                color:
                _faceVerified
                    ? const Color(
                  0xFF16803C,
                )
                    : const Color(
                  0xFF334E68,
                ),
              ),
            ),

            if (_similarity !=
                null) ...[
              const SizedBox(
                height: 5,
              ),
              Text(
                'Similarity: ${_similarity!.toStringAsFixed(4)}',
                style:
                const TextStyle(
                  fontSize: 12,
                  color:
                  Colors.grey,
                ),
              ),
            ],

            if (_faceVerified) ...[
              const SizedBox(
                height: 10,
              ),

              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(
                  10,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFEAF8EF,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    Icon(
                      Icons
                          .verified_rounded,
                      color:
                      Color(
                        0xFF16803C,
                      ),
                      size: 20,
                    ),
                    SizedBox(
                      width: 7,
                    ),
                    Text(
                      'Face Verified',
                      style:
                      TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight
                            .w700,
                        color:
                        Color(
                          0xFF16803C,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!_faceVerified &&
                !_isVerifying) ...[
              const SizedBox(
                height: 10,
              ),

              TextButton.icon(
                onPressed:
                _retryFaceVerification,
                icon:
                const Icon(
                  Icons
                      .refresh_rounded,
                ),
                label:
                const Text(
                  'Verify Again',
                ),
              ),
            ],

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Look directly at the camera and keep your face clearly visible.',
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
        ],
      ),
    );
  }

  // =====================================================
  // ERROR VIEW
  // =====================================================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color:
              Colors.redAccent,
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Unable to load candidates',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xFF102A43),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _errorMessage,
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });

                _loadCandidates();
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF102A43,
                ),
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}