import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/gonderi.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/sayfalar/profiliduzenle.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';
import 'package:socialapp/widgetlar/gonderikarti.dart';

class Profil extends StatefulWidget {
  final String profilSahibiId;

  const Profil({Key key, @required this.profilSahibiId}) : super(key: key);
  @override
  _ProfilState createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  int _gonderiSayisi = 0;
  int _takipci = 0;
  int _takipEdilen = 0;
  List<Gonderi> _gonderiler = [];
  String gonderiStili = "liste";
  String _aktifKullaniciId;
  Kullanici _profilSahibi;
  bool _takipEdildi = false;
  _takipciSayisiGetir() async {
    int takipciSayisi =
        await FirestoreServisi().takipciSayisi(widget.profilSahibiId);
    if (mounted) {
      setState(() {
        _takipci = takipciSayisi;
      });
    }
  }

  _takipEdilenSayisiGetir() async {
    int takipEdilenSayisi =
        await FirestoreServisi().takipEdilenSayisi(widget.profilSahibiId);
    if (mounted) {
      setState(() {
        _takipEdilen = takipEdilenSayisi;
      });
    }
  }

  _gonderileriGetir() async {
    List<Gonderi> gonderiler =
        await FirestoreServisi().gonderileriGetir(widget.profilSahibiId);
    if (mounted) {
      setState(() {
        _gonderiler = gonderiler;
        _gonderiSayisi = _gonderiler.length;
      });
    }
  }

  _takipKontrol() async {
    bool takipVarMi = await FirestoreServisi().takipKontrol(
        profilSahibiId: widget.profilSahibiId,
        aktifKullaniciId: _aktifKullaniciId);

    setState(() {
      _takipEdildi = takipVarMi;
    });
  }

  @override
  void initState() {
    super.initState();
    _takipciSayisiGetir();
    _takipEdilenSayisiGetir();
    _gonderileriGetir();
    _aktifKullaniciId =
        Provider.of<YetkilendirmeServisi>(context, listen: false)
            .aktifkullaniciId;

    _takipKontrol();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        backgroundColor: Colors.grey[100],
        leading: widget.profilSahibiId == _aktifKullaniciId
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          widget.profilSahibiId == _aktifKullaniciId
              ? IconButton(
                  icon: Icon(
                    Icons.exit_to_app,
                    color: Colors.black,
                  ),
                  onPressed: _cikisYap)
              : SizedBox(height: 0)
        ],
        title: Text(
          "Profil",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: FutureBuilder<Object>(
          future: FirestoreServisi().kullaniciGetir(widget.profilSahibiId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            _profilSahibi = snapshot.data;
            return ListView(
              children: [
                _profilDetaylari(snapshot.data),
                _gonderileriGoster(snapshot.data),
              ],
            );
          }),
    );
  }

  Widget _gonderileriGoster(Kullanici profilData) {
    if (gonderiStili == "liste") {
      return ListView.builder(
          shrinkWrap: true,
          primary: false,
          itemCount: _gonderiler.length,
          itemBuilder: (context, index) {
            return GonderiKarti(
              gonderi: _gonderiler[index],
              yayinlayan: profilData,
            );
          });
    } else {
      List<GridTile> fayanslar = [];
      GridTile _fayansOlustur(Gonderi gonderi) {
        return GridTile(
            child: Image.network(
          gonderi.gonderiResmiUrl,
          fit: BoxFit.cover,
        ));
      }

      _gonderiler.forEach((element) {
        fayanslar.add(_fayansOlustur(element));
      });

      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
        physics: NeverScrollableScrollPhysics(),
        children: fayanslar,
      );
    }
  }

  Widget _profilDetaylari(Kullanici profilData) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 50,
              backgroundImage: profilData.fotoUrl.isNotEmpty
                  ? NetworkImage(profilData.fotoUrl)
                  : AssetImage("assets/images/hayalet.png"),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sosyalSayac(baslik: "Gönderiler", sayi: _gonderiSayisi),
                  _sosyalSayac(baslik: "Takipçi", sayi: _takipci),
                  _sosyalSayac(baslik: "Takip", sayi: _takipEdilen)
                ],
              ),
            )
          ]),
          SizedBox(
            height: 10,
          ),
          Text(profilData.kullaniciAdi,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(profilData.hakkinda),
          SizedBox(height: 25),
          widget.profilSahibiId == _aktifKullaniciId
              ? _profiliDuzenleButon()
              : _takipButtonu()
        ],
      ),
    );
  }

  Widget _takipButtonu() {
    return _takipEdildi ? _takiptenCikButonu() : _takipEtButonu();
  }

  _takiptenCikButonu() {
    return Container(
      width: double.infinity,
      child: OutlinedButton(
        child: Text(
          "Takipten Çık",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          FirestoreServisi().takiptenCik(
              profilSahibiId: widget.profilSahibiId,
              aktifKullaniciId: _aktifKullaniciId);
          setState(() {
            _takipEdildi = false;
            _takipci -= 1;
          });
        },
      ),
    );
  }

  _takipEtButonu() {
    return Container(
      width: double.infinity,
      child: FlatButton(
        color: Theme.of(context).primaryColor,
        child: Text(
          "Takip Et",
          style: TextStyle(color: Colors.white),
        ),
        onPressed: () {
          FirestoreServisi().takipEt(
              profilSahibiId: widget.profilSahibiId,
              aktifKullaniciId: _aktifKullaniciId);
          setState(() {
            _takipEdildi = true;
            _takipci += 1;
          });
        },
      ),
    );
  }

  void _cikisYap() {
    Provider.of<YetkilendirmeServisi>(context, listen: false).cikisyap();
  }

  Widget _profiliDuzenleButon() {
    return Container(
      width: double.infinity,
      child: OutlinedButton(
        child: Text(
          "Profili Düzenle",
          style: TextStyle(color: Colors.black),
        ),
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ProfiliDuzenle(
                        profil: _profilSahibi,
                      )));
        },
      ),
    );
  }

  Widget _sosyalSayac({String baslik, int sayi}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          sayi.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2),
        Text(
          baslik,
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }
}
