import 'package:flutter/material.dart';

import 'api_service.dart';
import 'candidates_screen.dart';
import 'enrolled_members_screen.dart';
import 'verification_logs_screen.dart';
import 'results_screen.dart';
import 'demographics_analytics_screen.dart';
import 'visual_cryptography_screen.dart';
import 'settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  int selectedMenuIndex = 0;

  bool isLoadingDashboard = true;
  String? dashboardError;

  int totalVoters = 0;
  int votedVoters = 0;
  int remainingVoters = 0;
  int totalCandidates = 0;

  String faceMlStatus = 'Loading...';
  String databaseStatus = 'Loading...';

  final List<String> menuItems = [
    'Dashboard',
    'Enrolled Members',
    'Verification Logs',
    'Candidates',
    'Results',
    'Demographics & Analytics',
    'Visual Cryptography',
    'Settings',
    'Logout',
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard_rounded,
    Icons.people_alt_rounded,
    Icons.fact_check_rounded,
    Icons.how_to_vote_rounded,
    Icons.bar_chart_rounded,
    Icons.analytics_rounded,
    Icons.security_rounded,
    Icons.settings_rounded,
    Icons.logout_rounded,
  ];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboardData();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoadingDashboard = true;
      dashboardError = null;
    });

    try {
      final data =
      await ApiService.getAdminDashboard();

      if (!mounted) {
        return;
      }

      setState(() {
        totalVoters =
            int.tryParse(
              data['total_voters']?.toString() ??
                  '0',
            ) ??
                0;

        votedVoters =
            int.tryParse(
              data['voted_voters']?.toString() ??
                  '0',
            ) ??
                0;

        remainingVoters =
            int.tryParse(
              data['remaining_voters']?.toString() ??
                  '0',
            ) ??
                0;

        totalCandidates =
            int.tryParse(
              data['total_candidates']?.toString() ??
                  '0',
            ) ??
                0;

        faceMlStatus =
            data['face_ml']?.toString() ??
                'Unknown';

        databaseStatus =
            data['database']?.toString() ??
                'Unknown';

        isLoadingDashboard = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoadingDashboard = false;
        dashboardError =
        'Unable to load dashboard data.';
      });
    }
  }

  // ============================================================
  // MENU NAVIGATION
  // ============================================================

  void _openMenu(int index) {
    // Dashboard
    if (index == 0) {
      Navigator.pop(context);

      setState(() {
        selectedMenuIndex = 0;
      });

      _loadDashboardData();

      return;
    }

    // Enrolled Members
    if (index == 1) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const EnrolledMembersScreen(),
        ),
      );

      return;
    }

    // Verification Logs
    if (index == 2) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const VerificationLogsScreen(),
        ),
      );

      return;
    }

    // Candidates
    if (index == 3) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const CandidatesScreen(),
        ),
      );

      return;
    }

    // Results
    if (index == 4) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const ResultsScreen(),
        ),
      );

      return;
    }

    // Demographics & Analytics
    if (index == 5) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const DemographicsAnalyticsScreen(),
        ),
      );

      return;
    }

    // Visual Cryptography
    if (index == 6) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const VisualCryptographyScreen(),
        ),
      );

      return;
    }

    // Settings
    if (index == 7) {
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const SettingsScreen(),
        ),
      );

      return;
    }

    // Logout
    if (index == 8) {
      Navigator.pop(context);

      Navigator.pop(context);

      return;
    }

    // Other modules
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${menuItems[index]} module will be available soon.',
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),

      drawer: _buildDrawer(),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor:
        Colors.white,
        elevation: 0,
        title: const Text(
          'SmartPoll Admin',
          style: TextStyle(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

      body: _buildDashboardBody(),
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,

      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                ),

                itemCount:
                menuItems.length,

                itemBuilder: (
                    context,
                    index,
                    ) {
                  final isSelected =
                      selectedMenuIndex ==
                          index;

                  final isLogout =
                      index == 8;

                  return Container(
                    margin:
                    const EdgeInsets.only(
                      bottom: 4,
                    ),

                    decoration:
                    BoxDecoration(
                      color: isSelected
                          ? const Color(
                        0xFFE8F0F7,
                      )
                          : Colors.transparent,

                      borderRadius:
                      BorderRadius.circular(
                        12,
                      ),
                    ),

                    child: ListTile(
                      leading: Icon(
                        menuIcons[index],
                        color: isLogout
                            ? const Color(
                          0xFFD92D20,
                        )
                            : isSelected
                            ? const Color(
                          0xFF102A43,
                        )
                            : const Color(
                          0xFF64748B,
                        ),
                      ),

                      title: Text(
                        menuItems[index],
                        style: TextStyle(
                          fontSize: 14,

                          fontWeight:
                          isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,

                          color: isLogout
                              ? const Color(
                            0xFFD92D20,
                          )
                              : isSelected
                              ? const Color(
                            0xFF102A43,
                          )
                              : const Color(
                            0xFF334E68,
                          ),
                        ),
                      ),

                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),

                      onTap: () {
                        if (index != 8) {
                          setState(() {
                            selectedMenuIndex =
                                index;
                          });
                        }

                        _openMenu(index);
                      },
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.all(16),

              child: Text(
                'SmartPoll\nSecuring Democracy with Real-Time Face Verification',
                textAlign:
                TextAlign.center,

                style: TextStyle(
                  fontSize: 10,
                  height: 1.4,
                  color:
                  Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DRAWER HEADER
  // ============================================================

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.fromLTRB(
        20,
        24,
        20,
        22,
      ),

      decoration:
      const BoxDecoration(
        color: Color(0xFF102A43),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Container(
            width: 54,
            height: 54,

            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(
                16,
              ),
            ),

            child: const Icon(
              Icons.how_to_vote_rounded,
              color:
              Color(0xFF102A43),
              size: 30,
            ),
          ),

          const SizedBox(height: 14),

          const Text(
            'SmartPoll',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Admin Portal',
            style: TextStyle(
              color:
              Color(0xFFD9E7F2),
              fontSize: 13,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DASHBOARD BODY
  // ============================================================

  Widget _buildDashboardBody() {
    if (isLoadingDashboard) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,

      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            if (dashboardError != null)
              _buildDashboardError(),

            if (dashboardError != null)
              const SizedBox(height: 16),

            _buildWelcomeCard(),

            const SizedBox(height: 20),

            const Text(
              'Dashboard Overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.w800,
                color:
                Color(0xFF102A43),
              ),
            ),

            const SizedBox(height: 12),

            _buildStatisticsGrid(),

            const SizedBox(height: 24),

            const Text(
              'System Status',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                FontWeight.w800,
                color:
                Color(0xFF102A43),
              ),
            ),

            const SizedBox(height: 12),

            _buildSystemStatusCard(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD ERROR
  // ============================================================

  Widget _buildDashboardError() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(14),

      decoration:
      BoxDecoration(
        color:
        const Color(0xFFFFF1F0),

        borderRadius:
        BorderRadius.circular(14),

        border: Border.all(
          color:
          const Color(0xFFF5B5B0),
        ),
      ),

      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color:
            Color(0xFFD92D20),
          ),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Unable to load live dashboard data.',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
                color:
                Color(0xFFB42318),
              ),
            ),
          ),

          TextButton(
            onPressed:
            _loadDashboardData,

            child: const Text(
              'Retry',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
        const Color(0xFF102A43),

        borderRadius:
        BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
            const Color(
              0xFF102A43,
            ).withOpacity(0.18),

            blurRadius: 16,

            offset:
            const Offset(0, 7),
          ),
        ],
      ),

      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Welcome Admin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,

      shrinkWrap: true,

      physics:
      const NeverScrollableScrollPhysics(),

      crossAxisSpacing: 12,

      mainAxisSpacing: 12,

      childAspectRatio: 1.55,

      children: [
        _buildStatCard(
          title:
          'Enrolled Members',
          value:
          totalVoters.toString(),
          icon:
          Icons.people_alt_rounded,
          iconColor:
          const Color(0xFF2563EB),
        ),

        _buildStatCard(
          title:
          'Participants',
          value:
          votedVoters.toString(),
          icon:
          Icons.how_to_vote_rounded,
          iconColor:
          const Color(0xFF16803A),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(15),

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
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),

          const Spacer(),

          Text(
            value,
            style:
            const TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.w800,
              color:
              Color(0xFF102A43),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
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
    );
  }

  // ============================================================
  // SYSTEM STATUS
  // ============================================================

  Widget _buildSystemStatusCard() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(18),

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
          _buildStatusRow(
            title:
            'Face Verification',
            value: faceMlStatus,
            icon:
            Icons.face_rounded,
            color:
            const Color(0xFF16803A),
          ),

          const Divider(
            height: 22,
          ),

          _buildStatusRow(
            title: 'ML Model',
            value: 'buffalo_l',
            icon:
            Icons.psychology_rounded,
            color:
            const Color(0xFF2563EB),
          ),

          const Divider(
            height: 22,
          ),

          _buildStatusRow(
            title: 'Database',
            value: databaseStatus,
            icon:
            Icons.storage_rounded,
            color:
            databaseStatus == 'Connected'
                ? const Color(0xFF16803A)
                : const Color(0xFFD92D20),
          ),

          const Divider(
            height: 22,
          ),

          _buildStatusRow(
            title:
            'Visual Cryptography',
            value: 'Prototype',
            icon:
            Icons.security_rounded,
            color:
            const Color(0xFFB7791F),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,

          decoration:
          BoxDecoration(
            color:
            color.withOpacity(0.10),

            borderRadius:
            BorderRadius.circular(
              11,
            ),
          ),

          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style:
            const TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w600,
              color:
              Color(0xFF334E68),
            ),
          ),
        ),

        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),

          decoration:
          BoxDecoration(
            color:
            color.withOpacity(0.10),

            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),

          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
              FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}