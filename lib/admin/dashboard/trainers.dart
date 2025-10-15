import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../modal/trainer_modal.dart';
import '../services/api_service.dart';
import '../excel/excel_trainer_export.dart';
import 'package:capstone/PH phone number valid/phone_formatter.dart';
import 'package:capstone/PH phone number valid/phone_validator.dart';

class TrainersPage extends StatefulWidget {
  const TrainersPage({super.key});

  @override
  State<TrainersPage> createState() => _TrainersPageState();
}

class _TrainersPageState extends State<TrainersPage> {
  // Trainers data
  final List<Map<String, String>> _trainers = [];

  List<Map<String, String>> _filteredTrainers = [];
  TextEditingController searchController = TextEditingController();
  bool _isLoading = false;
  bool _showArchived = false;
  static const double _drawerWidth = 280;
  bool _navCollapsed = false;

  Widget _buildArchiveEmpty({
    required String title,
    required String helper,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              helper,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.group_outlined, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEFF3FF),
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _filteredTrainers = List.from(_trainers);
    _loadTrainers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainers() async {
    setState(() => _isLoading = true);
    final List<Map<String, String>> list = await ApiService.getAllTrainers();
    setState(() {
      _trainers
        ..clear()
        ..addAll(list);
      _filterTrainers(searchController.text);
      _isLoading = false;
    });
  }

  Future<void> _addTrainer(Map<String, String> trainer) async {
    final String firstName = trainer['firstName'] ?? '';
    final String lastName = trainer['lastName'] ?? '';
    final String contactNumber = trainer['contactNumber'] ?? '';
    final String middleName = trainer['middleName'] ?? '';

    // Validate using shared PH validator (handles spaces)
    final bool isContactValid = PhoneValidator.isValidPhilippineMobile(
      contactNumber,
    );
    if (firstName.isEmpty || lastName.isEmpty || !isContactValid) {
      if (mounted && !isContactValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid PH mobile number')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final bool ok = await ApiService.insertTrainer(
      firstName: firstName,
      middleName: middleName.isEmpty ? null : middleName,
      lastName: lastName,
      contactNumber: PhoneFormatter.cleanPhoneNumber(contactNumber),
    );
    if (mounted) {
      if (ok) {
        await _loadTrainers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trainer added successfully')),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add trainer')));
      }
    }
  }

  void _editTrainer(int index, Map<String, String> updatedTrainer) {
    setState(() {
      _trainers[index] = updatedTrainer;
      _filterTrainers(searchController.text);
    });
  }

  void _filterTrainers(String query) {
    setState(() {
      final lowerQuery = query.toLowerCase();
      _filteredTrainers =
          _trainers.where((trainer) {
            final String status = (trainer['status'] ?? '').toLowerCase();
            final bool matchesArchive =
                _showArchived ? status == 'inactive' : status != 'inactive';
            if (!matchesArchive) return false;
            final String firstName = (trainer['firstName'] ?? '').toLowerCase();
            final String lastName = (trainer['lastName'] ?? '').toLowerCase();
            final String contact =
                (trainer['contactNumber'] ?? '').toLowerCase();
            return firstName.contains(lowerQuery) ||
                lastName.contains(lowerQuery) ||
                contact.contains(lowerQuery);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: _navCollapsed ? 0 : _drawerWidth,
              child: SideNav(
                width: _drawerWidth,
                onClose: () => setState(() => _navCollapsed = true),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                decoration: const BoxDecoration(color: Colors.white),
                child:
                    isMobile
                        ? Column(
                          children: [
                            const SizedBox.shrink(),
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.transparent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // First row with Export and View Archives buttons
                                  Row(
                                    children: [
                                      // Export
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              () => exportTrainersToExcel(
                                                context,
                                                _filteredTrainers,
                                              ),
                                          icon: const Icon(
                                            Icons.table_view,
                                            size: 16,
                                          ),
                                          label: const Text('Export'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black87,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ).copyWith(
                                            side:
                                                WidgetStateProperty.resolveWith(
                                                  (states) => BorderSide(
                                                    color:
                                                        states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )
                                                            ? const Color(
                                                              0xFFFFA812,
                                                            )
                                                            : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // View Archives toggle
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              _showArchived = !_showArchived;
                                              _filterTrainers(
                                                searchController.text,
                                              );
                                            });
                                          },
                                          icon: Icon(
                                            _showArchived
                                                ? Icons.people
                                                : Icons.archive,
                                            size: 16,
                                          ),
                                          label: Text(
                                            _showArchived
                                                ? 'View Active'
                                                : 'View Archives',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.black87,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ).copyWith(
                                            side:
                                                WidgetStateProperty.resolveWith(
                                                  (states) => BorderSide(
                                                    color:
                                                        states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )
                                                            ? const Color(
                                                              0xFFFFA812,
                                                            )
                                                            : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Second row with New Trainer button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            TrainerModal.showAddTrainerModal(
                                              context,
                                              _addTrainer,
                                            );
                                          },
                                          icon: const Icon(Icons.add, size: 16),
                                          label: const Text('New Trainer'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Colors.blue,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                          ).copyWith(
                                            side:
                                                WidgetStateProperty.resolveWith(
                                                  (states) => BorderSide(
                                                    color:
                                                        states.contains(
                                                              WidgetState
                                                                  .hovered,
                                                            )
                                                            ? const Color(
                                                              0xFFFFA812,
                                                            )
                                                            : Colors.black26,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.all(16),
                                children: [
                                  if (_isLoading)
                                    const LinearProgressIndicator(minHeight: 2),
                                  if (_showArchived &&
                                      _filteredTrainers.isEmpty)
                                    _buildArchiveEmpty(
                                      title: 'No archived trainers',
                                      helper:
                                          'Archived trainers will appear here',
                                      actionLabel: 'View Active Trainers',
                                      onAction: () {
                                        setState(() => _showArchived = false);
                                        _filterTrainers(searchController.text);
                                      },
                                    )
                                  else
                                    ..._filteredTrainers.asMap().entries.map((
                                      entry,
                                    ) {
                                      int index = entry.key;
                                      var trainer = entry.value;
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 18,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '${trainer['firstName'] ?? ''} ${trainer['lastName'] ?? ''}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      // Edit button
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .blue
                                                                  .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                Colors
                                                                    .blue
                                                                    .shade200,
                                                          ),
                                                        ),
                                                        child: IconButton(
                                                          icon: const Icon(
                                                            Icons.edit_outlined,
                                                            color: Colors.blue,
                                                            size: 18,
                                                          ),
                                                          onPressed: () {
                                                            TrainerModal.showEditTrainerModal(
                                                              context,
                                                              trainer,
                                                              (updatedTrainer) {
                                                                _editTrainer(
                                                                  index,
                                                                  updatedTrainer,
                                                                );
                                                              },
                                                            );
                                                          },
                                                          padding:
                                                              const EdgeInsets.all(
                                                                8,
                                                              ),
                                                          constraints:
                                                              const BoxConstraints(
                                                                minWidth: 36,
                                                                minHeight: 36,
                                                              ),
                                                          tooltip:
                                                              'Edit Trainer',
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      // Archive/Restore button
                                                      Builder(
                                                        builder: (context) {
                                                          final String idStr =
                                                              trainer['id'] ??
                                                              '0';
                                                          final int id =
                                                              int.tryParse(
                                                                idStr,
                                                              ) ??
                                                              0;
                                                          final bool
                                                          isArchived =
                                                              (trainer['status'] ??
                                                                      '')
                                                                  .toLowerCase() ==
                                                              'inactive';

                                                          if (isArchived) {
                                                            return Container(
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    Colors
                                                                        .green
                                                                        .shade50,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      Colors
                                                                          .green
                                                                          .shade200,
                                                                ),
                                                              ),
                                                              child: IconButton(
                                                                onPressed: () async {
                                                                  setState(
                                                                    () =>
                                                                        _isLoading =
                                                                            true,
                                                                  );
                                                                  final bool
                                                                  ok =
                                                                      await ApiService.restoreTrainer(
                                                                        id,
                                                                      );
                                                                  if (mounted) {
                                                                    await _loadTrainers();
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content: Text(
                                                                          ok
                                                                              ? 'Trainer restored'
                                                                              : 'Action failed',
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                                icon: const Icon(
                                                                  Icons
                                                                      .restore_outlined,
                                                                  size: 18,
                                                                  color:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                                padding:
                                                                    const EdgeInsets.all(
                                                                      8,
                                                                    ),
                                                                constraints:
                                                                    const BoxConstraints(
                                                                      minWidth:
                                                                          36,
                                                                      minHeight:
                                                                          36,
                                                                    ),
                                                                tooltip:
                                                                    'Restore Trainer',
                                                              ),
                                                            );
                                                          }

                                                          return Container(
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Colors
                                                                      .orange
                                                                      .shade50,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    Colors
                                                                        .orange
                                                                        .shade200,
                                                              ),
                                                            ),
                                                            child: IconButton(
                                                              onPressed: () async {
                                                                setState(
                                                                  () =>
                                                                      _isLoading =
                                                                          true,
                                                                );
                                                                final bool ok =
                                                                    await ApiService.archiveTrainer(
                                                                      id,
                                                                    );
                                                                if (mounted) {
                                                                  await _loadTrainers();
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        ok
                                                                            ? 'Trainer archived'
                                                                            : 'Action failed',
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                              icon: const Icon(
                                                                Icons
                                                                    .archive_outlined,
                                                                size: 18,
                                                                color:
                                                                    Colors
                                                                        .orange,
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              constraints:
                                                                  const BoxConstraints(
                                                                    minWidth:
                                                                        36,
                                                                    minHeight:
                                                                        36,
                                                                  ),
                                                              tooltip:
                                                                  'Archive Trainer',
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // Enhanced contact display
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color:
                                                        Colors.green.shade200,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            6,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade100,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              6,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.phone_outlined,
                                                        size: 16,
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade700,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Contact',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color:
                                                                  Colors
                                                                      .green
                                                                      .shade700,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            PhoneFormatter.formatWithSpaces(
                                                              trainer['contactNumber'] ??
                                                                  '',
                                                            ),
                                                            style: const TextStyle(
                                                              fontSize: 13,
                                                              color:
                                                                  Colors
                                                                      .black87,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox.shrink(),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip:
                                            _navCollapsed
                                                ? 'Open Sidebar'
                                                : 'Close Sidebar',
                                        onPressed:
                                            () => setState(
                                              () =>
                                                  _navCollapsed =
                                                      !_navCollapsed,
                                            ),
                                        icon: Icon(
                                          _navCollapsed
                                              ? Icons.menu
                                              : Icons.chevron_left,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Trainers',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      // Search styled like admin_profile
                                      SizedBox(
                                        width: 560,
                                        height: 42,
                                        child: TextField(
                                          controller: searchController,
                                          onChanged: _filterTrainers,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Search',
                                            prefixIcon: const Icon(
                                              Icons.search,
                                              size: 20,
                                              color: Colors.black54,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.black26,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 0,
                                                ),
                                            isDense: true,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Export button (Excel icon + text)
                                      OutlinedButton.icon(
                                        onPressed:
                                            () => exportTrainersToExcel(
                                              context,
                                              _filteredTrainers,
                                            ),
                                        icon: const Icon(
                                          Icons.table_chart_rounded,
                                          color: Colors.teal,
                                          size: 20,
                                        ),
                                        label: const Text('Export'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black87,
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                        ).copyWith(
                                          side: WidgetStateProperty.resolveWith(
                                            (states) => BorderSide(
                                              color:
                                                  states.contains(
                                                        WidgetState.hovered,
                                                      )
                                                      ? const Color(0xFFFFA812)
                                                      : Colors.black26,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Archived Trainers toggle
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(
                                            () =>
                                                _showArchived = !_showArchived,
                                          );
                                          _filterTrainers(
                                            searchController.text,
                                          );
                                        },
                                        icon: Icon(
                                          _showArchived
                                              ? Icons.inventory_2
                                              : Icons.inventory_2_outlined,
                                          size: 18,
                                        ),
                                        label: Text(
                                          _showArchived
                                              ? 'Show Active Trainers'
                                              : 'Archived Trainers',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          elevation: 1,
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ).copyWith(
                                          side: WidgetStateProperty.resolveWith(
                                            (states) => BorderSide(
                                              color:
                                                  states.contains(
                                                        WidgetState.hovered,
                                                      )
                                                      ? const Color(0xFFFFA812)
                                                      : Colors.black26,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // New Trainer pill button
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          TrainerModal.showAddTrainerModal(
                                            context,
                                            _addTrainer,
                                          );
                                        },
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('New Trainer'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          elevation: 1,
                                          side: const BorderSide(
                                            color: Colors.black26,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                        ).copyWith(
                                          side: WidgetStateProperty.resolveWith(
                                            (states) => BorderSide(
                                              color:
                                                  states.contains(
                                                        WidgetState.hovered,
                                                      )
                                                      ? const Color(0xFFFFA812)
                                                      : Colors.black26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // Header Row styled like admin_profile/customers (larger text)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 18,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.shade300,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'First Name',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Last Name',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 4,
                                              child: Text(
                                                'Contact Number',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 160,
                                              child: Text(
                                                'Actions',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Data Rows
                                      if (_showArchived &&
                                          _filteredTrainers.isEmpty)
                                        _buildArchiveEmpty(
                                          title: 'No archived trainers',
                                          helper:
                                              'Archived trainers will appear here',
                                          actionLabel: 'Show Active Trainers',
                                          onAction: () {
                                            setState(
                                              () => _showArchived = false,
                                            );
                                            _filterTrainers(
                                              searchController.text,
                                            );
                                          },
                                        )
                                      else
                                        ..._filteredTrainers.asMap().entries.map((
                                          entry,
                                        ) {
                                          int index = entry.key;
                                          var trainer = entry.value;
                                          return Column(
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    flex: 3,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 14,
                                                            horizontal: 8,
                                                          ),
                                                      child: Text(
                                                        trainer['firstName'] ??
                                                            '',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 14,
                                                            horizontal: 8,
                                                          ),
                                                      child: Text(
                                                        trainer['lastName'] ??
                                                            '',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 4,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 14,
                                                            horizontal: 8,
                                                          ),
                                                      child: _buildPhoneNumberButton(
                                                        PhoneFormatter.formatWithSpaces(
                                                          trainer['contactNumber'] ??
                                                              '',
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 200,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        // Edit icon
                                                        Container(
                                                          decoration: BoxDecoration(
                                                            color:
                                                                Colors
                                                                    .blue
                                                                    .shade50,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                            border: Border.all(
                                                              color:
                                                                  Colors
                                                                      .blue
                                                                      .shade200,
                                                            ),
                                                          ),
                                                          child: IconButton(
                                                            onPressed: () {
                                                              TrainerModal.showEditTrainerModal(
                                                                context,
                                                                trainer,
                                                                (
                                                                  updatedTrainer,
                                                                ) {
                                                                  _editTrainer(
                                                                    index,
                                                                    updatedTrainer,
                                                                  );
                                                                },
                                                              );
                                                            },
                                                            icon: Icon(
                                                              Icons
                                                                  .edit_outlined,
                                                              size: 18,
                                                              color:
                                                                  Colors
                                                                      .blue
                                                                      .shade700,
                                                            ),
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  8,
                                                                ),
                                                            constraints:
                                                                const BoxConstraints(
                                                                  minWidth: 36,
                                                                  minHeight: 36,
                                                                ),
                                                            tooltip: 'Edit',
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        // Archive/Restore control
                                                        Container(
                                                          child: Builder(
                                                            builder: (context) {
                                                              final String
                                                              idStr =
                                                                  trainer['id'] ??
                                                                  '0';
                                                              final int id =
                                                                  int.tryParse(
                                                                    idStr,
                                                                  ) ??
                                                                  0;
                                                              final bool
                                                              isArchived =
                                                                  (trainer['status'] ??
                                                                          '')
                                                                      .toLowerCase() ==
                                                                  'inactive';
                                                              if (isArchived) {
                                                                return Container(
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        Colors
                                                                            .green
                                                                            .shade50,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          6,
                                                                        ),
                                                                    border: Border.all(
                                                                      color:
                                                                          Colors
                                                                              .green
                                                                              .shade200,
                                                                    ),
                                                                  ),
                                                                  child: IconButton(
                                                                    onPressed: () async {
                                                                      setState(
                                                                        () =>
                                                                            _isLoading =
                                                                                true,
                                                                      );
                                                                      final bool
                                                                      ok =
                                                                          await ApiService.restoreTrainer(
                                                                            id,
                                                                          );
                                                                      if (mounted) {
                                                                        await _loadTrainers();
                                                                        ScaffoldMessenger.of(
                                                                          context,
                                                                        ).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              ok
                                                                                  ? 'Trainer restored'
                                                                                  : 'Action failed',
                                                                            ),
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                                    icon: const Icon(
                                                                      Icons
                                                                          .restore_outlined,
                                                                      size: 18,
                                                                      color:
                                                                          Colors
                                                                              .green,
                                                                    ),
                                                                    padding:
                                                                        const EdgeInsets.all(
                                                                          8,
                                                                        ),
                                                                    constraints: const BoxConstraints(
                                                                      minWidth:
                                                                          36,
                                                                      minHeight:
                                                                          36,
                                                                    ),
                                                                    tooltip:
                                                                        'Restore',
                                                                  ),
                                                                );
                                                              }
                                                              return Container(
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      Colors
                                                                          .orange
                                                                          .shade50,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        6,
                                                                      ),
                                                                  border: Border.all(
                                                                    color:
                                                                        Colors
                                                                            .orange
                                                                            .shade200,
                                                                  ),
                                                                ),
                                                                child: IconButton(
                                                                  onPressed: () async {
                                                                    setState(
                                                                      () =>
                                                                          _isLoading =
                                                                              true,
                                                                    );
                                                                    final bool
                                                                    ok =
                                                                        await ApiService.archiveTrainer(
                                                                          id,
                                                                        );
                                                                    if (mounted) {
                                                                      await _loadTrainers();
                                                                      ScaffoldMessenger.of(
                                                                        context,
                                                                      ).showSnackBar(
                                                                        SnackBar(
                                                                          content: Text(
                                                                            ok
                                                                                ? 'Trainer archived'
                                                                                : 'Action failed',
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }
                                                                  },
                                                                  icon: const Icon(
                                                                    Icons
                                                                        .archive_outlined,
                                                                    size: 18,
                                                                    color:
                                                                        Colors
                                                                            .orange,
                                                                  ),
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        8,
                                                                      ),
                                                                  constraints:
                                                                      const BoxConstraints(
                                                                        minWidth:
                                                                            36,
                                                                        minHeight:
                                                                            36,
                                                                      ),
                                                                  tooltip:
                                                                      'Archive',
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Divider(
                                                height: 1,
                                                color: Colors.grey.shade200,
                                              ),
                                            ],
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build styled phone number button for desktop view
  Widget _buildPhoneNumberButton(String phoneNumber) {
    if (phoneNumber == 'N/A' || phoneNumber.isEmpty) {
      return Center(
        child: Text(
          'N/A',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8), // Light green background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone,
              size: 16,
              color: const Color(0xFF2E7D32), // Darker green icon
            ),
            const SizedBox(width: 6),
            Text(
              phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2E7D32), // Darker green text
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
