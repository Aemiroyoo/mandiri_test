import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/layanan_laundry.dart';
import 'form_layanan_screen.dart';
import '../services/firestore_service.dart';

class DaftarHargaScreen extends StatefulWidget {
  const DaftarHargaScreen({Key? key}) : super(key: key);

  @override
  State<DaftarHargaScreen> createState() => _DaftarHargaScreenState();
}

class _DaftarHargaScreenState extends State<DaftarHargaScreen> {
  final _formatCurrency = NumberFormat('#,###', 'id_ID');
  final TextEditingController _searchController = TextEditingController();
  List<LayananLaundry> daftarHarga = [];
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final data = await FirestoreService.getAllLayanan();
    setState(() {
      daftarHarga =
          data
              .where(
                (item) => item.namaLayanan.toLowerCase().contains(
                  _keyword.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  Future<void> _showDeleteConfirmation(String id) async {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Hapus Data"),
            content: Text("Yakin ingin menghapus layanan ini?"),
            actions: [
              TextButton(
                child: Text("Batal"),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text("Hapus", style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  await FirestoreService.deleteLayanan(id);
                  Navigator.pop(context);
                  fetchData();
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Daftar Harga Laundry",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _keyword = val);
                fetchData();
              },
              decoration: InputDecoration(
                hintText: 'Cari layanan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: const Color.fromARGB(0, 245, 245, 245),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child:
                daftarHarga.isEmpty
                    ? const Center(child: Text("Belum ada data harga."))
                    : ListView.builder(
                      itemCount: daftarHarga.length,
                      itemBuilder: (context, index) {
                        final item = daftarHarga[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    149,
                                    193,
                                    255,
                                  ).withOpacity(0.1), // transparan
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.namaLayanan,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${item.kategori} - ${item.satuan}",
                                              style: TextStyle(
                                                color: const Color.fromARGB(
                                                  255,
                                                  41,
                                                  41,
                                                  41,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Rp. ${_formatCurrency.format(item.harga)},-",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 5),
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap:
                                                    () => showEditDialog(item),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    Icons.edit,
                                                    size: 20,
                                                    color: Colors.blue.shade800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap:
                                                    () =>
                                                        _showDeleteConfirmation(
                                                          item.id!,
                                                        ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FormLayananScreen()),
          );
          if (result == true) {
            fetchData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void showEditDialog(LayananLaundry layanan) {
    final namaController = TextEditingController(text: layanan.namaLayanan);
    final hargaController = TextEditingController(
      text: _formatCurrency.format(layanan.harga),
    );
    final List<String> kategoriList = ["Kiloan", "Satuan", "Boneka", "Sepatu"];
    final List<String> satuanList = ["kg", "item", "pasang", "m", "cm"];
    String? kategori = layanan.kategori;
    String? satuan = layanan.satuan;
    final _formKey = GlobalKey<FormState>();

    hargaController.addListener(() {
      final text = hargaController.text.replaceAll('.', '');
      final value = int.tryParse(text);
      if (value != null) {
        final newText = _formatCurrency.format(value);
        if (newText != hargaController.text) {
          hargaController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      }
    });

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Edit Layanan"),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(
                      labelText: "Nama Layanan",
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? "Wajib diisi"
                                : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: hargaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Harga"),
                    validator: (value) {
                      final cleaned = value?.replaceAll('.', '') ?? '';
                      if (cleaned.isEmpty) return "Harga tidak boleh kosong";
                      if (int.tryParse(cleaned) == null)
                        return "Harga harus berupa angka";
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: kategori,
                    decoration: const InputDecoration(labelText: "Kategori"),
                    items:
                        kategoriList
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => kategori = val!,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: satuan,
                    decoration: const InputDecoration(labelText: "Satuan"),
                    items:
                        satuanList
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) => satuan = val!,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Batal"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text("Simpan"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final updatedLayanan = LayananLaundry(
                        id: layanan.id,
                        namaLayanan: namaController.text,
                        kategori: kategori!,
                        harga: int.parse(
                          hargaController.text.replaceAll('.', ''),
                        ),
                        satuan: satuan!,
                      );
                      await FirestoreService.updateLayanan(updatedLayanan);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Data berhasil diperbarui"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      fetchData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Terjadi kesalahan saat menyimpan"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }
}
