import 'package:cloud_firestore/cloud_firestore.dart';

class Yorum {
  final String id;
  final String icerik;
  final String yayinlananId;
  final Timestamp olusturulmaZamani;

  Yorum({this.id, this.icerik, this.yayinlananId, this.olusturulmaZamani});

  factory Yorum.dokumandanUret(DocumentSnapshot doc) {
    return Yorum(
        id: doc.id,
        icerik: doc.data()["icerik"],
        yayinlananId: doc.data()["yayinlananId"],
        olusturulmaZamani: doc.data()["olusturulmaZamani"]);
  }
}
