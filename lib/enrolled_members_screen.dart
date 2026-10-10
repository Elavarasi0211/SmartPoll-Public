import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';

class EnrolledMembersScreen extends StatefulWidget {
  const EnrolledMembersScreen({super.key});

  @override
  State<EnrolledMembersScreen> createState() =>
      _EnrolledMembersScreenState();
}

class _EnrolledMembersScreenState extends State<EnrolledMembersScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _members = [];

  Map<String, Map<String, dynamic>> _voterStatus = {};

  // ============================================================
  // FILTER
  // ============================================================

  String _selectedFilter = 'All Members';

  // ============================================================
  // VOTER SELECTOR
  // ============================================================

  String? _selectedVoterId;

  List<Map<String, dynamic>> get _filteredMembers {
    if (_selectedFilter == 'All Members') {
      return _members;
    }

    if (_selectedFilter == 'Voted') {
      return _members.where((member) {
        final voterId =
            member['voter_id']?.toString() ??
                member['id']?.toString() ??
                '';

        return _hasVoted(voterId);
      }).toList();
    }

    if (_selectedFilter == 'Not Voted') {
      return _members.where((member) {
        final voterId =
            member['voter_id']?.toString() ??
                member['id']?.toString() ??
                '';

        return !_hasVoted(voterId);
      }).toList();
    }

    return _members;
  }

  Map<String, dynamic>? get _selectedMember {
    if (_selectedVoterId == null) {
      return null;
    }

    for (final member in _filteredMembers) {
      final voterId =
          member['voter_id']?.toString() ??
              member['id']?.toString() ??
              '';

      if (voterId == _selectedVoterId) {
        return member;
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // ============================================================
  // LOAD MEMBERS
  // ============================================================

  Future<void> _loadMembers() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resultsFuture = ApiService.getAdminResults();
      final votersFuture = ApiService.getAllVoters();

      final results = await resultsFuture;
      final voters = await votersFuture;

      if (!mounted) {
        return;
      }

      final Map<String, Map<String, dynamic>> statusMap = {};

      final resultVoters = results['voters'];

      if (resultVoters is List) {
        for (final voter in resultVoters) {
          if (voter is Map) {
            final voterId = voter['voter_id']?.toString();

            if (voterId != null && voterId.isNotEmpty) {
              statusMap[voterId] = Map<String, dynamic>.from(voter);
            }
          }
        }
      }

      final List<Map<String, dynamic>> loadedMembers = [];

      for (final voter in voters) {
        if (voter is Map) {
          loadedMembers.add(
            Map<String, dynamic>.from(voter),
          );
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _members = loadedMembers;
        _voterStatus = statusMap;
        _isLoading = false;

        if (_selectedVoterId != null) {
          final exists = loadedMembers.any((member) {
            final voterId =
                member['voter_id']?.toString() ??
                    member['id']?.toString() ??
                    '';

            return voterId == _selectedVoterId;
          });

          if (!exists) {
            _selectedVoterId = null;
          }
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load enrolled members.';
      });
    }
  }

  // ============================================================
  // GET VOTER STATUS
  // ============================================================

  Map<String, dynamic>? _getVoterStatus(String voterId) {
    return _voterStatus[voterId];
  }

  bool _hasVoted(String voterId) {
    final voter = _getVoterStatus(voterId);

    if (voter == null) {
      return false;
    }

    return voter['has_voted'] == true;
  }

  String _getVotingStatus(String voterId) {
    final voter = _getVoterStatus(voterId);

    if (voter == null) {
      return 'Not Voted';
    }

    return voter['status']?.toString() ?? 'Not Voted';
  }

  Map<String, dynamic>? _getLatestVote(String voterId) {
    final voter = _getVoterStatus(voterId);

    if (voter == null) {
      return null;
    }

    final latestVote = voter['latest_vote'];

    if (latestVote is Map) {
      return Map<String, dynamic>.from(latestVote);
    }

    return null;
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(String status) {
    final bool voted = status.toLowerCase() == 'voted';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: voted
            ? Colors.green.withOpacity(0.10)
            : Colors.orange.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: voted
              ? Colors.green.withOpacity(0.35)
              : Colors.orange.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            voted ? Icons.check_circle : Icons.access_time,
            size: 16,
            color: voted ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: voted
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROGRESS BAR
  // ============================================================

  Widget _buildProgressBar(bool hasVoted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Voting Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              hasVoted ? '100%' : '0%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasVoted
                    ? Colors.green.shade700
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: hasVoted ? 1.0 : 0.0,
            minHeight: 7,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              hasVoted
                  ? Colors.green
                  : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LATEST VOTE
  // ============================================================

  Widget _buildLatestVote(
      Map<String, dynamic>? latestVote,
      ) {
    if (latestVote == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.how_to_vote_outlined,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(width: 8),
            Text(
              'No vote recorded',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final candidateName =
        latestVote['candidate_name']?.toString() ??
            'Unknown Candidate';

    final partyName =
        latestVote['party_name']?.toString() ??
            'Unknown Party';

    final symbol =
        latestVote['symbol']?.toString() ?? '';

    final referenceId =
        latestVote['reference_id']?.toString() ?? '';

    final timestamp =
        latestVote['timestamp']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Latest Vote',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.how_to_vote,
                  color: Color(0xFF0F2A43),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidateName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      partyName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (symbol.isNotEmpty)
                Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (referenceId.isNotEmpty)
            Text(
              'Reference: $referenceId',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          if (timestamp.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Time: $timestamp',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EDIT EMAIL
  // ============================================================

  Future<void> _showEditEmailDialog(
      String voterId,
      String name,
      String currentEmail,
      ) async {
    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _EditEmailDialog(
          voterId: voterId,
          name: name,
          currentEmail: currentEmail,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result == 'updated') {
      await _loadMembers();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Registered email updated successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ============================================================
  // MEMBER CARD
  // ============================================================

  Widget _buildMemberCard(
      Map<String, dynamic> member,
      ) {
    final voterId =
        member['voter_id']?.toString() ??
            member['id']?.toString() ??
            '';

    final name =
        member['name']?.toString() ?? '';

    final email =
        member['email']?.toString() ?? '';

    final district =
        member['district']?.toString() ?? '';

    final taluk =
        member['taluk']?.toString() ?? '';

    final booth =
        member['booth']?.toString() ?? '';

    final registration =
        member['registration']?.toString() ??
            'Verified';

    final hasVoted = _hasVoted(voterId);

    final votingStatus =
    _getVotingStatus(voterId);

    final latestVote =
    _getLatestVote(voterId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF0F2A43),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voterId,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(
                votingStatus,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(
            height: 1,
            color: Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------
          // REGISTERED EMAIL + EDIT
          // ------------------------------------------------------

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.email_outlined,
                  title: 'Registered Email',
                  value: email,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    _showEditEmailDialog(
                      voterId,
                      name,
                      email,
                    ),
                tooltip: 'Edit Email',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: Color(0xFF0F2A43),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon:
                  Icons.location_city_outlined,
                  title: 'District',
                  value: district,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.map_outlined,
                  title: 'Taluk',
                  value: taluk,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon:
                  Icons.how_to_vote_outlined,
                  title: 'Booth',
                  value: booth,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon:
                  Icons.verified_user_outlined,
                  title: 'Registration',
                  value: registration,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildProgressBar(
            hasVoted,
          ),

          const SizedBox(height: 16),

          _buildLatestVote(
            latestVote,
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _confirmRemoveMember(
                    voterId,
                    name,
                  ),
              icon: const Icon(
                Icons.delete_outline,
                size: 19,
              ),
              label: const Text(
                'Remove Member',
              ),
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                Colors.red.shade700,
                side: BorderSide(
                  color:
                  Colors.red.shade200,
                ),
                padding:
                const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO ITEM
  // ============================================================

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enrolled Members',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F2A43),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${_filteredMembers.length} of ${_members.length} registered voters',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
              _isLoading ? null : _loadMembers,
              tooltip: 'Refresh',
              icon: const Icon(
                Icons.refresh,
                color: Color(0xFF0F2A43),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed:
              _isSaving
                  ? null
                  : _showAddMemberDialog,
              icon: const Icon(
                Icons.person_add_alt_1,
                size: 18,
              ),
              label: const Text(
                'Add Member',
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF0F2A43),
                foregroundColor:
                Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // --------------------------------------------------------
        // SINGLE FILTER
        // --------------------------------------------------------

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(12),
            border: Border.all(
              color:
              const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              icon: const Icon(
                Icons.filter_list,
                color: Color(0xFF0F2A43),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'All Members',
                  child: Text(
                    'All Members',
                  ),
                ),
                DropdownMenuItem(
                  value: 'Voted',
                  child: Text(
                    'Voted',
                  ),
                ),
                DropdownMenuItem(
                  value: 'Not Voted',
                  child: Text(
                    'Not Voted',
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _selectedFilter = value;

                  // Reset selected voter when the main
                  // filter changes so an invalid member
                  // is never displayed.
                  _selectedVoterId = null;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // --------------------------------------------------------
        // VOTER SELECTOR
        // --------------------------------------------------------

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(12),
            border: Border.all(
              color:
              const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedVoterId,
              isExpanded: true,
              hint: const Row(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Select Voter',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF0F2A43),
              ),
              items: _filteredMembers.map((member) {
                final voterId =
                    member['voter_id']?.toString() ??
                        member['id']?.toString() ??
                        '';

                final name =
                    member['name']?.toString() ??
                        '';

                return DropdownMenuItem<String>(
                  value: voterId,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color:
                          const Color(0xFFEFF6FF),
                          borderRadius:
                          BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          size: 19,
                          color: Color(0xFF0F2A43),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          name.isEmpty
                              ? voterId
                              : '$voterId - $name',
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w600,
                            color:
                            Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _filteredMembers.isEmpty
                  ? null
                  : (value) {
                setState(() {
                  _selectedVoterId = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CAMERA CAPTURE
  // ============================================================

  Future<File?> _captureFaceImage() async {
    CameraController? controller;

    try {
      final cameras =
      await availableCameras();

      if (cameras.isEmpty) {
        throw Exception(
          'No camera available.',
        );
      }

      CameraDescription selectedCamera =
          cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection ==
            CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return null;
      }

      final File? capturedFile =
      await showDialog<File?>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _FaceCaptureDialog(
            controller: controller!,
          );
        },
      );

      await controller.dispose();

      return capturedFile;
    } catch (error) {
      await controller?.dispose();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Unable to open camera: $error',
            ),
            backgroundColor:
            Colors.red.shade700,
          ),
        );
      }

      return null;
    }
  }

  // ============================================================
  // ADD MEMBER DIALOG
  // ============================================================

  Future<void> _showAddMemberDialog() async {
    final voterIdController =
    TextEditingController();

    final nameController =
    TextEditingController();

    final phoneController =
    TextEditingController();

    final emailController =
    TextEditingController();

    final districtController =
    TextEditingController();

    final talukController =
    TextEditingController();

    final blockController =
    TextEditingController();

    final panchayatController =
    TextEditingController();

    final wardController =
    TextEditingController();

    final boothController =
    TextEditingController();

    File? faceImage;

    bool dialogSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            Future<void> captureFace() async {
              final image =
              await _captureFaceImage();

              if (image != null &&
                  dialogContext.mounted) {
                setDialogState(() {
                  faceImage = image;
                });
              }
            }

            Future<void> saveMember() async {
              if (voterIdController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter Voter ID.',
                );
                return;
              }

              if (nameController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter member name.',
                );
                return;
              }

              if (phoneController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter phone number.',
                );
                return;
              }

              if (emailController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter registered email.',
                );
                return;
              }

              final email =
              emailController.text.trim();

              final emailPattern = RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              );

              if (!emailPattern.hasMatch(email)) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter a valid email address.',
                );
                return;
              }

              if (districtController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter district.',
                );
                return;
              }

              if (talukController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter taluk.',
                );
                return;
              }

              if (boothController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter booth.',
                );
                return;
              }

              if (faceImage == null) {
                _showDialogMessage(
                  dialogContext,
                  'Please capture the face image.',
                );
                return;
              }

              setDialogState(() {
                dialogSaving = true;
              });

              try {
                await ApiService.addVoter(
                  voterId:
                  voterIdController.text.trim(),
                  name:
                  nameController.text.trim(),
                  phone:
                  phoneController.text.trim(),
                  email: email,
                  district:
                  districtController.text.trim(),
                  taluk:
                  talukController.text.trim(),
                  block:
                  blockController.text.trim(),
                  panchayat:
                  panchayatController.text.trim(),
                  ward:
                  wardController.text.trim(),
                  booth:
                  boothController.text.trim(),
                  faceImage: faceImage!,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop();

                if (!mounted) {
                  return;
                }

                ScaffoldMessenger.of(this.context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Member added successfully.',
                    ),
                    backgroundColor:
                    Colors.green,
                  ),
                );

                await _loadMembers();
              } catch (error) {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  dialogSaving = false;
                });

                _showDialogMessage(
                  dialogContext,
                  error
                      .toString()
                      .replaceFirst(
                    'Exception: ',
                    '',
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.person_add_alt_1,
                    color:
                    Color(0xFF0F2A43),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Add New Member',
                  ),
                ],
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller:
                        voterIdController,
                        label: 'Voter ID',
                        hint:
                        'Example: SPV010',
                      ),
                      _buildTextField(
                        controller:
                        nameController,
                        label: 'Name',
                        hint:
                        'Enter member name',
                      ),
                      _buildTextField(
                        controller:
                        phoneController,
                        label: 'Phone Number',
                        hint:
                        'Enter phone number',
                        keyboardType:
                        TextInputType.phone,
                      ),
                      _buildTextField(
                        controller:
                        emailController,
                        label:
                        'Registered Email',
                        hint:
                        'Enter registered email',
                        keyboardType:
                        TextInputType
                            .emailAddress,
                      ),
                      _buildTextField(
                        controller:
                        districtController,
                        label: 'District',
                        hint:
                        'Enter district',
                      ),
                      _buildTextField(
                        controller:
                        talukController,
                        label: 'Taluk',
                        hint:
                        'Enter taluk',
                      ),
                      _buildTextField(
                        controller:
                        blockController,
                        label: 'Block',
                        hint:
                        'Enter block',
                      ),
                      _buildTextField(
                        controller:
                        panchayatController,
                        label: 'Panchayat',
                        hint:
                        'Enter panchayat',
                      ),
                      _buildTextField(
                        controller:
                        wardController,
                        label: 'Ward',
                        hint:
                        'Enter ward',
                      ),
                      _buildTextField(
                        controller:
                        boothController,
                        label: 'Booth',
                        hint:
                        'Enter booth number',
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets.all(
                          14,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFF8FAFC,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                          border:
                          Border.all(
                            color:
                            const Color(
                              0xFFE2E8F0,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              faceImage == null
                                  ? Icons
                                  .face_retouching_natural
                                  : Icons
                                  .check_circle,
                              size: 38,
                              color:
                              faceImage == null
                                  ? const Color(
                                0xFF64748B,
                              )
                                  : Colors.green,
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Text(
                              faceImage == null
                                  ? 'Face image not captured'
                                  : 'Face image captured',
                              style:
                              TextStyle(
                                fontSize: 13,
                                fontWeight:
                                FontWeight.w600,
                                color:
                                faceImage == null
                                    ? const Color(
                                  0xFF64748B,
                                )
                                    : Colors
                                    .green
                                    .shade700,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            OutlinedButton.icon(
                              onPressed:
                              dialogSaving
                                  ? null
                                  : captureFace,
                              icon: const Icon(
                                Icons.camera_alt,
                              ),
                              label: Text(
                                faceImage == null
                                    ? 'Capture Face'
                                    : 'Capture Again',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogSaving
                      ? null
                      : () =>
                      Navigator.of(
                        dialogContext,
                      ).pop(),
                  child: const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: dialogSaving
                      ? null
                      : saveMember,
                  icon: dialogSaving
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.save,
                    size: 18,
                  ),
                  label: Text(
                    dialogSaving
                        ? 'Saving...'
                        : 'Save Member',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF0F2A43,
                    ),
                    foregroundColor:
                    Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    voterIdController.dispose();
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    districtController.dispose();
    talukController.dispose();
    blockController.dispose();
    panchayatController.dispose();
    wardController.dispose();
    boothController.dispose();
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor:
          const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
            borderSide:
            const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
            borderSide:
            const BorderSide(
              color: Color(0xFFE2E8F0),
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
            borderSide:
            const BorderSide(
              color: Color(0xFF0F2A43),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG MESSAGE
  // ============================================================

  void _showDialogMessage(
      BuildContext context,
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        Colors.red.shade700,
      ),
    );
  }

  // ============================================================
  // REMOVE MEMBER CONFIRMATION
  // ============================================================

  Future<void> _confirmRemoveMember(
      String voterId,
      String name,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Member',
          ),
          content: Text(
            'Are you sure you want to remove $name ($voterId)?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(
                    dialogContext,
                  ).pop(false),
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(
                    dialogContext,
                  ).pop(true),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red.shade700,
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                'Remove',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = true;
      });

      await ApiService.removeVoter(
        voterId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(this.context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Member removed successfully.',
          ),
          backgroundColor:
          Colors.green,
        ),
      );

      await _loadMembers();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(this.context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error
                .toString()
                .replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor:
          Colors.red.shade700,
        ),
      );
    }
  }

  // ============================================================
  // LOADING VIEW
  // ============================================================

  Widget _buildLoadingView() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF0F2A43),
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

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
              size: 50,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF475569),
                fontWeight:
                FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
              _loadMembers,
              icon:
              const Icon(Icons.refresh),
              label:
              const Text('Retry'),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF0F2A43,
                ),
                foregroundColor:
                Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredMembers =
        _filteredMembers;

    final selectedMember =
        _selectedMember;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        elevation: 0,
        surfaceTintColor:
        Colors.white,
        title: const Text(
          'Enrolled Members',
          style: TextStyle(
            color: Color(0xFF0F2A43),
            fontWeight:
            FontWeight.w700,
            fontSize: 19,
          ),
        ),
        iconTheme:
        const IconThemeData(
          color: Color(0xFF0F2A43),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadMembers,
          color:
          const Color(0xFF0F2A43),
          child: _isLoading
              ? _buildLoadingView()
              : _errorMessage != null
              ? _buildErrorView()
              : ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              30,
            ),
            children: [
              _buildHeader(),
              const SizedBox(
                height: 20,
              ),

              if (filteredMembers.isEmpty)
                _buildEmptyMembersView(
                  isFiltered:
                  _members.isNotEmpty,
                )
              else if (selectedMember != null)
                _buildMemberCard(
                  selectedMember,
                )
              else
                _buildSelectVoterMessage(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECT VOTER MESSAGE
  // ============================================================

  Widget _buildSelectVoterMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color:
              const Color(0xFFEFF6FF),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_search_outlined,
              size: 32,
              color:
              Color(0xFF0F2A43),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Select a Voter',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a voter from the dropdown above to view their full details.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color:
              Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY MEMBERS
  // ============================================================

  Widget _buildEmptyMembersView({
    bool isFiltered = false,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 55,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered
                ? 'No members found'
                : 'No enrolled members',
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            isFiltered
                ? 'No members match the selected filter.'
                : 'Add a new member to begin enrollment.',
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color:
              Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EDIT EMAIL DIALOG
// ============================================================

class _EditEmailDialog extends StatefulWidget {
  final String voterId;
  final String name;
  final String currentEmail;

  const _EditEmailDialog({
    required this.voterId,
    required this.name,
    required this.currentEmail,
  });

  @override
  State<_EditEmailDialog> createState() =>
      _EditEmailDialogState();
}

class _EditEmailDialogState
    extends State<_EditEmailDialog> {
  late final TextEditingController
  _emailController;

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _emailController =
        TextEditingController(
          text: widget.currentEmail,
        );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // UPDATE EMAIL
  // ============================================================

  Future<void> _updateEmail() async {
    final email =
    _emailController.text.trim();

    if (email.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
        'Please enter registered email.';
      });

      return;
    }

    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(email)) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
        'Please enter a valid email address.';
      });

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await ApiService.updateVoterEmail(
        voterId: widget.voterId,
        email: email,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop('updated');
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
        _errorMessage = error
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(
            Icons.email_outlined,
            color: Color(0xFF0F2A43),
          ),
          SizedBox(width: 10),
          Text(
            'Update Email',
          ),
        ],
      ),
      content: SizedBox(
        width: 430,
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.name} (${widget.voterId})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller:
              _emailController,
              enabled: !_saving,
              keyboardType:
              TextInputType.emailAddress,
              decoration:
              InputDecoration(
                labelText:
                'Registered Email',
                hintText:
                'Enter registered email',
                filled: true,
                fillColor:
                const Color(
                  0xFFF8FAFC,
                ),
                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                  borderSide:
                  const BorderSide(
                    color:
                    Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                  borderSide:
                  const BorderSide(
                    color:
                    Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                  borderSide:
                  const BorderSide(
                    color:
                    Color(0xFF0F2A43),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(10),
                decoration:
                BoxDecoration(
                  color:
                  Colors.red.withOpacity(
                    0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    8,
                  ),
                  border: Border.all(
                    color:
                    Colors.red.withOpacity(
                      0.20,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 18,
                      color:
                      Colors.red.shade700,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.red.shade700,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
            Navigator.of(
              context,
            ).pop();
          },
          child:
          const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed:
          _saving ? null : _updateEmail,
          icon: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
              color:
              Colors.white,
            ),
          )
              : const Icon(
            Icons.save,
            size: 18,
          ),
          label: Text(
            _saving
                ? 'Updating...'
                : 'Update Email',
          ),
          style:
          ElevatedButton.styleFrom(
            backgroundColor:
            const Color(
              0xFF0F2A43,
            ),
            foregroundColor:
            Colors.white,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FACE CAPTURE DIALOG
// ============================================================

class _FaceCaptureDialog
    extends StatefulWidget {
  final CameraController controller;

  const _FaceCaptureDialog({
    required this.controller,
  });

  @override
  State<_FaceCaptureDialog> createState() =>
      _FaceCaptureDialogState();
}

class _FaceCaptureDialogState
    extends State<_FaceCaptureDialog> {
  bool _isCapturing = false;

  Future<void> _capture() async {
    if (_isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final image =
      await widget.controller
          .takePicture();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        File(image.path),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCapturing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to capture image: $error',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
      const EdgeInsets.all(16),
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Padding(
              padding:
              const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Capture Face',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w700,
                        color:
                        Color(0xFF0F2A43),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed:
                    _isCapturing
                        ? null
                        : () =>
                        Navigator.of(
                          context,
                        ).pop(),
                    icon:
                    const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin:
              const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              height: 360,
              width: double.infinity,
              clipBehavior:
              Clip.antiAlias,
              decoration:
              BoxDecoration(
                color: Colors.black,
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child: CameraPreview(
                widget.controller,
              ),
            ),
            const Padding(
              padding:
              EdgeInsets.all(14),
              child: Text(
                'Keep the face clearly visible inside the camera frame.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color:
                  Color(0xFF64748B),
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                child:
                ElevatedButton.icon(
                  onPressed:
                  _isCapturing
                      ? null
                      : _capture,
                  icon: _isCapturing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.camera,
                  ),
                  label: Text(
                    _isCapturing
                        ? 'Capturing...'
                        : 'Capture Face',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF0F2A43,
                    ),
                    foregroundColor:
                    Colors.white,
                    padding:
                    const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}