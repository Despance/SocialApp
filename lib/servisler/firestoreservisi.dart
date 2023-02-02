import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:socialapp/modeller/duyuru.dart';
import 'package:socialapp/modeller/gonderi.dart';
import 'package:socialapp/modeller/kullanici.dart';
import 'package:socialapp/servisler/storageservisi.dart';

class FirestoreServisi {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final zaman = DateTime.now();

  Future<void> kullaniciOlustur({id, email, kullaniciAdi, fotoUrl = ""}) async {
    await _firestore.collection("kullanicilar").doc(id).set({
      "kullaniciAdi": kullaniciAdi,
      "email": email,
      "fotoUrl": fotoUrl,
      "hakkinda": " ",
      "olusturulmaZamani": zaman
    });
  }

  Future<Kullanici> kullaniciGetir(id) async {
    DocumentSnapshot doc =
        await _firestore.collection("kullanicilar").doc(id).get();
    if (doc.exists) {
      Kullanici kullanici = Kullanici.dokumandanUret(doc);
      return kullanici;
    }
    return null;
  }

  void kullaniciGuncelle(
      {String kullaniciId,
      String kullaniciAdi,
      String fotoUrl = "",
      String hakkinda}) {
    _firestore.collection("kullanicilar").doc(kullaniciId).update({
      "kullaniciAdi": kullaniciAdi,
      "hakkinda": hakkinda,
      "fotoUrl": fotoUrl
    });
  }

  Future<List<Kullanici>> kullaniciAra(String kelime) async {
    QuerySnapshot snapshot = await _firestore
        .collection("kullanicilar")
        .where("kullaniciAdi", isGreaterThanOrEqualTo: kelime)
        .get();

    List<Kullanici> kullanicilar =
        snapshot.docs.map((e) => Kullanici.dokumandanUret(e)).toList();
    return kullanicilar;
  }

  void takipEt({String aktifKullaniciId, String profilSahibiId}) {
    _firestore
        .collection("takipciler")
        .doc(profilSahibiId)
        .collection("kullanicininTakipcileri")
        .doc(aktifKullaniciId)
        .set({});

    _firestore
        .collection("takipedilenler")
        .doc(aktifKullaniciId)
        .collection("kullanicininTakipleri")
        .doc(profilSahibiId)
        .set({});

    duyuruEkle(
        aktiviteTipi: "takip",
        aktiviteYapanId: aktifKullaniciId,
        profilSahibiId: profilSahibiId);
  }

  void takiptenCik({String aktifKullaniciId, String profilSahibiId}) {
    _firestore
        .collection("takipciler")
        .doc(profilSahibiId)
        .collection("kullanicininTakipcileri")
        .doc(aktifKullaniciId)
        .get()
        .then((DocumentSnapshot value) {
      if (value.exists) {
        value.reference.delete();
      }
    });

    _firestore
        .collection("takipedilenler")
        .doc(aktifKullaniciId)
        .collection("kullanicininTakipleri")
        .doc(profilSahibiId)
        .get()
        .then((DocumentSnapshot value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
  }

  Future<bool> takipKontrol(
      {String aktifKullaniciId, String profilSahibiId}) async {
    DocumentSnapshot doc = await _firestore
        .collection("takipedilenler")
        .doc(aktifKullaniciId)
        .collection("kullanicininTakipleri")
        .doc(profilSahibiId)
        .get();

    if (doc.exists) {
      return true;
    } else {
      return false;
    }
  }

  Future<int> takipciSayisi(kullaniciId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("takipciler")
        .doc(kullaniciId)
        .collection("kullanicininTakipcileri")
        .get();

    return snapshot.docs.length;
  }

  Future<int> takipEdilenSayisi(kullaniciId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("takipedilenler")
        .doc(kullaniciId)
        .collection("kullanicininTakipleri")
        .get();

    return snapshot.docs.length;
  }

  void duyuruEkle(
      {String aktiviteYapanId,
      String profilSahibiId,
      String aktiviteTipi,
      String yorum,
      Gonderi gonderi}) {
    if (aktiviteYapanId == profilSahibiId) {
      return;
    }
    _firestore
        .collection("duyurular")
        .doc(profilSahibiId)
        .collection("kullanicininDuyurulari")
        .add({
      "aktiviteYapanId": aktiviteYapanId,
      "aktiviteTipi": aktiviteTipi,
      "gonderiId": gonderi?.id,
      "yorum": yorum,
      "olusturmaZamani": zaman,
      "gonderiFoto": gonderi?.gonderiResmiUrl
    });
  }

  duyurulariGetir(String profilSahibiId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("duyurular")
        .doc(profilSahibiId)
        .collection("kullanicininDuyurulari")
        .orderBy("olusturmaZamani", descending: true)
        .limit(20)
        .get();

    List<Duyuru> duyurular = [];
    snapshot.docs.forEach((DocumentSnapshot doc) {
      Duyuru duyuru = Duyuru.dokumandanUret(doc);
      duyurular.add(duyuru);
    });
    return duyurular;
  }

  Future<void> gonderiOlustur(
      {gonderiResmiUrl, aciklama, yayinlananId, konum}) async {
    await _firestore
        .collection("gonderiler")
        .doc(yayinlananId)
        .collection("kullaniciGonderileri")
        .add({
      "gonderiResmiUrl": gonderiResmiUrl,
      "aciklama": aciklama,
      "yayinlananId": yayinlananId,
      "begeniSayisi": 0,
      "konum": konum,
      "olusturulmaZamani": zaman
    });
  }

  Future<List<Gonderi>> gonderileriGetir(kullaniciId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("gonderiler")
        .doc(kullaniciId)
        .collection("kullaniciGonderileri")
        .orderBy("olusturulmaZamani", descending: true)
        .get();

    return snapshot.docs.map((e) => Gonderi.dokumandanUret(e)).toList();
  }

  Future<List<Gonderi>> akisGonderileriniGetir(kullaniciId) async {
    QuerySnapshot snapshot = await _firestore
        .collection("akislar")
        .doc(kullaniciId)
        .collection("kullaniciAkisGonderileri")
        .orderBy("olusturulmaZamani", descending: true)
        .get();

    return snapshot.docs.map((e) => Gonderi.dokumandanUret(e)).toList();
  }

  Future<void> gonderiSil({String aktifKullaniciId, Gonderi gonderi}) async {
    _firestore
        .collection("gonderiler")
        .doc(aktifKullaniciId)
        .collection("kullaniciGonderileri")
        .doc(gonderi.id)
        .get()
        .then((DocumentSnapshot value) {
      if (value.exists) {
        value.reference.delete();
      }
    });

    QuerySnapshot yorumlarSnapshot = await _firestore
        .collection("yorumlar")
        .doc(gonderi.id)
        .collection("gonderiYorumlari")
        .get();

    yorumlarSnapshot.docs.forEach((DocumentSnapshot element) {
      if (element.exists) {
        element.reference.delete();
      }
    });

    QuerySnapshot duyurularSnapshot = await _firestore
        .collection("duyurular")
        .doc(aktifKullaniciId)
        .collection("kullanicininDuyurulari")
        .where("gonderiId", isEqualTo: gonderi.id)
        .get();
    duyurularSnapshot.docs.forEach((DocumentSnapshot element) {
      if (element.exists) {
        element.reference.delete();
      }
    });
    StorageServisi().gonderResmiSil(gonderi.gonderiResmiUrl);
  }

  Future<Gonderi> tekliGonderiGetir(
      String gonderiId, String gonderiSahibiId) async {
    DocumentSnapshot doc = await _firestore
        .collection("gonderiler")
        .doc(gonderiSahibiId)
        .collection("kullaniciGonderileri")
        .doc(gonderiId)
        .get();
    Gonderi gonderi = Gonderi.dokumandanUret(doc);
    return gonderi;
  }

  Future<void> gonderiBegen(Gonderi gonderi, String aktifKullaniciId) async {
    DocumentReference docRef = _firestore
        .collection("gonderiler")
        .doc(gonderi.yayinlananId)
        .collection("kullaniciGonderileri")
        .doc(gonderi.id);

    DocumentSnapshot doc = await docRef.get();

    if (doc.exists) {
      Gonderi gonderi = Gonderi.dokumandanUret(doc);
      int yeniBegeniSayisi = gonderi.begeniSayisi + 1;
      print("begen ${gonderi.id}");
      await docRef.update({"begeniSayisi": yeniBegeniSayisi});
    }

    _firestore
        .collection("begeniler")
        .doc(gonderi.id)
        .collection("gonderiBegenileri")
        .doc(aktifKullaniciId)
        .set({});

    duyuruEkle(
        aktiviteTipi: "begeni",
        aktiviteYapanId: aktifKullaniciId,
        gonderi: gonderi,
        profilSahibiId: gonderi.yayinlananId);
  }

  Future<void> gonderiBegeniKaldir(
      Gonderi gonderi, String aktifKullaniciId) async {
    print("Begenme ${gonderi.id}");
    DocumentReference docRef = _firestore
        .collection("gonderiler")
        .doc(gonderi.yayinlananId)
        .collection("kullaniciGonderileri")
        .doc(gonderi.id);

    DocumentSnapshot doc = await docRef.get();

    if (doc.exists) {
      Gonderi gonderi = Gonderi.dokumandanUret(doc);
      int yeniBegeniSayisi = gonderi.begeniSayisi - 1;
      await docRef.update({"begeniSayisi": yeniBegeniSayisi});
    }
    DocumentSnapshot docBegeni = await _firestore
        .collection("begeniler")
        .doc(gonderi.id)
        .collection("gonderiBegenileri")
        .doc(aktifKullaniciId)
        .get();

    if (docBegeni.exists) {
      docBegeni.reference.delete();
    }
  }

  begeniVarMi(Gonderi gonderi, String aktifKullaniciId) async {
    DocumentSnapshot docBegeni = await _firestore
        .collection("begeniler")
        .doc(gonderi.id)
        .collection("gonderiBegenileri")
        .doc(aktifKullaniciId)
        .get();

    if (docBegeni.exists) {
      return true;
    } else {
      return false;
    }
  }

  Stream<QuerySnapshot> yorumlariGetir(String gonderId) {
    return _firestore
        .collection("yorumlar")
        .doc(gonderId)
        .collection("gonderiYorumlari")
        .orderBy("olusturulmaZamani", descending: false)
        .snapshots();
  }

  void yorumEkle(String aktifKullaniciId, Gonderi gonderi, String icerik) {
    _firestore
        .collection("yorumlar")
        .doc(gonderi.id)
        .collection("gonderiYorumlari")
        .add({
      "icerik": icerik,
      "yayinlananId": aktifKullaniciId,
      "olusturulmaZamani": zaman
    });
    duyuruEkle(
        aktiviteTipi: "yorum",
        aktiviteYapanId: aktifKullaniciId,
        gonderi: gonderi,
        profilSahibiId: gonderi.yayinlananId,
        yorum: icerik);
  }
}
