import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.96.186:8000';
  // ============================================================
  // GET VOTER
  // ============================================================

  static Future<Map<String, dynamic>> getVoter(
      String voterId,
      ) async {
    final uri = Uri.parse(
      '$baseUrl/voter/$voterId',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final voterData = decoded['voter'];

        if (voterData is Map<String, dynamic>) {
          return voterData;
        }

        throw Exception(
          'Invalid voter data received from server.',
        );
      }

      throw Exception(
        'Invalid voter data received from server.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Voter ID not found.',
      );
    }

    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to verify Voter ID.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to verify Voter ID.',
    );
  }

  // ============================================================
  // GET CANDIDATES - VOTER
  // ============================================================

  static Future<List<dynamic>> getCandidates(
      String voterId,
      ) async {
    final uri = Uri.parse(
      '$baseUrl/candidates/$voterId',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        final candidates = decoded['candidates'];

        if (candidates is List) {
          return candidates;
        }
      }

      throw Exception(
        'Invalid candidate data received from server.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Voter ID not found.',
      );
    }

    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load candidates.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load candidates.',
    );
  }

  // ============================================================
  // GET ALL CANDIDATES - ADMIN
  // ============================================================

  static Future<List<dynamic>> getAllCandidates() async {
    final uri = Uri.parse(
      '$baseUrl/admin/candidates',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map<String, dynamic>) {
        final candidates = decoded['candidates'];

        if (candidates is List) {
          return candidates;
        }
      }

      throw Exception(
        'Invalid admin candidate data received from server.',
      );
    }

    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load all candidates.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load all candidates: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN - GET ALL ENROLLED MEMBERS
  // ============================================================

  static Future<List<dynamic>> getAllVoters() async {
    final uri = Uri.parse(
      '$baseUrl/admin/voters',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        final voters = decoded['voters'];

        if (voters is List) {
          return voters;
        }
      }

      if (decoded is List) {
        return decoded;
      }

      throw Exception(
        'Invalid enrolled member data received from server.',
      );
    }

    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load enrolled members.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load enrolled members: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN - ADD NEW MEMBER
  // ============================================================

  static Future<Map<String, dynamic>> addVoter({
    required String voterId,
    required String name,
    required String phone,
    required String email,
    required String district,
    required String taluk,
    required String block,
    required String panchayat,
    required String ward,
    required String booth,
    required File faceImage,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/admin/voters/add',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['voter_id'] = voterId;
    request.fields['name'] = name;
    request.fields['phone'] = phone;
    request.fields['email'] = email;
    request.fields['district'] = district;
    request.fields['taluk'] = taluk;
    request.fields['block'] = block;
    request.fields['panchayat'] = panchayat;
    request.fields['ward'] = ward;
    request.fields['booth'] = booth;

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        faceImage.path,
      ),
    );

    final response = await request.send();

    final responseBody =
    await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid add member response.',
      );
    }

    try {
      final errorData = jsonDecode(
        responseBody,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to add new member.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to add new member: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN - UPDATE VOTER EMAIL
  // ============================================================

  static Future<Map<String, dynamic>> updateVoterEmail({
    required String voterId,
    required String email,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/admin/voters/$voterId/email',
    );

    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final responseBody = response.body;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid voter email update response.',
      );
    }

    try {
      final errorData = jsonDecode(
        responseBody,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to update voter email.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to update voter email: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // SEND EMAIL OTP
  // ============================================================

  static Future<Map<String, dynamic>> sendEmailOtp({
    required String voterId,
    required String email,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/auth/send-email-otp',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'voter_id': voterId,
        'email': email,
      }),
    );

    final responseBody = response.body;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid email OTP response.',
      );
    }

    try {
      final errorData = jsonDecode(
        responseBody,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to send email OTP.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to send email OTP: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // VERIFY EMAIL OTP
  // ============================================================

  static Future<Map<String, dynamic>> verifyEmailOtp({
    required String voterId,
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/auth/verify-email-otp',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'voter_id': voterId,
        'email': email,
        'otp': otp,
      }),
    );

    final responseBody = response.body;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid email OTP verification response.',
      );
    }

    try {
      final errorData = jsonDecode(
        responseBody,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Email OTP verification failed.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Email OTP verification failed: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN - REMOVE MEMBER
  // ============================================================

  static Future<Map<String, dynamic>> removeVoter(
      String voterId,
      ) async {
    final uri = Uri.parse(
      '$baseUrl/admin/voters/$voterId',
    );

    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid remove member response.',
      );
    }

    try {
      final errorData = jsonDecode(
        response.body,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to remove member.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to remove member: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN - ADD CANDIDATE
  // ============================================================

  static Future<Map<String, dynamic>> addCandidate({
    required String candidateName,
    required String partyName,
    required String district,
    required String taluk,
    required String block,
    required String panchayat,
    required String ward,
    required String booth,
    required String symbol,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/admin/candidates/add',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['candidate_name'] = candidateName;
    request.fields['party_name'] = partyName;
    request.fields['district'] = district;
    request.fields['taluk'] = taluk;
    request.fields['block'] = block;
    request.fields['panchayat'] = panchayat;
    request.fields['ward'] = ward;
    request.fields['booth'] = booth;
    request.fields['symbol'] = symbol;

    final response = await request.send();

    final responseBody =
    await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid add candidate response.',
      );
    }

    try {
      final errorData = jsonDecode(
        responseBody,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to add candidate.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to add candidate: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN - REMOVE CANDIDATE
  // ============================================================

  static Future<Map<String, dynamic>> removeCandidate(
      int candidateId,
      ) async {
    final uri = Uri.parse(
      '$baseUrl/admin/candidates/$candidateId',
    );

    final response = await http.delete(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid remove candidate response.',
      );
    }

    try {
      final errorData = jsonDecode(
        response.body,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to remove candidate.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to remove candidate: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // VOTER FACE VERIFICATION
  // ============================================================

  static Future<Map<String, dynamic>> verifyFace(
      File imageFile,
      String voterId,
      ) async {
    final uri = Uri.parse(
      '$baseUrl/verify-face',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.fields['voter_id'] = voterId;

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final response = await request.send();

    final responseBody =
    await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid face verification response.',
      );
    }

    try {
      final errorData = jsonDecode(
        responseBody,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Face verification failed.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Face verification failed: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN - GET PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> getAdminProfile() async {
    final uri = Uri.parse(
      '$baseUrl/admin/profile',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid admin profile data received from server.',
      );
    }

    try {
      final errorData = jsonDecode(
        response.body,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load admin profile.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load admin profile: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN - UPDATE PROFILE
  // ============================================================

  static Future<Map<String, dynamic>> updateAdminProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/admin/profile',
    );

    final request = http.MultipartRequest(
      'PUT',
      uri,
    );

    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['phone'] = phone;

    final response = await request.send();

    final responseBody =
    await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid admin profile update response.',
      );
    }

    try {
      final errorData = jsonDecode(
        responseBody,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to update admin profile.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to update admin profile: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // ADMIN FACE VERIFICATION
  // ============================================================

  static Future<Map<String, dynamic>> verifyAdminFace(
      File imageFile,
      ) async {
    final uri = Uri.parse(
      '$baseUrl/verify-admin-face',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
      ),
    );

    final response = await request.send();

    final responseBody =
    await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid admin verification response.',
      );
    }

    try {
      final errorData = jsonDecode(
        responseBody,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Admin face verification failed.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Admin face verification failed: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // GET VERIFICATION LOGS
  // ============================================================

  static Future<Map<String, dynamic>>
  getVerificationLogs() async {
    final uri = Uri.parse(
      '$baseUrl/verification-logs',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is List) {
        return {
          'logs': decoded,
        };
      }

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid verification log data.',
      );
    }

    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load verification logs.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load verification logs: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // SUBMIT VOTE
  // ============================================================

  static Future<Map<String, dynamic>> submitVote({
    required String voterId,
    required int candidateId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/submit-vote',
    );

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'voter_id': voterId,
        'candidate_id': candidateId,
      }),
    );

    final responseBody = response.body;

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        responseBody,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid vote registration response.',
      );
    }

    try {
      final errorData = jsonDecode(responseBody);

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to submit vote.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to submit vote: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // GET ADMIN RESULTS
  // ============================================================

  static Future<Map<String, dynamic>>
  getAdminResults() async {
    final uri = Uri.parse(
      '$baseUrl/admin/results',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid election results received from server.',
      );
    }

    try {
      final errorData = jsonDecode(
        response.body,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load election results.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load election results: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // GET ADMIN DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>>
  getAdminDashboard() async {
    final uri = Uri.parse(
      '$baseUrl/admin/dashboard',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid dashboard data received from server.',
      );
    }

    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load dashboard data.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load dashboard data: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // GET ADMIN ANALYTICS
  // ============================================================

  static Future<Map<String, dynamic>>
  getAdminAnalytics() async {
    final uri = Uri.parse(
      '$baseUrl/admin/analytics',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid analytics data received from server.',
      );
    }

    try {
      final errorData = jsonDecode(response.body);

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load analytics data.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load analytics data: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // GET VISUAL CRYPTOGRAPHY SHARES
  // ============================================================

  static Future<Map<String, dynamic>>
  getVisualCryptography() async {
    final uri = Uri.parse(
      '$baseUrl/admin/visual-cryptography',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid visual cryptography data received from server.',
      );
    }

    try {
      final errorData = jsonDecode(
        response.body,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to load visual cryptography data.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to load visual cryptography data: '
          '${response.statusCode}',
    );
  }

  // ============================================================
  // COMBINE VISUAL CRYPTOGRAPHY SHARES
  // ============================================================

  static Future<Map<String, dynamic>>
  combineVisualCryptographyShares() async {
    final uri = Uri.parse(
      '$baseUrl/admin/combine-shares',
    );

    final response = await http.post(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      throw Exception(
        'Invalid combined share result received from server.',
      );
    }

    try {
      final errorData = jsonDecode(
        response.body,
      );

      if (errorData is Map<String, dynamic>) {
        throw Exception(
          errorData['detail']?.toString() ??
              'Unable to combine vote shares.',
        );
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
    }

    throw Exception(
      'Unable to combine vote shares: '
          '${response.statusCode}',
    );
  }
}