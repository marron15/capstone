import 'package:flutter/material.dart';
import '../sidenav.dart';
import '../modal/trainer_modal.dart';

class TrainersPage extends StatefulWidget {
  const TrainersPage({super.key});

  @override
  State<TrainersPage> createState() => _TrainersPageState();
}

class _TrainersPageState extends State<TrainersPage> {
  // Sample data for trainers
  List<Map<String, String>> _trainers = [
    {
      'firstName': 'John',
      'lastName': 'Doe',
      'contactNumber': '+1 123-456-7890'
    },
    {
      'firstName': 'Jane',
      'lastName': 'Smith',
      'contactNumber': '+1 234-567-8901'
    },
    {
      'firstName': 'Michael',
      'lastName': 'Johnson',
      'contactNumber': '+1 345-678-9012'
    },
    {
      'firstName': 'Emily',
      'lastName': 'Williams',
      'contactNumber': '+1 456-789-0123'
    },
    {
      'firstName': 'Robert',
      'lastName': 'Brown',
      'contactNumber': '+1 567-890-1234'
    },
  ];

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
      body: Column(
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
                    TrainerModal.showAddTrainerModal(context, (newTrainer) {
                      setState(() {
                        _trainers.add(newTrainer);
                      });
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  child: const TextField(
                    decoration: InputDecoration(
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
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                _buildHeaderCell('First Name', flex: 3),
                _buildHeaderCell('Last Name', flex: 3),
                _buildHeaderCell('Contact Number', flex: 4),
                _buildHeaderCell('Actions', flex: 2),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _trainers.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, thickness: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      _buildCell(_trainers[index]['firstName'] ?? '', flex: 3),
                      _buildCell(_trainers[index]['lastName'] ?? '', flex: 3),
                      _buildCell(_trainers[index]['contactNumber'] ?? '',
                          flex: 4),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18, color: Colors.blue),
                              onPressed: () {
                                // Edit trainer modal
                                final trainer = _trainers[index];
                                TextEditingController firstNameController =
                                    TextEditingController(
                                        text: trainer['firstName']);
                                TextEditingController lastNameController =
                                    TextEditingController(
                                        text: trainer['lastName']);
                                TextEditingController contactNumberController =
                                    TextEditingController(
                                        text: trainer['contactNumber']);
                                final _formKey = GlobalKey<FormState>();
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Container(
                                        width: 400,
                                        padding: const EdgeInsets.all(20),
                                        child: Form(
                                          key: _formKey,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextFormField(
                                                controller: firstNameController,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'First Name'),
                                                validator: (value) => value ==
                                                            null ||
                                                        value.isEmpty
                                                    ? 'Please enter first name'
                                                    : null,
                                              ),
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller: lastNameController,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText: 'Last Name'),
                                                validator: (value) => value ==
                                                            null ||
                                                        value.isEmpty
                                                    ? 'Please enter last name'
                                                    : null,
                                              ),
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller:
                                                    contactNumberController,
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            'Contact Number'),
                                                validator: (value) => value ==
                                                            null ||
                                                        value.isEmpty
                                                    ? 'Please enter contact number'
                                                    : null,
                                              ),
                                              const SizedBox(height: 24),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        setState(() {
                                                          _trainers[index] = {
                                                            'firstName':
                                                                firstNameController
                                                                    .text,
                                                            'lastName':
                                                                lastNameController
                                                                    .text,
                                                            'contactNumber':
                                                                contactNumberController
                                                                    .text,
                                                          };
                                                        });
                                                        Navigator.of(context)
                                                            .pop();
                                                      }
                                                    },
                                                    child: const Text('Save'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _trainers.removeAt(index);
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }
}
