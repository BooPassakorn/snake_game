import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  Future<void> signOut() async {
    await GoogleSignIn().disconnect(); //ล้างข้อมูลบัญชีที่เคยlog in
    return await _firebaseAuth.signOut();
  }

  signInWithGoogle() async {
    try {
      //begin interactive sign in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        print("Google Sign-In ถูกยกเลิก");
        return null;
      }

      //obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      print("Access Token: ${gAuth.accessToken}");
      print("ID Token: ${gAuth.idToken}");

      //create a new credential for user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      //finally, sign in
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print("ลงชื่อเข้าใช้สำเร็จ: ${userCredential.user?.email}");
      return userCredential;
    } catch (e){
      print("เกิดข้อผิดพลาด: $e");
    }
  }
}

