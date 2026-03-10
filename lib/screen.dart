import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'app_localizations.dart';
import 'home.dart';

class SettingsPage extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final String selectedFont;
  final bool showAyaNumbers;
  final bool separateAyat;
  final bool showDividers;
  final List<Map<String, String>> availableFonts;
  final String selectedReciter;
  final String appLanguage;

  SettingsPage({
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
    required this.selectedFont,
    this.showAyaNumbers = true,
    this.separateAyat = false,
    this.showDividers = true,
    required this.availableFonts,
    this.selectedReciter = 'Alafasy_128kbps',
    this.appLanguage = 'ar',
  });

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Color _backgroundColor;
  late Color _textColor;
  late double _fontSize;
  late String _selectedFont;
  late bool _showAyaNumbers;
  late bool _separateAyat;
  late bool _showDividers;
  late String _selectedReciter;
  late String _appLanguage;

  String _tr(String key) => AppLocalizations.tr(key, _appLanguage);

  static const List<Map<String, String>> _languages = [
    {'code': 'ar', 'flag': '🇸🇦'},
    {'code': 'en', 'flag': '🇬🇧'},
    {'code': 'tr', 'flag': '🇹🇷'},
    {'code': 'sq', 'flag': '🇦🇱'},
  ];

  final List<Map<String, dynamic>> _themes = [
    {
      'nameKey': 'themeClassic',
      'background': Color(0xFFFFFBF0),
      'text': Color(0xFF2C1810),
      'icon': Icons.wb_sunny_outlined,
    },
    {
      'nameKey': 'themeNight',
      'background': Color(0xFF1A1A2E),
      'text': Color(0xFFE8E8E8),
      'icon': Icons.nightlight_outlined,
    },
    {
      'nameKey': 'themeSepia',
      'background': Color(0xFFF4ECD8),
      'text': Color(0xFF5C4033),
      'icon': Icons.auto_awesome,
    },
    {
      'nameKey': 'themeGreen',
      'background': Color(0xFFE8F5E9),
      'text': Color(0xFF1B5E20),
      'icon': Icons.eco_outlined,
    },
    {
      'nameKey': 'themeBlue',
      'background': Color(0xFFE3F2FD),
      'text': Color(0xFF0D47A1),
      'icon': Icons.water_drop_outlined,
    },
    {
      'nameKey': 'themeDark',
      'background': Color(0xFF121212),
      'text': Color(0xFFFFFFFF),
      'icon': Icons.dark_mode_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _backgroundColor = widget.backgroundColor;
    _textColor = widget.textColor;
    _fontSize = widget.fontSize;
    _selectedFont = widget.selectedFont;
    _showAyaNumbers = widget.showAyaNumbers;
    _separateAyat = widget.separateAyat;
    _showDividers = widget.showDividers;
    _selectedReciter = widget.selectedReciter;
    _appLanguage = widget.appLanguage;
  }

  void _pickColor(bool isBackground) async {
    Color tempColor = isBackground ? _backgroundColor : _textColor;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_tr('chooseColor')),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (color) {
                setState(() {
                  if (isBackground) {
                    _backgroundColor = color;
                  } else {
                    _textColor = color;
                  }
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_tr('done')),
            ),
          ],
        );
      },
    );
  }

  void _applyTheme(Map<String, dynamic> theme) {
    setState(() {
      _backgroundColor = theme['background'];
      _textColor = theme['text'];
    });
  }

  TextStyle _getPreviewStyle({double? fontSize, Color? color}) {
    double size = fontSize ?? _fontSize;
    Color textColor = color ?? _textColor;
    
    String fontFamily;
    switch (_selectedFont) {
      case 'Amiri Quran':
        fontFamily = 'AmiriQuran';
        break;
      case 'Amiri':
        fontFamily = 'Amiri';
        break;
      case 'Noto Naskh Arabic':
        fontFamily = 'NotoNaskhArabic';
        break;
      case 'Scheherazade New':
        fontFamily = 'ScheherazadeNew';
        break;
      default:
        fontFamily = 'AmiriQuran';
    }
    return TextStyle(fontFamily: fontFamily, fontSize: size, color: textColor);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tr('settings')),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الثيمات
            _buildSectionTitle(_tr('themes'), Icons.palette_outlined),
            Container(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _themes.length,
                itemBuilder: (context, index) {
                  final theme = _themes[index];
                  bool isSelected = _backgroundColor == theme['background'];
                  return GestureDetector(
                    onTap: () => _applyTheme(theme),
                    child: Container(
                      width: 70,
                      margin: EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        color: theme['background'],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(theme['icon'], color: theme['text'], size: 24),
                          SizedBox(height: 6),
                          Text(
                            _tr(theme['nameKey']),
                            style: TextStyle(
                              color: theme['text'],
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // الخطوط
            _buildSectionTitle('${_tr('font')} (${widget.availableFonts.length})', Icons.font_download_outlined),
            // شريط البحث والتصفية
            Container(
              height: 120,
              child: GridView.builder(
                scrollDirection: Axis.horizontal,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.availableFonts.length,
                itemBuilder: (context, index) {
                  final font = widget.availableFonts[index];
                  bool isSelected = _selectedFont == font['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedFont = font['name']!),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          font['display']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[700],
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '${_tr('selectedFont')}: ${widget.availableFonts.firstWhere((f) => f['name'] == _selectedFont, orElse: () => {'display': _selectedFont})['display']}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),

            _buildSectionTitle(_tr('customColors'), Icons.color_lens_outlined),
            Row(
              children: [
                Expanded(
                  child: _buildColorButton(_tr('background'), _backgroundColor, () => _pickColor(true)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildColorButton(_tr('text'), _textColor, () => _pickColor(false)),
                ),
              ],
            ),
            
            _buildSectionTitle(_tr('fontSize'), Icons.format_size),
            Row(
              children: [
                Icon(Icons.text_fields, size: 16, color: Colors.grey),
                Expanded(
                  child: Slider(
                    min: 16,
                    max: 36,
                    value: _fontSize,
                    divisions: 10,
                    label: _fontSize.round().toString(),
                    onChanged: (value) => setState(() => _fontSize = value),
                  ),
                ),
                Icon(Icons.text_fields, size: 24, color: Colors.grey),
              ],
            ),
            
            _buildSectionTitle(_tr('displayOptions'), Icons.view_agenda_outlined),
            Card(
              elevation: 0,
              color: Colors.grey[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(_tr('ayaNumbers'), style: TextStyle(fontSize: 14)),
                    subtitle: Text('﴿١﴾ ﴿٢﴾ ﴿٣﴾', style: TextStyle(fontSize: 12)),
                    value: _showAyaNumbers,
                    onChanged: (value) => setState(() => _showAyaNumbers = value),
                    dense: true,
                  ),
                  Divider(height: 1),
                  SwitchListTile(
                    title: Text(_tr('separateAyat'), style: TextStyle(fontSize: 14)),
                    subtitle: Text(_tr('separateAyatSub'), style: TextStyle(fontSize: 12)),
                    value: _separateAyat,
                    onChanged: (value) => setState(() => _separateAyat = value),
                    dense: true,
                  ),
                  Divider(height: 1),
                  SwitchListTile(
                    title: Text(_tr('dividerLine'), style: TextStyle(fontSize: 14)),
                    subtitle: Text(_tr('dividerLineSub'), style: TextStyle(fontSize: 12)),
                    value: _showDividers,
                    onChanged: (value) => setState(() => _showDividers = value),
                    dense: true,
                  ),
                ],
              ),
            ),
            
            _buildSectionTitle(_tr('reciter'), Icons.record_voice_over_outlined),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) {
                    return SafeArea(
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Text(_tr('chooseReciter'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: HomePage.availableReciters.length,
                                itemBuilder: (ctx, i) {
                                  final r = HomePage.availableReciters[i];
                                  final selected = _selectedReciter == r['id'];
                                  return ListTile(
                                    leading: Icon(
                                      selected ? Icons.check_circle : Icons.circle_outlined,
                                      color: selected ? Colors.green : Colors.grey,
                                    ),
                                    title: Text(r['name']!, textDirection: TextDirection.rtl,
                                      style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                                    onTap: () {
                                      setState(() => _selectedReciter = r['id']!);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.record_voice_over, color: Colors.green, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        HomePage.availableReciters.firstWhere(
                          (r) => r['id'] == _selectedReciter,
                          orElse: () => HomePage.availableReciters.first,
                        )['name']!,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),

            _buildSectionTitle(_tr('preview'), Icons.preview_outlined),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Text('﷽', style: _getPreviewStyle(fontSize: _fontSize + 4)),
                  SizedBox(height: 12),
                  Text(
                    'الحمد لله رب العالمين',
                    style: _getPreviewStyle(),
                    textAlign: TextAlign.center,
                  ),
                  if (_showAyaNumbers)
                    Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _textColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '٢',
                          style: _getPreviewStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  if (_showDividers) ...[
                    SizedBox(height: 12),
                    Divider(color: _textColor.withOpacity(0.2)),
                  ],
                ],
              ),
            ),
            
            // اللغة
            _buildSectionTitle(_tr('language'), Icons.language_outlined),
            _buildLanguageSelector(),

            SizedBox(height: 100),
          ],
        ),
      ),
      // زر الحفظ ثابت في الأسفل
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'backgroundColor': _backgroundColor,
                  'textColor': _textColor,
                  'fontSize': _fontSize,
                  'selectedFont': _selectedFont,
                  'showAyaNumbers': _showAyaNumbers,
                  'separateAyat': _separateAyat,
                  'showDividers': _showDividers,
                  'selectedReciter': _selectedReciter,
                  'appLanguage': _appLanguage,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _tr('saveSettings'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tr('appLanguage'),
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            SizedBox(height: 10),
            Row(
              children: _languages.map((lang) {
                final isSelected = _appLanguage == lang['code'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _appLanguage = lang['code']!),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      padding: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(lang['flag']!, style: TextStyle(fontSize: 22)),
                          SizedBox(height: 4),
                          Text(
                            AppLocalizations.tr(lang['code'] == 'ar' ? 'arabic'
                                : lang['code'] == 'en' ? 'english'
                                : lang['code'] == 'tr' ? 'turkish'
                                : 'albanian', lang['code']!),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[400]!, width: 1.5),
              ),
            ),
            SizedBox(width: 10),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            Spacer(),
            Icon(Icons.edit, size: 16, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
