import 'package:flutter/material.dart';

void main() {
  runApp(const WaterReminderApp());
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
      home: const UserInfoPage(),
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

  void _goToAlertSettings() {
    if (_formKey.currentState!.validate()) {
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
                  value: _selectedClimate,
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
                  value: _selectedActivity,
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
  final List<TimeOfDay> _alarms = [];
  final Map<TimeOfDay, bool> _alarmStatus = {};

  @override
  void initState() {
    super.initState();
    _generateAutomaticAlarms();
  }

  void _generateAutomaticAlarms() {
    final List<TimeOfDay> generated = [];
    DateTime current = DateTime(0, 1, 1, widget.wakeUpTime.hour, widget.wakeUpTime.minute);
    final DateTime end = DateTime(0, 1, 1, widget.bedTime.hour, widget.bedTime.minute);

    while (current.isBefore(end)) {
      generated.add(TimeOfDay(hour: current.hour, minute: current.minute));
      current = current.add(Duration(minutes: widget.intervalMinutes));
    }

    setState(() {
      _alarms.clear();
      _alarms.addAll(generated);
      for (var alarm in _alarms) {
        _alarmStatus[alarm] = true;
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
                  trailing: Switch(
                    value: _alarmStatus[time] ?? true,
                    onChanged: (val) {
                      setState(() {
                        _alarmStatus[time] = val;
                      });
                    },
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  double totalDrank = 0;

  double get dailyGoal => globalWaterTarget;

  void _drinkWater(double amount) {
    setState(() {
      totalDrank += amount;
      if (totalDrank > dailyGoal) {
        totalDrank = dailyGoal;
      }
    });
  }

  double get progress => (dailyGoal == 0) ? 0 : totalDrank / dailyGoal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Su Takibi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Günlük Su Hedefi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${dailyGoal.toInt()} ml', style: const TextStyle(fontSize: 24, color: Colors.blueAccent)),
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Su seviyesi (şişenin arkasında)
                  Positioned(
                    bottom: 30, // şişe yüksekliğine göre ayarlanabilir
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 60, // şişe genişliğinden biraz dar
                        height: 220 * progress,
                        color: Colors.blueAccent.withOpacity(0.6),
                      ),
                    ),
                  ),
                  // Şeffaf su şişesi PNG
                  Image.asset(
                    'assets/bottle.png', // senin görselinin yolu
                    height: 300,
                    fit: BoxFit.contain,
                  ),
                ],
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
                    Text('Tebrikler! Hedef tamamlandı 🎉',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                )
            ],
          ),
        ),
      ),
    );
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
}
