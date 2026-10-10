import 'package:flutter/material.dart';

class VisualCryptographyResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const VisualCryptographyResultScreen({
    super.key,
    required this.result,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  String _stringValue(
      dynamic value,
      String fallback,
      ) {
    final text = value?.toString().trim();

    if (text == null || text.isEmpty) {
      return fallback;
    }

    return text;
  }

  int _intValue(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  // ============================================================
  // PARTY-WISE VOTE CALCULATION
  // ============================================================

  Map<String, int> _calculatePartyVotes(
      List<dynamic> voteList,
      ) {
    final Map<String, int> partyVotes = {};

    for (final item in voteList) {
      if (item is! Map) {
        continue;
      }

      final partyName = _stringValue(
        item['party_name'],
        '',
      );

      if (partyName.isEmpty) {
        continue;
      }

      partyVotes[partyName] =
          (partyVotes[partyName] ?? 0) + 1;
    }

    return partyVotes;
  }

  // ============================================================
  // PARTY WINNER
  // ============================================================

  List<Map<String, dynamic>> _getWinningParties(
      Map<String, int> partyVotes,
      ) {
    if (partyVotes.isEmpty) {
      return [];
    }

    final highestVote =
    partyVotes.values.reduce(
          (a, b) => a > b ? a : b,
    );

    final winners = <Map<String, dynamic>>[];

    partyVotes.forEach(
          (party, votes) {
        if (votes == highestVote) {
          winners.add({
            'party_name': party,
            'vote_count': votes,
          });
        }
      },
    );

    return winners;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final reconstructedVotes =
    result['reconstructed_votes'];

    final totalVotes = _intValue(
      result['total_votes'],
    );

    final totalShares = _intValue(
      result['total_shares'],
    );

    final voteList =
    reconstructedVotes is List
        ? reconstructedVotes
        : <dynamic>[];

    final partyVotes =
    _calculatePartyVotes(
      voteList,
    );

    final winningParties =
    _getWinningParties(
      partyVotes,
    );

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
          'Reconstructed Results',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            // ==================================================
            // SUMMARY
            // ==================================================

            _buildSummaryCard(
              totalVotes: totalVotes,
              totalShares: totalShares,
            ),

            const SizedBox(height: 24),

            // ==================================================
            // WINNING PARTY
            // ==================================================

            _buildSectionTitle(
              'Winning Party',
              Icons.emoji_events_rounded,
            ),

            const SizedBox(height: 12),

            if (winningParties.isEmpty)
              _buildNoWinnerCard()
            else
              _buildWinningPartyCard(
                winningParties:
                winningParties,
              ),

            const SizedBox(height: 24),

            // ==================================================
            // PARTY VOTE DISTRIBUTION
            // ==================================================

            _buildSectionTitle(
              'Party Vote Distribution',
              Icons.pie_chart_rounded,
            ),

            const SizedBox(height: 12),

            if (partyVotes.isEmpty)
              _buildNoChartDataCard()
            else
              _buildPartyPieChart(
                partyVotes: partyVotes,
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard({
    required int totalVotes,
    required int totalShares,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            icon:
            Icons.how_to_vote_rounded,
            value:
            totalVotes.toString(),
            label:
            'Reconstructed Votes',
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _buildSummaryItem(
            icon:
            Icons.layers_rounded,
            value:
            totalShares.toString(),
            label:
            'Shares Combined',
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
      padding:
      const EdgeInsets.all(16),

      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration:
            BoxDecoration(
              color:
              const Color(0xFFE8F0F7),
              borderRadius:
              BorderRadius.circular(11),
            ),

            child: Icon(
              icon,
              color:
              const Color(0xFF102A43),
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  value,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF102A43),
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  label,
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color:
          const Color(0xFF102A43),
          size: 23,
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style:
          const TextStyle(
            color:
            Color(0xFF102A43),
            fontSize: 18,
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WINNING PARTY CARD
  // ============================================================

  Widget _buildWinningPartyCard({
    required List<Map<String, dynamic>>
    winningParties,
  }) {
    final highestVote =
    _intValue(
      winningParties.first['vote_count'],
    );

    final isTie =
        winningParties.length > 1;

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(22),

      decoration:
      BoxDecoration(
        color:
        const Color(0xFFE8F5E9),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFA5D6A7),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          Icon(
            isTie
                ? Icons.balance_rounded
                : Icons.emoji_events_rounded,
            color:
            const Color(0xFF2E7D32),
            size: 42,
          ),

          const SizedBox(height: 10),

          Text(
            isTie
                ? 'Party Vote Tie'
                : 'Winning Party',
            style:
            const TextStyle(
              color:
              Color(0xFF2E7D32),
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            winningParties
                .map(
                  (party) =>
                  _stringValue(
                    party['party_name'],
                    'Party',
                  ),
            )
                .join(' • '),
            textAlign:
            TextAlign.center,

            style:
            const TextStyle(
              color:
              Color(0xFF1B5E20),
              fontSize: 23,
              fontWeight:
              FontWeight.w900,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            '$highestVote vote${highestVote == 1 ? '' : 's'}',
            style:
            const TextStyle(
              color:
              Color(0xFF2E7D32),
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PARTY PIE CHART
  // ============================================================

  Widget _buildPartyPieChart({
    required Map<String, int> partyVotes,
  }) {
    final displayParties =
    <String, int>{};

    for (final party in [
      'TVK',
      'DMK',
      'ADMK',
    ]) {
      if (partyVotes.containsKey(party)) {
        displayParties[party] =
        partyVotes[party]!;
      }
    }

    // Keep any existing party names
    // without changing the original data.
    for (final entry
    in partyVotes.entries) {
      if (!displayParties
          .containsKey(entry.key)) {
        displayParties[entry.key] =
            entry.value;
      }
    }

    final total =
    displayParties.values.fold<int>(
      0,
          (sum, value) => sum + value,
    );

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),

      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          SizedBox(
            width: 220,
            height: 220,

            child: CustomPaint(
              painter:
              _PartyPieChartPainter(
                partyVotes:
                displayParties,
              ),
            ),
          ),

          const SizedBox(height: 20),

          ...displayParties.entries.map(
                (entry) {
              final percentage =
              total == 0
                  ? 0
                  : (entry.value /
                  total) *
                  100;

              return Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 10,
                ),

                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,

                      decoration:
                      BoxDecoration(
                        color:
                        _partyColor(
                          entry.key,
                        ),
                        shape:
                        BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        entry.key,
                        style:
                        const TextStyle(
                          color:
                          Color(
                            0xFF102A43,
                          ),
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ),

                    Text(
                      '${entry.value} votes',
                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF334E68,
                        ),
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(width: 12),

                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style:
                      const TextStyle(
                        color:
                        Color(
                          0xFF102A43,
                        ),
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PARTY COLOR
  // ============================================================

  Color _partyColor(String partyName) {
    final normalized =
    partyName.trim().toUpperCase();

    if (normalized == 'TVK') {
      return const Color(0xFF1565C0);
    }

    if (normalized == 'DMK') {
      return const Color(0xFFD32F2F);
    }

    if (normalized == 'ADMK' ||
        normalized == 'AIADMK') {
      return const Color(0xFF2E7D32);
    }

    return const Color(0xFF7B61A8);
  }

  // ============================================================
  // NO WINNER
  // ============================================================

  Widget _buildNoWinnerCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(20),

      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFFE2E8F0),
        ),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color:
            Color(0xFF64748B),
            size: 34,
          ),

          SizedBox(height: 8),

          Text(
            'No party result available',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Color(0xFF334E68),
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NO CHART DATA
  // ============================================================

  Widget _buildNoChartDataCard() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(24),

      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color:
          const Color(0xFFE2E8F0),
        ),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.pie_chart_outline_rounded,
            color:
            Color(0xFF94A3B8),
            size: 38,
          ),

          SizedBox(height: 9),

          Text(
            'No party vote data available',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Color(0xFF334E68),
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PIE CHART PAINTER
// ============================================================

class _PartyPieChartPainter
    extends CustomPainter {
  final Map<String, int> partyVotes;

  _PartyPieChartPainter({
    required this.partyVotes,
  });

  Color _partyColor(String partyName) {
    final normalized =
    partyName.trim().toUpperCase();

    if (normalized == 'TVK') {
      return const Color(0xFF1565C0);
    }

    if (normalized == 'DMK') {
      return const Color(0xFFD32F2F);
    }

    if (normalized == 'ADMK' ||
        normalized == 'AIADMK') {
      return const Color(0xFF2E7D32);
    }

    return const Color(0xFF7B61A8);
  }

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final total =
    partyVotes.values.fold<int>(
      0,
          (sum, value) => sum + value,
    );

    if (total <= 0) {
      return;
    }

    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        size.shortestSide / 2;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    double startAngle =
    -1.57079632679;

    for (final entry
    in partyVotes.entries) {
      final sweepAngle =
          (entry.value / total) *
              6.28318530718;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color =
        _partyColor(entry.key);

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Center circle for donut-style chart.
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    canvas.drawCircle(
      center,
      radius * 0.42,
      centerPaint,
    );

    final textPainter =
    TextPainter(
      text: TextSpan(
        text: total.toString(),
        style: const TextStyle(
          color:
          Color(0xFF102A43),
          fontSize: 24,
          fontWeight:
          FontWeight.w800,
        ),
      ),
      textDirection:
      TextDirection.ltr,
    );

    textPainter.layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx -
            textPainter.width / 2,
        center.dy -
            textPainter.height / 2 -
            4,
      ),
    );

    final labelPainter =
    TextPainter(
      text: const TextSpan(
        text: 'Votes',
        style: TextStyle(
          color:
          Color(0xFF64748B),
          fontSize: 9,
          fontWeight:
          FontWeight.w600,
        ),
      ),
      textDirection:
      TextDirection.ltr,
    );

    labelPainter.layout();

    labelPainter.paint(
      canvas,
      Offset(
        center.dx -
            labelPainter.width / 2,
        center.dy + 10,
      ),
    );
  }

  @override
  bool shouldRepaint(
      covariant _PartyPieChartPainter oldDelegate,
      ) {
    return oldDelegate.partyVotes !=
        partyVotes;
  }
}