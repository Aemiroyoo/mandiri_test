import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../db/db_helper.dart';
import '../models/layanan_laundry.dart';

class FormLayananScreen extends StatefulWidget {
  @override
  _FormLayananScreenState createState() => _FormLayananScreenState();
}

class _FormLayananScreenState extends State<FormLayananScreen> {
  String? ownerId;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();

  String? _kategoriTerpilih;
  String? _satuanTerpilih;

  final List<String> _kategoriList = ["Kiloan", "Satuan", "Boneka", "Sepatu"];
  final List<String> _satuanList = ["kg", "item", "pasang", "m", "cm"];

  final formatCurrency = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _hargaController.addListener(() {
      final text = _hargaController.text.replaceAll('.', '');
      if (text.isEmpty) return;

      final value = int.tryParse(text);
      if (value != null) {
        final newText = formatCurrency.format(value);
        if (newText != _hargaController.text) {
          _hargaController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      }
    });
  }

  Future<void> _simpanData() async {
    if (_formKey.currentState!.validate()) {
      final harga = int.parse(_hargaController.text.replaceAll('.', ''));

      final cleanedNamaLayanan = _namaController.text
          .toLowerCase()
          .split(' ')
          .where((word) => word.isNotEmpty)
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');

      final layanan = LayananLaundry(
        namaLayanan: cleanedNamaLayanan,
        kategori: _kategoriTerpilih!,
        harga: harga,
        satuan: _satuanTerpilih!,
      );

      print("DATA YANG AKAN DISIMPAN:");
      print(layanan.toMap());

      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('layanan_laundry').add({
        'namaLayanan': layanan.namaLayanan,
        'kategori': layanan.kategori,
        'harga': layanan.harga,
        'satuan': layanan.satuan,
        'owner_id': uid, // ✅ TAMBAH INI
      });

      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _hargaController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          "Tambah Layanan",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.topCenter,
            colors: [Colors.blue.shade900, Colors.blue.shade900],
            stops: [0, 0.3],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        Text(
                          "Detail Layanan",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        SizedBox(height: 20),
                        // Nama Layanan Field
                        TextFormField(
                          controller: _namaController,
                          decoration: InputDecoration(
                            labelText: "Nama Layanan",
                            labelStyle: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Icon(
                              Icons.local_laundry_service_outlined,
                              color: Colors.blue.shade900,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade900,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? "Nama tidak boleh kosong"
                                      : null,
                        ),
                        SizedBox(height: 20),
                        // Harga Field
                        TextFormField(
                          controller: _hargaController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: "Harga",
                            labelStyle: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Icon(
                              Icons.monetization_on_outlined,
                              color: Colors.blue.shade900,
                            ),
                            prefixText: "Rp ",
                            prefixStyle: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade900,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Harga tidak boleh kosong";
                            }
                            final cleaned = value.replaceAll('.', '');
                            if (int.tryParse(cleaned) == null) {
                              return "Harga harus berupa angka";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        // Kategori Dropdown
                        DropdownButtonFormField<String>(
                          value: _kategoriTerpilih,
                          decoration: InputDecoration(
                            labelText: "Kategori",
                            labelStyle: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Icon(
                              Icons.category_outlined,
                              color: Colors.blue.shade900,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade900,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down_circle,
                            color: Colors.blue.shade900,
                          ),
                          isExpanded: true,
                          items:
                              _kategoriList
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => _kategoriTerpilih = value),
                          validator:
                              (value) =>
                                  value == null ? "Pilih kategori" : null,
                        ),
                        SizedBox(height: 20),
                        // Satuan Dropdown
                        DropdownButtonFormField<String>(
                          value: _satuanTerpilih,
                          decoration: InputDecoration(
                            labelText: "Satuan",
                            labelStyle: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            floatingLabelStyle: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                            prefixIcon: Icon(
                              Icons.straighten_outlined,
                              color: Colors.blue.shade900,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.blue.shade900,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.red.shade700,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down_circle,
                            color: Colors.blue.shade900,
                          ),
                          isExpanded: true,
                          items:
                              _satuanList
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged:
                              (value) =>
                                  setState(() => _satuanTerpilih = value),
                          validator:
                              (value) => value == null ? "Pilih satuan" : null,
                        ),
                        SizedBox(height: 40),
                        // Tombol Simpan
                        ElevatedButton(
                          onPressed: _simpanData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade900,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            "Simpan Layanan",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
