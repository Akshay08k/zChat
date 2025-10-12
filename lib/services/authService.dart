import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/userModel.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;
  UserModel? currentUserModel;

  Stream<User?> get userChanges => _auth.userChanges();

  // Registers a new user with a globally-unique username.
  Future<UserModel?> register({
    required String username,
    String? name,
    required String email,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final usernameRef = _db.child('usernames/$normalized');
    final snapshot = await usernameRef.get();
    if (snapshot.value != null) throw Exception('Username already taken');

    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    final userModel = UserModel(
      uid: user.uid,
      name: (name?.trim().isNotEmpty == true ? name!.trim() : normalized),
      username: normalized,
      email: email,
      isOnline: true,
    );

    await usernameRef.set(user.uid);
    await _db.child('users/${user.uid}').set(userModel.toJson());
    currentUserModel = userModel;
    notifyListeners();
    return userModel;
  }

  Future<UserModel?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    await _db.child('users/${user.uid}/isOnline').set(true);

    final profileSnap = await _db.child('users/${user.uid}').get();
    final data = (profileSnap.value as Map?) ?? {};
    final userModel = UserModel.fromJson(data);
    currentUserModel = userModel;
    notifyListeners();
    return userModel;
  }

  Future<void> signOut() async {
    if (_auth.currentUser != null) {
      await _db.child('users/${_auth.currentUser!.uid}/isOnline').set(false);
    }
    currentUserModel = null;
    notifyListeners();
    await _auth.signOut();
  }

  Future<String?> uidForUsername(String username) async {
    final normalized = username.trim().toLowerCase();
    final snapshot = await _db.child('usernames/$normalized').get();
    return snapshot.value as String?;
  }

  //FCM Token Is Used for the push notification it's like ip of the device but got changed
  //timely just like access and refreshToken
  Future<void> saveFCMToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.child('fcmTokens/$uid').set(token);
  }


  Future<Map<String, dynamic>?> userProfile(String uid) async {
    final snap = await _db.child('users/$uid').get();
    return (snap.value as Map?)?.cast<String, dynamic>();
  }


  // Update profile (name, status, photo)
  Future<void> updateProfile({String? name, String? status, String? photoUrl}) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (status != null) updates['status'] = status;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;

    if (updates.isNotEmpty) {
      await _db.child('users/$uid').update(updates);
      // update local model
      if (currentUserModel != null) {
        if (name != null) currentUserModel!.name = name;
        if (status != null) currentUserModel!.status = status;
        if (photoUrl != null) currentUserModel!.photoUrl = photoUrl;
      }
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};
    final snapshot = await _db.child('users/$uid').get();
    if (!snapshot.exists) return {};
    final raw = snapshot.value as Map<dynamic, dynamic>? ?? {};
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
}
