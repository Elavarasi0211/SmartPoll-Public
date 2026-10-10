import 'package:flutter/material.dart';
import 'api_service.dart';

class DemographicsAnalyticsScreen extends StatefulWidget {
  const DemographicsAnalyticsScreen({
    super.key,
  });

  @override
  State<DemographicsAnalyticsScreen> createState() =>
      _DemographicsAnalyticsScreenState();
}

class _DemographicsAnalyticsScreenState
    extends State<DemographicsAnalyticsScreen> {
  bool isLoading = true;
  String? errorMessage;

  int totalVoters = 0;
  int votedVoters = 0;
  int notVotedVoters = 0;
  double participationPercentage = 0.0;

  Map<String, dynamic> voterDemographics = {};

  // ============================================================
  // DEMOGRAPHIC LEVEL
  // ============================================================

  String selectedDemographic = 'District';

  final List<String> demographicFilters = [
    'District',
    'Taluk',
    'Block',
    'Panchayat',
    'Ward',
    'Booth',
  ];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getAdminAnalytics();

      final voterOverview =
      data['voter_overview'] is Map<String, dynamic>
          ? data['voter_overview'] as Map<String, dynamic>
          : <String, dynamic>{};

      final demographics =
      data['voter_demographics'] is Map<String, dynamic>
          ? data['voter_demographics'] as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        totalVoters = _toInt(
          voterOverview['total_voters'],
        );

        votedVoters = _toInt(
          voterOverview['voted_voters'],
        );

        notVotedVoters = _toInt(
          voterOverview['not_voted_voters'],
        );

        participationPercentage = _toDouble(
          voterOverview['participation_percentage'],
        );

        voterDemographics = demographics;

        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = error.toString();
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0.0;
  }

  // ============================================================
  // DEMOGRAPHIC LEVEL SELECTOR
  // ============================================================

  Widget _buildDemographicLevelSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
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
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF1F4E79),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Demographic Level',
              style: TextStyle(
                color: Color(0xFF102A43),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedDemographic,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF102A43),
              ),
              style: const TextStyle(
                color: Color(0xFF102A43),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              items: demographicFilters
                  .map(
                    (level) => DropdownMenuItem<String>(
                  value: level,
                  child: Text(level),
                ),
              )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedDemographic = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SELECTED DEMOGRAPHIC DATA
  // ============================================================

  Widget _buildSelectedDemographic() {
    final selectedField = selectedDemographic.toLowerCase();

    final data = voterDemographics[selectedField];

    return _buildDemographicCard(
      title: selectedDemographic,
      data: data is List ? data : <dynamic>[],
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        title: const Text(
          'Demographics & Analytics',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : _loadAnalytics,
            tooltip: 'Refresh',
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ==================================================
              // VOTER PARTICIPATION
              // ==================================================

              _buildSectionTitle(
                'Voter Participation',
                Icons.how_to_vote_outlined,
              ),

              const SizedBox(height: 12),

              _buildParticipationCard(),

              const SizedBox(height: 24),

              // ==================================================
              // VOTER DEMOGRAPHICS
              // ==================================================

              _buildSectionTitle(
                'Voter Demographics',
                Icons.location_on_outlined,
              ),

              const SizedBox(height: 12),

              // ONE DEMOGRAPHIC LEVEL SELECTOR
              _buildDemographicLevelSelector(),

              const SizedBox(height: 12),

              // ONLY SELECTED LEVEL DATA
              _buildSelectedDemographic(),

              const SizedBox(height: 20),
            ],
          ),
        ),
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

  // ============================================================
  // VOTER PARTICIPATION
  // ============================================================

  Widget _buildParticipationCard() {
    final votedRatio = totalVoters > 0
        ? votedVoters / totalVoters
        : 0.0;

    final notVotedRatio = totalVoters > 0
        ? notVotedVoters / totalVoters
        : 0.0;

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Voted vs Not Voted',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF102A43),
                ),
              ),
              Text(
                '${participationPercentage.toStringAsFixed(2)}%',
                style: const TextStyle(
                  color: Color(0xFF1F4E79),
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: votedVoters == 0
                      ? 1
                      : votedVoters,
                  child: Container(
                    height: 20,
                    color:
                    const Color(0xFF2E7D32),
                  ),
                ),
                Expanded(
                  flex: notVotedVoters == 0
                      ? 1
                      : notVotedVoters,
                  child: Container(
                    height: 20,
                    color:
                    const Color(0xFFE0E7EF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _buildLegendItem(
                  title: 'Voted',
                  value: votedVoters,
                  percentage:
                  votedRatio * 100,
                  color:
                  const Color(0xFF2E7D32),
                ),
              ),
              Expanded(
                child: _buildLegendItem(
                  title: 'Not Voted',
                  value: notVotedVoters,
                  percentage:
                  notVotedRatio * 100,
                  color:
                  const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String title,
    required int value,
    required double percentage,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
                  color: Color(0xFF475569),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$value (${percentage.toStringAsFixed(2)}%)',
                style: const TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DEMOGRAPHIC CARD
  // ============================================================

  Widget _buildDemographicCard({
    required String title,
    required List<dynamic> data,
  }) {
    return _buildWhiteCard(
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding:
        const EdgeInsets.only(
          bottom: 8,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2F8),
            borderRadius:
            BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_city_outlined,
            color: Color(0xFF1F4E79),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102A43),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${data.length} locations',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
        children: data.isEmpty
            ? [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No data available for this demographic level.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
        ]
            : data.map((item) {
          final itemMap =
          item is Map<String, dynamic>
              ? item
              : <String, dynamic>{};

          final value =
              itemMap['value']?.toString() ??
                  'Not Specified';

          final count =
          _toInt(itemMap['count']);

          final percentage =
          totalVoters > 0
              ? (count / totalVoters) * 100
              : 0.0;

          return Padding(
            padding:
            const EdgeInsets.symmetric(
              vertical: 5,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style:
                        const TextStyle(
                          color:
                          Color(0xFF334155),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style:
                      const TextStyle(
                        color:
                        Color(0xFF102A43),
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 55,
                      child: Text(
                        '${percentage.toStringAsFixed(1)}%',
                        textAlign:
                        TextAlign.right,
                        style:
                        const TextStyle(
                          color:
                          Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value:
                  percentage / 100,
                  minHeight: 5,
                  borderRadius:
                  BorderRadius.circular(
                    5,
                  ),
                  backgroundColor:
                  const Color(0xFFE8EEF5),
                  valueColor:
                  const AlwaysStoppedAnimation<
                      Color>(
                    Color(0xFF1F4E79),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // WHITE CARD
  // ============================================================

  Widget _buildWhiteCard({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // ERROR VIEW
  // ============================================================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildWhiteCard(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFC62828),
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to Load Analytics',
                style: TextStyle(
                  color: Color(0xFF102A43),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ??
                    'Something went wrong.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'Retry',
                ),
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF102A43),
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
                    BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}