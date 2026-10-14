import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _trackerKey = 'daily-habit-tracker-v1';
const _accountsKey = 'daily-habit-accounts-v1';
const _sessionKey = 'daily-user-email';
const demoEmail = 'franz@gmail.com';
const demoPassword = 'franzsigma';

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.frequency,
    required this.color,
    List<String>? completedDates,
  }) : completedDates = completedDates ?? [];

  final String id;
  String name;
  String category;
  String frequency;
  String color;
  List<String> completedDates;

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'].toString(),
    name: json['name'] as String,
    category: json['category'] as String,
    frequency: json['frequency'] as String,
    color: json['color'] as String? ?? 'mint',
    completedDates: List<String>.from(json['completedDates'] as List? ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'frequency': frequency,
    'color': color,
    'completedDates': completedDates,
  };
}

class HabitDay {
  const HabitDay(this.key, this.label, this.date);

  final String key;
  final String label;
  final int date;
}

class HabitStore extends ChangeNotifier {
  HabitStore._(this._preferences);

  final SharedPreferences _preferences;
  final List<Habit> habits = [];
  final List<Map<String, dynamic>> _accounts = [];
  String name = 'Alex';
  bool weekStartsMonday = true;
  bool authenticated = false;
  String email = '';
  String? persistenceError;

  static const _starterHabits = [
    ('1', 'Drink 8 glasses of water', 'Health', 'mint'),
    ('2', 'Read for 20 minutes', 'Learning', 'sage'),
    ('3', 'Take a morning walk', 'Movement', 'lime'),
    ('4', 'Write in my journal', 'Mindfulness', 'forest'),
  ];

  static Future<HabitStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final store = HabitStore._(preferences);
    store._loadTracker();
    store._loadAccounts();
    if (store._accountFor(demoEmail) == null) {
      store._accounts.add({
        'id': 'daily-demo-account',
        'name': 'Demo User',
        'email': demoEmail,
        'passwordHash': sha256.convert(utf8.encode(demoPassword)).toString(),
      });
      try {
        await preferences.setString(_accountsKey, jsonEncode(store._accounts));
      } on Object {
        store.persistenceError =
            'Demo account could not be saved on this device.';
      }
    }
    final savedEmail = preferences.getString(_sessionKey);
    final account = store._accountFor(savedEmail ?? '');
    if (account != null) {
      store.authenticated = true;
      store.email = account['email'] as String;
    } else if (savedEmail != null) {
      await preferences.remove(_sessionKey);
    }
    return store;
  }

  void _loadTracker() {
    try {
      final saved = _preferences.getString(_trackerKey);
      if (saved == null) {
        _restoreStarterHabits();
        return;
      }
      final data = jsonDecode(saved) as Map<String, dynamic>;
      final savedHabits = data['habits'];
      if (savedHabits is List) {
        habits
          ..clear()
          ..addAll(
            savedHabits.map(
              (item) => Habit.fromJson(Map<String, dynamic>.from(item as Map)),
            ),
          );
      } else {
        _restoreStarterHabits();
      }
      name = data['name'] is String ? data['name'] as String : 'Alex';
      weekStartsMonday = data['weekStartsMonday'] != false;
    } on Object {
      _restoreStarterHabits();
      persistenceError =
          'Saved tracker data could not be read. Demo habits were loaded.';
    }
  }

  void _loadAccounts() {
    try {
      final saved = _preferences.getString(_accountsKey);
      if (saved == null) return;
      final decoded = jsonDecode(saved);
      if (decoded is List) {
        _accounts.addAll(
          decoded
              .whereType<Map>()
              .map((account) => Map<String, dynamic>.from(account))
              .where(
                (account) =>
                    account['email'] is String &&
                    account['passwordHash'] is String,
              ),
        );
      }
    } on Object {
      persistenceError = 'Saved account data could not be read.';
    }
  }

  void _restoreStarterHabits() {
    habits
      ..clear()
      ..addAll(
        _starterHabits.map(
          (habit) => Habit(
            id: habit.$1,
            name: habit.$2,
            category: habit.$3,
            frequency: 'Daily',
            color: habit.$4,
          ),
        ),
      );
    name = 'Alex';
    weekStartsMonday = true;
  }

  Map<String, dynamic>? _accountFor(String value) {
    for (final account in _accounts) {
      if (account['email'] == value) return account;
    }
    return null;
  }

  Future<void> _saveTracker() async {
    notifyListeners();
    var failed = false;
    try {
      await _preferences.setString(
        _trackerKey,
        jsonEncode({
          'habits': habits.map((habit) => habit.toJson()).toList(),
          'name': name,
          'weekStartsMonday': weekStartsMonday,
        }),
      );
    } on Object {
      failed = true;
      persistenceError = 'Your changes could not be saved on this device.';
    }
    if (failed) notifyListeners();
  }

  void clearPersistenceError() {
    persistenceError = null;
    notifyListeners();
  }

  Future<bool> signIn(String address, String password) async {
    final account = _accountFor(address.trim().toLowerCase());
    if (account == null) return false;
    final digest = sha256.convert(utf8.encode(password)).toString();
    if (account['passwordHash'] != digest) return false;
    await _startSession(account);
    return true;
  }

  Future<void> _startSession(Map<String, dynamic> account) async {
    name = account['name'] as String;
    authenticated = true;
    email = account['email'] as String;
    notifyListeners();
    try {
      await _preferences.setString(_sessionKey, email);
    } on Object {
      persistenceError = 'Your session could not be saved on this device.';
    }
    await _saveTracker();
    notifyListeners();
  }

  Future<void> signOut() async {
    authenticated = false;
    email = '';
    try {
      await _preferences.remove(_sessionKey);
    } on Object {
      persistenceError = 'Your session could not be cleared from this device.';
    }
    notifyListeners();
  }

  bool isDoneToday(Habit habit) => habit.completedDates.contains(todayKey());

  void toggleToday(String id) {
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit == null) return;
    final today = todayKey();
    if (!habit.completedDates.remove(today)) {
      habit.completedDates.add(today);
      habit.completedDates.sort();
    }
    _saveTracker();
  }

  void createHabit({
    required String name,
    required String category,
    required String frequency,
  }) {
    habits.insert(
      0,
      Habit(
        id: '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}',
        name: name.trim(),
        category: category,
        frequency: frequency,
        color: 'mint',
      ),
    );
    _saveTracker();
  }

  void updateHabit(
    String id, {
    required String name,
    required String category,
    required String frequency,
  }) {
    final habit = habits.where((item) => item.id == id).firstOrNull;
    if (habit == null) return;
    habit
      ..name = name.trim()
      ..category = category
      ..frequency = frequency;
    _saveTracker();
  }

  void deleteHabit(String id) {
    habits.removeWhere((habit) => habit.id == id);
    _saveTracker();
  }

  void saveName(String value) {
    final cleaned = value.trim();
    name = cleaned.isEmpty
        ? 'Alex'
        : cleaned.substring(0, min(cleaned.length, 24));
    _saveTracker();
  }

  void setWeekStartsMonday(bool value) {
    weekStartsMonday = value;
    _saveTracker();
  }

  void resetDemoData() {
    _restoreStarterHabits();
    _saveTracker();
  }

  int currentStreak(Habit habit) {
    var cursor = DateTime.now();
    if (!habit.completedDates.contains(dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (habit.completedDates.contains(dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<HabitDay> weekDays() {
    final today = DateTime.now();
    final sinceStart = weekStartsMonday
        ? today.weekday - DateTime.monday
        : today.weekday % 7;
    final start = today.subtract(Duration(days: sinceStart));
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      return HabitDay(dateKey(day), labels[day.weekday - 1], day.day);
    });
  }

  String todayKey() => dateKey(DateTime.now());

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
