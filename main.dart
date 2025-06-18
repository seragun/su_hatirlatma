import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
String? selectedProfileId; // Uygulama boyunca kullanılacak profil ID'si


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bildirim yapılandırması
  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Temel Bildirimler',
        channelDescription: 'Su içme hatırlatmaları için',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        playSound: true,
        enableVibration: true,
      )
    ],
    debug: true,
  );

  // Bildirim izni iste
  AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });




  runApp(const WaterReminderApp());
}

class ProfileSelectorPage extends StatefulWidget {
  const ProfileSelectorPage({super.key});

  @override
  State<ProfileSelectorPage> createState() => _ProfileSelectorPageState();
}

class _ProfileSelectorPageState extends State<ProfileSelectorPage> {
  List<String> _profiles = [];
  String? _selectedProfile;

  final TextEditingController _newProfileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profiles = prefs.getStringList('profiles') ?? [];
      _selectedProfile = prefs.getString('selected_profile');
    });
  }

  Future<void> _selectProfile(String profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_profile', profile);
    Navigator.pushReplacementNamed(context, '/home');
  }

  Future<void> _addNewProfile() async {
    final name = _newProfileController.text.trim();
    if (name.isEmpty || _profiles.contains(name)) return;
    final prefs = await SharedPreferences.getInstance();
    _profiles.add(name);
    await prefs.setStringList('profiles', _profiles);
    _newProfileController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Seçimi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Bir profil seçin veya yeni bir profil oluşturun:',
                style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            if (_profiles.isEmpty)
              const Text('Henüz hiç profil oluşturulmadı.'),
            Expanded(
              child: ListView.builder(
                itemCount: _profiles.length,
                itemBuilder: (context, index) {
                  final profile = _profiles[index];
                  return ListTile(
                    title: Text(profile),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        _profiles.remove(profile);
                        await prefs.setStringList('profiles', _profiles);
                        if (_selectedProfile == profile) {
                          await prefs.remove('selected_profile');
                        }
                        setState(() {});
                      },
                    ),
                    onTap: () => _selectProfile(profile),
                  );
                },
              ),
            ),
            TextField(
              controller: _newProfileController,
              decoration: const InputDecoration(labelText: 'Yeni profil adı'),
            ),
            ElevatedButton(
              onPressed: _addNewProfile,
              child: const Text('Profil Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}

class WaterReminderApp extends StatelessWidget {
  const WaterReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Su Hatırlatıcı',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFE0F7FA),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
          prefixIconColor: Colors.blueAccent,
        ),
      ),
        home: const ProfileSelectionPage(),
    );
  }
}

double globalWaterTarget = 2000;

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _waterTargetController = TextEditingController();

  String? _selectedClimate;
  String? _selectedActivity;

  final List<String> _climateOptions = ['Soğuk', 'Ilıman', 'Sıcak'];
  final List<String> _activityOptions = ['Az', 'Orta', 'Yüksek'];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = prefs.getString('selected_profile') ?? '';

    setState(() {
      _nameController.text = prefs.getString('profile_name_$profile') ?? '';
      _ageController.text = prefs.getInt('profile_age_$profile')?.toString() ?? '';
      _weightController.text = prefs.getInt('profile_weight_$profile')?.toString() ?? '';
      _selectedClimate = prefs.getString('profile_climate_$profile')?.trim();
      _selectedActivity = prefs.getString('profile_activity_$profile')?.trim();
      _waterTargetController.text = prefs.getInt('profile_water_target_$profile')?.toString() ?? '';
    });
  }

  Future<void> _saveUserInfoToProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final profile = prefs.getString('selected_profile') ?? '';

    await prefs.setString('profile_name_$profile', _nameController.text);
    await prefs.setInt('profile_age_$profile', int.tryParse(_ageController.text) ?? 0);
    await prefs.setInt('profile_weight_$profile', int.tryParse(_weightController.text) ?? 0);
    await prefs.setString('profile_climate_$profile', _selectedClimate ?? '');
    await prefs.setString('profile_activity_$profile', _selectedActivity ?? '');
    await prefs.setInt('profile_water_target_$profile', int.tryParse(_waterTargetController.text) ?? 0);
  }

  void _calculateWaterTarget() {
    if (_weightController.text.isEmpty || _selectedActivity == null || _selectedClimate == null) return;

    final double weight = double.tryParse(_weightController.text) ?? 0;
    double activityFactor;
    double climateFactor;

    switch (_selectedActivity) {
      case 'Az':
        activityFactor = 30;
        break;
      case 'Orta':
        activityFactor = 35;
        break;
      case 'Yüksek':
        activityFactor = 40;
        break;
      default:
        activityFactor = 35;
    }

    switch (_selectedClimate) {
      case 'Soğuk':
        climateFactor = 1.0;
        break;
      case 'Ilıman':
        climateFactor = 1.1;
        break;
      case 'Sıcak':
        climateFactor = 1.2;
        break;
      default:
        climateFactor = 1.1;
    }

    final double result = weight * activityFactor * climateFactor;
    _waterTargetController.text = result.toStringAsFixed(0);
    globalWaterTarget = result;
  }

  void _goToAlertSettings() async {
    if (_formKey.currentState!.validate()) {
      await _saveUserInfoToProfile();
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AlertSettingsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Bilgileri')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ad', prefixIcon: Icon(Icons.person)),
                  validator: (value) => value!.isEmpty ? 'Ad girin' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Yaş', prefixIcon: Icon(Icons.cake)),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Yaş girin';
                    final n = num.tryParse(value);
                    return (n == null || n <= 0) ? 'Geçerli yaş girin' : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(labelText: 'Kilo (kg)', prefixIcon: Icon(Icons.monitor_weight)),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Kilo girin';
                    final n = num.tryParse(value);
                    return (n == null || n <= 0) ? 'Geçerli kilo girin' : null;
                  },
                  onChanged: (_) => _calculateWaterTarget(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'İklim', prefixIcon: Icon(Icons.thermostat)),
                  value: _climateOptions.contains(_selectedClimate) ? _selectedClimate : null,
                  items: _climateOptions.map((climate) => DropdownMenuItem(value: climate, child: Text(climate))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClimate = value;
                      _calculateWaterTarget();
                    });
                  },
                  validator: (value) => value == null ? 'İklim seçin' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Günlük Aktivite', prefixIcon: Icon(Icons.fitness_center)),
                  value: _activityOptions.contains(_selectedActivity) ? _selectedActivity : null,
                  items: _activityOptions.map((activity) => DropdownMenuItem(value: activity, child: Text(activity))).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivity = value;
                      _calculateWaterTarget();
                    });
                  },
                  validator: (value) => value == null ? 'Aktivite seviyesi seçin' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _waterTargetController,
                  decoration: const InputDecoration(labelText: 'Günlük Su Hedefi (ml)', prefixIcon: Icon(Icons.water_drop)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _goToAlertSettings,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Devam'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




class AlertSettingsPage extends StatefulWidget {
  const AlertSettingsPage({super.key});

  @override
  State<AlertSettingsPage> createState() => _AlertSettingsPageState();
}

class _AlertSettingsPageState extends State<AlertSettingsPage> {
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 23, minute: 0);
  double _intervalMinutes = 120;

  Future<void> _pickTime({required bool isWakeUp}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isWakeUp ? _wakeUpTime : _bedTime,
    );
    if (picked != null) {
      setState(() {
        if (isWakeUp) {
          _wakeUpTime = picked;
        } else {
          _bedTime = picked;
        }
      });
    }
  }

  void _goToManualAlertPage() {
    if (_bedTime.hour < _wakeUpTime.hour ||
        (_bedTime.hour == _wakeUpTime.hour && _bedTime.minute <= _wakeUpTime.minute)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yatış saati kalkış saatinden sonra olmalıdır.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualAlertPage(
          wakeUpTime: _wakeUpTime,
          bedTime: _bedTime,
          intervalMinutes: _intervalMinutes.round(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Uyarı Ayarları')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                title: const Text('Kalkış Saati'),
                subtitle: Text(_wakeUpTime.format(context)),
                trailing: const Icon(Icons.edit),
                onTap: () => _pickTime(isWakeUp: true),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.nightlight_round, color: Colors.indigo),
                title: const Text('Yatış Saati'),
                subtitle: Text(_bedTime.format(context)),
                trailing: const Icon(Icons.edit),
                onTap: () => _pickTime(isWakeUp: false),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Uyarı Sıklığı (dakika):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              value: _intervalMinutes,
              min: 30,
              max: 240,
              divisions: 7,
              label: _intervalMinutes.round().toString(),
              onChanged: (value) {
                setState(() {
                  _intervalMinutes = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _goToManualAlertPage,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Devam'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
              ),
            )
          ],
        ),
      ),
    );
  }
}
class ManualAlertPage extends StatefulWidget {
  final TimeOfDay wakeUpTime;
  final TimeOfDay bedTime;
  final int intervalMinutes;

  const ManualAlertPage({
    super.key,
    required this.wakeUpTime,
    required this.bedTime,
    required this.intervalMinutes,
  });

  @override
  State<ManualAlertPage> createState() => _ManualAlertPageState();
}

class _ManualAlertPageState extends State<ManualAlertPage> {
  final Map<TimeOfDay, bool> _alarmStatus = {};
  List<TimeOfDay> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarmsFromStorage();
    _generateAutomaticAlarms(); // İlk açılışta da çalışsın
  }

  void _generateAutomaticAlarms() {
    final List<TimeOfDay> generated = [];
    DateTime current = DateTime(0, 1, 1, widget.wakeUpTime.hour, widget.wakeUpTime.minute);
    final DateTime end = DateTime(0, 1, 1, widget.bedTime.hour, widget.bedTime.minute);

    while (current.isBefore(end)) {
      final time = TimeOfDay(hour: current.hour, minute: current.minute);
      generated.add(time);
      current = current.add(Duration(minutes: widget.intervalMinutes));
    }

    for (var alarm in generated) {
      if (!_alarms.contains(alarm)) {
        _alarms.add(alarm);
        _alarmStatus[alarm] = true;
        _scheduleSingleAlarm(alarm);
      }
    }

    _saveAlarmsToStorage();
  }

  Future<void> _saveAlarmsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = _alarms.map((t) => json.encode({'hour': t.hour, 'minute': t.minute})).toList();
    await prefs.setStringList('manual_alarms', encoded);
  }

  Future<void> _loadAlarmsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('manual_alarms') ?? [];

    final loaded = stored.map((s) {
      final Map<String, dynamic> map = json.decode(s);
      return TimeOfDay(hour: map['hour'], minute: map['minute']);
    }).toList();

    setState(() {
      _alarms = loaded;
      for (var time in _alarms) {
        _alarmStatus[time] = true;
      }
    });
  }

  Future<void> _addManualAlarm() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && !_alarms.contains(picked)) {
      setState(() {
        _alarms.add(picked);
        _alarmStatus[picked] = true;
      });
      _scheduleSingleAlarm(picked);
      _saveAlarmsToStorage();
    }
  }

  Future<void> _deleteAlarm(TimeOfDay time) async {
    setState(() {
      _alarms.remove(time);
      _alarmStatus.remove(time);
    });
    int id = time.hour * 100 + time.minute;
    await AwesomeNotifications().cancel(id);
    _saveAlarmsToStorage();
  }

  Future<void> _scheduleSingleAlarm(TimeOfDay time) async {
    final now = DateTime.now();
    final alarmTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (alarmTime.isAfter(now)) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: time.hour * 100 + time.minute,
          channelKey: 'basic_channel',
          title: '💧 Su İçme Zamanı!',
          body: '${_formatTime(time)} saatinde su içmeyi unutma!',
        ),
        schedule: NotificationCalendar(
          hour: time.hour,
          minute: time.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        ),
      );
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  void _goToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manuel Uyarı Ayarları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addManualAlarm,
            tooltip: 'Yeni Uyarı Ekle',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: _alarms.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final time = _alarms[index];
                return ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.blueAccent),
                  title: Text(_formatTime(time), style: const TextStyle(fontSize: 18)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _alarmStatus[time] ?? true,
                        onChanged: (val) {
                          setState(() {
                            _alarmStatus[time] = val;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Sil',
                        onPressed: () => _deleteAlarm(time),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _goToHomePage,
              icon: const Icon(Icons.home),
              label: const Text('Ana Sayfaya Git'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          )
        ],
      ),
    );
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Su Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text("Ana Sayfa")),
    );
  }

class _HomePageState extends State<HomePage> {
  double totalDrank = 0;
  final double bottleHeight = 400;

  double get dailyGoal => globalWaterTarget;
  double get progress => (dailyGoal == 0) ? 0 : totalDrank / dailyGoal;

  Future<void> scheduleRepeatedNotifications() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 11,
        channelKey: 'basic_channel',
        title: '💧 Su İçme Zamanı!',
        body: 'Bir bardak su içmeyi unutma!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationInterval(
        interval: Duration(minutes:120) , // 2 saat
        timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        repeats: true,
      ),
    );
  }
  void showTestNotification() {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'basic_channel',
        title: '💧 Su İçme Zamanı!',
        body: 'Bir bardak su içmeyi unutma!',
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }


  void _drinkWater(double amount) {
    setState(() {
      totalDrank += amount;
      if (totalDrank > dailyGoal) {
        totalDrank = dailyGoal;
      }
    });
  }

  Widget _buildDrinkButton(int amount) {
    return ElevatedButton.icon(
      onPressed: () => _drinkWater(amount.toDouble()),
      icon: const Icon(Icons.local_drink),
      label: Text('$amount ml'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.lightBlueAccent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottleBottomOffset = 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Su Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Günlük Su Hedefi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${dailyGoal.toInt()} ml', style: const TextStyle(fontSize: 24, color: Colors.blueAccent)),
              const SizedBox(height: 30),
              SizedBox(
                height: bottleHeight,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.asset(
                      'assets/bottle.png',
                      height: bottleHeight,
                      fit: BoxFit.fill,
                    ),
                    Positioned(
                      bottom: bottleBottomOffset + (bottleHeight - 2 * bottleBottomOffset) * progress,
                      child: Column(
                        children: [
                          const Icon(Icons.arrow_drop_up, size: 40, color: Colors.redAccent),
                          const SizedBox(height: 4),
                          Text('${totalDrank.toInt()} ml', style: const TextStyle(fontSize: 16, color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('${totalDrank.toInt()} ml içildi', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: [
                  _buildDrinkButton(100),
                  _buildDrinkButton(250),
                  _buildDrinkButton(500),

                ],
              ),
              const SizedBox(height: 20),
              if (progress >= 1.0)
                Column(
                  children: const [
                    Icon(Icons.emoji_events, color: Colors.orange, size: 50),
                    Text(
                      'Tebrikler! Hedef tamamlandı 🎉',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
// HomePage sınıfının kapanışından sonra ekle

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  String _gender = 'Erkek';
  String? _selectedClimate;
  String? _selectedActivity;

  final List<String> _climateOptions = ['Soğuk', 'Ilıman', 'Sıcak'];
  final List<String> _activityOptions = ['Az', 'Orta', 'Yüksek'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? '';
      _ageController.text = prefs.getInt('profile_age')?.toString() ?? '';
      _weightController.text = prefs.getInt('profile_weight')?.toString() ?? '';
      _gender = prefs.getString('profile_gender') ?? 'Erkek';
      _selectedClimate = prefs.getString('profile_climate');
      _selectedActivity = prefs.getString('profile_activity');
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_name', _nameController.text);
    await prefs.setInt('profile_age', int.tryParse(_ageController.text) ?? 0);
    await prefs.setInt('profile_weight', int.tryParse(_weightController.text) ?? 0);
    await prefs.setString('profile_gender', _gender);
    if (_selectedClimate != null) await prefs.setString('profile_climate', _selectedClimate!);
    if ( _selectedActivity != null) await prefs.setString('profile_activity', _selectedActivity!);

    // Profili listeye ekle
    final profiles = prefs.getStringList('profile_names') ?? [];
    if (!profiles.contains(_nameController.text)) {
      profiles.add(_nameController.text);
      await prefs.setStringList('profile_names', profiles);
    }
    await prefs.setString('selected_profile', _nameController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil kaydedildi')),
    );

    Navigator.pop(context); // Profile kaydettikten sonra geri dön
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Ad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Yaş'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilo'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              items: ['Erkek', 'Kadın']
                  .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _gender = value;
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Cinsiyet'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _climateOptions.contains(_selectedClimate) ? _selectedClimate : null,
              decoration: const InputDecoration(labelText: 'İklim'),
              items: _climateOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedClimate = val),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedActivity,
              decoration: const InputDecoration(labelText: 'Aktivite Seviyesi'),
              items: _activityOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedActivity = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class UserDataService {
  final String profileId;

  UserDataService(this.profileId);

  String _key(String base) => '${base}_$profileId';

  Future<void> saveDrankAmount(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key('drank'), amount);
  }

  Future<double> getDrankAmount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_key('drank')) ?? 0.0;
  }

  Future<void> saveAlarms(List<String> times) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key('alarms'), times);
  }

  Future<List<String>> getAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key('alarms')) ?? [];
  }
}
// ProfilePage'den sonra
class ProfileSelectionPage extends StatefulWidget {
  const ProfileSelectionPage({super.key});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  List<String> _profileNames = [];
  String? _selectedProfile;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList('profile_names') ?? [];
    final selected = prefs.getString('selected_profile');
    setState(() {
      _profileNames = names;
      _selectedProfile = selected;
    });
  }

  Future<void> _selectProfile(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_profile', name);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  Future<void> _goToProfileCreation() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Seçimi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _profileNames.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Kayıtlı profil bulunamadı.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _goToProfileCreation,
                child: const Text('Yeni Profil Oluştur'),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _profileNames.length,
          itemBuilder: (context, index) {
            final name = _profileNames[index];
            return ListTile(
              title: Text(name),
              trailing: _selectedProfile == name
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => _selectProfile(name),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToProfileCreation,
        child: const Icon(Icons.add),
      ),
    );
  }
}
