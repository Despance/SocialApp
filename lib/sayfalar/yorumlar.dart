import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socialapp/modeller/gonderi.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/modeller/yorum.dart';
import 'package:socialapp/servisler/firestoreservisi.dart';
import 'package:socialapp/servisler/yetkilendirmeservisi.dart';
import 'package:timeago/timeago.dart' as timeago;

class Yorumlar extends StatefulWidget {
  final Gonderi gonderi;

  const Yorumlar({Key key, this.gonderi}) : super(key: key);
  @override
  _YorumlarState createState() => _YorumlarState();
}

class _YorumlarState extends State<Yorumlar> {
  TextEditingController _yorumKontrolcusu = TextEditingController();
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages("tr", timeago.TrMessages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        title: Text(
          "Yorumlar",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [_yorumlariGoster(), _yorumEkle()],
      ),
    );
  }

  Widget _yorumlariGoster() {
    return Expanded(
        child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreServisi().yorumlariGetir(widget.gonderi.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              return ListView.builder(
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    Yorum yorum =
                        Yorum.dokumandanUret(snapshot.data.docs[index]);
                    return _yorumSatiri(yorum);
                  });
            }));
  }

  Widget _yorumSatiri(Yorum yorum) {
    return FutureBuilder<Kullanici>(
        future: FirestoreServisi().kullaniciGetir(yorum.yayinlananId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              height: 0,
            );
          }
          Kullanici yayinlanayan = snapshot.data;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: NetworkImage(yayinlanayan.fotoUrl),
            ),
            title: RichText(
                text: TextSpan(
                    text: yayinlanayan.kullaniciAdi + " ",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    children: [
                  TextSpan(
                      text: yorum.icerik,
                      style: TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 14))
                ])),
            subtitle: Text(
                timeago.format(yorum.olusturulmaZamani.toDate(), locale: "tr")),
          );
        });
  }

  Widget _yorumEkle() {
    return ListTile(
      title: TextFormField(
        controller: _yorumKontrolcusu,
        decoration: InputDecoration(hintText: "Yorumu buraya yazın"),
      ),
      trailing: IconButton(
        icon: Icon(Icons.send),
        onPressed: () {
          String aktifKullaniciId =
              Provider.of<YetkilendirmeServisi>(context, listen: false)
                  .aktifkullaniciId;

          FirestoreServisi().yorumEkle(
              aktifKullaniciId, widget.gonderi, _yorumKontrolcusu.text);
          _yorumKontrolcusu.clear();
        },
      ),
    );
  }
}
