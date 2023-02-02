import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/storageservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';

class ProfiliDuzenle extends StatefulWidget {
  final Kullanici profil;

  const ProfiliDuzenle({Key key, this.profil}) : super(key: key);
  @override
  _ProfiliDuzenleState createState() => _ProfiliDuzenleState();
}

class _ProfiliDuzenleState extends State<ProfiliDuzenle> {
  var _formKey = GlobalKey<FormState>();
  String _kullaniciAdi;
  String _hakkinda;
  File _secilmisFoto;
  bool _yukleniyor = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: Text(
          "Profili Düzenle",
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: Colors.black,
            ),
            onPressed: _kaydet,
          ),
        ],
      ),
      body: ListView(
        children: [
          _yukleniyor
              ? LinearProgressIndicator()
              : SizedBox(
                  height: 0,
                ),
          _profilFoto(),
          _kullaniciBilgiler()
        ],
      ),
    );
  }

  _kaydet() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      setState(() {
        _yukleniyor = true;
      });
      String profilFotoUrl;

      if (_secilmisFoto == null) {
        profilFotoUrl == widget.profil.fotoUrl;
      } else {
        profilFotoUrl = await StorageServisi().profilResmiYukle(_secilmisFoto);
      }
      String aktifKullaniciId =
          Provider.of<YetkilendirmeServisi>(context, listen: false)
              .aktifkullaniciId;
      FirestoreServisi().kullaniciGuncelle(
          kullaniciAdi: _kullaniciAdi,
          hakkinda: _hakkinda,
          kullaniciId: aktifKullaniciId,
          fotoUrl: profilFotoUrl);
    }
    setState(() {
      _yukleniyor = false;
    });
    Navigator.pop(context);
  }

  _profilFoto() {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 20),
      child: Center(
        child: InkWell(
          onTap: _galeridenSec,
          child: CircleAvatar(
            backgroundColor: Colors.grey,
            backgroundImage: _secilmisFoto == null
                ? NetworkImage(widget.profil.fotoUrl)
                : FileImage(_secilmisFoto),
            radius: 55,
          ),
        ),
      ),
    );
  }

  _kullaniciBilgiler() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            SizedBox(height: 20),
            TextFormField(
              initialValue: widget.profil.kullaniciAdi,
              decoration: InputDecoration(labelText: "Kullanıcı Adı"),
              validator: (value) {
                return value.trim().length <= 3
                    ? "Kullanıcı adı en az 4 karakter olmalı"
                    : null;
              },
              onSaved: (val) => _kullaniciAdi = val,
            ),
            TextFormField(
              initialValue: widget.profil.hakkinda,
              decoration: InputDecoration(labelText: "Hakkında"),
              validator: (girilenDeger) {
                return girilenDeger.trim().length > 100
                    ? "100 Karakterden fazla olamaz"
                    : null;
              },
              onSaved: (val) => _hakkinda = val,
            )
          ],
        ),
      ),
    );
  }

  _galeridenSec() async {
    var image = await ImagePicker().getImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80);
    setState(() {
      _secilmisFoto = File(image.path);
    });
  }
}
