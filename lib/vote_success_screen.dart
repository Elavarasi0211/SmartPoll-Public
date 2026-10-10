import 'package:flutter/material.dart';

import 'voter_id_screen.dart';

class VoteSuccessScreen extends StatelessWidget {
  final String voterId;
  final String voterName;
  final String candidateName;
  final String partyName;
  final String referenceId;

  const VoteSuccessScreen({
    super.key,
    required this.voterId,
    required this.voterName,
    required this.candidateName,
    required this.partyName,
    required this.referenceId,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FC),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 45),

                // =====================================================
                // SUCCESS ICON
                // =====================================================

                Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 75,
                  ),
                ),

                const SizedBox(height: 25),

                // =====================================================
                // SUCCESS TITLE
                // =====================================================

                const Text(
                  'Vote Registered Successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF102A43),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Your vote has been successfully recorded '
                      'in the SmartPoll system.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 30),

                // =====================================================
                // VOTE DETAILS
                // =====================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vote Details',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF102A43),
                        ),
                      ),

                      const SizedBox(height: 18),

                      _detailRow(
                        'Voter ID',
                        voterId,
                      ),

                      _detailRow(
                        'Voter Name',
                        voterName,
                      ),

                      _detailRow(
                        'Candidate',
                        candidateName,
                      ),

                      _detailRow(
                        'Party',
                        partyName,
                      ),

                      _detailRow(
                        'Reference ID',
                        referenceId,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // =====================================================
                // SECURITY INFORMATION
                // =====================================================

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1F8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.security_outlined,
                        color: Color(0xFF102A43),
                        size: 27,
                      ),

                      SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Secure Voting',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF102A43),
                              ),
                            ),

                            SizedBox(height: 5),

                            Text(
                              'Your vote was processed after '
                                  'identity verification.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // =====================================================
                // BACK TO SMARTPOLL
                // =====================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const VoterIdScreen(),
                        ),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF102A43),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to SmartPoll',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // DETAIL ROW
  // =====================================================

  Widget _detailRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),

          const Text(
            ':',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF102A43),
              ),
            ),
          ),
        ],
      ),
    );
  }
}