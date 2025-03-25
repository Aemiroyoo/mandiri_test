import 'package:flutter/material.dart';
import 'package:mandiri_test/screen/form_layanan_screen.dart';
import '../db/db_helper.dart';
import '../models/layanan_laundry.dart';
import 'package:intl/intl.dart';

class DaftarHargaScreen extends StatefulWidget {
  @override
  _DaftarHargaScreenState createState() => _DaftarHargaScreenState();
}

class _DaftarHargaScreenState extends State<DaftarHargaScreen> {
  final _formatCurrency = NumberFormat('#,###', 'id_ID');
  List<LayananLaundry> daftarHarga = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Fetch data dari database
  Future<void> fetchData() async {
    final data = await DBHelper.getAllLayanan();
    setState(() {
      daftarHarga = data;
    });
  }

  // Tampilkan dialog edit
  void showEditDialog(LayananLaundry layanan) {
    final TextEditingController namaController = TextEditingController(
      text: layanan.namaLayanan,
    );
    final TextEditingController hargaController = TextEditingController(
      text: NumberFormat('#,###', 'id_ID').format(layanan.harga),
    );

    // ✅ Pindahkan ke atas

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

    String? kategori = layanan.kategori;
    String? satuan = layanan.satuan;

    final List<String> kategoriList = ["Kiloan", "Satuan", "Boneka", "Sepatu"];
    final List<String> satuanList = ["kg", "item", "pasang"];

    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Edit Layanan"),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: namaController,
                      decoration: InputDecoration(labelText: "Nama Layanan"),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? "Wajib diisi"
                                  : null,
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: hargaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "Harga"),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Harga tidak boleh kosong";
                        }
                        final cleaned = value.replaceAll(
                          '.',
                          '',
                        ); // 👉 hilangkan titik
                        if (int.tryParse(cleaned) == null) {
                          return "Harga harus berupa angka";
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: kategori,
                      decoration: InputDecoration(labelText: "Kategori"),
                      items:
                          kategoriList
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) => kategori = val!,
                      validator:
                          (value) => value == null ? "Pilih kategori" : null,
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: satuan,
                      decoration: InputDecoration(labelText: "Satuan"),
                      items:
                          satuanList
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) => satuan = val!,
                      validator:
                          (value) => value == null ? "Pilih satuan" : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text("Batal"),
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

                      await DBHelper.updateLayanan(updatedLayanan);
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Mohon lengkapi dan periksa form terlebih dahulu",
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
    );
  }

  // Tampilkan dialog konfirmasi hapus
  Future<void> _showDeleteConfirmation(int id) async {
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
                  await DBHelper.deleteLayanan(id);
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
      appBar: AppBar(
        title: Text("Daftar Harga Laundry"),
        backgroundColor: Colors.blue.shade900,
      ),
      body:
          daftarHarga.isEmpty
              ? Center(child: Text("Belum ada data harga."))
              : ListView.builder(
                itemCount: daftarHarga.length,
                itemBuilder: (context, index) {
                  final item = daftarHarga[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kiri: Nama + Kategori
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.namaLayanan,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
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

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Rp. ${_formatCurrency.format(item.harga)},-",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () => showEditDialog(item),
                                  ),
                                  SizedBox(width: 2),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed:
                                        () => _showDeleteConfirmation(item.id!),
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
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FormLayananScreen()),
          );
          if (result == true) {
            fetchData(); // Refresh data
          }
        },
      ),
    );
  }
}
