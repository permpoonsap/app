import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/daily_goal_provider.dart';
import '../model/daily_goal.dart';

class DailyGoalsScreen extends StatefulWidget {
  const DailyGoalsScreen({Key? key}) : super(key: key);

  @override
  State<DailyGoalsScreen> createState() => _DailyGoalsScreenState();
}

class _DailyGoalsScreenState extends State<DailyGoalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadGoals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<DailyGoalProvider>(context, listen: false);
      await provider.loadDailyGoals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เป้าหมายประจำวัน'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'วันนี้', icon: Icon(Icons.today)),
            Tab(text: 'ทำสำเร็จ', icon: Icon(Icons.check_circle)),
            Tab(text: 'ไม่ได้ทำ', icon: Icon(Icons.cancel)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGoals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayGoalsTab(),
                _buildCompletedGoalsTab(),
                _buildMissedGoalsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodayGoalsTab() {
    return Consumer<DailyGoalProvider>(
      builder: (context, provider, child) {
        final activeGoals = provider.getActiveGoals;
        final pendingGoals = provider.dailyGoals
            .where(
                (goal) => goal.status == GoalStatus.pending && !goal.isOverdue)
            .toList();

        if (activeGoals.isEmpty && pendingGoals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'ไม่มีเป้าหมายสำหรับวันนี้',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'กดปุ่ม + เพื่อเพิ่มเป้าหมายใหม่',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (activeGoals.isNotEmpty) ...[
              _buildSectionHeader('เป้าหมายที่ทำได้', Colors.blue),
              ...activeGoals.map((goal) => _buildGoalCard(goal, true)),
              const SizedBox(height: 16),
            ],
            if (pendingGoals.isNotEmpty) ...[
              _buildSectionHeader('เป้าหมายที่รอทำ', Colors.orange),
              ...pendingGoals.map((goal) => _buildGoalCard(goal, false)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCompletedGoalsTab() {
    return Consumer<DailyGoalProvider>(
      builder: (context, provider, child) {
        final completedGoals = provider.getCompletedGoals;

        if (completedGoals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'ยังไม่มีเป้าหมายที่ทำสำเร็จ',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedGoals.length,
          itemBuilder: (context, index) {
            return _buildGoalCard(completedGoals[index], false);
          },
        );
      },
    );
  }

  Widget _buildMissedGoalsTab() {
    return Consumer<DailyGoalProvider>(
      builder: (context, provider, child) {
        final missedGoals = provider.getMissedGoals;

        if (missedGoals.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'ไม่มีเป้าหมายที่ไม่ได้ทำ',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: missedGoals.length,
          itemBuilder: (context, index) {
            return _buildGoalCard(missedGoals[index], false);
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildGoalCard(DailyGoal goal, bool canComplete) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: goal.statusColor,
          child: Icon(
            _getGoalIcon(goal.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          goal.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: goal.status == GoalStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.description),
            const SizedBox(height: 4),
            // แสดงเวลาและวันที่แยกบรรทัดเพื่อหลีกเลี่ยง overflow
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'เวลา: ${goal.targetTimeText}',
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'วันที่: ${goal.targetDateText}',
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (goal.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: goal.tags
                    .map((tag) => Chip(
                          label: Text(tag, style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.blue[100],
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                        ))
                    .toList(),
              ),
            ],
            if (goal.status == GoalStatus.completed &&
                goal.completedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'ทำสำเร็จเมื่อ: ${_formatDateTime(goal.completedAt!)}',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: canComplete
            ? SizedBox(
                width: 80,
                child: ElevatedButton(
                  onPressed: () => _completeGoal(goal),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  child: const Text(
                    'ทำสำเร็จ',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              )
            : SizedBox(
                width: 40,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        if (goal.status == GoalStatus.pending) {
                          _showEditGoalDialog(context, goal);
                        }
                        break;
                      case 'delete':
                        _deleteGoal(goal);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (goal.status == GoalStatus.pending)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('แก้ไข', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('ลบ',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  IconData _getGoalIcon(GoalStatus status) {
    switch (status) {
      case GoalStatus.pending:
        return Icons.flag;
      case GoalStatus.completed:
        return Icons.check_circle;
      case GoalStatus.missed:
        return Icons.cancel;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _completeGoal(DailyGoal goal) async {
    try {
      final provider = Provider.of<DailyGoalProvider>(context, listen: false);
      await provider.completeGoal(goal.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ทำเป้าหมาย "${goal.title}" สำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteGoal(DailyGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('คุณต้องการลบเป้าหมาย "${goal.title}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final provider = Provider.of<DailyGoalProvider>(context, listen: false);
        await provider.deleteDailyGoal(goal.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบเป้าหมาย "${goal.title}" สำเร็จ'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAddGoalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddGoalDialog(),
    ).then((_) => _loadGoals());
  }

  void _showEditGoalDialog(BuildContext context, DailyGoal goal) {
    showDialog(
      context: context,
      builder: (context) => EditGoalDialog(goal: goal),
    ).then((_) => _loadGoals());
  }
}

class AddGoalDialog extends StatefulWidget {
  const AddGoalDialog({Key? key}) : super(key: key);

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  final List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'สุขภาพ',
    'ออกกำลังกาย',
    'ยา',
    'อาหาร',
    'การนอน',
    'งาน',
    'ครอบครัว'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เพิ่มเป้าหมายใหม่'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเป้าหมาย',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อเป้าหมาย';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรายละเอียด';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('เวลา'),
                      subtitle: Text(_selectedTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('วันที่'),
                      subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('แท็ก (เลือกได้หลายอัน)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableTags
                    .map((tag) => FilterChip(
                          label: Text(tag),
                          selected: _selectedTags.contains(tag),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('บันทึก'),
        ),
      ],
    );
  }

  Future<void> _saveGoal() async {
    if (_formKey.currentState!.validate()) {
      try {
        final goal = DailyGoal(
          userId: '', // Will be set by provider
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          targetTime: _selectedTime,
          targetDate: _selectedDate,
          tags: _selectedTags,
        );

        final provider = Provider.of<DailyGoalProvider>(context, listen: false);
        await provider.addDailyGoal(goal);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เพิ่มเป้าหมายสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class EditGoalDialog extends StatefulWidget {
  final DailyGoal goal;

  const EditGoalDialog({Key? key, required this.goal}) : super(key: key);

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TimeOfDay _selectedTime;
  late DateTime _selectedDate;
  late List<String> _selectedTags;
  final List<String> _availableTags = [
    'สุขภาพ',
    'ออกกำลังกาย',
    'ยา',
    'อาหาร',
    'การนอน',
    'งาน',
    'ครอบครัว'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal.title);
    _descriptionController =
        TextEditingController(text: widget.goal.description);
    _selectedTime = widget.goal.targetTime;
    _selectedDate = widget.goal.targetDate;
    _selectedTags = List.from(widget.goal.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('แก้ไขเป้าหมาย'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเป้าหมาย',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกชื่อเป้าหมาย';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียด',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรายละเอียด';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('เวลา'),
                      subtitle: Text(_selectedTime.format(context)),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) {
                          setState(() => _selectedTime = time);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('วันที่'),
                      subtitle: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('แท็ก (เลือกได้หลายอัน)'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableTags
                    .map((tag) => FilterChip(
                          label: Text(tag),
                          selected: _selectedTags.contains(tag),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(
          onPressed: _updateGoal,
          child: const Text('อัปเดต'),
        ),
      ],
    );
  }

  Future<void> _updateGoal() async {
    if (_formKey.currentState!.validate()) {
      try {
        final updatedGoal = widget.goal.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          targetTime: _selectedTime,
          targetDate: _selectedDate,
          tags: _selectedTags,
        );

        final provider = Provider.of<DailyGoalProvider>(context, listen: false);
        await provider.updateDailyGoal(updatedGoal);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัปเดตเป้าหมายสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
