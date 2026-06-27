import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/users_repository.dart';
import '../services/auth_service.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  UserModel? _selectedUser;

  bool _canPersons = false;
  bool _canStages = false;
  bool _canAreas = false;
  bool _canFathers = false;
  bool _canReports = false;
  bool _canUsers = false;
  bool _canAbsence = false;
  bool _canMaintenance = false;
  bool _canIdCard = false;
  bool _canTayo = false;
  bool _canTransfer = false;
  bool _canServices = false;
  bool _canKhoros = false;
  bool _canBehavior = false;
  bool _canMeetings = false;
  bool _canRohot = false;
  bool _canMonthlyFund = false;
  bool _canVisitation = false;

  bool _obscurePassword = true;

  static const List<_FeatureDefinition> _features = [
    _FeatureDefinition('persons', 'بيانات الأشخاص', Icons.people_outline),
    _FeatureDefinition(
      'attendance',
      'تسجيل الحضور',
      Icons.calendar_month_outlined,
    ),
    _FeatureDefinition(
      'visitation',
      'الافتقاد',
      Icons.volunteer_activism_outlined,
    ),
    _FeatureDefinition(
      'behavior',
      'تقييم السلوك',
      Icons.thumbs_up_down_outlined,
    ),
    _FeatureDefinition('meetings', 'الاجتماعات', Icons.groups_3_outlined),
    _FeatureDefinition('rohot', 'الرهوط', Icons.diversity_3_outlined),
    _FeatureDefinition('monthlyFund', 'الصندوق الشهري', Icons.savings_outlined),
    _FeatureDefinition(
      'reports',
      'التقارير والإحصائيات',
      Icons.analytics_outlined,
    ),
    _FeatureDefinition(
      'users',
      'إدارة المستخدمين',
      Icons.admin_panel_settings_outlined,
    ),
    _FeatureDefinition('idCard', 'إصدار كارنيه', Icons.badge_outlined),
    _FeatureDefinition('tayo', 'كروت الطايو', Icons.card_giftcard_outlined),
    _FeatureDefinition('stages', 'المراحل الدراسية', Icons.school_outlined),
    _FeatureDefinition('areas', 'المناطق السكنية', Icons.map_outlined),
    _FeatureDefinition('fathers', 'آباء الإعتراف', Icons.church_outlined),
    _FeatureDefinition(
      'services',
      'إدارة الخدمات',
      Icons.miscellaneous_services_outlined,
    ),
    _FeatureDefinition('khoros', 'إدارة الخوارس', Icons.library_music_outlined),
    _FeatureDefinition('transfer', 'نقل البيانات', Icons.swap_horiz_outlined),
    _FeatureDefinition('maintenance', 'صيانة النظام', Icons.settings_outlined),
  ];

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearForm() {
    setState(() {
      _selectedUser = null;
      _usernameController.clear();
      _passwordController.clear();
      _obscurePassword = true;

      _canPersons = false;
      _canStages = false;
      _canAreas = false;
      _canFathers = false;
      _canReports = false;
      _canUsers = false;
      _canAbsence = false;
      _canMaintenance = false;
      _canIdCard = false;
      _canTayo = false;
      _canTransfer = false;
      _canServices = false;
      _canKhoros = false;
      _canBehavior = false;
      _canMeetings = false;
      _canRohot = false;
      _canMonthlyFund = false;
      _canVisitation = false;
    });
  }

  void _loadUserIntoForm(UserModel user) {
    setState(() {
      _selectedUser = user;
      _usernameController.text = user.username;
      _passwordController.text = user.password;
      _obscurePassword = true;

      _canPersons = user.canPersons;
      _canStages = user.canStages;
      _canAreas = user.canAreas;
      _canFathers = user.canFathers;
      _canReports = user.canReports;
      _canUsers = user.canUsers;
      _canAbsence = user.canAbsence;
      _canMaintenance = user.canMaintenance;
      _canIdCard = user.canIdCard;
      _canTayo = user.canTayo;
      _canTransfer = user.canTransfer;
      _canServices = user.canServices;
      _canKhoros = user.canKhoros;
      _canBehavior = user.canBehavior;
      _canMeetings = _granularFeatureEnabled(user, 'meetings');
      _canRohot = _granularFeatureEnabled(user, 'rohot');
      _canMonthlyFund = _granularFeatureEnabled(user, 'monthlyFund');
      _canVisitation = _granularFeatureEnabled(user, 'visitation');
    });
  }

  bool _granularFeatureEnabled(UserModel user, String featureKey) {
    final permissions = user.granularPermissions[featureKey];
    return permissions != null && permissions.values.any((value) => value);
  }

  bool _featureEnabled(String featureKey) {
    switch (featureKey) {
      case 'persons':
        return _canPersons;
      case 'stages':
        return _canStages;
      case 'areas':
        return _canAreas;
      case 'fathers':
        return _canFathers;
      case 'reports':
        return _canReports;
      case 'users':
        return _canUsers;
      case 'attendance':
        return _canAbsence;
      case 'maintenance':
        return _canMaintenance;
      case 'idCard':
        return _canIdCard;
      case 'tayo':
        return _canTayo;
      case 'transfer':
        return _canTransfer;
      case 'services':
        return _canServices;
      case 'khoros':
        return _canKhoros;
      case 'behavior':
        return _canBehavior;
      case 'meetings':
        return _canMeetings;
      case 'rohot':
        return _canRohot;
      case 'monthlyFund':
        return _canMonthlyFund;
      case 'visitation':
        return _canVisitation;
    }
    return false;
  }

  void _setFeatureEnabled(String featureKey, bool value) {
    switch (featureKey) {
      case 'persons':
        _canPersons = value;
        break;
      case 'stages':
        _canStages = value;
        break;
      case 'areas':
        _canAreas = value;
        break;
      case 'fathers':
        _canFathers = value;
        break;
      case 'reports':
        _canReports = value;
        break;
      case 'users':
        _canUsers = value;
        break;
      case 'attendance':
        _canAbsence = value;
        break;
      case 'maintenance':
        _canMaintenance = value;
        break;
      case 'idCard':
        _canIdCard = value;
        break;
      case 'tayo':
        _canTayo = value;
        break;
      case 'transfer':
        _canTransfer = value;
        break;
      case 'services':
        _canServices = value;
        break;
      case 'khoros':
        _canKhoros = value;
        break;
      case 'behavior':
        _canBehavior = value;
        break;
      case 'meetings':
        _canMeetings = value;
        break;
      case 'rohot':
        _canRohot = value;
        break;
      case 'monthlyFund':
        _canMonthlyFund = value;
        break;
      case 'visitation':
        _canVisitation = value;
        break;
    }
  }

  Map<String, Map<String, bool>> _basicPermissionsSnapshot() {
    final result = <String, Map<String, bool>>{};
    for (final feature in _features) {
      if (_featureEnabled(feature.key)) {
        result[feature.key] = {'add': true, 'edit': true, 'delete': true};
      }
    }
    return result;
  }

  void _toggleBasicPermission(String featureKey, bool enabled) {
    setState(() {
      _setFeatureEnabled(featureKey, enabled);
    });
  }

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final isCreating = _selectedUser == null;

    if (username.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسم المستخدم وكلمة المرور')),
      );
      return;
    }

    final repo = ref.read(usersRepositoryProvider.notifier);
    final granularPermissions = _basicPermissionsSnapshot();
    final visibilityFilters = <String, List<int>>{};

    bool success;
    if (_selectedUser == null) {
      success = await repo.addUser(
        username,
        password,
        canPersons: _canPersons,
        canStages: _canStages,
        canAreas: _canAreas,
        canFathers: _canFathers,
        canReports: _canReports,
        canUsers: _canUsers,
        canAbsence: _canAbsence,
        canMaintenance: _canMaintenance,
        canIdCard: _canIdCard,
        canTayo: _canTayo,
        canTransfer: _canTransfer,
        canServices: _canServices,
        canKhoros: _canKhoros,
        canBehavior: _canBehavior,
        isAdvanced: false,
        granularPermissions: granularPermissions,
        visibilityFilters: visibilityFilters,
      );
    } else {
      success = await repo.updateUser(
        _selectedUser!.id,
        username,
        password,
        canPersons: _canPersons,
        canStages: _canStages,
        canAreas: _canAreas,
        canFathers: _canFathers,
        canReports: _canReports,
        canUsers: _canUsers,
        canAbsence: _canAbsence,
        canMaintenance: _canMaintenance,
        canIdCard: _canIdCard,
        canTayo: _canTayo,
        canTransfer: _canTransfer,
        canServices: _canServices,
        canKhoros: _canKhoros,
        canBehavior: _canBehavior,
        isAdvanced: false,
        granularPermissions: granularPermissions,
        visibilityFilters: visibilityFilters,
      );
    }

    if (!mounted) return;

    if (success) {
      await ref.read(authServiceProvider.notifier).refreshUser();
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCreating ? 'تم إنشاء المستخدم بنجاح' : 'تم تحديث المستخدم بنجاح',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCreating ? 'اسم المستخدم موجود بالفعل' : 'فشل تحديث المستخدم',
          ),
        ),
      );
    }
  }

  Future<void> _delete(UserModel user) async {
    final currentUser = ref.read(authServiceProvider).value;
    if (currentUser != null && currentUser.id == user.id) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن حذف المستخدم الحالي أثناء تسجيل الدخول'),
        ),
      );
      return;
    }

    if (user.username.toLowerCase() == 'admin') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن حذف حساب admin الافتراضي')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل تريد حذف المستخدم "${user.username}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(usersRepositoryProvider.notifier)
        .deleteUser(user.id);
    if (!mounted) return;

    if (success) {
      await ref.read(authServiceProvider.notifier).refreshUser();
      if (_selectedUser?.id == user.id) {
        _clearForm();
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'تم حذف المستخدم' : 'تعذر حذف المستخدم'),
      ),
    );
  }

  int _enabledFeatureCount(UserModel user) {
    var count = 0;
    if (user.canPersons) count++;
    if (user.canStages) count++;
    if (user.canAreas) count++;
    if (user.canFathers) count++;
    if (user.canReports) count++;
    if (user.canUsers) count++;
    if (user.canAbsence) count++;
    if (user.canMaintenance) count++;
    if (user.canIdCard) count++;
    if (user.canTayo) count++;
    if (user.canTransfer) count++;
    if (user.canServices) count++;
    if (user.canKhoros) count++;
    if (user.canBehavior) count++;
    if (_granularFeatureEnabled(user, 'meetings')) count++;
    if (_granularFeatureEnabled(user, 'rohot')) count++;
    if (_granularFeatureEnabled(user, 'monthlyFund')) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersRepositoryProvider);
    final currentUser = ref.watch(authServiceProvider).value;
    final isWide = MediaQuery.of(context).size.width >= 1050;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: EdgeInsets.all(isWide ? 16 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 430, child: _buildFormCard()),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildUsersListCard(
                              usersAsync: usersAsync,
                              currentUser: currentUser,
                              shrinkWrap: false,
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _buildFormCard(),
                          const SizedBox(height: 16),
                          _buildUsersListCard(
                            usersAsync: usersAsync,
                            currentUser: currentUser,
                            shrinkWrap: true,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'إدارة المستخدمين',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          'واجهة مبسطة لإدارة الحسابات والصلاحيات',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  _selectedUser == null
                      ? Icons.person_add_alt_1
                      : Icons.edit_note,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedUser == null ? 'حساب جديد' : 'تعديل الحساب',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_selectedUser != null)
                  TextButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('جديد'),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                prefixIcon: Icon(Icons.account_circle_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBasicPermissionsSection(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _save,
              icon: Icon(
                _selectedUser == null ? Icons.person_add : Icons.save_outlined,
              ),
              label: Text(
                _selectedUser == null ? 'إنشاء المستخدم' : 'حفظ التعديلات',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الصلاحيات الأساسية',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          'فعّل الشاشات التي تريدها لهذا المستخدم. في هذا الوضع ستكون الإضافة والتعديل والحذف متاحة بالكامل داخل الشاشة.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _features.map((feature) {
            final enabled = _featureEnabled(feature.key);
            return SizedBox(
              width: 185,
              child: FilterChip(
                avatar: Icon(
                  feature.icon,
                  size: 18,
                  color: enabled
                      ? Colors.white
                      : Theme.of(context).primaryColor,
                ),
                label: Text(feature.label),
                selected: enabled,
                onSelected: (value) =>
                    _toggleBasicPermission(feature.key, value),
                selectedColor: Theme.of(context).primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: enabled ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUsersListCard({
    required AsyncValue<List<UserModel>> usersAsync,
    required User? currentUser,
    required bool shrinkWrap,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_alt_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'قائمة المستخدمين',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (_selectedUser != null)
                  Text(
                    'جارٍ تعديل: ${_selectedUser!.username}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (shrinkWrap)
              usersAsync.when(
                data: (users) {
                  if (users.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('لا يوجد مستخدمون مسجلون')),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildUserTile(users[index], currentUser),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) =>
                    Center(child: Text('خطأ في تحميل المستخدمين: $e')),
              )
            else
              Expanded(
                child: usersAsync.when(
                  data: (users) {
                    if (users.isEmpty) {
                      return const Center(
                        child: Text('لا يوجد مستخدمون مسجلون'),
                      );
                    }

                    return ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _buildUserTile(users[index], currentUser),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('خطأ في تحميل المستخدمين: $e')),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user, User? currentUser) {
    final isSelected = _selectedUser?.id == user.id;
    final isCurrentUser = currentUser?.id == user.id;
    final canDelete = !isCurrentUser && user.username.toLowerCase() != 'admin';

    return ListTile(
      selected: isSelected,
      selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.1),
        child: const Icon(Icons.person_outline, color: Colors.blue, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              user.username,
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isCurrentUser)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'أنت',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildUserInfoChip(
              '${_enabledFeatureCount(user)} شاشة',
              Colors.blue,
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _loadUserIntoForm(user),
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            tooltip: 'تعديل',
          ),
          IconButton(
            onPressed: canDelete ? () => _delete(user) : null,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: canDelete ? 'حذف' : 'لا يمكن حذف هذا الحساب',
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FeatureDefinition {
  final String key;
  final String label;
  final IconData icon;

  const _FeatureDefinition(this.key, this.label, this.icon);
}
