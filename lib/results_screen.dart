import 'package:flutter/material.dart';

import 'api_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _totalVoters = 0;
  int _votedVoters = 0;
  int _remainingVoters = 0;

  List<dynamic> _candidates = [];

  @override
  void initState() {
    super.initState();

    // Load results after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResults();
    });
  }

  // ============================================================
  // LOAD ACTUAL RESULTS
  // ============================================================

  Future<void> _loadResults() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getAdminResults();

      if (!mounted) return;

      if (data.isEmpty) {
        throw Exception(
          'Empty election results received from server.',
        );
      }

      final totalVoters = _toInt(
        data['total_voters'],
      );

      final votedVoters = _toInt(
        data['voted_voters'],
      );

      final remainingVoters = _toInt(
        data['remaining_voters'],
      );

      final candidatesData = data['candidates'];

      List<dynamic> loadedCandidates = [];

      if (candidatesData is List) {
        loadedCandidates = List<dynamic>.from(
          candidatesData,
        );
      }

      setState(() {
        _totalVoters = totalVoters;
        _votedVoters = votedVoters;
        _remainingVoters = remainingVoters;
        _candidates = loadedCandidates;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(
          error,
        );
      });
    }
  }

  // ============================================================
  // CLEAN ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(dynamic error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(
        'Exception: '.length,
      );
    }

    return message.isEmpty
        ? 'Something went wrong while loading results.'
        : message;
  }

  // ============================================================
  // SAFE INTEGER CONVERSION
  // ============================================================

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '0',
    ) ??
        0;
  }

  // ============================================================
  // GET VOTE COUNT
  // ============================================================

  int _getVoteCount(dynamic candidate) {
    if (candidate is Map) {
      return _toInt(
        candidate['vote_count'],
      );
    }

    return 0;
  }

  // ============================================================
  // GET CANDIDATE NAME
  // ============================================================

  String _getCandidateName(dynamic candidate) {
    if (candidate is Map) {
      final name =
      candidate['candidate_name']?.toString();

      if (name != null && name.trim().isNotEmpty) {
        return name;
      }
    }

    return 'Unknown Candidate';
  }

  // ============================================================
  // GET PARTY NAME
  // ============================================================

  String _getPartyName(dynamic candidate) {
    if (candidate is Map) {
      final party =
      candidate['party_name']?.toString();

      if (party != null && party.trim().isNotEmpty) {
        return party;
      }
    }

    return 'Independent';
  }

  // ============================================================
  // GET SYMBOL
  // ============================================================

  String _getSymbol(dynamic candidate) {
    if (candidate is Map) {
      return candidate['symbol']?.toString() ?? '';
    }

    return '';
  }

  // ============================================================
  // GET CANDIDATE ID
  // ============================================================

  int _getCandidateId(dynamic candidate) {
    if (candidate is Map) {
      return _toInt(
        candidate['candidate_id'],
      );
    }

    return 0;
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(
          right: 8,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE3EAF2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius:
                BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF102A43),
                size: 21,
              ),
            ),
            const SizedBox(height: 11),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7C93),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                color: Color(0xFF102A43),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PARTY ACCENT COLOR
  // ============================================================

  Color _getPartyAccentColor(String party) {
    final normalizedParty =
    party.trim().toUpperCase();

    if (normalizedParty == 'TVK') {
      return const Color(0xFFC62828);
    }

    if (normalizedParty == 'DMK') {
      return const Color(0xFFD32F2F);
    }

    if (normalizedParty == 'ADMK' ||
        normalizedParty == 'AIADMK') {
      return const Color(0xFF2E7D32);
    }

    return const Color(0xFF102A43);
  }

  // ============================================================
  // GET REQUIRED PARTY GROUPS
  // ============================================================

  Map<String, List<dynamic>> _getRequiredPartyGroups() {
    final Map<String, List<dynamic>> grouped = {
      'TVK': <dynamic>[],
      'DMK': <dynamic>[],
      'ADMK': <dynamic>[],
    };

    for (final candidate in _candidates) {
      final party =
      _getPartyName(candidate)
          .trim()
          .toUpperCase();

      if (party == 'TVK') {
        grouped['TVK']!.add(candidate);
      } else if (party == 'DMK') {
        grouped['DMK']!.add(candidate);
      } else if (party == 'ADMK' ||
          party == 'AIADMK') {
        grouped['ADMK']!.add(candidate);
      }
    }

    return grouped;
  }

  // ============================================================
  // PARTY RESULT BOX
  // ============================================================

  Widget _partyResultBox({
    required String party,
    required List<dynamic> candidates,
  }) {
    final partyVotes = candidates.fold<int>(
      0,
          (sum, candidate) {
        return sum + _getVoteCount(candidate);
      },
    );

    final accentColor =
    _getPartyAccentColor(party);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE3EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        childrenPadding:
        const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        collapsedShape:
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius:
            BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.account_balance_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          party,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF102A43),
          ),
        ),
        subtitle: Text(
          candidates.isEmpty
              ? 'No candidate data'
              : '${candidates.length} candidate${candidates.length == 1 ? '' : 's'}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7C93),
          ),
        ),
        trailing: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            Text(
              '$partyVotes',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const Text(
              'Votes',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF6B7C93),
              ),
            ),
          ],
        ),
        children: candidates.isEmpty
            ? [
          _emptyPartyContent(),
        ]
            : List.generate(
          candidates.length,
              (index) {
            return _candidateVoteRow(
              candidate:
              candidates[index],
              index: index,
              accentColor:
              accentColor,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // CANDIDATE VOTE ROW
  // ============================================================

  Widget _candidateVoteRow({
    required dynamic candidate,
    required int index,
    required Color accentColor,
  }) {
    final name =
    _getCandidateName(candidate);

    final symbol =
    _getSymbol(candidate);

    final candidateId =
    _getCandidateId(candidate);

    final votes =
    _getVoteCount(candidate);

    return Container(
      margin: EdgeInsets.only(
        bottom: index == 0 ? 0 : 10,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8EEF5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                symbol.isNotEmpty
                    ? symbol
                    : '${index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Candidate ID: $candidateId',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8A9BAD),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                '$votes',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              const Text(
                'Votes',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF6B7C93),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY PARTY CONTENT
  // ============================================================

  Widget _emptyPartyContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE8EEF5),
        ),
      ),
      child: const Text(
        'No candidate data available for this party.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7C93),
        ),
      ),
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Color(0xFFD9534F),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load results',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7C93),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : _loadResults,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'Try Again',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF102A43),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final partyGroups =
    _getRequiredPartyGroups();

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Election Results',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Results',
            onPressed: _isLoading
                ? null
                : _loadResults,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF102A43),
        ),
      )
          : _errorMessage != null
          ? _errorView()
          : RefreshIndicator(
        onRefresh: _loadResults,
        color:
        const Color(0xFF102A43),
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.all(16),
          children: [
            const Text(
              'Election Results',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                Color(0xFF102A43),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Results based on submitted votes.',
              style: TextStyle(
                fontSize: 13,
                color:
                Color(0xFF6B7C93),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // THREE SUMMARY BOXES
            // ==================================================

            Row(
              children: [
                _summaryCard(
                  title:
                  'Total Voters',
                  value:
                  '$_totalVoters',
                  icon: Icons
                      .people_outline,
                ),
                _summaryCard(
                  title:
                  'Voted Voters',
                  value:
                  '$_votedVoters',
                  icon: Icons
                      .verified_user_outlined,
                ),
                _summaryCard(
                  title:
                  'Remaining',
                  value:
                  '$_remainingVoters',
                  icon: Icons
                      .pending_actions_outlined,
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ==================================================
            // PARTY-WISE RESULTS
            // ==================================================

            const Text(
              'Party-wise Results',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color:
                Color(0xFF102A43),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Open a party to view its candidate vote counts.',
              style: TextStyle(
                fontSize: 12,
                color:
                Color(0xFF6B7C93),
              ),
            ),

            const SizedBox(height: 14),

            // TVK
            _partyResultBox(
              party: 'TVK',
              candidates:
              partyGroups['TVK']!,
            ),

            // DMK
            _partyResultBox(
              party: 'DMK',
              candidates:
              partyGroups['DMK']!,
            ),

            // ADMK
            _partyResultBox(
              party: 'ADMK',
              candidates:
              partyGroups['ADMK']!,
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}