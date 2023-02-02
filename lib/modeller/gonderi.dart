import 'package:cloud_firestore/cloud_firestore.dart';

class Gonderi {
  final String id;
  final String gonderiResmiUrl;
  final String aciklama;
  final String yayinlananId;
  final int begeniSayisi;
  final String konum;

  Gonderi(
      {this.id,
      this.gonderiResmiUrl,
      this.aciklama,
      this.yayinlananId,
      this.begeniSayisi,
      this.konum});

  factory Gonderi.dokumandanUret(DocumentSnapshot doc) {
    return Gonderi(
        id: doc.id,
        gonderiResmiUrl: doc.data()["gonderiResmiUrl"],
        aciklama: doc.data()["aciklama"],
        yayinlananId: doc.data()["yayinlananId"],
        begeniSayisi: doc.data()["begeniSayisi"],
        konum: doc.data()["konum"]);
  }
}
