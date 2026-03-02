import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'home.dart';

// الإشعارات العامة
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة المناطق الزمنية
  tz.initializeTimeZones();
  try {
    // محاولة استخدام المنطقة الزمنية المحلية
    final String timeZoneName = DateTime.now().timeZoneName;
    if (timeZoneName == 'AST' || timeZoneName == '+03') {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    } else {
      tz.setLocalLocation(tz.local);
    }
  } catch (e) {
    // استخدام UTC كاحتياطي
    tz.setLocalLocation(tz.UTC);
  }
  
  // تهيئة الإشعارات
  await _initNotifications();
  
  // تهيئة SharedPreferences
  await SharedPreferences.getInstance();
  
  // إخفاء أزرار النظام وشريط الحالة بالكامل (وضع غامر)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const MyApp());
}

Future<void> _initNotifications() async {
  // إعدادات Android
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  // إعدادات iOS
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // معالجة النقر على الإشعار
    },
  );
  
  // إنشاء قناة الإشعارات على Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'quran_reminder_channel',
    'تذكير القرآن',
    description: 'تذكير بقراءة القرآن الكريم',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );
  
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'فرقان',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        fontFamily: 'Amiri',
        // جعل AppBar شفاف
        appBarTheme: const AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: HomePage(),
    );
  }
}
