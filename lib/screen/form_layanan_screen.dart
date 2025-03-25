import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // <-- Tambahkan ini
import '../db/db_helper.dart';
import '../models/layanan_laundry.dart';

class FormLayananScreen extends StatefulWidget {
  @override
  _FormLayananScreenState createState() => _FormLayananScreenState();
}

class _FormLayananScreenState extends State<FormLayananScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();

  String? _kategoriTerpilih;
  String? _satuanTerpilih;

  final List<String> _kategoriList = ["Kiloan", "Satuan", "Boneka", "Sepatu"];
  final List<String> _satuanList = ["kg", "item", "pasang"];

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

      final layanan = LayananLaundry(
        namaLayanan: _namaController.text,
        kategori: _kategoriTerpilih!,
        harga: harga,
        satuan: _satuanTerpilih!,
      );

      print("DATA YANG AKAN DISIMPAN:");
      print(layanan.toMap());

      await DBHelper.insertLayanan(layanan);
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
        title: Text("Tambah Layanan"),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(labelText: "Nama Layanan"),
                validator:
                    (value) =>
                        value!.isEmpty ? "Nama tidak boleh kosong" : null,
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _hargaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Harga"),
                validator:
                    (value) =>
                        value!.isEmpty ? "Harga tidak boleh kosong" : null,
              ),
              SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _kategoriTerpilih,
                decoration: InputDecoration(labelText: "Kategori"),
                items:
                    _kategoriList
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _kategoriTerpilih = value),
                validator: (value) => value == null ? "Pilih kategori" : null,
              ),
              SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _satuanTerpilih,
                decoration: InputDecoration(labelText: "Satuan"),
                items:
                    _satuanList
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _satuanTerpilih = value),
                validator: (value) => value == null ? "Pilih satuan" : null,
              ),
              SizedBox(height: 24),

              ElevatedButton(
                onPressed: _simpanData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
