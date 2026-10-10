import 'package:flutter/material.dart';
import 'api_service.dart';

class VerificationLogsScreen extends StatefulWidget {
  const VerificationLogsScreen({super.key});

  @override
  State<VerificationLogsScreen> createState() =>
      _VerificationLogsScreenState();
}

class _VerificationLogsScreenState
    extends State<VerificationLogsScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<dynamic> logs = [];

  @override
  void initState() {
    super.initState();
    loadVerificationLogs();
  }

  Future<void> loadVerificationLogs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await ApiService.getVerificationLogs();

      if (!mounted) return;

      final loadedLogs = data['logs'];

      setState(() {
        logs = loadedLogs is List ? loadedLogs : [];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // ============================================================
  // MAIN PAGE
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verification Logs',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading
                ? null
                : loadVerificationLogs,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: _buildMainBody(),
    );
  }

  Widget _buildMainBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF102A43),
        ),
      );
    }

    if (errorMessage != null) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 100),
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Unable to load verification logs',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102A43),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: loadVerificationLogs,
              icon: const Icon(
                Icons.refresh_rounded,
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
          ),
        ],
      );
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeaderCard(),

        const SizedBox(height: 22),

        _buildLoginButton(
          title: 'Voter Logins',
          subtitle:
          'View voter face verification logs',
          icon: Icons.people_alt_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    VoterLoginLogsScreen(
                      logs: logs,
                    ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        _buildLoginButton(
          title: 'Admin Logins',
          subtitle:
          'View admin face verification logs',
          icon:
          Icons.admin_panel_settings_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AdminLoginLogsScreen(
                      logs: logs,
                    ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              const Color(0xFFE8F0F7),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Color(0xFF102A43),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w700,
                    color:
                    Color(0xFF102A43),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Select a login type to view verification activity.',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                    Color(0xFF64748B),
                    height: 1.4,
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
  // MAIN LOGIN BUTTON
  // ============================================================

  Widget _buildLoginButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE1EAF2),
            ),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(0.035),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE8F0F7),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color:
                  const Color(0xFF102A43),
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// VOTER LOGIN LOGS PAGE
// ==================================================================

class VoterLoginLogsScreen extends StatefulWidget {
  final List<dynamic> logs;

  const VoterLoginLogsScreen({
    super.key,
    required this.logs,
  });

  @override
  State<VoterLoginLogsScreen> createState() =>
      _VoterLoginLogsScreenState();
}

class _VoterLoginLogsScreenState
    extends State<VoterLoginLogsScreen> {
  String selectedResultFilter = 'All';

  // ============================================================
  // CHECK ADMIN LOG
  // ============================================================

  bool isAdminLog(Map<String, dynamic> log) {
    final voterId =
    (log['voter_id'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    final verificationType =
    (log['verification_type'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    return voterId.startsWith('ADMIN') ||
        verificationType.contains('ADMIN');
  }

  // ============================================================
  // RESULT
  // ============================================================

  String getLogResult(Map<String, dynamic> log) {
    final result =
    (log['result'] ?? '')
        .toString()
        .trim();

    if (result.isEmpty) {
      return 'Not Tested';
    }

    final upperResult = result.toUpperCase();

    if (upperResult == 'MATCH' ||
        upperResult == 'MATCHED' ||
        upperResult == 'VERIFIED' ||
        upperResult == 'SUCCESS') {
      return 'Match';
    }

    if (upperResult == 'FAIL' ||
        upperResult == 'FAILED' ||
        upperResult == 'NO MATCH' ||
        upperResult == 'NOT MATCHED') {
      return 'Failed';
    }

    if (upperResult == 'NOT TESTED') {
      return 'Not Tested';
    }

    return result;
  }

  Color getResultColor(String result) {
    final normalized = result.toUpperCase();

    if (normalized == 'MATCH' ||
        normalized == 'MATCHED' ||
        normalized == 'VERIFIED' ||
        normalized == 'SUCCESS') {
      return const Color(0xFF16803A);
    }

    if (normalized == 'NOT TESTED') {
      return const Color(0xFF64748B);
    }

    return const Color(0xFFD92D20);
  }

  IconData getResultIcon(String result) {
    final normalized = result.toUpperCase();

    if (normalized == 'MATCH' ||
        normalized == 'MATCHED' ||
        normalized == 'VERIFIED' ||
        normalized == 'SUCCESS') {
      return Icons.verified_rounded;
    }

    if (normalized == 'NOT TESTED') {
      return Icons.help_outline_rounded;
    }

    return Icons.cancel_rounded;
  }

  // ============================================================
  // FORMAT SIMILARITY
  // ============================================================

  String formatScore(dynamic value) {
    if (value == null) {
      return '-';
    }

    final score = double.tryParse(
      value.toString(),
    );

    if (score == null) {
      return value.toString();
    }

    return score.toStringAsFixed(4);
  }

  // ============================================================
  // FORMAT THRESHOLD
  // ============================================================

  String formatThreshold(dynamic value) {
    if (value == null) {
      return '-';
    }

    final threshold = double.tryParse(
      value.toString(),
    );

    if (threshold == null) {
      return value.toString();
    }

    return threshold.toStringAsFixed(2);
  }

  // ============================================================
  // GET SIMILARITY
  // ============================================================

  dynamic getSimilarityValue(
      Map<String, dynamic> log,
      ) {
    if (log['similarity_score'] != null) {
      return log['similarity_score'];
    }

    if (log['similarity'] != null) {
      return log['similarity'];
    }

    if (log['score'] != null) {
      return log['score'];
    }

    return null;
  }

  // ============================================================
  // GET VOTER LOGS
  //
  // Only latest record for each voter.
  // ============================================================

  List<Map<String, dynamic>> getVoterLogs() {
    final selectedLogs =
    <Map<String, dynamic>>[];

    for (final item in widget.logs) {
      if (item is! Map) {
        continue;
      }

      final log =
      Map<String, dynamic>.from(item);

      if (isAdminLog(log)) {
        continue;
      }

      selectedLogs.add(log);
    }

    final Map<String, Map<String, dynamic>>
    latestByVoter = {};

    for (final log in selectedLogs) {
      final voterId =
      (log['voter_id'] ?? '')
          .toString()
          .trim()
          .toUpperCase();

      if (voterId.isEmpty) {
        continue;
      }

      if (!latestByVoter.containsKey(voterId)) {
        latestByVoter[voterId] = log;
        continue;
      }

      final currentLog =
      latestByVoter[voterId]!;

      final currentTime =
      _getLogTime(currentLog);
      final newTime =
      _getLogTime(log);

      if (newTime != null &&
          currentTime != null &&
          newTime.isAfter(currentTime)) {
        latestByVoter[voterId] = log;
      }
    }

    return latestByVoter.values.toList();
  }

  DateTime? _getLogTime(
      Map<String, dynamic> log,
      ) {
    final possibleFields = [
      'created_at',
      'timestamp',
      'verified_at',
      'verification_time',
      'login_time',
      'date_time',
    ];

    for (final field in possibleFields) {
      final value = log[field];

      if (value == null) {
        continue;
      }

      final parsed = DateTime.tryParse(
        value.toString(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>>
  getFilteredLogs() {
    final selectedLogs = getVoterLogs();

    if (selectedResultFilter == 'All') {
      return selectedLogs;
    }

    return selectedLogs.where((log) {
      final result = getLogResult(log);

      return result.toLowerCase() ==
          selectedResultFilter.toLowerCase();
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredLogs =
    getFilteredLogs();

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Voter Login Logs',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildFilterCard(),

          const SizedBox(height: 16),

          if (filteredLogs.isEmpty)
            _buildEmptyState()
          else
            ...filteredLogs.map(
                  (log) => _buildLogCard(log),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _buildFilterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
              color: Color(0xFF102A43),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Filter Logs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF102A43),
              ),
            ),
          ),
          Container(
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
              child: DropdownButton<String>(
                value: selectedResultFilter,
                isDense: true,
                icon: const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  color:
                  Color(0xFF102A43),
                ),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w700,
                  color:
                  Color(0xFF102A43),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'All',
                    child: Text('All'),
                  ),
                  DropdownMenuItem(
                    value: 'Match',
                    child: Text('Match'),
                  ),
                  DropdownMenuItem(
                    value: 'Failed',
                    child: Text('Failed'),
                  ),
                  DropdownMenuItem(
                    value: 'Not Tested',
                    child:
                    Text('Not Tested'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedResultFilter =
                        value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOG CARD
  // ============================================================

  Widget _buildLogCard(
      Map<String, dynamic> log,
      ) {
    final voterId =
    (log['voter_id'] ?? '-')
        .toString();

    final similarity = formatScore(
      getSimilarityValue(log),
    );

    final threshold = formatThreshold(
      log['threshold'],
    );

    final result = getLogResult(log);

    final resultColor =
    getResultColor(result);

    final resultIcon =
    getResultIcon(result);

    final verificationType =
    (log['verification_type'] ?? '')
        .toString()
        .trim();

    final logTime =
    _getLogTime(log);

    return _buildCommonLogCard(
      log: log,
      title: voterId,
      subtitle: 'Voter face verification',
      verificationType:
      verificationType,
      similarity: similarity,
      threshold: threshold,
      result: result,
      resultColor: resultColor,
      resultIcon: resultIcon,
      logTime: logTime,
      icon:
      Icons.person_search_rounded,
    );
  }

  // ============================================================
  // COMMON LOG CARD
  // ============================================================

  Widget _buildCommonLogCard({
    required Map<String, dynamic> log,
    required String title,
    required String subtitle,
    required String verificationType,
    required String similarity,
    required String threshold,
    required String result,
    required Color resultColor,
    required IconData resultIcon,
    required DateTime? logTime,
    required IconData icon,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE1EAF2),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE8F0F7),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                  const Color(0xFF102A43),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(0xFF102A43),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        color:
                        Color(0xFF64748B),
                      ),
                    ),
                    if (verificationType
                        .isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        verificationType,
                        style:
                        const TextStyle(
                          fontSize: 10,
                          color:
                          Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: resultColor
                      .withOpacity(0.10),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      resultIcon,
                      size: 15,
                      color: resultColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      result,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        resultColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(
            height: 1,
            color: Color(0xFFE8EEF4),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  title: 'Similarity',
                  value: similarity,
                  icon:
                  Icons.analytics_rounded,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  title: 'Threshold',
                  value: threshold,
                  icon:
                  Icons.tune_rounded,
                ),
              ),
            ],
          ),

          if (logTime != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 17,
                  color:
                  Color(0xFF64748B),
                ),
                const SizedBox(width: 7),
                Text(
                  _formatDateTime(logTime),
                  style:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Color(0xFF64748B),
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _buildDetailItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF102A43),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(
      DateTime dateTime) {
    final local =
    dateTime.toLocal();

    final day =
    local.day.toString().padLeft(
      2,
      '0',
    );
    final month =
    local.month.toString().padLeft(
      2,
      '0',
    );
    final year =
    local.year.toString();

    final hour =
    local.hour.toString().padLeft(
      2,
      '0',
    );
    final minute =
    local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/$year  $hour:$minute';
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding:
      const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE1EAF2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 14),
          const Text(
            'No voter verification logs',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF102A43),
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Voter face verification activity will appear here.',
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
}

// ==================================================================
// ADMIN LOGIN LOGS PAGE
// ==================================================================

class AdminLoginLogsScreen extends StatefulWidget {
  final List<dynamic> logs;

  const AdminLoginLogsScreen({
    super.key,
    required this.logs,
  });

  @override
  State<AdminLoginLogsScreen> createState() =>
      _AdminLoginLogsScreenState();
}

class _AdminLoginLogsScreenState
    extends State<AdminLoginLogsScreen> {
  String selectedResultFilter = 'All';

  // ============================================================
  // CHECK ADMIN LOG
  // ============================================================

  bool isAdminLog(Map<String, dynamic> log) {
    final voterId =
    (log['voter_id'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    final verificationType =
    (log['verification_type'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    return voterId.startsWith('ADMIN') ||
        verificationType.contains('ADMIN');
  }

  // ============================================================
  // RESULT
  // ============================================================

  String getLogResult(
      Map<String, dynamic> log) {
    final result =
    (log['result'] ?? '')
        .toString()
        .trim();

    if (result.isEmpty) {
      return 'Not Tested';
    }

    final upperResult =
    result.toUpperCase();

    if (upperResult == 'MATCH' ||
        upperResult == 'MATCHED' ||
        upperResult == 'VERIFIED' ||
        upperResult == 'SUCCESS') {
      return 'Match';
    }

    if (upperResult == 'FAIL' ||
        upperResult == 'FAILED' ||
        upperResult == 'NO MATCH' ||
        upperResult == 'NOT MATCHED') {
      return 'Failed';
    }

    if (upperResult == 'NOT TESTED') {
      return 'Not Tested';
    }

    return result;
  }

  Color getResultColor(String result) {
    final normalized =
    result.toUpperCase();

    if (normalized == 'MATCH' ||
        normalized == 'MATCHED' ||
        normalized == 'VERIFIED' ||
        normalized == 'SUCCESS') {
      return const Color(0xFF16803A);
    }

    if (normalized == 'NOT TESTED') {
      return const Color(0xFF64748B);
    }

    return const Color(0xFFD92D20);
  }

  IconData getResultIcon(String result) {
    final normalized =
    result.toUpperCase();

    if (normalized == 'MATCH' ||
        normalized == 'MATCHED' ||
        normalized == 'VERIFIED' ||
        normalized == 'SUCCESS') {
      return Icons.verified_rounded;
    }

    if (normalized == 'NOT TESTED') {
      return Icons.help_outline_rounded;
    }

    return Icons.cancel_rounded;
  }

  // ============================================================
  // FORMAT SIMILARITY
  // ============================================================

  String formatScore(dynamic value) {
    if (value == null) {
      return '-';
    }

    final score = double.tryParse(
      value.toString(),
    );

    if (score == null) {
      return value.toString();
    }

    return score.toStringAsFixed(4);
  }

  // ============================================================
  // FORMAT THRESHOLD
  // ============================================================

  String formatThreshold(dynamic value) {
    if (value == null) {
      return '-';
    }

    final threshold = double.tryParse(
      value.toString(),
    );

    if (threshold == null) {
      return value.toString();
    }

    return threshold.toStringAsFixed(2);
  }

  // ============================================================
  // GET SIMILARITY
  // ============================================================

  dynamic getSimilarityValue(
      Map<String, dynamic> log) {
    if (log['similarity_score'] != null) {
      return log['similarity_score'];
    }

    if (log['similarity'] != null) {
      return log['similarity'];
    }

    if (log['score'] != null) {
      return log['score'];
    }

    return null;
  }

  // ============================================================
  // GET ADMIN LOGS
  // ============================================================

  List<Map<String, dynamic>>
  getAdminLogs() {
    final selectedLogs =
    <Map<String, dynamic>>[];

    for (final item in widget.logs) {
      if (item is! Map) {
        continue;
      }

      final log =
      Map<String, dynamic>.from(item);

      if (!isAdminLog(log)) {
        continue;
      }

      selectedLogs.add(log);
    }

    return selectedLogs;
  }

  // ============================================================
  // FILTER
  // ============================================================

  List<Map<String, dynamic>>
  getFilteredLogs() {
    final selectedLogs =
    getAdminLogs();

    if (selectedResultFilter == 'All') {
      return selectedLogs;
    }

    return selectedLogs.where((log) {
      final result =
      getLogResult(log);

      return result.toLowerCase() ==
          selectedResultFilter
              .toLowerCase();
    }).toList();
  }

  DateTime? _getLogTime(
      Map<String, dynamic> log) {
    final possibleFields = [
      'created_at',
      'timestamp',
      'verified_at',
      'verification_time',
      'login_time',
      'date_time',
    ];

    for (final field in possibleFields) {
      final value = log[field];

      if (value == null) {
        continue;
      }

      final parsed =
      DateTime.tryParse(
        value.toString(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final filteredLogs =
    getFilteredLogs();

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Login Logs',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(16),
        children: [
          _buildFilterCard(),

          const SizedBox(height: 16),

          if (filteredLogs.isEmpty)
            _buildEmptyState()
          else
            ...filteredLogs.map(
                  (log) => _buildLogCard(log),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _buildFilterCard() {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFE8F0F7),
              borderRadius:
              BorderRadius.circular(
                11,
              ),
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
              'Filter Logs',
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF102A43),
              ),
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFF5F8FC),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
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
                selectedResultFilter,
                isDense: true,
                icon:
                const Icon(
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
                items: const [
                  DropdownMenuItem(
                    value: 'All',
                    child:
                    Text('All'),
                  ),
                  DropdownMenuItem(
                    value: 'Match',
                    child:
                    Text('Match'),
                  ),
                  DropdownMenuItem(
                    value: 'Failed',
                    child:
                    Text('Failed'),
                  ),
                  DropdownMenuItem(
                    value:
                    'Not Tested',
                    child: Text(
                        'Not Tested'),
                  ),
                ],
                onChanged:
                    (value) {
                  if (value ==
                      null) {
                    return;
                  }

                  setState(() {
                    selectedResultFilter =
                        value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOG CARD
  // ============================================================

  Widget _buildLogCard(
      Map<String, dynamic> log) {
    final adminId =
    (log['voter_id'] ?? '-')
        .toString();

    final similarity =
    formatScore(
      getSimilarityValue(log),
    );

    final threshold =
    formatThreshold(
      log['threshold'],
    );

    final result =
    getLogResult(log);

    final resultColor =
    getResultColor(result);

    final resultIcon =
    getResultIcon(result);

    final verificationType =
    (log['verification_type'] ??
        '')
        .toString()
        .trim();

    final logTime =
    _getLogTime(log);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
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
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFE8F0F7,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons
                      .admin_panel_settings_rounded,
                  color:
                  Color(0xFF102A43),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      adminId,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Color(
                          0xFF102A43,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    const Text(
                      'Admin face verification',
                      style:
                      TextStyle(
                        fontSize: 12,
                        color:
                        Color(
                          0xFF64748B,
                        ),
                      ),
                    ),
                    if (verificationType
                        .isNotEmpty) ...[
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        verificationType,
                        style:
                        const TextStyle(
                          fontSize: 10,
                          color:
                          Color(
                            0xFF94A3B8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration:
                BoxDecoration(
                  color:
                  resultColor
                      .withOpacity(
                    0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child: Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Icon(
                      resultIcon,
                      size: 15,
                      color:
                      resultColor,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Text(
                      result,
                      style:
                      TextStyle(
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        resultColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          const Divider(
            height: 1,
            color:
            Color(0xFFE8EEF4),
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child:
                _buildDetailItem(
                  title:
                  'Similarity',
                  value:
                  similarity,
                  icon:
                  Icons
                      .analytics_rounded,
                ),
              ),
              Expanded(
                child:
                _buildDetailItem(
                  title:
                  'Threshold',
                  value:
                  threshold,
                  icon:
                  Icons
                      .tune_rounded,
                ),
              ),
            ],
          ),

          if (logTime != null) ...[
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                const Icon(
                  Icons
                      .access_time_rounded,
                  size: 17,
                  color:
                  Color(0xFF64748B),
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  _formatDateTime(
                    logTime,
                  ),
                  style:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Color(
                      0xFF64748B,
                    ),
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL ITEM
  // ============================================================

  Widget _buildDetailItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color:
          const Color(0xFF64748B),
        ),
        const SizedBox(
          width: 8,
        ),
        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style:
              const TextStyle(
                fontSize: 11,
                color:
                Color(0xFF64748B),
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              value,
              style:
              const TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.w700,
                color:
                Color(0xFF102A43),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDateTime(
      DateTime dateTime) {
    final local =
    dateTime.toLocal();

    final day =
    local.day.toString().padLeft(
      2,
      '0',
    );
    final month =
    local.month.toString().padLeft(
      2,
      '0',
    );
    final year =
    local.year.toString();

    final hour =
    local.hour.toString().padLeft(
      2,
      '0',
    );
    final minute =
    local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/$year  $hour:$minute';
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding:
      const EdgeInsets.all(35),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          const Color(0xFFE1EAF2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 58,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(
            height: 14,
          ),
          const Text(
            'No admin verification logs',
            style:
            TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
              color:
              Color(0xFF102A43),
            ),
          ),
          const SizedBox(
            height: 7,
          ),
          const Text(
            'Admin face verification activity will appear here.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
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