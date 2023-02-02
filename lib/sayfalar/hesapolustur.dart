import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';

class HesapOlustur extends StatefulWidget {
  @override
  _HesapOlusturState createState() => _HesapOlusturState();
}

class _HesapOlusturState extends State<HesapOlustur> {
  bool yukleniyor = false;
  final _formAnahtari = GlobalKey<FormState>();
  final _scaffoldAnahtari = GlobalKey<ScaffoldState>();
  String kullaniciAdi, email, sifre;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldAnahtari,
      appBar: AppBar(
        title: Text("Hesap Oluştur"),
      ),
      body: ListView(
        children: [
          yukleniyor ? LinearProgressIndicator() : SizedBox(height: 0),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
                key: _formAnahtari,
                child: Column(
                  children: [
                    TextFormField(
                        keyboardType: TextInputType.name,
                        decoration: InputDecoration(
                            hintText: "Kullanıcı adınızı giriniz",
                            labelText: "Kullanıcı adı",
                            prefixIcon: Icon(Icons.person),
                            errorStyle: TextStyle(fontSize: 16)),
                        validator: (girilenDeger) {
                          if (girilenDeger.isEmpty) {
                            return "Kullanıcı adı boş bırakılamaz!";
                          } else if (girilenDeger.trim().length < 4 ||
                              girilenDeger.trim().length > 10) {
                            return "En az 4 en fazla 10 karakterden olabilir!";
                          }
                          return null;
                        },
                        onSaved: (girilenDeger) {
                          kullaniciAdi = girilenDeger;
                        }),
                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                        autocorrect: true,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            hintText: "Email Adresinizi giriniz",
                            labelText: "Email Adresi",
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
                        onSaved: (girilenDeger) {
                          email = girilenDeger;
                        }),
                    SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                          hintText: "Şifrenizi oluşturun",
                          labelText: "Şifreniz",
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
                      onSaved: (girilenDeger) {
                        sifre = girilenDeger;
                      },
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Container(
                      width: double.infinity,
                      child: FlatButton(
                          onPressed: _kullaniciOlustur,
                          child: Text(
                            "Hesap Oluştur",
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          color: Theme.of(context).primaryColor),
                    ),
                  ],
                )),
          )
        ],
      ),
    );
  }

  Future<void> _kullaniciOlustur() async {
    final _yetkilendirmeServisi =
        Provider.of<YetkilendirmeServisi>(context, listen: false);

    var _formState = _formAnahtari.currentState;
    if (_formState.validate()) {
      _formState.save();
      setState(() {
        yukleniyor = true;
      });
      try {
        Kullanici kullanici =
            await _yetkilendirmeServisi.maillekayit(email, sifre);
        if (kullanici != null) {
          FirestoreServisi().kullaniciOlustur(
            id: kullanici.id,
            email: kullanici.email,
            kullaniciAdi: kullaniciAdi,
          );
        }
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          yukleniyor = false;
        });
        uyariGoster(hataKodu: e.code);
      }
    }
  }

  uyariGoster({hataKodu}) {
    String hataMesaji;

    print(hataKodu);
    if (hataKodu == "ınvalıd-emaıl") {
      hataMesaji = "Girdiğiniz mail adresi geçersizdir";
    } else if (hataKodu == "emaıl-already-ın-use") {
      hataMesaji = "Girdiğiniz mail adresi kayıtlıdır";
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
