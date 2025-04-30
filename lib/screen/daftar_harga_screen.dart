import 'package:firebase_auth/firebase_auth.dart';
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
  String? ownerId;
  // final List<String> _kategoriList = ["Kiloan", "Satuan", "Boneka", "Sepatu"];
  final _formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );
  final TextEditingController _searchController = TextEditingController();
  List<LayananLaundry> daftarHarga = [];
  List<String> _kategoriList = [];
  String _keyword = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    ambilOwnerId().then((_) {
      fetchData();
    });
  }

  Future<void> ambilOwnerId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    final data = userDoc.data();
    ownerId = data?['owner_id'] ?? uid;
    print('📌 owner_id aktif: $ownerId');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data =
          await FirebaseFirestore.instance
              .collection('layanan_laundry')
              .where('owner_id', isEqualTo: ownerId)
              .get();

      final layananList =
          data.docs.map((doc) {
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
        _kategoriList =
            layananList.map((item) => item.kategori).toSet().toList();
        daftarHarga =
            layananList.where((item) {
              if (_keyword.isEmpty) return true;
              if (_kategoriList.contains(_keyword)) {
                return item.kategori.toLowerCase() == _keyword.toLowerCase();
              } else {
                return item.namaLayanan.toLowerCase().contains(
                  _keyword.toLowerCase(),
                );
              }
            }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal memuat data: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'kiloan':
        return '⚖️';
      case 'satuan':
        return '👕';
      case 'boneka':
        return '🧸';
      case 'sepatu':
        return '👟';
      default:
        return '🧺';
    }
  }

  Color _getColorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'kiloan':
        return Colors.blue.shade50;
      case 'satuan':
        return Colors.green.shade50;
      case 'boneka':
        return Colors.purple.shade50;
      case 'sepatu':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Future<void> _showDeleteConfirmation(String id, String name) async {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Hapus Layanan"),
            content: Text("Yakin ingin menghapus layanan \"$name\"?"),
            actions: [
              TextButton(
                child: Text("Batal"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Hapus"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await FirestoreService.deleteLayanan(id);
                    fetchData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Layanan berhasil dihapus"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Gagal menghapus layanan"),
                        backgroundColor: Colors.red,
                      ),
                    );
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Daftar Harga Laundry",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade800],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar in Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _keyword = val);
                    fetchData();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari layanan...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade800),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    suffixIcon:
                        _keyword.isNotEmpty
                            ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _keyword = '');
                                fetchData();
                              },
                            )
                            : null,
                  ),
                ),
              ),
            ),
          ),

          // Category Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip("Semua", isSelected: _keyword.isEmpty),
                  _buildCategoryChip("Kiloan"),
                  _buildCategoryChip("Satuan"),
                  _buildCategoryChip("Boneka"),
                  _buildCategoryChip("Sepatu"),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : daftarHarga.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            _keyword.isEmpty
                                ? "Belum ada data harga"
                                : "Tidak ditemukan layanan \"$_keyword\"",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                            ),
                          ),
                          if (_keyword.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _keyword = '');
                                fetchData();
                              },
                              child: Text("Reset Pencarian"),
                            ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: fetchData,
                      color: Colors.blue.shade900,
                      child: ListView.builder(
                        padding: EdgeInsets.only(bottom: 80),
                        itemCount: daftarHarga.length,
                        itemBuilder: (context, index) {
                          final item = daftarHarga[index];
                          return _buildServiceCard(item);
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        elevation: 4,
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

  Widget _buildCategoryChip(String category, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected:
            isSelected ||
            (category != "Semua" &&
                _keyword.toLowerCase() == category.toLowerCase()),
        onSelected: (selected) {
          if (selected) {
            _searchController.text = category == "Semua" ? "" : category;
            setState(() => _keyword = category == "Semua" ? "" : category);
            fetchData();
          }
        },
        backgroundColor: Colors.white,
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue.shade900,
        labelStyle: TextStyle(
          color:
              isSelected ||
                      (category != "Semua" &&
                          _keyword.toLowerCase() == category.toLowerCase())
                  ? Colors.blue.shade900
                  : Colors.black87,
          fontWeight:
              isSelected ||
                      (category != "Semua" &&
                          _keyword.toLowerCase() == category.toLowerCase())
                  ? FontWeight.bold
                  : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildServiceCard(LayananLaundry item) {
    final cardColor = _getColorForCategory(item.kategori);
    final categoryIcon = _getIconForCategory(item.kategori);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(categoryIcon, style: TextStyle(fontSize: 24)),
                ),
              ),
              SizedBox(width: 12),

              // Service Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaLayanan,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.kategori,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "Per ${item.satuan}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Price and Actions
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${_formatCurrency.format(item.harga)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        color: Colors.blue,
                        onTap: () => showEditDialog(item),
                      ),
                      SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete,
                        color: Colors.red,
                        onTap:
                            () => _showDeleteConfirmation(
                              item.id!,
                              item.namaLayanan,
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
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void showEditDialog(LayananLaundry layanan) {
    final namaController = TextEditingController(text: layanan.namaLayanan);
    final hargaController = TextEditingController(
      text: layanan.harga.toString(),
    );
    final List<String> kategoriList = ["Kiloan", "Satuan", "Boneka", "Sepatu"];
    final List<String> satuanList = ["kg", "item", "pasang", "m", "cm"];
    String? kategori = layanan.kategori;
    String? satuan = layanan.satuan;
    final _formKey = GlobalKey<FormState>();

    // Format the currency for display
    _updateHargaTextFormatting(hargaController);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Edit Layanan"),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: namaController,
                      decoration: InputDecoration(
                        labelText: "Nama Layanan",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.cleaning_services),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? "Wajib diisi"
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: hargaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Harga",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.monetization_on),
                        prefixText: "Rp. ",
                      ),
                      onChanged:
                          (_) => _updateHargaTextFormatting(hargaController),
                      validator: (value) {
                        final cleaned = value?.replaceAll('.', '') ?? '';
                        if (cleaned.isEmpty) return "Harga tidak boleh kosong";
                        if (int.tryParse(cleaned) == null)
                          return "Harga harus berupa angka";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: kategori,
                      decoration: InputDecoration(
                        labelText: "Kategori",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items:
                          kategoriList
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) => kategori = val!,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: satuan,
                      decoration: InputDecoration(
                        labelText: "Satuan",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.straighten),
                      ),
                      items:
                          satuanList
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                      onChanged: (val) => satuan = val!,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text("Simpan"),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final cleanedNamaLayanan = namaController.text
                          .toLowerCase()
                          .split(' ')
                          .where((word) => word.isNotEmpty)
                          .map(
                            (word) => word[0].toUpperCase() + word.substring(1),
                          )
                          .join(' ');

                      final updatedLayanan = LayananLaundry(
                        id: layanan.id,
                        namaLayanan: cleanedNamaLayanan,
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

  void _updateHargaTextFormatting(TextEditingController controller) {
    String text = controller.text.replaceAll('.', '');
    final value = int.tryParse(text);
    if (value != null) {
      final formatter = NumberFormat('#,###', 'id_ID');
      final newText = formatter.format(value);
      if (newText != controller.text) {
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }
  }
}
