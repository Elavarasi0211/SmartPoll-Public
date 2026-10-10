import 'package:flutter/material.dart';
import 'api_service.dart';
import 'face_verification_screen.dart';
import 'admin_login_screen.dart';

class VoterIdScreen extends StatefulWidget {
  const VoterIdScreen({super.key});

  @override
  State<VoterIdScreen> createState() => _VoterIdScreenState();
}

class _VoterIdScreenState extends State<VoterIdScreen> {
  final TextEditingController voterIdController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    voterIdController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> continueLogin() async {
    final voterId =
    voterIdController.text.trim().toUpperCase();

    final email =
    emailController.text.trim().toLowerCase();

    if (voterId.isEmpty) {
      showMessage('Please enter your Voter ID.');
      return;
    }

    if (email.isEmpty) {
      showMessage('Please enter your registered email.');
      return;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(email)) {
      showMessage('Please enter a valid email address.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final voter =
      await ApiService.getVoter(voterId);

      if (!mounted) return;

      final registeredEmail =
          voter['email']?.toString().trim().toLowerCase() ?? '';

      if (registeredEmail.isEmpty) {
        setState(() {
          isLoading = false;
        });

        showMessage(
          'No registered email found for this Voter ID. '
              'Please contact the administrator.',
        );
        return;
      }

      if (registeredEmail != email) {
        setState(() {
          isLoading = false;
        });

        showMessage(
          'The email does not match the registered email.',
        );
        return;
      }

      final voted = voter['voted'] == 1;
      final isDemoVoter = voterId == 'SPV001';

      // SPV001 can vote multiple times
      // for demo/testing.
      if (voted && !isDemoVoter) {
        setState(() {
          isLoading = false;
        });

        showAlreadyVoted();
        return;
      }

      await ApiService.sendEmailOtp(
        voterId: voterId,
        email: registeredEmail,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EmailOtpScreen(
            voterId: voterId,
            voterName:
            voter['name']?.toString() ?? '',
            email: registeredEmail,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showAlreadyVoted() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Already Voted',
          ),
          content: const Text(
            'You have already voted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void openAdminLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const AdminLoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.how_to_vote_rounded,
                    size: 70,
                    color:
                    Color(0xFF102A43),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'SmartPoll',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xFF102A43),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Securing Democracy with Real-Time Face Verification',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                      Colors.blueGrey,
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Voter Login',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xFF102A43),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Enter your Voter ID and registered email to continue.',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                      Colors.blueGrey,
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller:
                    voterIdController,
                    textCapitalization:
                    TextCapitalization.characters,
                    decoration:
                    InputDecoration(
                      labelText:
                      'Voter ID',
                      hintText:
                      'Example: SPV001',
                      prefixIcon:
                      const Icon(
                        Icons.badge_outlined,
                      ),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      filled: true,
                      fillColor:
                      Colors.white,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller:
                    emailController,
                    keyboardType:
                    TextInputType.emailAddress,
                    decoration:
                    InputDecoration(
                      labelText:
                      'Registered Email',
                      hintText:
                      'Example: voter@gmail.com',
                      prefixIcon:
                      const Icon(
                        Icons.email_outlined,
                      ),
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      filled: true,
                      fillColor:
                      Colors.white,
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child:
                    ElevatedButton(
                      onPressed:
                      isLoading
                          ? null
                          : continueLogin,
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
                            12,
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Text(
                        'Send OTP',
                        style:
                        TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color:
                          Colors.grey[300],
                        ),
                      ),
                      const Padding(
                        padding:
                        EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color:
                          Colors.grey[300],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 50,
                    child:
                    OutlinedButton.icon(
                      onPressed:
                      openAdminLogin,
                      icon: const Icon(
                        Icons
                            .admin_panel_settings_outlined,
                      ),
                      label: const Text(
                        'Admin Login',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      style:
                      OutlinedButton.styleFrom(
                        foregroundColor:
                        const Color(
                          0xFF102A43,
                        ),
                        side:
                        const BorderSide(
                          color:
                          Color(
                            0xFF102A43,
                          ),
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color:
                        Colors.blueGrey,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Your identity is securely verified',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMAIL OTP SCREEN
// ============================================================

class EmailOtpScreen extends StatefulWidget {
  final String voterId;
  final String voterName;
  final String email;

  const EmailOtpScreen({
    super.key,
    required this.voterId,
    required this.voterName,
    required this.email,
  });

  @override
  State<EmailOtpScreen> createState() =>
      _EmailOtpScreenState();
}

class _EmailOtpScreenState
    extends State<EmailOtpScreen> {
  final TextEditingController otpController =
  TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  Future<void> verifyOtp() async {
    final otp =
    otpController.text.trim();

    if (otp.isEmpty) {
      showMessage(
        'Please enter the OTP.',
      );
      return;
    }

    if (otp.length != 6) {
      showMessage(
        'Please enter the 6-digit OTP.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await ApiService.verifyEmailOtp(
        voterId: widget.voterId,
        email: widget.email,
        otp: otp,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FaceVerificationScreen(
                voterId: widget.voterId,
                voterName: widget.voterName,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail =
    _maskEmail(widget.email);

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor:
        const Color(0xFF102A43),
        foregroundColor:
        Colors.white,
        title: const Text(
          'Email Verification',
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 70,
                    color:
                    Color(0xFF102A43),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Verify Your Email',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xFF102A43),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'A 6-digit OTP has been sent to\n$maskedEmail',
                    textAlign:
                    TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color:
                      Colors.blueGrey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  TextField(
                    controller:
                    otpController,
                    keyboardType:
                    TextInputType.number,
                    maxLength: 6,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration:
                    InputDecoration(
                      labelText:
                      'Enter OTP',
                      hintText:
                      '123456',
                      prefixIcon:
                      const Icon(
                        Icons.lock_outline,
                      ),
                      counterText: '',
                      border:
                      OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      filled: true,
                      fillColor:
                      Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child:
                    ElevatedButton(
                      onPressed:
                      isLoading
                          ? null
                          : verifyOtp,
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
                            12,
                          ),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Text(
                        'Verify OTP',
                        style:
                        TextStyle(
                          fontSize: 16,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color:
                        Colors.blueGrey,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'OTP is valid for 5 minutes.',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _maskEmail(String email) {
    final parts =
    email.split('@');

    if (parts.length != 2) {
      return email;
    }

    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }

    return '${username.substring(0, 2)}***@$domain';
  }
}