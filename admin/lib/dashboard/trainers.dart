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
  List<Map<String, String>> _trainers = [];

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
      _filteredTrainers = _trainers.where((trainer) {
        return trainer['firstName']!.toLowerCase().contains(lowerQuery) ||
            trainer['lastName']!.toLowerCase().contains(lowerQuery) ||
            trainer['contactNumber']!.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SideNav(),
      appBar: AppBar(
        title: const Text('Gym Trainers'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: LayoutBuilder(
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
                        TrainerModal.showAddTrainerModal(context, _addTrainer);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16),
                          SizedBox(width: 4),
                          Text('new trainer', style: TextStyle(fontSize: 14)),
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
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey, size: 20),
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
                          horizontal: 16, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${trainer['firstName'] ?? ''} ${trainer['lastName'] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
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
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Delete Trainer'),
                                            content: const Text(
                                                'Are you sure you want to delete this trainer?'),
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
                                                child: const Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red)),
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
                                fontSize: 14, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          } else {
            // Desktop/tablet layout: table
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.blue,
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          TrainerModal.showAddTrainerModal(
                              context, _addTrainer);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16),
                            SizedBox(width: 4),
                            Text('new trainer', style: TextStyle(fontSize: 14)),
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
                            prefixIcon: Icon(Icons.search,
                                color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Header Row
                            Container(
                              color: Colors.blue[50],
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: const Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text('First Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 3,
                                      child: Text('Last Name',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 4,
                                      child: Text('Contact Number',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  SizedBox(
                                      width: 80,
                                      child: Text('Actions',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Colors.black26),
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
                                          child:
                                              Text(trainer['firstName'] ?? '')),
                                      Expanded(
                                          flex: 3,
                                          child:
                                              Text(trainer['lastName'] ?? '')),
                                      Expanded(
                                          flex: 4,
                                          child: Text(
                                              trainer['contactNumber'] ?? '')),
                                      SizedBox(
                                        width: 80,
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                TrainerModal
                                                    .showEditTrainerModal(
                                                  context,
                                                  trainer,
                                                  (updatedTrainer) {
                                                    _editTrainer(
                                                        index, updatedTrainer);
                                                  },
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: const Text(
                                                          'Delete Trainer'),
                                                      content: const Text(
                                                          'Are you sure you want to delete this trainer?'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                              'Cancel'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            _removeTrainer(
                                                                index);
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                              'Delete',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red)),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(
                                      height: 1, color: Colors.black12),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
