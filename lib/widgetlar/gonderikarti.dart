import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/gonderi.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/sayfalar/profil.dart';
import 'package:socialapp/sayfalar/yorumlar.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';

class GonderiKarti extends StatefulWidget {
  final Gonderi gonderi;
  final Kullanici yayinlayan;

  const GonderiKarti({Key key, this.gonderi, this.yayinlayan})
      : super(key: key);
  @override
  _GonderiKartiState createState() => _GonderiKartiState();
}

class _GonderiKartiState extends State<GonderiKarti> {
  int _begeniSayisi = 0;
  bool _begendin = false;
  String _aktifKullaniciId;
  @override
  void initState() {
    super.initState();
    _aktifKullaniciId =
        Provider.of<YetkilendirmeServisi>(context, listen: false)
            .aktifkullaniciId;
    _begeniSayisi = widget.gonderi.begeniSayisi;
    begeniVarmi();
  }

  begeniVarmi() async {
    bool begeniVarmi =
        await FirestoreServisi().begeniVarMi(widget.gonderi, _aktifKullaniciId);
    if (begeniVarmi) {
      if (mounted) {
        setState(() {
          _begendin = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
      child: Column(
        children: [_gonderiBasligi(), _gonderiResmi(), _gonderAlt()],
      ),
    );
  }

  gonderiSecenekleri() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("Seçenekler"),
          children: [
            SimpleDialogOption(
              child: Text("Gönderiyi sil"),
              onPressed: () {
                FirestoreServisi().gonderiSil(
                    aktifKullaniciId: _aktifKullaniciId,
                    gonderi: widget.gonderi);
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Text("İptal et"),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }

  Widget _gonderiBasligi() {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        Profil(profilSahibiId: widget.gonderi.yayinlananId)));
          },
          child: CircleAvatar(
            backgroundColor: Colors.blue,
            backgroundImage: widget.yayinlayan.fotoUrl.isNotEmpty
                ? NetworkImage(widget.yayinlayan.fotoUrl)
                : AssetImage("assets/images/hayalet.png"),
          ),
        ),
      ),
      title: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      Profil(profilSahibiId: widget.gonderi.yayinlananId)));
        },
        child: Text(
          widget.yayinlayan.kullaniciAdi,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      trailing: _aktifKullaniciId == widget.gonderi.yayinlananId
          ? IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {
                gonderiSecenekleri();
              },
            )
          : null,
      contentPadding: EdgeInsets.all(0),
    );
  }

  Widget _gonderiResmi() {
    return GestureDetector(
      onDoubleTap: _begeniDegistir,
      child: Image.network(
        widget.gonderi.gonderiResmiUrl,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.width,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _gonderAlt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
                icon: !_begendin
                    ? Icon(
                        Icons.favorite_border,
                        size: 35,
                      )
                    : Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 35,
                      ),
                onPressed: _begeniDegistir),
            IconButton(
                icon: Icon(
                  Icons.comment,
                  size: 35,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Yorumlar(
                                gonderi: widget.gonderi,
                              )));
                }),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            "$_begeniSayisi beğeni",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 2),
        widget.gonderi.aciklama.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: RichText(
                    text: TextSpan(
                        text: widget.yayinlayan.kullaniciAdi + " ",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        children: [
                      TextSpan(
                          text: widget.gonderi.aciklama,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.normal))
                    ])),
              )
            : SizedBox(
                height: 0,
              )
      ],
    );
  }

  void _begeniDegistir() {
    if (_begendin) {
      setState(() {
        _begendin = false;
        _begeniSayisi -= 1;
      });
      FirestoreServisi().gonderiBegeniKaldir(widget.gonderi, _aktifKullaniciId);
    } else {
      setState(() {
        _begendin = true;
        _begeniSayisi += 1;
      });
      FirestoreServisi().gonderiBegen(widget.gonderi, _aktifKullaniciId);
    }
  }
}
