import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupEntry {
  final String code;
  String? alias;

  GroupEntry({required this.code, this.alias});

  Map<String, dynamic> toJson() => {
        'code': code,
        if (alias != null) 'alias': alias,
      };

  factory GroupEntry.fromJson(Map<String, dynamic> json) => GroupEntry(
        code: json['code'] as String,
        alias: json['alias'] as String?,
      );

  String get displayName => alias ?? code;
}

class GroupService {
  static GroupService? _instance;
  static const _groupsKey = 'groups';
  static const _activeGroupCodeKey = 'active_group_code';

  List<GroupEntry> _groups = [];
  String? _activeGroupCode;
  late SharedPreferences _prefs;

  final ValueNotifier<String?> activeGroupNotifier = ValueNotifier(null);

  GroupService._();

  static GroupService get instance {
    _instance ??= GroupService._();
    return _instance!;
  }

  bool get hasGroup => _activeGroupCode != null;
  String get groupCode => _activeGroupCode!;
  List<GroupEntry> get groups => List.unmodifiable(_groups);

  GroupEntry? get activeEntry {
    if (_activeGroupCode == null) return null;
    return _groups.cast<GroupEntry?>().firstWhere(
          (e) => e!.code == _activeGroupCode,
          orElse: () => null,
        );
  }

  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadGroups();
  }

  void _loadGroups() {
    final raw = _prefs.getString(_groupsKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _groups =
          list.map((e) => GroupEntry.fromJson(e as Map<String, dynamic>)).toList();
    }
    _activeGroupCode = _prefs.getString(_activeGroupCodeKey);
    activeGroupNotifier.value = _activeGroupCode;
  }

  Future<void> _persist() async {
    final json = jsonEncode(_groups.map((e) => e.toJson()).toList());
    await _prefs.setString(_groupsKey, json);
    if (_activeGroupCode != null) {
      await _prefs.setString(_activeGroupCodeKey, _activeGroupCode!);
    } else {
      await _prefs.remove(_activeGroupCodeKey);
    }
  }

  Future<void> ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<String> createGroup({String? alias}) async {
    await ensureSignedIn();
    debugPrint('createGroup: isSignedIn=$isSignedIn, uid=${FirebaseAuth.instance.currentUser?.uid}');
    if (!isSignedIn) {
      throw Exception('Not authenticated. On macOS, enable Keychain Sharing in Xcode (Signing & Capabilities).');
    }
    final code = _generateCode();
    await FirebaseFirestore.instance.collection('groups').doc(code).set({
      'createdAt': FieldValue.serverTimestamp(),
    });
    final entry = GroupEntry(code: code, alias: alias);
    _groups.add(entry);
    _activeGroupCode = code;
    activeGroupNotifier.value = code;
    await _persist();
    return code;
  }

  Future<bool> joinGroup(String code, {String? alias}) async {
    if (_groups.any((e) => e.code == code)) {
      _activeGroupCode = code;
      activeGroupNotifier.value = code;
      await _persist();
      return true;
    }

    await ensureSignedIn();
    if (!isSignedIn) {
      throw Exception('Not authenticated. On macOS, enable Keychain Sharing in Xcode (Signing & Capabilities).');
    }
    final doc =
        await FirebaseFirestore.instance.collection('groups').doc(code).get();
    if (!doc.exists) return false;

    final entry = GroupEntry(code: code, alias: alias);
    _groups.add(entry);
    _activeGroupCode = code;
    activeGroupNotifier.value = code;
    await _persist();
    return true;
  }

  void switchGroup(String code) {
    if (!_groups.any((e) => e.code == code)) return;
    _activeGroupCode = code;
    activeGroupNotifier.value = code;
    _persist();
  }

  Future<void> removeGroup(String code) async {
    _groups.removeWhere((e) => e.code == code);
    if (_activeGroupCode == code) {
      _activeGroupCode = _groups.isNotEmpty ? _groups.first.code : null;
      activeGroupNotifier.value = _activeGroupCode;
    }
    await _persist();
  }

  void updateAlias(String code, String? alias) {
    final entry = _groups.cast<GroupEntry?>().firstWhere(
          (e) => e!.code == code,
          orElse: () => null,
        );
    if (entry != null) {
      entry.alias = alias;
      _persist();
    }
  }
}
