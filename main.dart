
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FatehoonApp());
}

class FatehoonApp extends StatelessWidget {
  const FatehoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لعبة الفاتحون',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFF10131C),
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: GameScreen(),
      ),
    );
  }
}

class EnemyData {
  final String name;
  final int hp;
  final int attack;
  final int defense;
  final int xp;
  final int gold;

  const EnemyData(this.name, this.hp, this.attack, this.defense, this.xp, this.gold);
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random rng = Random();

  String playerName = 'البطل';
  int hp = 100, maxHp = 100, attack = 15, defense = 5;
  int level = 1, xp = 0, xpNext = 100, gold = 0, battles = 0;

  int location = 1;
  EnemyData? enemy;
  int enemyHp = 0;

  final List<String> inventory = [];
  final Map<String, int> cooldowns = {'ضربة قوية': 0};
  List<String> skills = ['ضربة قوية'];

  String message = 'مرحباً بك في لعبة الفاتحون!';
  bool saved = false;

  final Map<int, String> locations = {
    1: 'القرية',
    2: 'الغابة المظلمة',
    3: 'الجبال الجليدية',
    4: 'قلعة الظلام',
    5: 'مملكة الأشباح',
  };

  final Map<int, List<EnemyData>> enemies = {
    1: const [
      EnemyData('ذئب مجنون', 30, 8, 0, 20, 10),
      EnemyData('لص القرية', 25, 10, 2, 15, 15),
      EnemyData('عنكبوت عملاق', 35, 9, 1, 25, 12),
    ],
    2: const [
      EnemyData('غول الغابة', 60, 15, 3, 40, 25),
      EnemyData('شبح الشجر', 45, 18, 2, 35, 20),
      EnemyData('نمر الظلام', 55, 20, 4, 45, 30),
    ],
    3: const [
      EnemyData('يخضور الثلج', 80, 22, 5, 60, 40),
      EnemyData('طائر العاصفة', 70, 25, 3, 55, 35),
      EnemyData('غول الجبل', 90, 20, 8, 70, 45),
    ],
    4: const [
      EnemyData('كائن الظلام', 120, 28, 6, 90, 60),
      EnemyData('حارس القلعة', 150, 32, 10, 110, 75),
      EnemyData('شبح الحرب', 130, 30, 8, 100, 70),
    ],
    5: const [
      EnemyData('ملك الأشباح', 200, 35, 12, 150, 100),
      EnemyData('الشيطان الأحمر', 180, 38, 10, 140, 90),
      EnemyData('وحش الأبعاد', 220, 40, 15, 180, 120),
    ],
  };

  final Map<int, EnemyData> bosses = {
    2: const EnemyData('زعيم الغابة', 150, 30, 8, 100, 80),
    3: const EnemyData('ملك الجليد', 200, 35, 12, 150, 100),
    4: const EnemyData('قائد الظلام', 250, 40, 15, 200, 150),
    5: const EnemyData('إمبراطور الأشباح', 300, 45, 18, 250, 200),
  };

  @override
  void initState() {
    super.initState();
    loadGame();
  }

  Future<void> saveGame() async {
    final p = await SharedPreferences.getInstance();
    final data = {
      'playerName': playerName, 'hp': hp, 'maxHp': maxHp, 'attack': attack,
      'defense': defense, 'level': level, 'xp': xp, 'xpNext': xpNext,
      'gold': gold, 'battles': battles, 'location': location,
      'inventory': inventory, 'skills': skills,
      'cooldowns': cooldowns,
    };
    await p.setString('fatehoon_save', jsonEncode(data));
    if (mounted) setState(() { saved = true; message = 'تم حفظ اللعبة بنجاح 💾'; });
  }

  Future<void> loadGame() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('fatehoon_save');
    if (raw == null) return;
    try {
      final d = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        playerName = d['playerName'] ?? 'البطل';
        hp = d['hp'] ?? 100; maxHp = d['maxHp'] ?? 100;
        attack = d['attack'] ?? 15; defense = d['defense'] ?? 5;
        level = d['level'] ?? 1; xp = d['xp'] ?? 0;
        xpNext = d['xpNext'] ?? 100; gold = d['gold'] ?? 0;
        battles = d['battles'] ?? 0; location = d['location'] ?? 1;
        inventory
          ..clear()
          ..addAll(List<String>.from(d['inventory'] ?? []));
        skills = List<String>.from(d['skills'] ?? ['ضربة قوية']);
        cooldowns
          ..clear()
          ..addAll(Map<String, dynamic>.from(d['cooldowns'] ?? {'ضربة قوية': 0})
              .map((k, v) => MapEntry(k, (v as num).toInt())));
        message = 'تم تحميل اللعبة المحفوظة 🎮';
      });
    } catch (_) {}
  }

  void newGame() {
    setState(() {
      playerName = 'البطل';
      hp = maxHp = 100; attack = 15; defense = 5;
      level = 1; xp = 0; xpNext = 100; gold = 0; battles = 0;
      location = 1; enemy = null; enemyHp = 0;
      inventory.clear(); skills = ['ضربة قوية'];
      cooldowns.clear(); cooldowns['ضربة قوية'] = 0;
      message = 'بدأت مغامرة جديدة! حان وقت القتال ⚔️';
    });
  }

  void spawnEnemy() {
    final list = enemies[location]!;
    enemy = list[rng.nextInt(list.length)];
    enemyHp = enemy!.hp;
    setState(() => message = 'ظهر ${enemy!.name}! استعد للقتال 👹');
  }

  void ensureEnemy() {
    if (enemy == null || enemyHp <= 0) spawnEnemy();
  }

  int playerDamage() => max(1, rng.nextInt(max(2, attack + 11)) + attack - 5);

  void attackEnemy() {
    ensureEnemy();
    if (enemy == null) return;
    final raw = playerDamage();
    final damage = max(1, raw - enemy!.defense);
    setState(() {
      enemyHp = max(0, enemyHp - damage);
      message = 'هاجمت ${enemy!.name} وأصبتَه بـ $damage ضرر ⚔️';
    });
    if (enemyHp <= 0) {
      winBattle();
    } else {
      enemyTurn();
    }
  }

  void enemyTurn() {
    final raw = rng.nextInt(max(2, enemy!.attack + 11)) + enemy!.attack - 5;
    final damage = max(1, raw - defense);
    setState(() {
      hp = max(0, hp - damage);
      message = '${enemy!.name} هاجمك! تلقيت $damage ضرر 💥';
    });
    if (hp <= 0) {
      setState(() {
        hp = max(1, (maxHp * .5).round());
        gold = max(0, gold - 10);
        enemy = null;
        enemyHp = 0;
        message = 'خسرت المعركة! عُدت إلى القرية وخسرت 10 ذهب 🏠';
      });
    }
  }

  void winBattle() {
    final e = enemy!;
    setState(() {
      xp += e.xp;
      gold += e.gold;
      battles++;
      message = 'انتصرت على ${e.name}! +${e.xp} خبرة و +${e.gold} ذهب 🏆';
      enemy = null;
      enemyHp = 0;
    });
    levelCheck();
    if (rng.nextDouble() < .3) {
      final items = ['جلباب شفاء صغير', 'درع خفيف', 'سيف حديدي قديم'];
      final item = items[rng.nextInt(items.length)];
      setState(() {
        inventory.add(item);
        message += '\nحصلت على: $item 🎁';
      });
    }
    saveGame();
  }

  void levelCheck() {
    while (xp >= xpNext) {
      setState(() {
        xp -= xpNext;
        level++;
        maxHp += 20;
        hp = maxHp;
        attack += 3;
        defense += 1;
        xpNext = (xpNext * 1.5).round();
        message = 'مبروك! وصلت للمستوى $level 🎉';
      });
    }
  }

  void useSkill(String skill) {
    ensureEnemy();
    final cd = cooldowns[skill] ?? 0;
    if (cd > 0) {
      setState(() => message = '$skill جاهزة بعد $cd دورات ⏳');
      return;
    }

    if (skill == 'ضربة قوية') {
      final damage = max(1, (attack * 1.8).round() - enemy!.defense);
      setState(() {
        enemyHp = max(0, enemyHp - damage);
        cooldowns[skill] = 3;
        message = 'استخدمت ضربة قوية! $damage ضرر 🔥';
      });
    } else if (skill == 'علاج') {
      final healed = min(maxHp - hp, (maxHp * .3).round());
      setState(() {
        hp += healed;
        cooldowns[skill] = 4;
        message = 'استخدمت العلاج واستعدت $healed صحة ❤️';
      });
    } else if (skill == 'انفجار الطاقة') {
      final damage = max(1, (attack * 2.5).round() - enemy!.defense);
      final selfDamage = (damage * .3).round();
      setState(() {
        enemyHp = max(0, enemyHp - damage);
        hp = max(1, hp - selfDamage);
        cooldowns[skill] = 5;
        message = 'انفجار الطاقة! $damage ضرر، و $selfDamage ضرر ذاتي 💥';
      });
    }

    reduceCooldowns();
    if (enemyHp <= 0) {
      winBattle();
    } else {
      enemyTurn();
    }
  }

  void reduceCooldowns() {
    for (final k in cooldowns.keys) {
      if (cooldowns[k]! > 0) cooldowns[k] = cooldowns[k]! - 1;
    }
  }

  void flee() {
    if (enemy == null) {
      setState(() => message = 'لا يوجد عدو أمامك.');
      return;
    }
    if (rng.nextDouble() < .7) {
      setState(() {
        enemy = null; enemyHp = 0;
        message = 'هربت بنجاح 🏃';
      });
    } else {
      setState(() => message = 'فشل الهروب! 😨');
      enemyTurn();
    }
  }

  void travel(int newLocation) {
    if (newLocation > level) {
      setState(() => message = 'تحتاج إلى المستوى $newLocation لفتح هذه المنطقة 🔒');
      return;
    }
    setState(() {
      location = newLocation;
      enemy = null;
      enemyHp = 0;
      message = 'وصلت إلى ${locations[newLocation]} 🗺️';
    });
  }

  void buy(String item) {
    final prices = {
      'سيف حديدي': 50, 'درع فولاذي': 40, 'جلباب الشفاء': 25,
      'معطف القوة': 80, 'خاتم الحكمة': 60, 'رمح النار': 120,
    };
    final price = prices[item]!;
    if (gold < price) {
      setState(() => message = 'لا يوجد لديك ذهب كافٍ 💰');
      return;
    }
    setState(() {
      gold -= price;
      inventory.add(item);
      if (item == 'سيف حديدي') attack += 5;
      if (item == 'درع فولاذي') defense += 3;
      if (item == 'معطف القوة') attack += 8;
      if (item == 'رمح النار') attack += 12;
      if (item == 'خاتم الحكمة') { maxHp += 20; hp += 20; }
      if (item == 'جلباب الشفاء') hp = min(maxHp, hp + 30);
      message = 'تم شراء $item بنجاح 🛒';
    });
    saveGame();
  }

  void showSkillsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171C28),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(18),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('المهارات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            for (final skill in skills)
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.cyan),
                title: Text(skill),
                trailing: Text((cooldowns[skill] ?? 0) == 0 ? 'جاهزة' : '${cooldowns[skill]}'),
                onTap: () { Navigator.pop(context); useSkill(skill); },
              ),
            if (level >= 3 && !skills.contains('علاج'))
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.red),
                title: const Text('فتح مهارة العلاج'),
                subtitle: const Text('المستوى 3'),
                onTap: () {
                  setState(() { skills.add('علاج'); cooldowns['علاج'] = 0; });
                  Navigator.pop(context);
                },
              ),
            if (level >= 6 && !skills.contains('انفجار الطاقة'))
              ListTile(
                leading: const Icon(Icons.bolt, color: Colors.amber),
                title: const Text('فتح انفجار الطاقة'),
                subtitle: const Text('المستوى 6'),
                onTap: () {
                  setState(() { skills.add('انفجار الطاقة'); cooldowns['انفجار الطاقة'] = 0; });
                  Navigator.pop(context);
                },
              ),
          ]),
        ),
      ),
    );
  }

  void showShop() {
    final items = ['سيف حديدي','درع فولاذي','جلباب الشفاء','معطف القوة','خاتم الحكمة','رمح النار'];
    final prices = [50,40,25,80,60,120];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF171C28),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: SizedBox(
          height: MediaQuery.of(context).size.height * .72,
          child: Column(children: [
            const SizedBox(height: 15),
            const Text('🛒 المتجر', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text('رصيدك: $gold ذهب', style: const TextStyle(color: Colors.amber)),
            Expanded(child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.amber),
                  title: Text(items[i]),
                  subtitle: Text('${prices[i]} ذهب'),
                  trailing: ElevatedButton(
                    onPressed: gold >= prices[i] ? () { buy(items[i]); Navigator.pop(context); } : null,
                    child: const Text('شراء'),
                  ),
                ),
              ),
            )),
          ]),
        )),
      ),
    );
  }

  void showTravel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF171C28),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🗺️ السفر', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            for (final e in locations.entries)
              ListTile(
                leading: Icon(e.key <= level ? Icons.location_on : Icons.lock),
                title: Text(e.value),
                subtitle: Text(e.key == 1 ? 'متاحة' : 'تحتاج مستوى ${e.key}'),
                enabled: e.key <= level,
                onTap: () { Navigator.pop(context); travel(e.key); },
              ),
          ]),
        )),
      ),
    );
  }

  void showStatus() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('👤 حالة اللاعب'),
        content: Text(
          'الاسم: $playerName\n\n'
          'المستوى: $level\n'
          'الصحة: $hp / $maxHp\n'
          'الهجوم: $attack\n'
          'الدفاع: $defense\n'
          'الخبرة: $xp / $xpNext\n'
          'الذهب: $gold\n'
          'الانتصارات: $battles\n'
          'الموقع: ${locations[location]}\n'
          'المخزون: ${inventory.length} عنصر',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  Widget statBar(String label, int value, int max, IconData icon, Color color) {
    final ratio = max == 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 5),
        Text('$label: $value / $max', style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(value: ratio, minHeight: 10, color: color),
      ),
    ]);
  }

  Widget actionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 25),
          label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enemyName = enemy?.name ?? 'لا يوجد عدو';
    final currentEnemyHp = enemy == null ? 0 : enemyHp;
    final currentEnemyMax = enemy?.hp ?? 1;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('👑 لعبة الفاتحون', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: saveGame, icon: const Icon(Icons.save)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(children: [
                    const CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.person, size: 38),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(playerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('المستوى $level • ${locations[location]}'),
                      ],
                    )),
                    Column(children: [
                      const Icon(Icons.monetization_on, color: Colors.amber),
                      Text('$gold', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ]),
                  ]),
                  const SizedBox(height: 12),
                  statBar('الصحة', hp, maxHp, Icons.favorite, Colors.red),
                  const SizedBox(height: 8),
                  statBar('الخبرة', xp, xpNext, Icons.star, Colors.amber),
                ]),
              ),
            ),
            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Text(
                    enemy == null ? '🏰 ${locations[location]}' : '⚔️ أنت في قتال ضد: $enemyName',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (enemy != null) ...[
                    statBar('صحة العدو', currentEnemyHp, currentEnemyMax, Icons.favorite, Colors.red),
                    const SizedBox(height: 15),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF263A5C), Color(0xFF16221D)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '🧙‍♂️  ⚔️  👹',
                          style: const TextStyle(fontSize: 55),
                        ),
                      ),
                    ),
                  ] else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF315A3C), Color(0xFF172D42)],
                        ),
                      ),
                      child: const Center(
                        child: Text('🏰   🌲   ⚔️   🌲', style: TextStyle(fontSize: 42)),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                  ),
                ]),
              ),
            ),

            if (enemy == null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: spawnEnemy,
                    icon: const Icon(Icons.sports_martial_arts),
                    label: const Text('ابدأ قتالاً جديداً', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red.shade700,
                    ),
                  ),
                ),
              )
            else ...[
              const SizedBox(height: 8),
              Row(children: [
                actionButton('هجوم', Icons.gps_fixed, Colors.red.shade700, attackEnemy),
                actionButton('المهارات', Icons.auto_awesome, Colors.indigo, showSkillsDialog),
                actionButton('هرب', Icons.directions_run, Colors.deepPurple, flee),
              ]),
            ],

            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.45,
              children: [
                actionButton('المتجر', Icons.store, Colors.orange.shade800, showShop),
                actionButton('السفر', Icons.map, Colors.teal.shade700, showTravel),
                actionButton('حالة اللاعب', Icons.person, Colors.blueGrey.shade700, showStatus),
                actionButton('حفظ اللعبة', Icons.save, Colors.green.shade700, saveGame),
                actionButton('لعبة جديدة', Icons.restart_alt, Colors.purple.shade700, newGame),
                actionButton('المخزون', Icons.backpack, Colors.brown.shade700, () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('🎒 المخزون'),
                      content: Text(
                        inventory.isEmpty ? 'المخزون فارغ.' : inventory.join('\n'),
                        textDirection: TextDirection.rtl,
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
