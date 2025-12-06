import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../sidenav.dart';

class AuditLogsPage extends StatefulWidget {
  const AuditLogsPage({super.key});

  @override
  State<AuditLogsPage> createState() => _AuditLogsPageState();
}

class _AuditLogsPageState extends State<AuditLogsPage> {
  final double _drawerWidth = 280;
  bool _navCollapsed = false;
  final TextEditingController _searchController = TextEditingController();

  final List<AuditLogEntry> _logs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedActorType;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    final logs = await ApiService.getAuditLogs(
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      actorType: _selectedActorType,
      limit: 250,
    );
    if (!mounted) return;

    // Apply client-side filtering based on actor type
    // Note: Backend already filters by actor_type, but we keep this as a safety check
    List<AuditLogEntry> filteredLogs =
        logs.map(AuditLogEntry.fromJson).toList();
    filteredLogs =
        filteredLogs.where((entry) => !_isReservationEntry(entry)).toList();

    if (_selectedActorType == 'admin') {
      // Admin activities: filter by actor_type == 'admin'
      filteredLogs =
          filteredLogs.where((entry) {
            final actorType = entry.actorType.toLowerCase();
            return actorType == 'admin' ||
                actorType == 'staff' ||
                actorType == 'administrator';
          }).toList();
    } else if (_selectedActorType == 'customer') {
      // Customer activities: filter by actor_type == 'customer' or entries with customer_id and system actor
      filteredLogs =
          filteredLogs.where((entry) {
            final actorType = entry.actorType.toLowerCase();
            final isCustomerType =
                actorType == 'customer' ||
                actorType == 'system' ||
                actorType.isEmpty;
            // Include customer activities (has customer_id and is customer/system type)
            return entry.customerId != null && isCustomerType;
          }).toList();
    }
    // If _selectedActorType is null, show all (no filtering)

    setState(() {
      _logs
        ..clear()
        ..addAll(filteredLogs);
      _isLoading = false;
    });
  }

  void _handleSearchChanged(String value) {
    _searchQuery = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _fetchLogs);
  }

  void _handleActorTypeChange(String? actorType) {
    if (_selectedActorType == actorType) return;
    setState(() => _selectedActorType = actorType);
    _fetchLogs();
  }

  bool _isReservationEntry(AuditLogEntry entry) {
    final String category = entry.activityCategory.toLowerCase();
    final String type = entry.activityType.toLowerCase();
    final String title = entry.activityTitle.toLowerCase();
    final String description = (entry.description ?? '').toLowerCase();
    return category.contains('reservation') ||
        type.contains('reservation') ||
        title.contains('reservation') ||
        description.contains('reservation');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer:
          isMobile
              ? Drawer(
                width: _drawerWidth,
                child: SideNav(
                  width: _drawerWidth,
                  onClose: () => Navigator.of(context).pop(),
                ),
              )
              : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMobile)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _navCollapsed ? 72 : _drawerWidth,
                child: SideNav(
                  width: _navCollapsed ? 72 : _drawerWidth,
                  onClose: () => setState(() => _navCollapsed = !_navCollapsed),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(context, isMobile),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchLogs,
                      child: _buildContent(isMobile),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audit Logs',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton.icon(
                onPressed: _fetchLogs,
                icon: const Icon(Icons.refresh),
                label: Text(isMobile ? '' : 'Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isMobile) ...[
            TextField(
              controller: _searchController,
              onChanged: _handleSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by customer, action, ID...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearchChanged('');
                          },
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _handleActorTypeChange(null),
                  icon: Icon(
                    _selectedActorType == null
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 18,
                  ),
                  label: const Text('All Actions'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == null
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == null
                              ? Colors.white
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _handleActorTypeChange('customer'),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Customer Activity'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == 'customer'
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == 'customer'
                              ? Colors.white
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _handleActorTypeChange('admin'),
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text('Admin Activity'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == 'admin'
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == 'admin'
                              ? Colors.white
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _searchController,
              onChanged: _handleSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search by customer, action, ID...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _handleSearchChanged('');
                          },
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => _handleActorTypeChange(null),
                  icon: Icon(
                    _selectedActorType == null
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 18,
                  ),
                  label: const Text('All Actions'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == null
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == null
                              ? Colors.white
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _handleActorTypeChange('customer'),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Customer Activity'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == 'customer'
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == 'customer'
                              ? Colors.white
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _handleActorTypeChange('admin'),
                  icon: const Icon(Icons.admin_panel_settings, size: 18),
                  label: const Text('Admin Activity'),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == 'admin'
                              ? Colors.blue.shade700
                              : Colors.grey.shade300,
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          _selectedActorType == 'admin'
                              ? Colors.white
                              : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_logs.isEmpty) {
      return _EmptyState(onRefresh: _fetchLogs, searchQuery: _searchQuery);
    }

    if (isMobile) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _logs.length,
        itemBuilder: (context, index) => _AuditLogCard(entry: _logs[index]),
      );
    }

    return _AuditLogTable(
      entries: _logs,
      isAdminActivity: _selectedActorType == 'admin',
      selectedActorType: _selectedActorType,
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  final AuditLogEntry entry;

  const _AuditLogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = _categoryTitleColor(entry.activityCategoryTitle);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                  child: Icon(
                    _categoryIcon(entry.activityCategory),
                    color: badgeColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.activityTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entry.formattedTimestamp,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (entry.customerId != null)
                      Text(
                        '#${entry.customerId}',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoPill(
                  label: 'Customer',
                  value: entry.customerName ?? 'Unknown',
                  icon: Icons.person_outline,
                ),
                _InfoPill(
                  label: 'Category',
                  value: entry.activityCategoryTitle,
                  icon: Icons.category_outlined,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entry.sections.isNotEmpty)
              Wrap(
                spacing: 8,
                children:
                    entry.sections
                        .map(
                          (section) => Chip(
                            label: Text(section),
                            backgroundColor: badgeColor.withValues(alpha: 0.12),
                            labelStyle: TextStyle(color: badgeColor),
                          ),
                        )
                        .toList(),
              ),
            if (entry.changeRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    entry.changeRows
                        .map(
                          (row) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${row.label}: ${row.oldValue ?? '—'} → ${row.newValue ?? '—'}',
                              style: const TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    switch (category) {
      case 'profile':
        return Icons.manage_accounts_outlined;
      case 'attendance':
        return Icons.access_time;
      case 'auth':
        return Icons.login;
      default:
        return Icons.event_note;
    }
  }

  // Get color based on activity category title (for differentiated Time In/Out)
  static Color _categoryTitleColor(String categoryTitle) {
    if (categoryTitle == 'Time In') {
      return Colors.green;
    }
    if (categoryTitle == 'Time Out') {
      return Colors.red;
    }
    // Fallback: map category titles to their base categories
    final lower = categoryTitle.toLowerCase();
    if (lower.contains('profile')) return Colors.blue;
    if (lower.contains('log in') || lower.contains('login'))
      return Colors.orange;
    if (lower.contains('log out') || lower.contains('logout'))
      return Colors.orange;
    if (lower.contains('time')) return Colors.teal;
    // Default fallback
    return Colors.grey;
  }
}

class _AuditLogTable extends StatelessWidget {
  final List<AuditLogEntry> entries;
  final bool isAdminActivity;
  final String? selectedActorType;

  const _AuditLogTable({
    required this.entries,
    this.isAdminActivity = false,
    this.selectedActorType,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _TableHeader(
                  isAdminActivity: isAdminActivity,
                  selectedActorType: selectedActorType,
                ),
                if (entries.isEmpty)
                  const SizedBox.shrink()
                else
                  ...entries.map(
                    (entry) =>
                        _TableRow(entry, isAdminActivity: isAdminActivity),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final bool isAdminActivity;
  final String? selectedActorType;

  const _TableHeader({this.isAdminActivity = false, this.selectedActorType});

  String get _actorColumnHeader {
    if (isAdminActivity) {
      return 'Admin';
    } else if (selectedActorType == 'customer') {
      return 'Customer';
    } else {
      // All Actions selected
      return 'Admin/Customer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 2),
        ),
      ),
      child: Row(
        children:
            isAdminActivity
                ? const [
                  _HeaderCell(text: 'Activity', flex: 2),
                  _HeaderCell(text: 'Admin', flex: 2),
                  _HeaderCell(text: 'Details', flex: 3),
                  _HeaderCell(text: 'Date & Time (PH)', flex: 2),
                ]
                : [
                  const _HeaderCell(text: 'Activity', flex: 3),
                  _HeaderCell(text: _actorColumnHeader, flex: 2),
                  const _HeaderCell(text: 'Category', flex: 2),
                  const _HeaderCell(text: 'Date & Time (PH)', flex: 2),
                  const _HeaderIdCell(text: 'Log ID'),
                ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _HeaderIdCell extends StatelessWidget {
  final String text;
  const _HeaderIdCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final AuditLogEntry entry;
  final bool isAdminActivity;

  const _TableRow(this.entry, {this.isAdminActivity = false});

  String get _detailsText {
    if (entry.description != null && entry.description!.isNotEmpty) {
      return entry.description!;
    }
    // Fallback to activity title if no description
    return entry.activityTitle;
  }

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = _AuditLogCard._categoryTitleColor(
      entry.activityCategoryTitle,
    );
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children:
                isAdminActivity
                    ? [
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            entry.activityTitle,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            entry.actorName ?? 'Unknown',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            _detailsText,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.formattedTimestamp,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ]
                    : [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                entry.activityTitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.actorType == 'admin'
                              ? (entry.actorName ?? 'Unknown')
                              : (entry.customerName ?? 'Unknown'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              entry.actorType == 'admin'
                                  ? entry.activityTitle
                                  : entry.activityCategoryTitle,
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.formattedTimestamp,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          '#${entry.id}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final String searchQuery;

  const _EmptyState({required this.onRefresh, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Column(
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                searchQuery.isEmpty
                    ? 'No audit records yet'
                    : 'No audit records matched "$searchQuery"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh or adjust your filters.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuditLogEntry {
  AuditLogEntry({
    required this.id,
    required this.activityCategory,
    required this.activityType,
    required this.activityTitle,
    required this.createdAtRaw,
    this.customerId,
    this.customerName,
    this.actorType = 'system',
    this.actorName,
    this.description,
    this.metadata = const {},
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    final dynamic metadata = json['metadata'];
    final String createdAtPh =
        json['created_at_ph']?.toString().trim().replaceAll('T', ' ') ?? '';
    final String createdAt =
        json['created_at']?.toString().trim().replaceAll('T', ' ') ?? '';
    return AuditLogEntry(
      id:
          json['id'] is int
              ? json['id'] as int
              : int.tryParse('${json['id']}') ?? 0,
      customerId:
          json['customer_id'] == null
              ? null
              : int.tryParse('${json['customer_id']}'),
      customerName: json['customer_name']?.toString(),
      actorType: json['actor_type']?.toString() ?? 'system',
      actorName: json['actor_name']?.toString(),
      activityCategory: json['activity_category']?.toString() ?? 'general',
      activityType: json['activity_type']?.toString() ?? 'general',
      activityTitle: json['activity_title']?.toString() ?? 'Activity',
      description: json['description']?.toString(),
      createdAtRaw:
          createdAtPh.isNotEmpty
              ? createdAtPh
              : createdAt.isNotEmpty
              ? createdAt
              : _nowString(),
      metadata:
          metadata is Map<String, dynamic> ? metadata : <String, dynamic>{},
    );
  }

  final int id;
  final int? customerId;
  final String? customerName;
  final String activityCategory;
  final String activityType;
  final String activityTitle;
  final String? description;
  final String actorType;
  final String? actorName;
  final String createdAtRaw;
  final Map<String, dynamic> metadata;

  String get formattedTimestamp {
    final String raw = createdAtRaw;
    if (raw.isEmpty) return '--';
    final parts = raw.split(' ');
    if (parts.length != 2) return raw;
    final dateParts = parts[0].split('-');
    final timeParts = parts[1].split(':');
    if (dateParts.length < 3 || timeParts.length < 2) return raw;

    final int? year = int.tryParse(dateParts[0]);
    final int? month = int.tryParse(dateParts[1]);
    final int? day = int.tryParse(dateParts[2]);
    final int? hour24 = int.tryParse(timeParts[0]);
    final int? minute = int.tryParse(timeParts[1]);

    if ([year, month, day, hour24, minute].any((value) => value == null)) {
      return raw;
    }

    final bool isPm = hour24! >= 12;
    final int hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;

    return '${_pad2(month!)}'
        '/${_pad2(day!)}'
        '/$year '
        '${_pad2(hour12)}:${_pad2(minute!)} ${isPm ? 'PM' : 'AM'}';
  }

  String get activityCategoryTitle {
    if (activityCategory == 'auth') {
      final normalized = activityType.toLowerCase();
      if (normalized.contains('logout')) return 'Log out';
      if (normalized.contains('login')) return 'Log in';
    }
    if (activityCategory == 'attendance') {
      final normalized = activityType.toLowerCase();
      if (normalized.contains('attendance_out') ||
          normalized.contains('time_out') ||
          normalized.contains('timed_out')) {
        return 'Time Out';
      }
      if (normalized.contains('attendance_in') ||
          normalized.contains('time_in') ||
          normalized.contains('timed_in')) {
        return 'Time In';
      }
      // Fallback to check activity title
      final titleLower = activityTitle.toLowerCase();
      if (titleLower.contains('timed out') || titleLower.contains('time out')) {
        return 'Time Out';
      }
      if (titleLower.contains('timed in') || titleLower.contains('time in')) {
        return 'Time In';
      }
    }
    return _categoryTitles[activityCategory] ?? activityCategory;
  }

  List<String> get sections {
    final dynamic sectionList = metadata['sections'];
    if (sectionList is List) {
      return sectionList
          .map((item) => item.toString().replaceAll('_', ' '))
          .toList();
    }
    return [];
  }

  List<_ChangeRow> get changeRows {
    final dynamic changeMap = metadata['changes'];
    if (changeMap is Map) {
      return changeMap.entries.where((entry) => entry.value is Map).map((
        entry,
      ) {
        final Map<String, dynamic> change = Map<String, dynamic>.from(
          entry.value as Map,
        );
        return _ChangeRow(
          label: entry.key.toString().replaceAll('_', ' '),
          oldValue: change['old']?.toString(),
          newValue: change['new']?.toString(),
        );
      }).toList();
    }
    return [];
  }

  static const Map<String, String> _categoryTitles = {
    'profile': 'Profile Updates',
    'attendance': 'Time In/Out',
    'auth': 'Login/Logout',
  };

  static String _pad2(int value) => value.toString().padLeft(2, '0');

  static String _nowString() {
    final DateTime now = DateTime.now();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  }
}

class _ChangeRow {
  final String label;
  final String? oldValue;
  final String? newValue;

  _ChangeRow({
    required this.label,
    required this.oldValue,
    required this.newValue,
  });
}
