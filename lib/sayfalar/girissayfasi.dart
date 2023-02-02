import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/sayfalar/hesapolustur.dart';
import 'package:socialapp/sayfalar/sifremiUnuttum.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';

class GirisSayfasi extends StatefulWidget {
  @override
  _GirisSayfasiState createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  final _formAnahtari = GlobalKey<FormState>();
  final _scaffoldAnahtari = GlobalKey<ScaffoldState>();
  bool yukleniyor = false;
  String email, sifre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldAnahtari,
      body: Stack(
        children: [_sayfaElemanlari(context), _yuklemeAnimasyonu()],
      ),
    );
  }

  _yuklemeAnimasyonu() {
    if (yukleniyor) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return SizedBox(
        height: 0,
      );
    }
  }

  Widget _sayfaElemanlari(BuildContext context) {
    return Form(
      key: _formAnahtari,
      child: ListView(
        padding: EdgeInsets.only(right: 20, left: 20, top: 60),
        children: [
          FlutterLogo(
            size: 90,
          ),
          SizedBox(
            height: 80,
          ),
          TextFormField(
            autocorrect: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                hintText: "Email Adresi",
                prefixIcon: Icon(Icons.mail),
                errorStyle: TextStyle(fontSize: 16)),
            validator: (girilenDeger) {
              if (girilenDeger.isEmpty) {
                return "Email alanı boş bırakılamaz!";
              } else if (!girilenDeger.contains("@")) {
                return "Girilen değer mail formatında olmalı!";
              }
              return null;
            },
            onSaved: (girilenDeger) => email = girilenDeger,
          ),
          SizedBox(
            height: 40,
          ),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(
                hintText: "Şifreniz",
                prefixIcon: Icon(Icons.lock),
                errorStyle: TextStyle(fontSize: 16)),
            validator: (girilenDeger) {
              if (girilenDeger.isEmpty) {
                return "Şifre alanı boş bırakılamaz.";
              } else if (girilenDeger.trim().length < 4) {
                return "Sifre 4 karakterden az olamaz!";
              }
              return null;
            },
            onSaved: (girilenDeger) => sifre = girilenDeger,
          ),
          SizedBox(
            height: 40,
          ),
          Row(
            children: [
              Expanded(
                child: FlatButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => HesapOlustur()));
                    },
                    child: Text(
                      "Hesap Oluştur",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    color: Theme.of(context).primaryColor),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: FlatButton(
                    onPressed: _girisYap,
                    child: Text(
                      "Giriş yap",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    color: Theme.of(context).primaryColorDark),
              )
            ],
          ),
          SizedBox(height: 20),
          Center(child: Text("veya")),
          SizedBox(height: 20),
          Center(
              child: InkWell(
            onTap: _googleIleGiris,
            child: Text(
              "Google ile giriş yap",
              style: TextStyle(
                  fontSize: 19,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold),
            ),
          )),
          SizedBox(height: 20),
          Center(
              child: InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SifremiUnuttum()));
            },
            child: Text("Şifremi unuttum"),
          ))
        ],
      ),
    );
  }

  Future<void> _girisYap() async {
    final _yetkilendirmeServisi =
        Provider.of<YetkilendirmeServisi>(context, listen: false);
    if (_formAnahtari.currentState.validate()) {
      _formAnahtari.currentState.save();
      setState(() {
        yukleniyor = true;
      });
      try {
        await _yetkilendirmeServisi.maillegiris(email, sifre);
      } catch (e) {
        setState(() {
          yukleniyor = false;
        });
        uyariGoster(hataKodu: e.code);
      }
    }
  }

  Future<void> _googleIleGiris() async {
    setState(() {
      yukleniyor = true;
    });
    var _yetkilendirmeServisi =
        Provider.of<YetkilendirmeServisi>(context, listen: false);
    try {
      Kullanici kullanici = await _yetkilendirmeServisi.googleIleGiris();
      if (kullanici != null) {
        Kullanici firestoreKullanici =
            await FirestoreServisi().kullaniciGetir(kullanici.id);

        if (firestoreKullanici == null) {
          FirestoreServisi().kullaniciOlustur(
              email: kullanici.email,
              kullaniciAdi: kullanici.kullaniciAdi,
              id: kullanici.id,
              fotoUrl: kullanici.fotoUrl);
        }
      }
    } catch (e) {
      setState(() {
        yukleniyor = false;
      });
      uyariGoster(hataKodu: e.code);
    }
  }

  uyariGoster({hataKodu}) {
    String hataMesaji;

    print(hataKodu);
    if (hataKodu == "ınvalıd-emaıl") {
      hataMesaji = "Girdiğiniz mail adresi geçersizdir";
    } else if (hataKodu == "user-not-found") {
      hataMesaji = "Girdiğiniz kullanıcı bulunamadı";
    } else if (hataKodu == "wrong-password") {
      hataMesaji = "Girilen şifre yanlış";
    } else {
      hataMesaji = "Tanımlanamayan bir hata oluştu $hataKodu";
    }
    var snackBar = SnackBar(
      content: Text(hataMesaji),
    );
    _scaffoldAnahtari.currentState.showSnackBar(snackBar);
  }
}
