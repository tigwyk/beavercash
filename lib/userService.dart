import 'dart:ffi';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';

final log = Logger('userServiceLogs');

class User {
  final int    id;
  final String name;
  final String email;

  User({
    required this.id,
    required this.name,
    required this.email,
    });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],    
      );
  }
}

class UserService {
  Future<User> getUser() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/users/0'));
    log.info('Response status: ${response.statusCode}');
    log.info('Response body: ${response.body}');
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
        } else {
      throw Exception('Failed to load user');
    }
  }
}