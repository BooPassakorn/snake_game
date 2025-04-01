import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }

  signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        print("Google Sign-In ถูกยกเลิก");
        return;
      }

      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      print("Access Token: ${gAuth.accessToken}");
      print("ID Token: ${gAuth.idToken}");

      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print("ลงชื่อเข้าใช้สำเร็จ: ${userCredential.user?.email}");
      return userCredential;
    } catch (e) {
      print("เกิดข้อผิดพลาด: $e");
    }
  }

}