import 'package:flutter/material.dart';

import 'api_service.dart';
import 'candidate_selection_screen.dart';

class VoterProfileScreen extends StatefulWidget {
  final String voterId;
  final String voterName;

  const VoterProfileScreen({
    super.key,
    required this.voterId,
    required this.voterName,
  });

  @override
  State<VoterProfileScreen> createState() => _VoterProfileScreenState();
}

class _VoterProfileScreenState extends State<VoterProfileScreen> {
  bool isLoading = true;

  String district = '';
  String taluk = '';
  String block = '';
  String panchayat = '';
  String ward = '';
  String booth = '';

  @override
  void initState() {
    super.initState();
    _loadVoterDetails();
  }

  Future<void> _loadVoterDetails() async {
    try {
      final voter = await ApiService.getVoter(widget.voterId);

      if (!mounted) return;

      setState(() {
        district = voter['district']?.toString() ?? '';
        taluk = voter['taluk']?.toString() ?? '';
        block = voter['block']?.toString() ?? '';
        panchayat = voter['panchayat']?.toString() ?? '';
        ward = voter['ward']?.toString() ?? '';
        booth = voter['booth']?.toString() ?? '';

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load voter details.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        title: const Text(
          'Voter Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0F8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF102A43),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 55,
                  color: Color(0xFF102A43),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Voter Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Your identity has been successfully verified.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              // Profile Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileRow(
                      'Voter Name',
                      widget.voterName,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'Voter ID',
                      widget.voterId,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'District',
                      isLoading ? 'Loading...' : district,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'Taluk',
                      isLoading ? 'Loading...' : taluk,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'Block',
                      isLoading ? 'Loading...' : block,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'Panchayat',
                      isLoading ? 'Loading...' : panchayat,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'Ward',
                      isLoading ? 'Loading...' : ward,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'Booth',
                      isLoading ? 'Loading...' : booth,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'Face Verification',
                      'Verified',
                      valueColor: Colors.green,
                    ),

                    const Divider(height: 28),

                    _profileRow(
                      'Status',
                      'Eligible to Vote',
                      valueColor: Colors.green,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CandidateSelectionScreen(
                              voterId: widget.voterId,
                              voterName: widget.voterName,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF102A43),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    Colors.grey.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue to Candidate Selection',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'SmartPoll • Secure Digital Voting Prototype',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileRow(
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color:
              valueColor ??
                  const Color(0xFF102A43),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}