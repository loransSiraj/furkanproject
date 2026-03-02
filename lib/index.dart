import 'package:flutter/material.dart';
import 'app_localizations.dart';

class IndexPage extends StatefulWidget {
  final Map<int, List<Map<String, dynamic>>> groupedBySura;
  final Function(int) onSuraSelected;
  final String appLanguage;

  IndexPage({
    required this.groupedBySura,
    required this.onSuraSelected,
    this.appLanguage = 'ar',
  });

  @override
  _IndexPageState createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  List<Map<String, dynamic>> _suras = [];
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredSuras = [];

  String _tr(String key) => AppLocalizations.tr(key, widget.appLanguage);

  @override
  void initState() {
    super.initState();
    _extractSuras();
    _filteredSuras = List.from(_suras);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _toArabicNumber(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      return arabicNumbers[int.parse(digit)];
    }).join();
  }

  void _extractSuras() {
    List<int> suraNumbers = widget.groupedBySura.keys.toList()..sort();

    for (int suraNo in suraNumbers) {
      List<Map<String, dynamic>>? ayat = widget.groupedBySura[suraNo];
      if (ayat != null && ayat.isNotEmpty) {
        var firstAya = ayat.first;
        _suras.add({
          'name': firstAya['sura_name_ar'] ?? 'سورة $suraNo',
          'name_en': firstAya['sura_name_en'] ?? '',
          'number': suraNo,
          'ayat_count': ayat.length,
        });
      }
    }
  }

  void _search(String query) {
    query = query.trim();
    if (query.isEmpty) {
      setState(() => _filteredSuras = List.from(_suras));
      return;
    }

    setState(() {
      _filteredSuras = _suras.where((sura) {
        String name = sura['name']?.toString() ?? '';
        String nameEn = sura['name_en']?.toString() ?? '';
        int number = sura['number'] ?? 0;
        
        return name.contains(query) ||
            nameEn.toLowerCase().contains(query.toLowerCase()) ||
            number.toString() == query ||
            _toArabicNumber(number).contains(query);
      }).toList();
    });
  }

  void _goToSura(int suraNo) {
    widget.onSuraSelected(suraNo);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tr('suraIndex')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF8B6914),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // حقل البحث
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF8B6914).withOpacity(0.05),
            ),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: _tr('searchSura'),
                hintTextDirection: TextDirection.rtl,
                prefixIcon: Icon(Icons.search, color: Color(0xFF8B6914)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF8B6914), width: 2),
                ),
              ),
              onChanged: _search,
            ),
          ),
          // قائمة السور
          Expanded(
            child: _buildSurasList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSurasList() {
    if (_suras.isEmpty) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF8B6914)));
    }

    if (_filteredSuras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(_tr('noResults'), style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _filteredSuras.length,
      itemBuilder: (context, index) {
        final sura = _filteredSuras[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _goToSura(sura['number']),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Color(0xFF8B6914).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _toArabicNumber(sura['number']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B6914),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sura['name'] ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C1810),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${sura['name_en'] ?? ''} • ${_toArabicNumber(sura['ayat_count'])} ${_tr('aya')}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
