import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_localizations.dart';
import 'index.dart';
import 'screen.dart';
import 'reminder_page.dart';

// أنواع العناصر
enum ItemType { suraHeader, basmala, aya }

class QuranItem {
  final ItemType type;
  final int suraNo;
  final String suraName;
  final int? ayaNo;
  final String? ayaText;
  final bool isSajda;
  final int totalAyatInSura;

  QuranItem({
    required this.type,
    required this.suraNo,
    required this.suraName,
    this.ayaNo,
    this.ayaText,
    this.isSajda = false,
    this.totalAyatInSura = 0,
  });
}

class HomePage extends StatefulWidget {
  static const List<Map<String, String>> availableReciters = [
    {'id': 'Alafasy_128kbps', 'name': 'مشاري العفاسي'},
    {'id': 'Abdul_Basit_Murattal_192kbps', 'name': 'عبد الباسط - مرتل'},
    {'id': 'Abdul_Basit_Mujawwad_128kbps', 'name': 'عبد الباسط - مجود'},
    {'id': 'Husary_128kbps', 'name': 'محمود خليل الحصري'},
    {'id': 'Husary_Muallim_128kbps', 'name': 'الحصري - معلم'},
    {'id': 'Minshawy_Murattal_128kbps', 'name': 'المنشاوي - مرتل'},
    {'id': 'Minshawy_Mujawwad_192kbps', 'name': 'المنشاوي - مجود'},
    {'id': 'Abdurrahmaan_As-Sudais_192kbps', 'name': 'عبد الرحمن السديس'},
    {'id': 'Saood_ash-Shuraym_128kbps', 'name': 'سعود الشريم'},
    {'id': 'MaherAlMuaiqly128kbps', 'name': 'ماهر المعيقلي'},
    {'id': 'Hani_Rifai_192kbps', 'name': 'هاني الرفاعي'},
    {'id': 'Abu_Bakr_Ash-Shaatree_128kbps', 'name': 'أبو بكر الشاطري'},
    {'id': 'Muhammad_Ayyoub_128kbps', 'name': 'محمد أيوب'},
    {'id': 'Muhammad_Jibreel_128kbps', 'name': 'محمد جبريل'},
    {'id': 'Hudhaify_128kbps', 'name': 'علي الحذيفي'},
    {'id': 'Abdullah_Basfar_192kbps', 'name': 'عبد الله بصفر'},
    {'id': 'Nasser_Alqatami_128kbps', 'name': 'ناصر القطامي'},
    {'id': 'Yasser_Ad-Dussary_128kbps', 'name': 'ياسر الدوسري'},
    {'id': 'Salah_Al_Budair_128kbps', 'name': 'صلاح البدير'},
    {'id': 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net', 'name': 'أحمد العجمي'},
  ];

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<QuranItem> _items = [];
  Map<int, List<Map<String, dynamic>>> _groupedBySura = {};
  Map<String, int> _ayaToIndex = {}; // "suraNo-ayaNo" -> index
  Map<int, int> _suraHeaderIndex = {}; // suraNo -> index of header
  
  bool _isLoading = true;
  String _currentSura = "";
  int _currentSuraNo = 1;
  int _currentAyaNo = 1;
  int _totalAyatInCurrentSura = 1;
  
  // إعدادات المظهر
  Color _backgroundColor = const Color(0xFFFFFBF0);
  Color _textColor = const Color(0xFF2C1810);
  Color _accentColor = const Color(0xFF8B6914);
  double _fontSize = 22;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  final Map<int, Offset> _activePointers = {};
  double _initialPinchDistance = 0;
  String _selectedFont = 'Amiri Quran';
  bool _showAyaNumbers = true;
  bool _separateAyat = false;
  bool _showDividers = true;
  
  // Controllers للتمرير
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ScrollOffsetController _scrollOffsetController = ScrollOffsetController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ScrollOffsetListener _scrollOffsetListener = ScrollOffsetListener.create();

  // نظام القراءة التلقائية
  bool _autoScrollEnabled = false;
  double _autoScrollSpeed = 1.0;
  bool _showAutoScrollPanel = false;
  bool _userIsTouching = false;

  // مؤشر القراءة والمرجعيات
  String? _selectedAyaKey; // "suraNo-ayaNo" للآية المحددة
  String? _translationAyaKey; // الآية التي تظهر ترجمتها
  Map<String, int> _bookmarks = {}; // key -> colorIndex

  static const List<Color> _bookmarkColors = [
    Color(0xFFE53935), // أحمر
    Color(0xFF1E88E5), // أزرق
    Color(0xFF43A047), // أخضر
    Color(0xFFFB8C00), // برتقالي
    Color(0xFF8E24AA), // بنفسجي
    Color(0xFF00ACC1), // تركواز
    Color(0xFFF4511E), // أحمر برتقالي
    Color(0xFF3949AB), // نيلي
    Color(0xFFD81B60), // وردي
    Color(0xFF6D4C41), // بني
  ];

  // مواضع السجدات
  final Map<int, List<int>> _sajdaPositions = {
    7: [206], 13: [15], 16: [50], 17: [109], 19: [58],
    22: [18, 77], 25: [60], 27: [26], 32: [15], 38: [24],
    41: [38], 53: [62], 84: [21], 96: [19],
  };

  // نظام الصوت
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;
  String? _playingAyaKey;
  String _selectedReciter = 'Alafasy_128kbps';
  // 0 = آية واحدة, 1 = مستمر, 2 = تكرار (loop)
  int _playMode = 1;

  // اللغة والترجمة
  String _appLanguage = 'ar';
  Map<String, String> _translationData = {};
  bool _translationLoading = false;

  String _tr(String key) => AppLocalizations.tr(key, _appLanguage);
  bool get _hasTranslation => _appLanguage != 'ar' && _translationData.isNotEmpty;

  // الخطوط المتاحة (خطوط قرآنية فقط)
  final List<Map<String, String>> _availableFonts = [
    {'name': 'Amiri Quran', 'display': 'أميري قرآن'},
    {'name': 'Amiri', 'display': 'أميري'},
    {'name': 'Noto Naskh Arabic', 'display': 'النسخ'},
    {'name': 'Scheherazade New', 'display': 'شهرزاد'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadJsonData();
    _itemPositionsListener.itemPositions.addListener(_onPositionChanged);
    _setupAudioListeners();
  }

  bool _audioSessionInitialized = false;

  Future<void> _initAudioSession() async {
    if (_audioSessionInitialized) return;
    _audioSessionInitialized = true;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
    } catch (e) {
      debugPrint('Audio session init error: $e');
    }
  }

  static const _wakelockChannel = MethodChannel('com.furqan.quran/wakelock');

  void _setWakeLock(bool enabled) {
    if (enabled) {
      _wakelockChannel.invokeMethod('enable');
    } else {
      if (!_autoScrollEnabled && !_isPlayingAudio) {
        _wakelockChannel.invokeMethod('disable');
      }
    }
  }

  @override
  void dispose() {
    _autoScrollEnabled = false;
    _audioPlayer.dispose();
    _wakelockChannel.invokeMethod('disable');
    _saveLastPosition();
    _saveBookmarks();
    super.dispose();
  }

  // ========== حفظ واسترجاع الإعدادات ==========
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _backgroundColor = Color(prefs.getInt('backgroundColor') ?? 0xFFFFFBF0);
      _textColor = Color(prefs.getInt('textColor') ?? 0xFF2C1810);
      _accentColor = Color(prefs.getInt('accentColor') ?? 0xFF8B6914);
      _fontSize = prefs.getDouble('fontSize') ?? 22;
      _selectedFont = prefs.getString('selectedFont') ?? 'Amiri Quran';
      _showAyaNumbers = prefs.getBool('showAyaNumbers') ?? true;
      _separateAyat = prefs.getBool('separateAyat') ?? false;
      _showDividers = prefs.getBool('showDividers') ?? true;
      _autoScrollSpeed = prefs.getDouble('autoScrollSpeed') ?? 1.0;
      _selectedReciter = prefs.getString('selectedReciter') ?? 'Alafasy_128kbps';
      _appLanguage = prefs.getString('appLanguage') ?? 'ar';
      final bookmarkList = prefs.getStringList('bookmarks_v2') ?? [];
      _bookmarks = {};
      for (final entry in bookmarkList) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          _bookmarks[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }
    });

    if (_appLanguage != 'ar') {
      _loadTranslation(_appLanguage);
    }
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt('backgroundColor', _backgroundColor.value);
    await prefs.setInt('textColor', _textColor.value);
    await prefs.setInt('accentColor', _accentColor.value);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('selectedFont', _selectedFont);
    await prefs.setBool('showAyaNumbers', _showAyaNumbers);
    await prefs.setBool('separateAyat', _separateAyat);
    await prefs.setBool('showDividers', _showDividers);
    await prefs.setDouble('autoScrollSpeed', _autoScrollSpeed);
    await prefs.setString('selectedReciter', _selectedReciter);
    await prefs.setString('appLanguage', _appLanguage);
    await _saveBookmarks(prefs: prefs);
  }

  Future<void> _saveBookmarks({SharedPreferences? prefs}) async {
    prefs ??= await SharedPreferences.getInstance();
    await prefs.setStringList('bookmarks_v2',
        _bookmarks.entries.map((e) => '${e.key}:${e.value}').toList());
  }
  
  // ========== نظام الترجمة ==========

  Future<void> _loadTranslation(String langCode) async {
    if (_translationLoading) return;
    setState(() => _translationLoading = true);

    final Map<String, String> fileMap = {
      'en': 'assets/translation_en.json',
      'tr': 'assets/translation_tr.json',
      'sq': 'assets/translation_sq.json',
    };

    final filePath = fileMap[langCode];
    if (filePath == null) {
      setState(() {
        _translationData = {};
        _translationLoading = false;
      });
      return;
    }

    try {
      final jsonString = await rootBundle.loadString(filePath);
      final data = json.decode(jsonString);
      final List<dynamic> quranList = data['quran'] ?? [];

      Map<String, String> translations = {};
      for (var item in quranList) {
        final chapter = item['chapter'];
        final verse = item['verse'];
        final text = item['text'] ?? '';
        translations['$chapter-$verse'] = text;
      }

      setState(() {
        _translationData = translations;
        _translationLoading = false;
      });
    } catch (e) {
      debugPrint('خطأ في تحميل الترجمة: $e');
      setState(() {
        _translationData = {};
        _translationLoading = false;
      });
    }
  }

  // ========== نظام تشغيل الصوت ==========

  void _setupAudioListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_playMode == 2) {
          _replayCurrentAya();
        } else if (_playMode == 1) {
          _playNextAya();
        } else {
          setState(() {
            _isPlayingAudio = false;
            _playingAyaKey = null;
          });
          _setWakeLock(false);
        }
      }
    });
  }

  String _getAudioUrl(int suraNo, int ayaNo) {
    final sura = suraNo.toString().padLeft(3, '0');
    final aya = ayaNo.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$_selectedReciter/$sura$aya.mp3';
  }

  Future<void> _playAya(int suraNo, int ayaNo) async {
    final key = '$suraNo-$ayaNo';
    
    if (_isPlayingAudio && _playingAyaKey == key) {
      await _stopAudio();
      return;
    }
    
    try {
      await _initAudioSession();
      if (_autoScrollEnabled) _stopAutoScroll();
      
      setState(() {
        _isPlayingAudio = true;
        _playingAyaKey = key;
        _showAutoScrollPanel = true;
      });
      _setWakeLock(true);
      
      final url = _getAudioUrl(suraNo, ayaNo);
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      final index = _ayaToIndex[key];
      if (index != null && _itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('خطأ في تشغيل الصوت: $e');
      setState(() {
        _isPlayingAudio = false;
        _playingAyaKey = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('audioError'),
                textAlign: TextAlign.center),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _replayCurrentAya() async {
    if (_playingAyaKey == null) return;
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('خطأ في إعادة التشغيل: $e');
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlayingAudio = false;
      _playingAyaKey = null;
    });
    _setWakeLock(false);
  }

  Future<void> _pauseResumeAudio() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
      setState(() => _isPlayingAudio = false);
    } else {
      await _audioPlayer.play();
      setState(() => _isPlayingAudio = true);
    }
  }

  void _cyclePlayMode() {
    setState(() {
      _playMode = (_playMode + 1) % 3;
    });
  }

  String _getPlayModeLabel() {
    switch (_playMode) {
      case 0: return _tr('singleAya');
      case 1: return _tr('continuous');
      case 2: return _tr('loop');
      default: return '';
    }
  }

  IconData _getPlayModeIcon() {
    switch (_playMode) {
      case 0: return Icons.looks_one_rounded;
      case 1: return Icons.playlist_play_rounded;
      case 2: return Icons.repeat_one_rounded;
      default: return Icons.repeat_rounded;
    }
  }

  void _playNextAya() {
    if (_playingAyaKey == null) return;
    final parts = _playingAyaKey!.split('-');
    final suraNo = int.parse(parts[0]);
    final ayaNo = int.parse(parts[1]);
    
    final suraAyat = _groupedBySura[suraNo];
    if (suraAyat != null && ayaNo < suraAyat.length) {
      _playAya(suraNo, ayaNo + 1);
    } else if (suraNo < 114) {
      _playAya(suraNo + 1, 1);
    } else {
      _stopAudio();
    }
  }

  void _playPreviousAya() {
    if (_playingAyaKey == null) return;
    final parts = _playingAyaKey!.split('-');
    final suraNo = int.parse(parts[0]);
    final ayaNo = int.parse(parts[1]);
    
    if (ayaNo > 1) {
      _playAya(suraNo, ayaNo - 1);
    } else if (suraNo > 1) {
      final prevSuraAyat = _groupedBySura[suraNo - 1];
      if (prevSuraAyat != null) {
        _playAya(suraNo - 1, prevSuraAyat.length);
      }
    }
  }

  Future<void> _saveLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastSuraNo', _currentSuraNo);
    await prefs.setInt('lastAyaNo', _currentAyaNo);
  }
  
  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    int lastSuraNo = prefs.getInt('lastSuraNo') ?? 1;
    int lastAyaNo = prefs.getInt('lastAyaNo') ?? 1;
    
    if (lastSuraNo > 1 || lastAyaNo > 1) {
      // تأخير قليل للتأكد من تحميل القائمة
      Future.delayed(Duration(milliseconds: 500), () {
        _scrollToSura(lastSuraNo, ayaNo: lastAyaNo);
      });
    }
  }

  double _getPinchDistance() {
    if (_activePointers.length < 2) return 0;
    final points = _activePointers.values.toList();
    return (points[0] - points[1]).distance;
  }

  void _onPositionChanged() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      // الحصول على العنصر الأكثر ظهوراً
      var visiblePositions = positions.where((p) => p.itemLeadingEdge < 0.5).toList();
      if (visiblePositions.isEmpty) visiblePositions = positions.toList();
      
      int topIndex = visiblePositions.map((p) => p.index).reduce((a, b) => a < b ? a : b);
      
      if (topIndex >= 0 && topIndex < _items.length) {
        QuranItem item = _items[topIndex];
        
        bool needsUpdate = false;
        int newSuraNo = item.suraNo;
        int newAyaNo = item.ayaNo ?? 1;
        int newTotalAyat = item.totalAyatInSura;
        String newSuraName = item.suraName;
        
        if (_currentSuraNo != newSuraNo) {
          needsUpdate = true;
        }
        if (item.type == ItemType.aya && _currentAyaNo != newAyaNo) {
          needsUpdate = true;
        }
        
        if (needsUpdate) {
          setState(() {
            _currentSuraNo = newSuraNo;
            _currentSura = newSuraName;
            _currentAyaNo = item.type == ItemType.aya ? newAyaNo : 1;
            _totalAyatInCurrentSura = newTotalAyat;
          });
          // حفظ مكان التوقف تلقائياً
          _saveLastPosition();
        }
      }
    }
  }

  Future<void> _loadJsonData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/smart.json');
      List<dynamic> jsonList = json.decode(jsonString);

      // تجميع حسب السورة
      Map<int, List<Map<String, dynamic>>> groupedBySura = {};
      for (var item in jsonList) {
        int suraNo = item['sura_no'] ?? 0;
        if (!groupedBySura.containsKey(suraNo)) {
          groupedBySura[suraNo] = [];
        }
        groupedBySura[suraNo]?.add(Map<String, dynamic>.from(item));
      }

      List<int> suraNumbers = groupedBySura.keys.toList()..sort();
      
      // بناء قائمة العناصر
      List<QuranItem> items = [];
      Map<String, int> ayaToIndex = {};
      Map<int, int> suraHeaderIndex = {};
      
      for (int suraNo in suraNumbers) {
        List<Map<String, dynamic>> ayat = groupedBySura[suraNo] ?? [];
        if (ayat.isEmpty) continue;
        
        String suraName = ayat.first['sura_name_ar'] ?? '';
        int totalAyat = ayat.length;
        
        // حفظ index عنوان السورة
        suraHeaderIndex[suraNo] = items.length;
        
        // إضافة عنوان السورة
        items.add(QuranItem(
          type: ItemType.suraHeader,
          suraNo: suraNo,
          suraName: suraName,
          totalAyatInSura: totalAyat,
        ));
        
        // إضافة البسملة (ما عدا الفاتحة والتوبة)
        if (suraNo != 1 && suraNo != 9) {
          items.add(QuranItem(
            type: ItemType.basmala,
            suraNo: suraNo,
            suraName: suraName,
            totalAyatInSura: totalAyat,
          ));
        }
        
        // إضافة الآيات
        for (var aya in ayat) {
          int ayaNo = aya['aya_no'] ?? 0;
          String ayaText = aya['aya_text_emlaey'] ?? '';
          
          // تخطي البسملة كآية
          if (ayaNo == 1 && suraNo != 1 && ayaText == 'بسم الله الرحمن الرحيم') {
            continue;
          }
          
          bool isSajda = _sajdaPositions[suraNo]?.contains(ayaNo) ?? false;
          
          // حفظ index الآية
          ayaToIndex['$suraNo-$ayaNo'] = items.length;
          
          items.add(QuranItem(
            type: ItemType.aya,
            suraNo: suraNo,
            suraName: suraName,
            ayaNo: ayaNo,
            ayaText: ayaText,
            isSajda: isSajda,
            totalAyatInSura: totalAyat,
          ));
        }
      }

      setState(() {
        _items = items;
        _groupedBySura = groupedBySura;
        _ayaToIndex = ayaToIndex;
        _suraHeaderIndex = suraHeaderIndex;
        _currentSura = groupedBySura[1]?.first['sura_name_ar'] ?? "";
        _currentSuraNo = 1;
        _currentAyaNo = 1;
        _totalAyatInCurrentSura = groupedBySura[1]?.length ?? 1;
        _isLoading = false;
      });
      
      // استعادة آخر موقع
      _loadLastPosition();
    } catch (e) {
      print('خطأ في تحميل البيانات: $e');
      setState(() => _isLoading = false);
    }
  }

  // التنقل للسورة أو للآية
  void _scrollToSura(int suraNo, {int? ayaNo}) {
    if (_autoScrollEnabled) _stopAutoScroll();
    
    int? index;
    
    if (ayaNo != null && ayaNo > 1) {
      // الانتقال للآية المحددة
      index = _ayaToIndex['$suraNo-$ayaNo'];
    }
    
    // إذا لم نجد الآية، ننتقل لبداية السورة
    index ??= _suraHeaderIndex[suraNo];
    
    if (index != null && _itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      
      setState(() {
        _currentSuraNo = suraNo;
        _currentSura = _groupedBySura[suraNo]?.first['sura_name_ar'] ?? "";
        _totalAyatInCurrentSura = _groupedBySura[suraNo]?.length ?? 1;
        _currentAyaNo = ayaNo ?? 1;
      });
    }
  }

  // فتح نافذة الانتقال السريع للآية
  void _showGoToAyaDialog() {
    TextEditingController ayaController = TextEditingController();
    int maxAya = _totalAyatInCurrentSura;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_tr('goToAya'), style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_tr('sura')} $_currentSura',
              style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '${_tr('ayaCount')}: ${_toArabicNumber(maxAya)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: ayaController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              autofocus: true,
              decoration: InputDecoration(
                hintText: _tr('enterAyaNumber'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _accentColor, width: 2),
                ),
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildQuickAyaButton(1, ayaController),
                if (maxAya > 10) _buildQuickAyaButton(10, ayaController),
                if (maxAya > 50) _buildQuickAyaButton(50, ayaController),
                if (maxAya > 100) _buildQuickAyaButton(100, ayaController),
                if (maxAya > 200) _buildQuickAyaButton(200, ayaController),
                _buildQuickAyaButton(maxAya, ayaController),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_tr('cancel'), style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              int? ayaNo = int.tryParse(ayaController.text);
              if (ayaNo != null && ayaNo >= 1 && ayaNo <= maxAya) {
                Navigator.pop(context);
                _scrollToSura(_currentSuraNo, ayaNo: ayaNo);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_tr('invalidAyaNumber')} (١ - ${_toArabicNumber(maxAya)})'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_tr('go'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAyaButton(int aya, TextEditingController controller) {
    return InkWell(
      onTap: () => controller.text = aya.toString(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _toArabicNumber(aya),
          style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
  
  // البحث في القرآن
  void _showSearchDialog() {
    TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void performSearch(String query) {
            if (query.trim().length < 2) {
              setDialogState(() => searchResults = []);
              return;
            }
            
            List<Map<String, dynamic>> results = [];
            for (var item in _items) {
              if (item.type == ItemType.aya && item.ayaText != null) {
                if (item.ayaText!.contains(query.trim())) {
                  results.add({
                    'suraNo': item.suraNo,
                    'suraName': item.suraName,
                    'ayaNo': item.ayaNo,
                    'ayaText': item.ayaText,
                  });
                  if (results.length >= 50) break; // حد أقصى 50 نتيجة
                }
              }
            }
            setDialogState(() => searchResults = results);
          }
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _tr('searchQuran'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _accentColor),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    textDirection: TextDirection.rtl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: _tr('searchHint'),
                      hintTextDirection: TextDirection.rtl,
                      prefixIcon: Icon(Icons.search, color: _accentColor),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                searchController.clear();
                                setDialogState(() => searchResults = []);
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _accentColor, width: 2),
                      ),
                    ),
                    onChanged: performSearch,
                  ),
                  SizedBox(height: 8),
                  Text(
                    searchResults.isEmpty 
                        ? _tr('enterSearchWord')
                        : '${_tr('resultsCount')}: ${_toArabicNumber(searchResults.length)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search, size: 64, color: Colors.grey[300]),
                                SizedBox(height: 8),
                                Text(_tr('resultsWillAppear'), style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              var result = searchResults[index];
                              String preview = result['ayaText'];
                              if (preview.length > 80) {
                                preview = '${preview.substring(0, 80)}...';
                              }
                              
                              return Card(
                                margin: EdgeInsets.symmetric(vertical: 4),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                    _scrollToSura(result['suraNo'], ayaNo: result['ayaNo']);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${_tr('aya')} ${_toArabicNumber(result['ayaNo'])}',
                                              style: TextStyle(
                                                color: _accentColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              result['suraName'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          preview,
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 14, height: 1.5),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_tr('close'), style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ========== نظام القراءة التلقائية (تدريجي سلس) ==========
  
  void _startAutoScroll() {
    if (_autoScrollEnabled) return;
    setState(() => _autoScrollEnabled = true);
    _setWakeLock(true);
    _continueAutoScroll();
  }
  
  void _continueAutoScroll() async {
    if (!_autoScrollEnabled) return;
    
    // إذا كان المستخدم يلمس الشاشة، انتظر قليلاً ثم حاول مرة أخرى
    if (_userIsTouching) {
      await Future.delayed(Duration(milliseconds: 100));
      if (_autoScrollEnabled && mounted) {
        _continueAutoScroll();
      }
      return;
    }
    
    double scrollAmount = 50;
    double pixelsPerSecond = _autoScrollSpeed * 30;
    int durationMs = (scrollAmount / pixelsPerSecond * 1000).round();
    if (durationMs < 50) durationMs = 50;
    
    try {
      await _scrollOffsetController.animateScroll(
        offset: scrollAmount,
        duration: Duration(milliseconds: durationMs),
        curve: Curves.linear,
      );
      
      if (_autoScrollEnabled && mounted) {
        _continueAutoScroll();
      }
    } catch (e) {
      // تجاهل الخطأ والمتابعة
      if (_autoScrollEnabled && mounted) {
        await Future.delayed(Duration(milliseconds: 100));
        _continueAutoScroll();
      }
    }
  }
  
  void _stopAutoScroll() {
    setState(() => _autoScrollEnabled = false);
    _setWakeLock(false);
  }
  
  void _toggleAutoScroll() {
    if (_autoScrollEnabled) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }
  
  void _updateAutoScrollSpeed(double newSpeed) {
    setState(() => _autoScrollSpeed = newSpeed);
    _saveSettings();
  }

  // ========== مؤشر القراءة والخيارات ==========

  void _onAyaTap(QuranItem item) {
    final key = '${item.suraNo}-${item.ayaNo}';
    setState(() {
      _selectedAyaKey = (_selectedAyaKey == key) ? null : key;
    });
  }

  Color _getBookmarkColor(String key) {
    final idx = _bookmarks[key] ?? 0;
    return _bookmarkColors[idx % _bookmarkColors.length];
  }

  int _nextBookmarkColorIndex() {
    final usedIndices = _bookmarks.values.toSet();
    for (int i = 0; i < _bookmarkColors.length; i++) {
      if (!usedIndices.contains(i)) return i;
    }
    return _bookmarks.length % _bookmarkColors.length;
  }

  void _onAyaLongPress(QuranItem item) {
    final key = '${item.suraNo}-${item.ayaNo}';
    final isBookmarked = _bookmarks.containsKey(key);
    _showAyaOptionsSheet(item, key, isBookmarked);
  }

  void _showAyaOptionsSheet(QuranItem item, String key, bool isBookmarked) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '${_tr('sura')} ${item.suraName} - ${_tr('aya')} ${_toArabicNumber(item.ayaNo!)}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _accentColor),
                ),
                SizedBox(height: 8),
                Divider(),
                ListTile(
                  leading: Icon(Icons.play_circle_fill_rounded, color: Colors.green[600]),
                  title: Text(_tr('playFromHere'), textDirection: TextDirection.rtl),
                  subtitle: Text(
                    HomePage.availableReciters.firstWhere((r) => r['id'] == _selectedReciter, orElse: () => {'name': ''})['name'] ?? '',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textDirection: TextDirection.rtl,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _playAya(item.suraNo, item.ayaNo!);
                  },
                ),
                if (_appLanguage != 'ar') ...[
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.translate_rounded,
                        color: _translationAyaKey == key ? Colors.blue : _accentColor),
                    title: Text(_tr('translation'), textDirection: TextDirection.rtl),
                    subtitle: Text(
                      _tr(_appLanguage == 'en' ? 'english' : _appLanguage == 'tr' ? 'turkish' : 'albanian'),
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                      textDirection: TextDirection.rtl,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _translationAyaKey = (_translationAyaKey == key) ? null : key;
                      });
                      if (_translationData.isEmpty) {
                        _loadTranslation(_appLanguage);
                      }
                    },
                  ),
                ],
                Divider(),
                ListTile(
                  leading: Icon(Icons.copy_rounded, color: _accentColor),
                  title: Text(_tr('copyAya'), textDirection: TextDirection.rtl),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: '${item.ayaText} ﴿${_toArabicNumber(item.ayaNo!)}﴾ - ${_tr('sura')} ${item.suraName}'));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_tr('ayaCopied'), textAlign: TextAlign.center),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? _getBookmarkColor(key) : _accentColor,
                  ),
                  title: Text(
                    isBookmarked ? _tr('removeBookmark') : _tr('addBookmark'),
                    textDirection: TextDirection.rtl,
                  ),
                  onTap: () {
                    setState(() {
                      if (isBookmarked) {
                        _bookmarks.remove(key);
                      } else {
                        _bookmarks[key] = _nextBookmarkColorIndex();
                      }
                    });
                    _saveSettings();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBookmarked ? _tr('bookmarkRemoved') : _tr('bookmarkAdded'),
                          textAlign: TextAlign.center,
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.search_rounded, color: _accentColor),
                  title: Text(_tr('searchTafseer'), textDirection: TextDirection.rtl),
                  onTap: () async {
                    Navigator.pop(context);
                    String query;
                    switch (_appLanguage) {
                      case 'en':
                        query = 'Quran tafsir surah ${item.suraNo} ayah ${item.ayaNo} english';
                        break;
                      case 'tr':
                        query = 'Kuran tefsir sure ${item.suraNo} ayet ${item.ayaNo} türkçe';
                        break;
                      case 'sq':
                        query = 'Kurani tefsir surja ${item.suraNo} ajeti ${item.ayaNo} shqip';
                        break;
                      default:
                        query = 'تفسير سورة ${item.suraName} آية ${item.ayaNo}';
                    }
                    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint('خطأ في فتح المتصفح: $e');
                    }
                  },
                ),
                if (_bookmarks.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.bookmarks_rounded, color: _accentColor),
                    title: Text(_tr('showBookmarks'), textDirection: TextDirection.rtl),
                    onTap: () {
                      Navigator.pop(context);
                      _showBookmarks();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scrollToBookmark(int suraNo, int ayaNo) {
    if (_autoScrollEnabled) _stopAutoScroll();
    
    final key = '$suraNo-$ayaNo';
    int? index = _ayaToIndex[key];
    index ??= _suraHeaderIndex[suraNo];
    
    if (index != null) {
      final targetIndex = (index - 1).clamp(0, _items.length - 1);
      
      if (_itemScrollController.isAttached) {
        _itemScrollController.scrollTo(
          index: targetIndex,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.0,
        );
        
        setState(() {
          _currentSuraNo = suraNo;
          _currentSura = _groupedBySura[suraNo]?.first['sura_name_ar'] ?? "";
          _totalAyatInCurrentSura = _groupedBySura[suraNo]?.length ?? 1;
          _currentAyaNo = ayaNo;
          _selectedAyaKey = '$suraNo-$ayaNo';
        });
      }
    }
  }

  void _showBookmarks() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final sortedKeys = _bookmarks.keys.toList()..sort((a, b) {
          final aParts = a.split('-').map(int.parse).toList();
          final bParts = b.split('-').map(int.parse).toList();
          if (aParts[0] != bParts[0]) return aParts[0].compareTo(bParts[0]);
          return aParts[1].compareTo(bParts[1]);
        });
        
        return SafeArea(
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _tr('bookmarks'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _accentColor),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: sortedKeys.isEmpty
                      ? Center(child: Text(_tr('noBookmarks'), style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: sortedKeys.length,
                          itemBuilder: (context, index) {
                            final key = sortedKeys[index];
                            final parts = key.split('-');
                            final suraNo = int.parse(parts[0]);
                            final ayaNo = int.parse(parts[1]);
                            final suraName = _groupedBySura[suraNo]?.first['sura_name_ar'] ?? '';
                            final color = _getBookmarkColor(key);
                            
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: Icon(Icons.bookmark, color: color),
                                title: Text(
                                  '${_tr('sura')} $suraName - ${_tr('aya')} ${_toArabicNumber(ayaNo)}',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 20),
                                  onPressed: () {
                                    setState(() => _bookmarks.remove(key));
                                    _saveSettings();
                                    Navigator.pop(context);
                                    _showBookmarks();
                                  },
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _scrollToBookmark(suraNo, ayaNo);
                                },
                              ),
                            );
                          },
                        ),
                ),
                SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_tr('close'), style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _toArabicNumber(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) {
      return arabicNumbers[int.parse(digit)];
    }).join();
  }

  TextStyle _getTextStyle({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? height,
    bool applyScale = true,
  }) {
    double size = applyScale
        ? (fontSize ?? _fontSize) * _currentScale
        : (fontSize ?? _fontSize);
    Color textColor = color ?? _textColor;
    // ارتفاع سطر افتراضي أعلى للحركات العربية
    double lineHeight = height ?? 1.8;
    
    try {
      switch (_selectedFont) {
        case 'Amiri Quran':
          return GoogleFonts.amiriQuran(fontSize: size, color: textColor, fontWeight: fontWeight, height: lineHeight);
        case 'Amiri':
          return GoogleFonts.amiri(fontSize: size, color: textColor, fontWeight: fontWeight, height: lineHeight);
        case 'Noto Naskh Arabic':
          return GoogleFonts.notoNaskhArabic(fontSize: size, color: textColor, fontWeight: fontWeight, height: lineHeight);
        case 'Scheherazade New':
          return GoogleFonts.scheherazadeNew(fontSize: size, color: textColor, fontWeight: fontWeight, height: lineHeight);
        default:
          return GoogleFonts.amiriQuran(fontSize: size, color: textColor, fontWeight: fontWeight, height: lineHeight);
      }
    } catch (e) {
      return TextStyle(fontSize: size, color: textColor, fontWeight: fontWeight, height: lineHeight);
    }
  }

  void _openIndexPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IndexPage(
          groupedBySura: _groupedBySura,
          onSuraSelected: (suraNo) => _scrollToSura(suraNo),
          appLanguage: _appLanguage,
        ),
      ),
    );
  }

  void _openSettingsPage() async {
    final settings = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          backgroundColor: _backgroundColor,
          textColor: _textColor,
          fontSize: _fontSize,
          selectedFont: _selectedFont,
          showAyaNumbers: _showAyaNumbers,
          separateAyat: _separateAyat,
          showDividers: _showDividers,
          availableFonts: _availableFonts,
          selectedReciter: _selectedReciter,
          appLanguage: _appLanguage,
        ),
      ),
    );
    if (settings != null) {
      final oldLanguage = _appLanguage;

      setState(() {
        _backgroundColor = settings['backgroundColor'];
        _textColor = settings['textColor'];
        _fontSize = settings['fontSize'];
        _selectedFont = settings['selectedFont'] ?? 'Amiri Quran';
        _showAyaNumbers = settings['showAyaNumbers'] ?? true;
        _separateAyat = settings['separateAyat'] ?? false;
        _showDividers = settings['showDividers'] ?? true;
        _selectedReciter = settings['selectedReciter'] ?? 'Alafasy_128kbps';
        _appLanguage = settings['appLanguage'] ?? 'ar';
      });
      _saveSettings();

      if (_appLanguage != 'ar' && (_appLanguage != oldLanguage || _translationData.isEmpty)) {
        _loadTranslation(_appLanguage);
      } else if (_appLanguage == 'ar') {
        setState(() => _translationData = {});
      }
    }
  }

  void _openReminderPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReminderPage(appLanguage: _appLanguage)),
    );
  }

  // بناء عنصر واحد
  Widget _buildItem(QuranItem item, int index) {
    switch (item.type) {
      case ItemType.suraHeader:
        return _buildSuraHeader(item);
      case ItemType.basmala:
        return _buildBasmala(item);
      case ItemType.aya:
        return _buildAya(item);
    }
  }

  Widget _buildSuraHeader(QuranItem item) {
    return Container(
      color: _backgroundColor,
      child: Column(
        children: [
          // الفاصل بين السور
          if (_showDividers && item.suraNo != 1)
            Container(
              height: 30,
              color: _accentColor.withOpacity(0.05),
            ),
          Container(
            margin: EdgeInsets.only(
              top: item.suraNo == 1 ? 0 : 16,
              bottom: 16,
              left: 16,
              right: 16,
            ),
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentColor.withOpacity(0.08),
                  _accentColor.withOpacity(0.15),
                  _accentColor.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _accentColor.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _toArabicNumber(item.suraNo),
                    style: _getTextStyle(fontSize: 12, color: _accentColor, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '${_tr('sura')} ${item.suraName}',
                  style: _getTextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasmala(QuranItem item) {
    return Container(
      color: _backgroundColor,
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '﷽',
        style: _getTextStyle(fontSize: 28, applyScale: false),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAya(QuranItem item) {
    if (_separateAyat) {
      return _buildSeparatedAyaContent(item);
    } else {
      return _buildContinuousAyaContent(item);
    }
  }

  Widget _buildTranslationWidget(String key, QuranItem item) {
    if (_translationAyaKey != key || !_hasTranslation) return SizedBox.shrink();
    final text = _translationData[key];
    if (text == null || text.isEmpty) return SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 4, bottom: 6, left: 16, right: 16),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.translate_rounded, size: 14, color: _accentColor.withOpacity(0.6)),
              SizedBox(width: 6),
              Text(
                _tr(_appLanguage == 'en' ? 'english' : _appLanguage == 'tr' ? 'turkish' : 'albanian'),
                style: TextStyle(fontSize: 11, color: _accentColor.withOpacity(0.7), fontWeight: FontWeight.w600),
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  final isBookmarked = _bookmarks.containsKey(key);
                  _showAyaOptionsSheet(item, key, isBookmarked);
                },
                child: Icon(Icons.more_horiz_rounded, size: 20, color: _accentColor.withOpacity(0.5)),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _translationAyaKey = null),
                child: Icon(Icons.close_rounded, size: 18, color: Colors.red.withOpacity(0.5)),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            text,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 14,
              color: _textColor.withOpacity(0.75),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // الآيات المتصلة بصرياً (الوضع الافتراضي)
  Widget _buildContinuousAyaContent(QuranItem item) {
    final key = '${item.suraNo}-${item.ayaNo}';
    final isSelected = _selectedAyaKey == key;
    final isPlaying = _playingAyaKey == key;
    final isBookmarked = _bookmarks.containsKey(key);
    final bmColor = isBookmarked ? _getBookmarkColor(key) : null;
    
    return GestureDetector(
      onTap: () => _onAyaTap(item),
      onLongPress: () => _onAyaLongPress(item),
      child: Container(
        color: isPlaying
            ? Colors.green.withOpacity(0.08)
            : (isSelected ? _accentColor.withOpacity(0.08) : _backgroundColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(right: 16, left: 16),
              child: Stack(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: item.ayaText,
                          style: _getTextStyle(height: 2.4).copyWith(
                            backgroundColor: item.isSajda ? Colors.red.withOpacity(0.1) : null,
                          ),
                        ),
                        if (_showAyaNumbers)
                          TextSpan(
                            text: ' ﴿${_toArabicNumber(item.ayaNo!)}﴾',
                            style: _getTextStyle(
                              fontSize: _fontSize * 0.7,
                              color: _accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (item.isSajda)
                          TextSpan(
                            text: ' ۩',
                            style: TextStyle(fontSize: 16, color: Colors.red[700]),
                          ),
                        TextSpan(text: ' '),
                      ],
                    ),
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    strutStyle: StrutStyle(
                      fontSize: _fontSize * _currentScale,
                      height: 2.4,
                      forceStrutHeight: true,
                    ),
                  ),
                  if (isBookmarked)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Icon(Icons.bookmark, color: bmColor, size: 18),
                    ),
                ],
              ),
            ),
            _buildTranslationWidget(key, item),
          ],
        ),
      ),
    );
  }

  // الآيات المنفصلة
  Widget _buildSeparatedAyaContent(QuranItem item) {
    final key = '${item.suraNo}-${item.ayaNo}';
    final isSelected = _selectedAyaKey == key;
    final isPlaying = _playingAyaKey == key;
    final isBookmarked = _bookmarks.containsKey(key);
    final bmColor = isBookmarked ? _getBookmarkColor(key) : null;
    
    return GestureDetector(
      onTap: () => _onAyaTap(item),
      onLongPress: () => _onAyaLongPress(item),
      child: Container(
        color: _backgroundColor,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isPlaying
              ? Colors.green.withOpacity(0.1)
              : (isSelected
                  ? _accentColor.withOpacity(0.1)
                  : (item.isSajda
                      ? Colors.red.withOpacity(0.05)
                      : (item.ayaNo! % 2 == 0 ? _accentColor.withOpacity(0.02) : Colors.transparent))),
          borderRadius: BorderRadius.circular(8),
          border: isPlaying
              ? Border.all(color: Colors.green.withOpacity(0.4))
              : (isSelected
                  ? Border.all(color: _accentColor.withOpacity(0.4))
                  : (item.isSajda ? Border.all(color: Colors.red.withOpacity(0.2)) : null)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    item.ayaText ?? '',
                    style: _getTextStyle(height: 2.2),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    strutStyle: StrutStyle(
                      fontSize: _fontSize * _currentScale,
                      height: 2.2,
                      forceStrutHeight: true,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  children: [
                    if (isBookmarked)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(Icons.bookmark, color: bmColor, size: 16),
                      ),
                    if (_showAyaNumbers)
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _toArabicNumber(item.ayaNo!),
                          style: _getTextStyle(fontSize: 11, color: _accentColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (item.isSajda) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('۩', style: TextStyle(fontSize: 12, color: Colors.red[700])),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            _buildTranslationWidget(key, item),
          ],
        ),
      ),
    );
  }

  // شريط معلومات الآية تحت AppBar
  Widget _buildAudioInfoBar() {
    if (_playingAyaKey == null) return SizedBox.shrink();
    
    String currentAyaInfo = '';
    String reciterName = '';
    if (_playingAyaKey != null) {
      final parts = _playingAyaKey!.split('-');
      final suraNo = int.parse(parts[0]);
      final ayaNo = int.parse(parts[1]);
      final suraName = _groupedBySura[suraNo]?.first['sura_name_ar'] ?? '';
      currentAyaInfo = '$suraName - ${_tr('aya')} ${_toArabicNumber(ayaNo)}';
      reciterName = HomePage.availableReciters
          .firstWhere((r) => r['id'] == _selectedReciter, orElse: () => {'name': ''})['name'] ?? '';
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.green.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isPlayingAudio ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.green, size: 16),
          SizedBox(width: 8),
          Text(
            '$currentAyaInfo  •  $reciterName',
            style: TextStyle(fontSize: 12, color: Colors.green[800], fontWeight: FontWeight.w500),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(width: 8),
          GestureDetector(
            onTap: _stopAudio,
            child: Icon(Icons.close_rounded, color: Colors.red[400], size: 18),
          ),
        ],
      ),
    );
  }

  void _startAudioFromCurrentPosition() {
    if (_autoScrollEnabled) _stopAutoScroll();
    _playAya(_currentSuraNo, _currentAyaNo);
  }

  // لوحة التحكم السفلية
  Widget _buildBottomControlPanel() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: (_showAutoScrollPanel ? 120.0 : 65) + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showAutoScrollPanel = !_showAutoScrollPanel),
            child: Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // الصف الرئيسي: سرعة التمرير + تشغيل/إيقاف تمرير
          Container(
            height: 52,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showAutoScrollPanel ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: _accentColor,
                  ),
                  onPressed: () => setState(() => _showAutoScrollPanel = !_showAutoScrollPanel),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_autoScrollSpeed > 0.5) _updateAutoScrollSpeed(_autoScrollSpeed - 0.5);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.remove, color: _accentColor, size: 20),
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _autoScrollEnabled
                              ? Colors.green.withOpacity(0.15)
                              : _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_autoScrollSpeed.toStringAsFixed(1)}x',
                          style: TextStyle(
                            color: _autoScrollEnabled ? Colors.green[700] : _accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          if (_autoScrollSpeed < 5) _updateAutoScrollSpeed(_autoScrollSpeed + 0.5);
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.add, color: _accentColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _toggleAutoScroll,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _autoScrollEnabled
                            ? [Colors.red[400]!, Colors.red[600]!]
                            : [Colors.green[400]!, Colors.green[600]!],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_autoScrollEnabled ? Colors.red : Colors.green).withOpacity(0.4),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _autoScrollEnabled ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // اللوحة المنسدلة: أدوات القارئ الصوتي
          if (_showAutoScrollPanel)
            Expanded(child: _buildAudioControls()),
        ],
      ),
    );
  }

  Widget _buildAudioControls() {
    final hasAudio = _playingAyaKey != null;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ctrlBtn(Icons.stop_rounded,
              hasAudio ? Colors.red[400]! : Colors.grey[400]!,
              hasAudio ? _stopAudio : () {}),
          _ctrlBtn(Icons.skip_previous_rounded,
              hasAudio ? _accentColor : Colors.grey[400]!,
              hasAudio ? _playPreviousAya : () {}),
          // تشغيل / إيقاف مؤقت (يبدأ القراءة من الآية الحالية إذا لم يكن هناك صوت)
          GestureDetector(
            onTap: hasAudio ? _pauseResumeAudio : _startAudioFromCurrentPosition,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: Icon(
                hasAudio && _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white, size: 24,
              ),
            ),
          ),
          _ctrlBtn(Icons.skip_next_rounded,
              hasAudio ? _accentColor : Colors.grey[400]!,
              hasAudio ? _playNextAya : () {}),
          // وضع التشغيل
          GestureDetector(
            onTap: _cyclePlayMode,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _playMode == 2
                    ? Colors.orange.withOpacity(0.15)
                    : (_playMode == 1 ? Colors.green.withOpacity(0.1) : _accentColor.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getPlayModeIcon(), size: 18,
                    color: _playMode == 2 ? Colors.orange : (_playMode == 1 ? Colors.green : _accentColor)),
                  SizedBox(width: 4),
                  Text(_getPlayModeLabel(),
                    style: TextStyle(fontSize: 10,
                      color: _playMode == 2 ? Colors.orange : (_playMode == 1 ? Colors.green : _accentColor))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: color, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              _currentSura,
              style: _getTextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: _showGoToAyaDialog,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_toArabicNumber(_currentAyaNo)} / ${_toArabicNumber(_totalAyatInCurrentSura)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: _accentColor),
          onPressed: _openIndexPage,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: _accentColor),
            onPressed: _showSearchDialog,
          ),
          if (_bookmarks.isNotEmpty)
            IconButton(
              icon: Icon(Icons.bookmarks_outlined, color: Colors.orange),
              onPressed: _showBookmarks,
            ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: _accentColor),
            onPressed: _openReminderPage,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: _accentColor),
            onPressed: _openSettingsPage,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _accentColor),
                  SizedBox(height: 16),
                  Text(_tr('loading'), style: _getTextStyle(fontSize: 16)),
                ],
              ),
            )
          : Column(
              children: [
                _buildAudioInfoBar(),
                Expanded(
                  child: Listener(
                    onPointerDown: (event) {
                      _activePointers[event.pointer] = event.position;
                      setState(() => _userIsTouching = true);
                      if (_activePointers.length == 2) {
                        _baseScale = _currentScale;
                        _initialPinchDistance = _getPinchDistance();
                      }
                    },
                    onPointerMove: (event) {
                      _activePointers[event.pointer] = event.position;
                      if (_activePointers.length >= 2 && _initialPinchDistance > 0) {
                        final currentDistance = _getPinchDistance();
                        final scale = currentDistance / _initialPinchDistance;
                        setState(() {
                          _currentScale = (_baseScale * scale).clamp(0.7, 2.0);
                        });
                      }
                    },
                    onPointerUp: (event) {
                      _activePointers.remove(event.pointer);
                      _initialPinchDistance = 0;
                      if (_activePointers.isEmpty) {
                        setState(() => _userIsTouching = false);
                      }
                    },
                    onPointerCancel: (event) {
                      _activePointers.remove(event.pointer);
                      _initialPinchDistance = 0;
                      if (_activePointers.isEmpty) {
                        setState(() => _userIsTouching = false);
                      }
                    },
                    child: ScrollablePositionedList.builder(
                      itemCount: _items.length,
                      itemScrollController: _itemScrollController,
                      scrollOffsetController: _scrollOffsetController,
                      itemPositionsListener: _itemPositionsListener,
                      scrollOffsetListener: _scrollOffsetListener,
                      itemBuilder: (context, index) => _buildItem(_items[index], index),
                    ),
                  ),
                ),
                _buildBottomControlPanel(),
              ],
            ),
    );
  }
}
