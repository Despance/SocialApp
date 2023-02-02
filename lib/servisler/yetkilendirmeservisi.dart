import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:socialapp/modeller/kullanici.dart';

class YetkilendirmeServisi {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String aktifkullaniciId;
  Kullanici _kullaniciOlustur(User kullanici) {
    return kullanici == null ? null : Kullanici.firebasedenUret(kullanici);
  }

  Stream<Kullanici> get durumTakipcisi {
    return _firebaseAuth.authStateChanges().map(_kullaniciOlustur);
  }

  maillekayit(String eposta, String sifre) async {
    var giriskarti = await _firebaseAuth.createUserWithEmailAndPassword(
        email: eposta, password: sifre);

    return _kullaniciOlustur(giriskarti.user);
  }

  maillegiris(String eposta, String sifre) async {
    var giriskarti = await _firebaseAuth.signInWithEmailAndPassword(
        email: eposta, password: sifre);

    return _kullaniciOlustur(giriskarti.user);
  }

  Future<void> cikisyap() {
    return _firebaseAuth.signOut();
  }

  Future<void> sifremiSifirla(String eposta) async {
    await _firebaseAuth.sendPasswordResetEmail(email: eposta);
  }

  Future<Kullanici> googleIleGiris() async {
    GoogleSignInAccount googleHesabi = await GoogleSignIn().signIn();
    GoogleSignInAuthentication googleYetkiKartim =
        await googleHesabi.authentication;
    AuthCredential sifresizGirisBelgesi = GoogleAuthProvider.credential(
        idToken: googleYetkiKartim.idToken,
        accessToken: googleYetkiKartim.accessToken);

    UserCredential girisKarti =
        await _firebaseAuth.signInWithCredential(sifresizGirisBelgesi);

    return _kullaniciOlustur(girisKarti.user);
  }
}
