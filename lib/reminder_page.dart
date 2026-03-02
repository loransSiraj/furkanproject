import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_localizations.dart';
import 'main.dart' show flutterLocalNotificationsPlugin;

class ReminderPage extends StatefulWidget {
  final String appLanguage;
  ReminderPage({this.appLanguage = 'ar'});
  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  List<ReminderItem> _reminders = [];
  bool _isInitialized = false;
  bool _hasPermission = false;

  String _tr(String key) => AppLocalizations.tr(key, widget.appLanguage);

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    await _requestPermissions();
    setState(() => _isInitialized = true);
    await _loadReminders();
  }

  Future<void> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final bool? granted = await androidPlugin.requestNotificationsPermission();
          if (mounted) setState(() => _hasPermission = granted ?? false);
          await androidPlugin.requestExactAlarmsPermission();
        }
      } else if (Platform.isIOS) {
        final bool? granted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
        if (mounted) setState(() => _hasPermission = granted ?? false);
      }
    } catch (e) {
      debugPrint('خطأ في طلب الأذونات: $e');
    }
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? remindersJson = prefs.getString('reminders');
    
    if (remindersJson != null && remindersJson.isNotEmpty) {
      try {
        final List<dynamic> remindersList = jsonDecode(remindersJson);
        if (mounted) {
          setState(() {
            _reminders = remindersList.map((item) => ReminderItem.fromJson(item)).toList();
          });
        }
        
        for (var reminder in _reminders) {
          if (reminder.isEnabled) {
            await _scheduleNotification(reminder);
          }
        }
      } catch (e) {
        debugPrint('خطأ في تحميل التذكيرات: $e');
        _setDefaultReminders();
        await _saveReminders();
      }
    } else {
      _setDefaultReminders();
      await _saveReminders();
    }
  }

  void _setDefaultReminders() {
    _reminders = [
      ReminderItem(id: 1, title: 'ورد الفجر', time: TimeOfDay(hour: 5, minute: 0), isEnabled: false),
      ReminderItem(id: 2, title: 'ورد الظهر', time: TimeOfDay(hour: 12, minute: 30), isEnabled: false),
      ReminderItem(id: 3, title: 'ورد العصر', time: TimeOfDay(hour: 15, minute: 30), isEnabled: false),
      ReminderItem(id: 4, title: 'ورد المغرب', time: TimeOfDay(hour: 18, minute: 30), isEnabled: false),
      ReminderItem(id: 5, title: 'ورد العشاء', time: TimeOfDay(hour: 20, minute: 0), isEnabled: false),
    ];
  }

  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String remindersJson = jsonEncode(_reminders.map((r) => r.toJson()).toList());
      await prefs.setString('reminders', remindersJson);
      debugPrint('✅ تم حفظ ${_reminders.length} تذكير');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ التذكيرات: $e');
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'ص' : 'م';
    return '$hour:$minute $period';
  }

  Future<void> _scheduleNotification(ReminderItem reminder) async {
    if (!_isInitialized) return;

    const androidDetails = AndroidNotificationDetails(
      'quran_reminder_channel',
      'تذكير القرآن',
      channelDescription: 'تذكير بقراءة القرآن الكريم',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day,
      reminder.time.hour, reminder.time.minute,
    );
    
    if (scheduledDate.isBefore(now) || scheduledDate.isAtSameMomentAs(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    final int notifId = reminder.id % 100000;

    try {
      await flutterLocalNotificationsPlugin.cancel(notifId);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notifId,
        '📖 ${reminder.title}',
        _tr('reminderBody'),
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('✅ تم جدولة: ${reminder.title} في $scheduledDate');
    } catch (e) {
      debugPrint('❌ خطأ في جدولة الإشعار: $e');
    }
  }

  Future<void> _cancelNotification(int id) async {
    try {
      final int notifId = id % 100000;
      await flutterLocalNotificationsPlugin.cancel(notifId);
    } catch (e) {
      debugPrint('خطأ في إلغاء الإشعار: $e');
    }
  }

  Future<void> _toggleReminder(ReminderItem reminder) async {
    setState(() {
      reminder.isEnabled = !reminder.isEnabled;
    });

    if (reminder.isEnabled) {
      await _scheduleNotification(reminder);
      _showSnackBar('تم تفعيل ${reminder.title}');
    } else {
      await _cancelNotification(reminder.id);
      _showSnackBar('تم إلغاء ${reminder.title}');
    }
    
    await _saveReminders();
  }

  Future<void> _editReminderTime(ReminderItem reminder) async {
    final TimeOfDay? newTime = await showTimePicker(
      context: context,
      initialTime: reminder.time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: Color(0xFF8B6914)),
          ),
          child: Directionality(textDirection: TextDirection.rtl, child: child!),
        );
      },
    );

    if (newTime != null) {
      setState(() {
        reminder.time = newTime;
      });
      
      if (reminder.isEnabled) {
        await _cancelNotification(reminder.id);
        await _scheduleNotification(reminder);
        _showSnackBar('تم تحديث وقت ${reminder.title}');
      }
      
      await _saveReminders();
    }
  }

  Future<void> _addNewReminder() async {
    final TextEditingController titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(_tr('addReminder'), textAlign: TextAlign.right),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: _tr('reminderTitle'),
                      hintText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text('الوقت', textAlign: TextAlign.right),
                    trailing: TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setDialogState(() => selectedTime = time);
                        }
                      },
                      child: Text(_formatTime(selectedTime), style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      Navigator.pop(context, {
                        'title': titleController.text,
                        'time': selectedTime,
                      });
                    }
                  },
                  child: Text(_tr('addReminder')),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      // استخدام ID صغير فريد
      final int newId = (_reminders.isEmpty ? 10 : _reminders.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1);
      
      final newReminder = ReminderItem(
        id: newId,
        title: result['title'],
        time: result['time'],
        isEnabled: true,
      );
      
      setState(() {
        _reminders.add(newReminder);
      });
      
      await _scheduleNotification(newReminder);
      await _saveReminders();
      _showSnackBar('تم إضافة التذكير');
    }
  }

  Future<void> _deleteReminder(ReminderItem reminder) async {
    await _cancelNotification(reminder.id);
    setState(() {
      _reminders.remove(reminder);
    });
    await _saveReminders();
    _showSnackBar('تم حذف ${reminder.title}');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.center),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tr('reminders')),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addNewReminder,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF8B6914).withOpacity(0.1),
                    Color(0xFF8B6914).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFF8B6914).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.notifications_active, size: 40, color: Color(0xFF8B6914)),
                  SizedBox(height: 12),
                  Text(
                    _tr('reminderTitle'),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C1810)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _tr('daily'),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _reminders.length,
                itemBuilder: (context, index) {
                  final reminder = _reminders[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: reminder.isEnabled
                            ? Color(0xFF8B6914).withOpacity(0.3)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: reminder.isEnabled
                              ? Color(0xFF8B6914).withOpacity(0.1)
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.alarm,
                          color: reminder.isEnabled ? Color(0xFF8B6914) : Colors.grey[400],
                        ),
                      ),
                      title: Text(
                        reminder.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: reminder.isEnabled ? Color(0xFF2C1810) : Colors.grey[500],
                        ),
                      ),
                      subtitle: GestureDetector(
                        onTap: () => _editReminderTime(reminder),
                        child: Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Text(
                              _formatTime(reminder.time),
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '(${_tr('editTime')})',
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (reminder.id > 5)
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                              onPressed: () => _deleteReminder(reminder),
                            ),
                          Switch(
                            value: reminder.isEnabled,
                            onChanged: (_) => _toggleReminder(reminder),
                            activeColor: Color(0xFF8B6914),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: !_hasPermission ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_hasPermission ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    !_hasPermission ? Icons.warning_amber_rounded : Icons.check_circle,
                    color: !_hasPermission ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      !_hasPermission
                          ? _tr('noPermission')
                          : _tr('enabled'),
                      style: TextStyle(
                        fontSize: 12,
                        color: !_hasPermission ? Colors.orange[700] : Colors.green[700],
                      ),
                    ),
                  ),
                  if (!_hasPermission)
                    TextButton(
                      onPressed: _requestPermissions,
                      child: Text('تفعيل', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class ReminderItem {
  final int id;
  String title;
  TimeOfDay time;
  bool isEnabled;

  ReminderItem({
    required this.id,
    required this.title,
    required this.time,
    this.isEnabled = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'hour': time.hour,
    'minute': time.minute,
    'isEnabled': isEnabled,
  };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
    id: json['id'],
    title: json['title'],
    time: TimeOfDay(hour: json['hour'], minute: json['minute']),
    isEnabled: json['isEnabled'] ?? false,
  );
}
