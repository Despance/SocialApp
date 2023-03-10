import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/duyuru.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/sayfalar/profil.dart';
import 'package:socialapp/sayfalar/tekligonderi.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';
import 'package:timeago/timeago.dart' as timeago;

class Duyurular extends StatefulWidget {
  @override
  _DuyurularState createState() => _DuyurularState();
}

class _DuyurularState extends State<Duyurular> {
  List<Duyuru> _duyurular;
  String _aktifKullaniciId;
  bool _yukleniyor = true;
  @override
  void initState() {
    super.initState();

    _aktifKullaniciId =
        Provider.of<YetkilendirmeServisi>(context, listen: false)
            .aktifkullaniciId;

    duyurulariGetir();
    timeago.setLocaleMessages("tr", timeago.TrMessages());
  }

  Future<void> duyurulariGetir() async {
    List<Duyuru> duyurular =
        await FirestoreServisi().duyurulariGetir(_aktifKullaniciId);

    if (mounted) {
      setState(() {
        _duyurular = duyurular;
        _yukleniyor = false;
      });
    }
  }

  Widget duyurulariGoster() {
    if (_yukleniyor) {
      return Center(child: CircularProgressIndicator());
    }
    if (_duyurular.isEmpty) {
      return Center(
        child: Text("Hiç duyurunuz yok"),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: 12),
      child: RefreshIndicator(
        onRefresh: duyurulariGetir,
        child: ListView.builder(
            itemCount: _duyurular.length,
            itemBuilder: (context, index) {
              Duyuru duyuru = _duyurular[index];
              return duyuruSatiri(duyuru);
            }),
      ),
    );
  }

  duyuruSatiri(Duyuru duyuru) {
    String mesaj = mesajOlustur(duyuru.aktiviteTipi);
    return FutureBuilder(
        future: FirestoreServisi().kullaniciGetir(duyuru.aktiviteYapanId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              height: 0,
            );
          }
          Kullanici aktiviteYapan = snapshot.data;
          return ListTile(
            leading: InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            Profil(profilSahibiId: duyuru.aktiviteYapanId)));
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(aktiviteYapan.fotoUrl),
              ),
            ),
            title: RichText(
              text: TextSpan(
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Profil(
                                  profilSahibiId: duyuru.aktiviteYapanId)));
                    },
                  text: aktiviteYapan.kullaniciAdi,
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                        text: " $mesaj ",
                        style: TextStyle(fontWeight: FontWeight.normal)),
                  ]),
            ),
            subtitle: duyuru.yorum != null
                ? RichText(
                    text: TextSpan(
                        text: timeago.format(duyuru.olusturulmaZamani.toDate(),
                            locale: "tr"),
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w300),
                        children: [
                        TextSpan(
                            text: "  -> " + duyuru.yorum,
                            style: TextStyle(fontWeight: FontWeight.w400))
                      ]))
                : Text(timeago.format(duyuru.olusturulmaZamani.toDate(),
                    locale: "tr")),
            trailing: gonderiGorsel(
                duyuru.aktiviteTipi, duyuru.gonderiFoto, duyuru.gonderiId),
          );
        });
  }

  gonderiGorsel(String aktiviteTipi, String gonderiFoto, String gonderiId) {
    if (aktiviteTipi == "takip") {
      return null;
    } else if (aktiviteTipi == "begeni" || aktiviteTipi == "yorum") {
      return GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TekliGonderi(
                        gonderiId: gonderiId,
                        gonderiSahibiId: _aktifKullaniciId,
                      )));
        },
        child: Image.network(gonderiFoto,
            width: 50, height: 50, fit: BoxFit.cover),
      );
    }
  }

  mesajOlustur(String aktiviteTipi) {
    if (aktiviteTipi == "begeni") {
      return "gönderini beğendi.";
    } else if (aktiviteTipi == "takip") {
      return "seni takip etti.";
    } else if (aktiviteTipi == "yorum") {
      return "gönderine yorum yaptı";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Duyurular",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.grey[100],
      ),
      body: duyurulariGoster(),
    );
  }
}
