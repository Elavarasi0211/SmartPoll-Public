import 'package:flutter/material.dart';

import 'api_service.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({
    super.key,
  });

  @override
  State<CandidatesScreen> createState() =>
      _CandidatesScreenState();
}

class _CandidatesScreenState
    extends State<CandidatesScreen> {
  List<dynamic> candidates = [];

  bool isLoading = true;
  bool isSaving = false;
  String errorMessage = '';

  // ============================================================
  // PARTY FILTER
  // ============================================================

  String selectedPartyFilter = 'All Parties';

  // ============================================================
  // CANDIDATE FILTER
  // ============================================================

  String selectedCandidateFilter =
      'All Candidates';

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  // ============================================================
  // LOAD ALL CANDIDATES - ADMIN
  // ============================================================

  Future<void> _loadCandidates() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }

    try {
      final result =
      await ApiService.getAllCandidates();

      if (!mounted) return;

      setState(() {
        candidates = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Admin candidate loading error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e
            .toString()
            .replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // GET PARTY NAME
  // ============================================================

  String _getPartyName(
      Map<String, dynamic> candidate,
      ) {
    return (candidate['party_name'] ??
        candidate['party'] ??
        'Independent')
        .toString()
        .trim();
  }

  // ============================================================
  // GET CANDIDATE NAME
  // ============================================================

  String _getCandidateName(
      Map<String, dynamic> candidate,
      ) {
    return (candidate['candidate_name'] ??
        candidate['name'] ??
        'Unknown Candidate')
        .toString()
        .trim();
  }

  // ============================================================
  // GET CANDIDATE FILTER KEY
  // ============================================================

  String _getCandidateFilterKey(
      Map<String, dynamic> candidate,
      ) {
    final candidateId =
    candidate['id']?.toString().trim();

    if (candidateId != null &&
        candidateId.isNotEmpty) {
      return candidateId;
    }

    return _getCandidateName(candidate);
  }

  // ============================================================
  // GET AVAILABLE PARTIES
  // ============================================================

  List<String> _getAvailableParties() {
    final Set<String> partySet = {};

    for (final item in candidates) {
      if (item is Map<String, dynamic>) {
        final party =
        _getPartyName(item);

        if (party.isNotEmpty) {
          partySet.add(party);
        }
      }
    }

    final parties = partySet.toList();

    parties.sort(
          (a, b) => a.toUpperCase().compareTo(
        b.toUpperCase(),
      ),
    );

    return parties;
  }

  // ============================================================
  // GET AVAILABLE CANDIDATES
  //
  // Depends on selected party.
  // If All Parties -> all candidates.
  // If a party is selected -> only that party's candidates.
  // ============================================================

  List<Map<String, dynamic>>
  _getAvailableCandidates() {
    final List<Map<String, dynamic>>
    availableCandidates = [];

    for (final item in candidates) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      if (selectedPartyFilter !=
          'All Parties') {
        final party =
        _getPartyName(item);

        if (party.toUpperCase() !=
            selectedPartyFilter
                .toUpperCase()) {
          continue;
        }
      }

      availableCandidates.add(item);
    }

    availableCandidates.sort(
          (a, b) =>
          _getCandidateName(a)
              .toUpperCase()
              .compareTo(
            _getCandidateName(b)
                .toUpperCase(),
          ),
    );

    return availableCandidates;
  }

  // ============================================================
  // GET FILTERED CANDIDATES
  //
  // Existing candidate data is not changed.
  // Candidates are displayed only after a filter is selected.
  // ============================================================

  List<Map<String, dynamic>>
  _getFilteredCandidates() {
    final List<Map<String, dynamic>>
    filteredCandidates = [];

    // ----------------------------------------------------------
    // IMPORTANT:
    // If both filters are at their default values,
    // do not display any candidate cards.
    // ----------------------------------------------------------

    final bool noFilterSelected =
        selectedPartyFilter ==
            'All Parties' &&
            selectedCandidateFilter ==
                'All Candidates';

    if (noFilterSelected) {
      return filteredCandidates;
    }

    for (final item in candidates) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      // --------------------------------------------------------
      // PARTY FILTER
      // --------------------------------------------------------

      if (selectedPartyFilter !=
          'All Parties') {
        final party =
        _getPartyName(item);

        if (party.toUpperCase() !=
            selectedPartyFilter
                .toUpperCase()) {
          continue;
        }
      }

      // --------------------------------------------------------
      // CANDIDATE FILTER
      // --------------------------------------------------------

      if (selectedCandidateFilter !=
          'All Candidates') {
        final candidateKey =
        _getCandidateFilterKey(item);

        if (candidateKey !=
            selectedCandidateFilter) {
          continue;
        }
      }

      filteredCandidates.add(item);
    }

    return filteredCandidates;
  }

  // ============================================================
  // ADD CANDIDATE
  // ============================================================

  Future<void> _showAddCandidateDialog() async {
    final candidateNameController =
    TextEditingController();

    final partyNameController =
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

    final symbolController =
    TextEditingController();

    bool dialogSaving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            Future<void> saveCandidate() async {
              if (candidateNameController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter candidate name.',
                );
                return;
              }

              if (partyNameController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter party name.',
                );
                return;
              }

              if (symbolController.text
                  .trim()
                  .isEmpty) {
                _showDialogMessage(
                  dialogContext,
                  'Please enter candidate symbol.',
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

              setDialogState(() {
                dialogSaving = true;
              });

              try {
                await ApiService.addCandidate(
                  candidateName:
                  candidateNameController.text
                      .trim(),
                  partyName:
                  partyNameController.text
                      .trim(),
                  district:
                  districtController.text
                      .trim(),
                  taluk:
                  talukController.text
                      .trim(),
                  block:
                  blockController.text
                      .trim(),
                  panchayat:
                  panchayatController.text
                      .trim(),
                  ward:
                  wardController.text
                      .trim(),
                  booth:
                  boothController.text
                      .trim(),
                  symbol:
                  symbolController.text
                      .trim(),
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

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Candidate added successfully.',
                    ),
                    backgroundColor:
                    Colors.green,
                  ),
                );

                await _loadCandidates();
              } catch (e) {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  dialogSaving = false;
                });

                _showDialogMessage(
                  dialogContext,
                  e.toString().replaceFirst(
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
                    Icons.person_add_alt_1_rounded,
                    color:
                    Color(0xFF102A43),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Add Candidate',
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
                        candidateNameController,
                        label: 'Candidate Name',
                        hint:
                        'Enter candidate name',
                      ),
                      _buildTextField(
                        controller:
                        partyNameController,
                        label: 'Party Name',
                        hint:
                        'Enter party name',
                      ),
                      _buildTextField(
                        controller:
                        symbolController,
                        label: 'Party Symbol',
                        hint:
                        'Example: 🌞',
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
                      : saveCandidate,
                  icon: dialogSaving
                      ? const SizedBox(
                    width: 17,
                    height: 17,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.save_rounded,
                    size: 18,
                  ),
                  label: Text(
                    dialogSaving
                        ? 'Saving...'
                        : 'Save Candidate',
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF102A43,
                    ),
                    foregroundColor:
                    Colors.white,
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
            );
          },
        );
      },
    );

    candidateNameController.dispose();
    partyNameController.dispose();
    districtController.dispose();
    talukController.dispose();
    blockController.dispose();
    panchayatController.dispose();
    wardController.dispose();
    boothController.dispose();
    symbolController.dispose();
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor:
          const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFFE1EAF2),
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFFE1EAF2),
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF102A43),
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
  // REMOVE CANDIDATE
  // ============================================================

  Future<void> _confirmRemoveCandidate(
      int candidateId,
      String candidateName,
      String partyName,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text(
                'Remove Candidate',
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove '
                '$candidateName ($partyName)?',
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
      setState(() {
        isLoading = true;
      });

      await ApiService.removeCandidate(
        candidateId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Candidate removed successfully.',
          ),
          backgroundColor:
          Colors.green,
        ),
      );

      await _loadCandidates();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
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
          Colors.red.shade700,
        ),
      );
    }
  }

  // ============================================================
  // SYMBOL
  // ============================================================

  Widget _buildCandidateSymbol(
      Map<String, dynamic> candidate,
      ) {
    final party =
    (candidate['party_name'] ??
        candidate['party'] ??
        '')
        .toString()
        .trim()
        .toUpperCase();

    final symbol =
    (candidate['symbol'] ?? '')
        .toString()
        .trim();

    IconData icon =
        Icons.how_to_vote_rounded;

    Color iconColor =
    const Color(0xFF102A43);

    if (party == 'TVK') {
      icon =
          Icons.local_fire_department_rounded;
      iconColor =
      const Color(0xFFD32F2F);
    } else if (party == 'DMK') {
      icon =
          Icons.wb_sunny_rounded;
      iconColor =
      const Color(0xFFE53935);
    } else if (party == 'ADMK' ||
        party == 'AIADMK') {
      icon =
          Icons.eco_rounded;
      iconColor =
      const Color(0xFF16803A);
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color:
        iconColor.withOpacity(0.10),
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: symbol.isNotEmpty
          ? Center(
        child: Text(
          symbol,
          style: const TextStyle(
            fontSize: 30,
          ),
        ),
      )
          : Icon(
        icon,
        color: iconColor,
        size: 34,
      ),
    );
  }

  // ============================================================
  // CANDIDATE CARD
  // ============================================================

  Widget _buildCandidateCard(
      Map<String, dynamic> candidate,
      int index,
      ) {
    final candidateName =
    (candidate['candidate_name'] ??
        candidate['name'] ??
        'Unknown Candidate')
        .toString();

    final partyName =
    (candidate['party_name'] ??
        candidate['party'] ??
        'Independent')
        .toString();

    final district =
    (candidate['district'] ?? '-')
        .toString();

    final taluk =
    (candidate['taluk'] ?? '-')
        .toString();

    final block =
    (candidate['block'] ?? '-')
        .toString();

    final panchayat =
    (candidate['panchayat'] ?? '-')
        .toString();

    final ward =
    (candidate['ward'] ?? '-')
        .toString();

    final booth =
    (candidate['booth'] ?? '-')
        .toString();

    final candidateIdValue =
    candidate['id'];

    final int? candidateId =
    candidateIdValue is int
        ? candidateIdValue
        : int.tryParse(
      candidateIdValue
          ?.toString() ??
          '',
    );

    final candidateIdDisplay =
        candidateId?.toString() ??
            (index + 1).toString();

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(bottom: 14),
      padding:
      const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFE1EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.025,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
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
              _buildCandidateSymbol(
                candidate,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidateName,
                      style:
                      const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xFFE8F0F7,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          20,
                        ),
                      ),
                      child: Text(
                        partyName,
                        style:
                        const TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w800,
                          color:
                          Color(0xFF102A43),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFFF5F8FC),
                  borderRadius:
                  BorderRadius.circular(
                    8,
                  ),
                ),
                child: Text(
                  '#$candidateIdDisplay',
                  style:
                  const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(
            height: 1,
            color: Color(0xFFE1EAF2),
          ),

          const SizedBox(height: 14),

          const Text(
            'Election Location',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF102A43),
            ),
          ),

          const SizedBox(height: 10),

          _buildLocationRow(
            Icons.location_city_rounded,
            'District',
            district,
          ),

          _buildLocationRow(
            Icons.map_rounded,
            'Taluk',
            taluk,
          ),

          _buildLocationRow(
            Icons.account_tree_rounded,
            'Block',
            block,
          ),

          _buildLocationRow(
            Icons.home_work_rounded,
            'Panchayat',
            panchayat,
          ),

          _buildLocationRow(
            Icons.pin_drop_rounded,
            'Ward',
            ward,
          ),

          _buildLocationRow(
            Icons.meeting_room_rounded,
            'Booth',
            booth,
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: candidateId == null
                  ? null
                  : () =>
                  _confirmRemoveCandidate(
                    candidateId,
                    candidateName,
                    partyName,
                  ),
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
              ),
              label: const Text(
                'Remove Candidate',
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
                const EdgeInsets
                    .symmetric(
                  vertical: 11,
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
        ],
      ),
    );
  }

  // ============================================================
  // LOCATION ROW
  // ============================================================

  Widget _buildLocationRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color:
            const Color(0xFF64748B),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 82,
            child: Text(
              title,
              style:
              const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF64748B),
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontSize: 12,
                color:
                Color(0xFF334E68),
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(30),
      decoration: BoxDecoration(
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
          const Icon(
            Icons.how_to_vote_outlined,
            size: 52,
            color:
            Color(0xFF94A3B8),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Candidates Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'No candidate records are available from the database.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color:
              Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed:
            _showAddCandidateDialog,
            icon: const Icon(
              Icons.add,
            ),
            label: const Text(
              'Add Candidate',
            ),
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              const Color(
                0xFF102A43,
              ),
              foregroundColor:
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO FILTER RESULTS
  // ============================================================

  Widget _buildNoFilterResultsState() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(30),
      decoration: BoxDecoration(
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
          Icon(
            Icons.filter_alt_off_rounded,
            size: 52,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No Candidates Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'No candidates match the selected filters.',
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
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
        const Color(0xFFFFF5F5),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color:
          const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color:
            Color(0xFFD92D20),
          ),
          const SizedBox(height: 12),
          const Text(
            'Unable to Load Candidates',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF991B1B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage.isEmpty
                ? 'Please check the backend connection.'
                : errorMessage,
            textAlign:
            TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color:
              Color(0xFF7F1D1D),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 45,
            child:
            ElevatedButton.icon(
              onPressed:
              _loadCandidates,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label:
              const Text('Retry'),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF102A43,
                ),
                foregroundColor:
                Colors.white,
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
        ],
      ),
    );
  }

  // ============================================================
  // PARTY FILTER UI
  // ============================================================

  Widget _buildPartyFilter(
      List<String> availableParties,
      ) {
    final List<String> filterItems = [
      'All Parties',
      ...availableParties,
    ];

    if (!filterItems.contains(
      selectedPartyFilter,
    )) {
      selectedPartyFilter = 'All Parties';
      selectedCandidateFilter =
      'All Candidates';
    }

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE1EAF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
              const Color(0xFFE8F0F7),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.filter_list_rounded,
              color:
              Color(0xFF102A43),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Filter by Party',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF102A43),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Flexible prevents Right Overflow.
          Flexible(
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color:
                const Color(0xFFF5F8FC),
                borderRadius:
                BorderRadius.circular(10),
                border: Border.all(
                  color:
                  const Color(0xFFE1EAF2),
                ),
              ),
              child:
              DropdownButtonHideUnderline(
                child:
                DropdownButton<String>(
                  value:
                  selectedPartyFilter,
                  isDense: true,
                  isExpanded: true,
                  icon: const Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                    color:
                    Color(0xFF102A43),
                  ),
                  style:
                  const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF102A43),
                  ),
                  items:
                  filterItems.map(
                        (party) {
                      return DropdownMenuItem<
                          String>(
                        value: party,
                        child: Text(
                          party,
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged:
                      (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedPartyFilter =
                          value;

                      // Reset candidate filter
                      // whenever party changes.
                      selectedCandidateFilter =
                      'All Candidates';
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CANDIDATE FILTER UI
  // ============================================================

  Widget _buildCandidateFilter(
      List<Map<String, dynamic>>
      availableCandidates,
      ) {
    final List<String> filterItems = [
      'All Candidates',
      ...availableCandidates.map(
            (candidate) =>
            _getCandidateFilterKey(
              candidate,
            ),
      ),
    ];

    if (!filterItems.contains(
      selectedCandidateFilter,
    )) {
      selectedCandidateFilter =
      'All Candidates';
    }

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE1EAF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
              const Color(0xFFE8F0F7),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.person_search_rounded,
              color:
              Color(0xFF102A43),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Select Candidate',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF102A43),
              ),
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              decoration: BoxDecoration(
                color:
                const Color(0xFFF5F8FC),
                borderRadius:
                BorderRadius.circular(10),
                border: Border.all(
                  color:
                  const Color(0xFFE1EAF2),
                ),
              ),
              child:
              DropdownButtonHideUnderline(
                child:
                DropdownButton<String>(
                  value:
                  selectedCandidateFilter,
                  isDense: true,
                  isExpanded: true,
                  icon: const Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                    color:
                    Color(0xFF102A43),
                  ),
                  style:
                  const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF102A43),
                  ),
                  items:
                  filterItems.map(
                        (candidateKey) {
                      String displayText =
                          candidateKey;

                      // ------------------------------------------------
                      // ONLY CANDIDATE NAME DISPLAY
                      // ------------------------------------------------

                      if (candidateKey !=
                          'All Candidates') {
                        Map<String, dynamic>?
                        selectedCandidate;

                        for (final candidate
                        in availableCandidates) {
                          if (_getCandidateFilterKey(
                            candidate,
                          ) ==
                              candidateKey) {
                            selectedCandidate =
                                candidate;
                            break;
                          }
                        }

                        if (selectedCandidate !=
                            null) {
                          displayText =
                              _getCandidateName(
                                selectedCandidate,
                              );
                        }
                      }

                      return DropdownMenuItem<
                          String>(
                        value:
                        candidateKey,
                        child: Text(
                          displayText,
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ).toList(),
                  onChanged:
                      (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedCandidateFilter =
                          value;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final filteredCandidates =
    _getFilteredCandidates();

    final availableParties =
    _getAvailableParties();

    final availableCandidates =
    _getAvailableCandidates();

    // ----------------------------------------------------------
    // Show candidate list only when at least one filter
    // is actually selected.
    // ----------------------------------------------------------

    final bool hasSelectedFilter =
        selectedPartyFilter !=
            'All Parties' ||
            selectedCandidateFilter !=
                'All Candidates';

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor:
        Colors.white,
        elevation: 0,

        title: const Text(
          'Candidates',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed:
            isLoading
                ? null
                : _loadCandidates,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            tooltip:
            'Refresh Candidates',
          ),
        ],
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed:
        isSaving
            ? null
            : _showAddCandidateDialog,
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor:
        Colors.white,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Add Candidate',
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh:
          _loadCandidates,

          color:
          const Color(0xFF102A43),

          child:
          SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),

            padding:
            const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // SECTION TITLE
                // ------------------------------------------------

                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Candidate List',
                        style:
                        TextStyle(
                          fontSize: 20,
                          fontWeight:
                          FontWeight
                              .w800,
                          color:
                          Color(
                            0xFF102A43,
                          ),
                        ),
                      ),
                    ),
                    if (!isLoading &&
                        errorMessage
                            .isEmpty)
                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xFFE8F0F7,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            20,
                          ),
                        ),
                        child: Text(
                          '${candidates.length}',
                          style:
                          const TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight
                                .w800,
                            color:
                            Color(
                              0xFF102A43,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                // ------------------------------------------------
                // PARTY FILTER
                // ------------------------------------------------

                if (!isLoading &&
                    errorMessage
                        .isEmpty &&
                    candidates
                        .isNotEmpty)
                  _buildPartyFilter(
                    availableParties,
                  ),

                if (!isLoading &&
                    errorMessage
                        .isEmpty &&
                    candidates
                        .isNotEmpty)
                  const SizedBox(
                    height: 12,
                  ),

                // ------------------------------------------------
                // CANDIDATE FILTER
                // ------------------------------------------------

                if (!isLoading &&
                    errorMessage
                        .isEmpty &&
                    candidates
                        .isNotEmpty)
                  _buildCandidateFilter(
                    availableCandidates,
                  ),

                if (!isLoading &&
                    errorMessage
                        .isEmpty &&
                    candidates
                        .isNotEmpty)
                  const SizedBox(
                    height: 16,
                  ),

                // ------------------------------------------------
                // CONTENT
                // ------------------------------------------------

                if (isLoading)
                  const Padding(
                    padding:
                    EdgeInsets.only(
                      top: 70,
                    ),
                    child: Center(
                      child:
                      CircularProgressIndicator(
                        color:
                        Color(
                          0xFF102A43,
                        ),
                      ),
                    ),
                  )
                else if (errorMessage
                    .isNotEmpty)
                  _buildErrorState()
                else if (candidates
                      .isEmpty)
                    _buildEmptyState()
                  else if (!hasSelectedFilter)
                    // ------------------------------------------------
                    // INITIAL STATE:
                    // No candidate cards are shown.
                    // ------------------------------------------------
                      const SizedBox.shrink()
                    else if (filteredCandidates
                          .isEmpty)
                        _buildNoFilterResultsState()
                      else
                        ...List.generate(
                          filteredCandidates
                              .length,
                              (index) {
                            final item =
                            filteredCandidates[
                            index];

                            return _buildCandidateCard(
                              item,
                              index,
                            );
                          },
                        ),

                const SizedBox(
                  height: 80,
                ),

                const Center(
                  child: Text(
                    'SmartPoll • Candidate Management',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                      Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}