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
  List<LayananLaundry> daftarHarga = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final data = await FirestoreService.getAllLayanan();
    setState(() {
      daftarHarga = data;
    });

    // setState(() {
    //   daftarHarga =
    //       snapshot.docs.map((doc) {
    //         final data = doc.data();
    //         return LayananLaundry(
    //           id: doc.id,
    //           namaLayanan: data['namaLayanan'],
    //           kategori: data['kategori'],
    //           harga: data['harga'],
    //           satuan: data['satuan'],
    //         );
    //       }).toList();
    // });
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
                  await FirestoreService.deleteLayanan(
                    id,
                  ); // ⬅️ Ini pemanggilannya
                  Navigator.pop(context);
                  fetchData(); // Refresh data
                },
              ),
            ],
          ),
    );
  }

  void showEditDialog(LayananLaundry layanan) {
    final namaController = TextEditingController(text: layanan.namaLayanan);
    final hargaController = TextEditingController(
      text: _formatCurrency.format(layanan.harga),
    );

    final List<String> kategoriList = ["Kiloan", "Satuan", "Boneka", "Sepatu"];
    final List<String> satuanList = ["kg", "item", "pasang"];

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
                      if (int.tryParse(cleaned) == null) {
                        return "Harga harus berupa angka";
                      }
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

                      await FirestoreService.updateLayanan(
                        updatedLayanan,
                      ); // ⬅️ Pemanggilannya
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Harga Laundry"),
        backgroundColor: Colors.blue.shade900,
      ),
      body:
          daftarHarga.isEmpty
              ? const Center(child: Text("Belum ada data harga."))
              : ListView.builder(
                itemCount: daftarHarga.length,
                itemBuilder: (context, index) {
                  final item = daftarHarga[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kiri
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Kanan
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Rp. ${_formatCurrency.format(item.harga)},-",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => showEditDialog(item),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed:
                                        () => _showDeleteConfirmation(item.id!),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
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
}
