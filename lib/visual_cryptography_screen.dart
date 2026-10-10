import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'visual_cryptography_result_screen.dart';

class VisualCryptographyScreen extends StatefulWidget {
  const VisualCryptographyScreen({
    super.key,
  });

  @override
  State<VisualCryptographyScreen> createState() =>
      _VisualCryptographyScreenState();
}

class _VisualCryptographyScreenState
    extends State<VisualCryptographyScreen> {
  bool isLoading = true;
  bool isCombining = false;
  bool showGeneratedShares = false;

  String? errorMessage;

  List<dynamic> votes = [];

  int totalVotedVoters = 0;
  int totalShares = 0;

  // PARTY FILTER
  String selectedParty = 'All Parties';

  @override
  void initState() {
    super.initState();
    _loadVisualCryptography();
  }

  Future<void> _loadVisualCryptography() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getVisualCryptography();

      if (!mounted) {
        return;
      }

      final loadedVotes = data['votes'];

      setState(() {
        votes = loadedVotes is List ? loadedVotes : [];

        totalVotedVoters =
            int.tryParse(
              data['total_voted_voters']?.toString() ?? '0',
            ) ??
                0;

        totalShares =
            int.tryParse(
              data['total_shares']?.toString() ?? '0',
            ) ??
                0;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  Future<void> _combineShares() async {
    if (isCombining) {
      return;
    }

    setState(() {
      isCombining = true;
    });

    try {
      final result =
      await ApiService.combineVisualCryptographyShares();

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisualCryptographyResultScreen(
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCombining = false;
        });
      }
    }
  }

  List<dynamic> get filteredVotes {
    if (selectedParty == 'All Parties') {
      return votes;
    }

    return votes.where((vote) {
      if (vote is! Map<String, dynamic>) {
        return false;
      }

      final partyName =
          vote['party_name']?.toString() ?? '';

      return partyName == selectedParty;
    }).toList();
  }

  List<String> get partyFilters {
    final parties = <String>{};

    for (final vote in votes) {
      if (vote is Map<String, dynamic>) {
        final partyName =
            vote['party_name']?.toString().trim() ?? '';

        if (partyName.isNotEmpty) {
          parties.add(partyName);
        }
      }
    }

    final result = parties.toList();
    result.sort();

    return [
      'All Parties',
      ...result,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Visual Cryptography',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF102A43),
        ),
      )
          : errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final displayedVotes = filteredVotes;

    return RefreshIndicator(
      color: const Color(0xFF102A43),
      onRefresh: _loadVisualCryptography,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 14),
            _buildCombineCard(),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Generated Vote Shares',
              Icons.layers_outlined,
            ),
            const SizedBox(height: 6),
            const Text(
              'Each counted vote is represented using two separate visual shares.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildPartyFilter(),
            const SizedBox(height: 12),
            _buildGeneratedSharesButton(),
            if (showGeneratedShares) ...[
              const SizedBox(height: 14),
              if (displayedVotes.isEmpty)
                _buildNoVotesCard()
              else
                ...List.generate(
                  displayedVotes.length,
                      (index) {
                    final vote = displayedVotes[index];

                    if (vote is Map<String, dynamic>) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 14,
                        ),
                        child: _buildVoteShareCard(
                          vote: vote,
                          voteNumber: index + 1,
                        ),
                      );
                    }

                    return const SizedBox();
                  },
                ),
            ],
            const SizedBox(height: 8),
            _buildInformationCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            icon: Icons.how_to_vote_rounded,
            value: totalVotedVoters.toString(),
            label: 'Voted Voters',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryItem(
            icon: Icons.layers_rounded,
            value: totalShares.toString(),
            label: 'Total Shares',
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0F7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF102A43),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF102A43),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyFilter() {
    final options = partyFilters;

    if (!options.contains(selectedParty)) {
      selectedParty = 'All Parties';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.filter_list_rounded,
            color: Color(0xFF102A43),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            'Party',
            style: TextStyle(
              color: Color(0xFF334E68),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedParty,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF102A43),
                ),
                style: const TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                items: options.map(
                      (party) {
                    return DropdownMenuItem<String>(
                      value: party,
                      child: Text(
                        party,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedParty = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedSharesButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            showGeneratedShares = !showGeneratedShares;
          });
        },
        icon: Icon(
          showGeneratedShares
              ? Icons.visibility_off_outlined
              : Icons.layers_outlined,
        ),
        label: Text(
          showGeneratedShares
              ? 'Hide Vote Shares'
              : 'Generated Vote Shares',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF102A43),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF102A43),
          size: 23,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteShareCard({
    required Map<String, dynamic> vote,
    required int voteNumber,
  }) {
    final voterId =
        vote['voter_id']?.toString() ?? '-';

    final voterName =
        vote['voter_name']?.toString() ??
            'Unknown Voter';

    final referenceId =
        vote['reference_id']?.toString() ?? '-';

    final candidateName =
        vote['candidate_name']?.toString() ??
            'Candidate';

    final partyName =
        vote['party_name']?.toString() ?? '';

    final share1 =
    vote['share_1']?.toString();

    final share2 =
    vote['share_2']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.how_to_vote_rounded,
                  color: Color(0xFF102A43),
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
                      'Vote $voteNumber',
                      style: const TextStyle(
                        color: Color(0xFF102A43),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$voterId • $voterName',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Stored',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  color: Color(0xFF1F4E79),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reference: $referenceId',
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Candidate: $candidateName',
            style: const TextStyle(
              color: Color(0xFF334E68),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (partyName.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              'Party: $partyName',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActualShare(
                  title: 'Share 1',
                  imageData: share1,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActualShare(
                  title: 'Share 2',
                  imageData: share2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActualShare({
    required String title,
    required String? imageData,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          height: 125,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FC),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
            ),
          ),
          child: imageData == null ||
              imageData.isEmpty
              ? const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
          )
              : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _decodeBase64Image(imageData),
              fit: BoxFit.contain,
              errorBuilder: (
                  context,
                  error,
                  stackTrace,
                  ) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF94A3B8),
                    size: 28,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Uint8List _decodeBase64Image(
      String imageData,
      ) {
    try {
      final cleaned = imageData.contains(',')
          ? imageData.split(',').last
          : imageData;

      return base64Decode(cleaned);
    } catch (_) {
      return Uint8List(0);
    }
  }

  Widget _buildCombineCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.merge_type_rounded,
            color: Color(0xFF1F4E79),
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'Combine Vote Shares',
            style: TextStyle(
              color: Color(0xFF102A43),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Combine all stored Share 1 and Share 2 pairs to reconstruct the actual vote information.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
              votes.isEmpty || isCombining
                  ? null
                  : _combineShares,
              icon: isCombining
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.merge_type_rounded,
              ),
              label: Text(
                isCombining
                    ? 'Combining Shares...'
                    : 'Combine Shares',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF102A43),
                disabledBackgroundColor:
                const Color(0xFFB8C9D9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.layers_clear_outlined,
            color: Color(0xFF94A3B8),
            size: 40,
          ),
          SizedBox(height: 10),
          Text(
            'No voted records available',
            style: TextStyle(
              color: Color(0xFF334E68),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Vote shares will appear here after votes are recorded.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2F8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF1F4E79),
            size: 20,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Each vote is stored as two separate visual shares. The original vote information is reconstructed only when both shares are combined.',
              style: TextStyle(
                color: Color(0xFF334E68),
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFC62828),
                size: 34,
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Unable to load Visual Cryptography',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF102A43),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ??
                  'Unable to connect to the server.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadVisualCryptography,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Try Again',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF102A43),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}