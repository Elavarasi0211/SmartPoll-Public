import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool smartPollExpanded = false;
  bool helpSupportExpanded = false;
  bool systemStatusExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------
            // SMARTPOLL
            // ----------------------------------------------------------
            _buildExpandableCard(
              icon: Icons.how_to_vote_outlined,
              title: 'SmartPoll',
              subtitle: 'Learn more about SmartPoll',
              isExpanded: smartPollExpanded,
              onTap: () {
                setState(() {
                  smartPollExpanded = !smartPollExpanded;
                });
              },
              child: _buildSmartPollDetails(),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------------
            // HELP & SUPPORT
            // ----------------------------------------------------------
            _buildExpandableCard(
              icon: Icons.help_outline,
              title: 'Help & Support',
              subtitle: 'Get help and support for SmartPoll',
              isExpanded: helpSupportExpanded,
              onTap: () {
                setState(() {
                  helpSupportExpanded = !helpSupportExpanded;
                });
              },
              child: _buildHelpSupportDetails(),
            ),

            const SizedBox(height: 20),

            // ----------------------------------------------------------
            // SYSTEM STATUS
            // ----------------------------------------------------------
            _buildExpandableCard(
              icon: Icons.monitor_heart_outlined,
              title: 'System Status',
              subtitle: 'View current SmartPoll system status',
              isExpanded: systemStatusExpanded,
              onTap: () {
                setState(() {
                  systemStatusExpanded = !systemStatusExpanded;
                });
              },
              child: _buildSystemStatusDetails(),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                'SmartPoll • Secure Online Voting System',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // EXPANDABLE CARD
  // --------------------------------------------------------------------

  Widget _buildExpandableCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              child: Row(
                children: [
                  _buildIconContainer(icon),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172B4D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF53657A),
                  ),
                ],
              ),
            ),
          ),

          if (isExpanded) ...[
            const Divider(
              height: 1,
              color: Color(0xFFE2E8F0),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // SMARTPOLL DETAILS
  // --------------------------------------------------------------------

  Widget _buildSmartPollDetails() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SmartPoll',
          style: TextStyle(
            color: Color(0xFF0B1F3A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'SmartPoll is a secure online voting system '
              'designed using Face Recognition and Visual Cryptography.',
          style: TextStyle(
            color: Color(0xFF53657A),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 12),
        Text(
          'Technologies',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Flutter • FastAPI • SQLite • InsightFace • '
              'OpenCV • Visual Cryptography',
          style: TextStyle(
            color: Color(0xFF53657A),
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------
  // HELP & SUPPORT DETAILS
  // --------------------------------------------------------------------

  Widget _buildHelpSupportDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Need Help?',
          style: TextStyle(
            color: Color(0xFF0B1F3A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'For assistance with SmartPoll, please contact '
              'the system administrator or project support team.',
          style: TextStyle(
            color: Color(0xFF53657A),
            fontSize: 13,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 16),

        _buildSupportRow(
          icon: Icons.help_center_outlined,
          title: 'System Help',
          value: 'Use the available options in SmartPoll.',
        ),

        _buildSupportRow(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          value: 'Contact the system administrator.',
        ),
      ],
    );
  }

  // --------------------------------------------------------------------
  // SUPPORT ROW
  // --------------------------------------------------------------------

  Widget _buildSupportRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF53657A),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172B4D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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

  // --------------------------------------------------------------------
  // SYSTEM STATUS DETAILS
  // --------------------------------------------------------------------

  Widget _buildSystemStatusDetails() {
    return Column(
      children: [
        _buildStatusRow(
          icon: Icons.dns_outlined,
          title: 'Backend Server',
          value: 'Online',
        ),

        _buildStatusRow(
          icon: Icons.storage_outlined,
          title: 'Database',
          value: 'Connected',
        ),

        _buildStatusRow(
          icon: Icons.face_outlined,
          title: 'Face Recognition',
          value: 'Active',
        ),

        _buildStatusRow(
          icon: Icons.image_outlined,
          title: 'Visual Cryptography',
          value: 'Active',
        ),
      ],
    );
  }

  // --------------------------------------------------------------------
  // SYSTEM STATUS ROW
  // --------------------------------------------------------------------

  Widget _buildStatusRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF53657A),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172B4D),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EE),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // ICON CONTAINER
  // --------------------------------------------------------------------

  Widget _buildIconContainer(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F8),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF0B1F3A),
        size: 22,
      ),
    );
  }
}