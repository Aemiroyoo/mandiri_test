import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mandiri_test/models/layanan_laundry.dart';
import 'package:mandiri_test/models/penjualan_detail.dart';
import '../db/db_helper.dart';

class InputPenjualanScreen extends StatefulWidget {
  @override
  State<InputPenjualanScreen> createState() => _InputPenjualanScreenState();
}

class _InputPenjualanScreenState extends State<InputPenjualanScreen> {
  String? ownerId;

  final TextEditingController namaController = TextEditingController();
  final TextEditingController jumlahController = TextEditingController();

  List<LayananLaundry> semuaLayanan = [];
  List<String> kategoriList = [];
  String? kategoriTerpilih;
  LayananLaundry? layananTerpilih;
  List<LayananLaundry> filteredLayanan = [];

  List<PenjualanDetail> daftarLayanan = [];
  int totalHarga = 0;

  @override
  void initState() {
    super.initState();
    ambilOwnerId().then((_) {
      loadLayanan(); // setelah tahu owner, baru load data layanan
    });
  }

  Future<void> ambilOwnerId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = userDoc.data();
    setState(() {
      ownerId = data?['owner_id'] ?? uid;
      print("📌 owner_id aktif: $ownerId");
    });
  }

  Future<void> loadLayanan() async {
    if (ownerId == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('layanan_laundry')
            .where('owner_id', isEqualTo: ownerId)
            .get();

    final semuaLayanan =
        snapshot.docs.map((doc) {
          final d = doc.data();
          return LayananLaundry(
            id: doc.id,
            namaLayanan: d['namaLayanan'],
            kategori: d['kategori'],
            harga: d['harga'],
            satuan: d['satuan'],
          );
        }).toList();

    setState(() {
      // assign ke variabel lokal untuk digunakan di dropdown
    });
  }

  void tambahKeDaftar() {
    if (layananTerpilih != null && jumlahController.text.isNotEmpty) {
      final jumlah = int.tryParse(jumlahController.text) ?? 0;
      if (jumlah == 0) return;

      final total = jumlah * layananTerpilih!.harga;

      final detail = PenjualanDetail(
        penjualanId: '',
        layananId: layananTerpilih!.id!,
        namaLayanan: layananTerpilih!.namaLayanan,
        hargaSatuan: layananTerpilih!.harga,
        satuan: layananTerpilih!.satuan,
        jumlah: jumlah,
        total: total,
      );

      setState(() {
        daftarLayanan.add(detail);
        totalHarga += total;
        jumlahController.clear();
        layananTerpilih = null;
      });
    }
  }

  void hapusLayanan(int index) {
    setState(() {
      totalHarga -= daftarLayanan[index].total;
      daftarLayanan.removeAt(index);
    });
  }

  String capitalizeWords(String text) {
    return text
        .split(' ')
        .map(
          (word) =>
              word.isEmpty
                  ? ''
                  : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Future<void> simpanTransaksi() async {
    if (daftarLayanan.isEmpty || namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mohon isi nama & tambahkan layanan'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tanggal = DateTime.now().toIso8601String().substring(0, 10);
    print("Tanggal disimpan: $tanggal");

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final docRef = await FirebaseFirestore.instance.collection('penjualan').add(
      {
        'nama_pelanggan': capitalizeWords(namaController.text.trim()),
        'tanggal': tanggal,
        'total': totalHarga,
        'owner_id': uid, // ✅ TAMBAH INI
      },
    );

    for (var detail in daftarLayanan) {
      final dataDetail = detail.copyWith(penjualanId: docRef.id);
      await FirebaseFirestore.instance
          .collection('penjualan')
          .doc(docRef.id)
          .collection('detail')
          .add(dataDetail.toMap());
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Transaksi berhasil disimpan'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Input Penjualan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade900, Colors.blue.shade50],
            stops: [0.0, 0.1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ListView(
              physics: BouncingScrollPhysics(),
              children: [
                SizedBox(height: 20),
                // Card for input section
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detail Pelanggan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: namaController,
                          decoration: InputDecoration(
                            labelText: "Nama Pelanggan",
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.blue.shade700,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Card for layanan input
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Pilih Layanan",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: kategoriTerpilih,
                          hint: Text("Pilih Kategori"),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.category,
                              color: Colors.blue.shade700,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                          items:
                              kategoriList
                                  .map(
                                    (kat) => DropdownMenuItem(
                                      value: kat,
                                      child: Text(kat),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            setState(() {
                              kategoriTerpilih = value;
                              filteredLayanan =
                                  semuaLayanan
                                      .where((e) => e.kategori == value)
                                      .toList();
                              layananTerpilih = null;
                            });
                          },
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<LayananLaundry>(
                          value: layananTerpilih,
                          hint: Text("Pilih Layanan"),
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.local_laundry_service,
                              color: Colors.blue.shade700,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                          items:
                              filteredLayanan
                                  .map(
                                    (layanan) => DropdownMenuItem(
                                      value: layanan,
                                      child: Text(
                                        "${layanan.namaLayanan} - Rp ${layanan.harga}/${layanan.satuan}",
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (val) => setState(() => layananTerpilih = val),
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: jumlahController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Jumlah",
                            prefixIcon: Icon(
                              Icons.format_list_numbered,
                              color: Colors.blue.shade700,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.blue.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.add_shopping_cart),
                            label: Text(
                              "Tambah ke Daftar",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: tambahKeDaftar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Daftar layanan section
                if (daftarLayanan.isNotEmpty) ...[
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shopping_cart,
                                color: Colors.blue.shade900,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Daftar Layanan",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 24, thickness: 1),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: daftarLayanan.length,
                            separatorBuilder:
                                (context, index) => Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = daftarLayanan[i];
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                title: Text(
                                  item.namaLayanan,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  "${item.jumlah} ${item.satuan} x Rp${item.hargaSatuan}",
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "Rp ${item.total}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red.shade700,
                                      ),
                                      onPressed: () => hapusLayanan(i),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Divider(height: 24, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "Total: ",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "Rp $totalHarga",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      height: 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Belum ada layanan dipilih",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 20),

                // Button simpan
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  width: double.infinity,
                  // height: 55,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text(
                      "SIMPAN TRANSAKSI",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: simpanTransaksi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
