import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../modal/trainer_modal.dart';

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

  @override
  void initState() {
    super.initState();
    _filteredTrainers = List.from(_trainers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _addTrainer(Map<String, String> trainer) {
    setState(() {
      _trainers.add(trainer);
      _filterTrainers(searchController.text);
    });
  }

  void _editTrainer(int index, Map<String, String> updatedTrainer) {
    setState(() {
      _trainers[index] = updatedTrainer;
      _filterTrainers(searchController.text);
    });
  }

  void _removeTrainer(int index) {
    setState(() {
      _trainers.removeAt(index);
      _filterTrainers(searchController.text);
    });
  }

  void _filterTrainers(String query) {
    setState(() {
      final lowerQuery = query.toLowerCase();
      _filteredTrainers =
          _trainers.where((trainer) {
            return trainer['firstName']!.toLowerCase().contains(lowerQuery) ||
                trainer['lastName']!.toLowerCase().contains(lowerQuery) ||
                trainer['contactNumber']!.toLowerCase().contains(lowerQuery);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Center(child: Text('Gym Trainers')),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Mobile layout: vertical cards for each trainer
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          TrainerModal.showAddTrainerModal(
                            context,
                            _addTrainer,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text('New Trainer', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 220,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: _filterTrainers,
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey,
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._filteredTrainers.asMap().entries.map((entry) {
                    int index = entry.key;
                    var trainer = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${trainer['firstName'] ?? ''} ${trainer['lastName'] ?? ''}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () {
                                        TrainerModal.showEditTrainerModal(
                                          context,
                                          trainer,
                                          (updatedTrainer) {
                                            _editTrainer(index, updatedTrainer);
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text(
                                                'Delete Trainer',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to delete this trainer?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    _removeTrainer(index);
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Text(
                                                    'Delete',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              trainer['contactNumber'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            } else {
              // Desktop/tablet layout: styled like customers table
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
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
                            // Search styled like customers
                            SizedBox(
                              width: 560,
                              height: 42,
                              child: TextField(
                                controller: searchController,
                                onChanged: _filterTrainers,
                                style: const TextStyle(color: Colors.black87),
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
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.black26,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const Spacer(),
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
                                side: const BorderSide(color: Colors.black26),
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
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const AlwaysScrollableScrollPhysics(),
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
                            // Header Row styled like admin_profile/customers
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
                                        fontSize: 15,
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
                                        fontSize: 15,
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
                                        fontSize: 15,
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
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Data Rows
                            ..._filteredTrainers.asMap().entries.map((entry) {
                              int index = entry.key;
                              var trainer = entry.value;
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            trainer['firstName'] ?? '',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            trainer['lastName'] ?? '',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 4,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            trainer['contactNumber'] ?? '',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 160,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Edit icon
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.blue.shade200,
                                                ),
                                              ),
                                              child: IconButton(
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
                                                icon: Icon(
                                                  Icons.edit_outlined,
                                                  size: 14,
                                                  color: Colors.blue.shade700,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 28,
                                                      minHeight: 28,
                                                    ),
                                                tooltip: 'Edit',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Delete icon
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: Colors.orange.shade200,
                                                ),
                                              ),
                                              child: IconButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          'Delete Trainer',
                                                        ),
                                                        content: const Text(
                                                          'Are you sure you want to delete this trainer?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(),
                                                            child: const Text(
                                                              'Cancel',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              _removeTrainer(
                                                                index,
                                                              );
                                                              Navigator.of(
                                                                context,
                                                              ).pop();
                                                            },
                                                            child: const Text(
                                                              'Delete',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 14,
                                                  color: Colors.orange,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 28,
                                                      minHeight: 28,
                                                    ),
                                                tooltip: 'Delete',
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
              );
            }
          },
        ),
      ),
    );
  }
}
