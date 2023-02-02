import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';

class SifremiUnuttum extends StatefulWidget {
  @override
  _SifremiUnuttumState createState() => _SifremiUnuttumState();
}

class _SifremiUnuttumState extends State<SifremiUnuttum> {
  bool yukleniyor = false;
  final _formAnahtari = GlobalKey<FormState>();
  final _scaffoldAnahtari = GlobalKey<ScaffoldState>();
  String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldAnahtari,
      appBar: AppBar(
        title: Text("Şifremi unuttum"),
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
                      height: 50,
                    ),
                    Container(
                      width: double.infinity,
                      child: FlatButton(
                          onPressed: _sifreyiSifirla,
                          child: Text(
                            "Şifremi Sıfırla",
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

  Future<void> _sifreyiSifirla() async {
    final _yetkilendirmeServisi =
        Provider.of<YetkilendirmeServisi>(context, listen: false);

    var _formState = _formAnahtari.currentState;
    if (_formState.validate()) {
      _formState.save();
      setState(() {
        yukleniyor = true;
      });
      try {
        await _yetkilendirmeServisi.sifremiSifirla(email);

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
    } else if (hataKodu == "user-not-found") {
      hataMesaji = "Girdiğiniz kullanıcı bulunamadı";
    } else {
      hataMesaji = "Tanımlanamayan bir hata oluştu $hataKodu";
    }
    var snackBar = SnackBar(
      content: Text(hataMesaji),
    );
    _scaffoldAnahtari.currentState.showSnackBar(snackBar);
  }
}
