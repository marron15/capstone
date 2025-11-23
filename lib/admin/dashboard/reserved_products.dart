import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../sidenav.dart';

class ReservedProductsPage extends StatefulWidget {
  const ReservedProductsPage({super.key});

  @override
  State<ReservedProductsPage> createState() => _ReservedProductsPageState();
}

enum _ReservationStatus { pending, accepted, declined }

class _ReservedProductRequest {
  final int id;
  final int productId;
  final int customerId;
  final String productName;
  final String customerName;
  final String customerEmail;
  final String notes;
  final int requestedQty;
  final DateTime requestedAt;
  _ReservationStatus status;

  _ReservedProductRequest({
    required this.id,
    required this.productId,
    required this.customerId,
    required this.productName,
    required this.customerName,
    required this.customerEmail,
    required this.notes,
    required this.requestedQty,
    required this.requestedAt,
    this.status = _ReservationStatus.pending,
  });

  factory _ReservedProductRequest.fromMap(Map<String, dynamic> map) {
    final String statusString =
        (map['status'] ?? 'pending').toString().toLowerCase();
    return _ReservedProductRequest(
      id: int.tryParse((map['id'] ?? '').toString()) ?? 0,
      productId: int.tryParse((map['product_id'] ?? '').toString()) ?? 0,
      customerId: int.tryParse((map['customer_id'] ?? '').toString()) ?? 0,
      productName: (map['product_name'] ?? 'Unknown Product').toString(),
      customerName: _composeCustomerName(map),
      customerEmail: (map['email'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      requestedQty: int.tryParse((map['quantity'] ?? '0').toString()) ?? 0,
      requestedAt:
          DateTime.tryParse((map['created_at'] ?? '').toString()) ??
          DateTime.now(),
      status: _statusFromString(statusString),
    );
  }

  static _ReservationStatus _statusFromString(String status) {
    switch (status) {
      case 'accepted':
        return _ReservationStatus.accepted;
      case 'declined':
        return _ReservationStatus.declined;
      default:
        return _ReservationStatus.pending;
    }
  }

  static String _composeCustomerName(Map<String, dynamic> map) {
    final String firstName = (map['first_name'] ?? '').toString().trim();
    final String lastName = (map['last_name'] ?? '').toString().trim();
    final String full = '$firstName $lastName'.trim();
    if (full.isEmpty) return (map['customerName'] ?? 'Customer').toString();
    return full;
  }
}

class _ReservedProductsPageState extends State<ReservedProductsPage> {
  final double _drawerWidth = 280;
  bool _navCollapsed = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  final List<_ReservedProductRequest> _reservations = [];

  List<_ReservedProductRequest> get _filteredReservations {
    if (_searchQuery.trim().isEmpty) return _reservations;
    final lower = _searchQuery.toLowerCase();
    return _reservations.where((request) {
      return request.productName.toLowerCase().contains(lower) ||
          request.customerName.toLowerCase().contains(lower) ||
          request.notes.toLowerCase().contains(lower) ||
          request.id.toString().contains(lower);
    }).toList();
  }

  Color _statusColor(_ReservationStatus status) {
    switch (status) {
      case _ReservationStatus.accepted:
        return Colors.green;
      case _ReservationStatus.declined:
        return Colors.redAccent;
      case _ReservationStatus.pending:
        return Colors.orangeAccent;
    }
  }

  String _statusLabel(_ReservationStatus status) {
    switch (status) {
      case _ReservationStatus.accepted:
        return 'Accepted';
      case _ReservationStatus.declined:
        return 'Declined';
      case _ReservationStatus.pending:
        return 'Pending';
    }
  }

  String _statusValue(_ReservationStatus status) {
    switch (status) {
      case _ReservationStatus.accepted:
        return 'accepted';
      case _ReservationStatus.declined:
        return 'declined';
      case _ReservationStatus.pending:
        return 'pending';
    }
  }

  Future<void> _handleDecision(
    _ReservedProductRequest request,
    _ReservationStatus status,
  ) async {
    if (request.status == status) return;

    // If declining, show modal for decline note
    if (status == _ReservationStatus.declined) {
      final String? declineNote = await _showDeclineModal();
      if (declineNote == null) return; // User cancelled

      final previousStatus = request.status;
      setState(() => request.status = status);

      final bool ok = await ApiService.updateReservationStatus(
        reservationId: request.id,
        status: _statusValue(status),
        declineNote: declineNote,
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation declined'),
            backgroundColor: Colors.red,
          ),
        );
        await _fetchReservations();
      } else {
        setState(() => request.status = previousStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update reservation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Accepting - no note needed
      final previousStatus = request.status;
      setState(() => request.status = status);

      final bool ok = await ApiService.updateReservationStatus(
        reservationId: request.id,
        status: _statusValue(status),
      );
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation accepted'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchReservations();
      } else {
        setState(() => request.status = previousStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update reservation. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showDeclineModal() async {
    final TextEditingController noteController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Decline Reservation'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please provide a reason for declining this reservation:',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter decline reason...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final note = noteController.text.trim();
                if (note.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a decline reason'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(note);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Decline'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getReservedProducts();
    final requests =
        data
            .map<_ReservedProductRequest>(_ReservedProductRequest.fromMap)
            .toList();
    if (!mounted) return;
    setState(() {
      _reservations
        ..clear()
        ..addAll(requests);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;
    final bool isCompactTable = screenWidth < 1180;
    final double actionHeight = isCompactTable ? 56 : 64;

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
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Desktop sidebar - hidden on mobile
            if (!isMobile)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isMobile)
                                Builder(
                                  builder: (context) => IconButton(
                                    tooltip: 'Open Menu',
                                    onPressed: () => Scaffold.of(context).openDrawer(),
                                    icon: const Icon(Icons.menu),
                                  ),
                                )
                              else
                                IconButton(
                                  tooltip:
                                      _navCollapsed
                                          ? 'Open Sidebar'
                                          : 'Close Sidebar',
                                  onPressed:
                                      () => setState(
                                        () => _navCollapsed = !_navCollapsed,
                                      ),
                                  icon: Icon(
                                    _navCollapsed ? Icons.menu : Icons.chevron_left,
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Reserved Products',
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              if (!isMobile) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_filteredReservations.length} Request(s)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: isMobile ? 36 : 42,
                            child: TextField(
                              controller: _searchController,
                              onChanged:
                                  (value) => setState(() => _searchQuery = value),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: isMobile
                                    ? 'Search'
                                    : 'Search by product, customer, or notes',
                                hintStyle: TextStyle(
                                  fontSize: isMobile ? 14 : null,
                                  color: Colors.grey.shade500,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: isMobile ? 18 : 20,
                                  color: Colors.black54,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 20 : 12,
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 20 : 12,
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    isMobile ? 20 : 12,
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: isMobile ? 8 : 0,
                                ),
                                isDense: isMobile,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: isMobile
                          ? _buildMobileView()
                          : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
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
                                    child: Row(
                                      children: const [
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            'Req ID',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Product',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Customer',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Notes',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'Qty',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'Status',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Actions',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isLoading)
                                    const Padding(
                                      padding: EdgeInsets.all(48),
                                      child: CircularProgressIndicator(),
                                    )
                                  else if (_filteredReservations.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(48),
                                      child: Column(
                                        children: const [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 60,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'No reservations found',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Incoming requests will be listed here.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ..._filteredReservations.map((request) {
                                  final Color statusColor = _statusColor(
                                    request.status,
                                  );
                                  return Column(
                                    children: [
                                      SizedBox(
                                        height: actionHeight,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 60,
                                              child: Center(
                                                child: Text(
                                                  '#${request.id}',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: Text(
                                                    request.productName,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        request.customerName,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Requested ${_timeAgo(request.requestedAt)}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: Text(
                                                    request.notes,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Center(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                      ),
                                                  child: Text(
                                                    'x${request.requestedQty}',
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Center(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _statusLabel(
                                                      request.status,
                                                    ),
                                                    style: TextStyle(
                                                      color:
                                                          statusColor.darken(),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Center(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                      ),
                                                  child: _buildActionButtons(
                                                    request,
                                                    isCompactTable,
                                                    actionHeight,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
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

  String _timeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);

    // If less than 1 minute, show seconds
    if (diff.inSeconds < 60) {
      return diff.inSeconds <= 1
          ? '${diff.inSeconds} second ago'
          : '${diff.inSeconds} seconds ago';
    }

    // If less than 1 hour, show minutes
    if (diff.inMinutes < 60) {
      return diff.inMinutes == 1
          ? '${diff.inMinutes} minute ago'
          : '${diff.inMinutes} minutes ago';
    }

    // If less than 24 hours, show hours
    if (diff.inHours < 24) {
      return diff.inHours == 1
          ? '${diff.inHours} hour ago'
          : '${diff.inHours} hours ago';
    }

    // If 24+ hours (days), show actual date and time
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;

    // Format time (12-hour format with AM/PM)
    int hour = dateTime.hour;
    final String period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;

    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$month $day, $year at $hour:$minute $period';
  }

  Widget _buildMobileView() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.inventory_2_outlined,
              size: 60,
            ),
            SizedBox(height: 12),
            Text(
              'No reservations found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Incoming requests will be listed here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: _filteredReservations.map((request) {
        final Color statusColor = _statusColor(request.status);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.blue.shade200,
                        ),
                      ),
                      child: Text(
                        '#${request.id}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor,
                        ),
                      ),
                      child: Text(
                        _statusLabel(request.status),
                        style: TextStyle(
                          color: statusColor.darken(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  request.productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer: ${request.customerName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Requested ${_timeAgo(request.requestedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (request.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.notes,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        'Qty: ${request.requestedQty}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildMobileActionButtons(request),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileActionButtons(_ReservedProductRequest request) {
    final bool isAccepted = request.status == _ReservationStatus.accepted;
    final bool isDeclined = request.status == _ReservationStatus.declined;

    return Row(
      children: [
        if (!isDeclined)
          SizedBox(
            width: 80,
            child: ElevatedButton(
              onPressed: isAccepted
                  ? null
                  : () => _handleDecision(
                    request,
                    _ReservationStatus.accepted,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (!isDeclined && !isAccepted) const SizedBox(width: 8),
        if (!isAccepted)
          SizedBox(
            width: 80,
            child: OutlinedButton(
              onPressed: isDeclined
                  ? null
                  : () => _handleDecision(
                    request,
                    _ReservationStatus.declined,
                  ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: const Text(
                'Decline',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(
    _ReservedProductRequest request,
    bool isCompactLayout,
    double actionHeight,
  ) {
    final bool isAccepted = request.status == _ReservationStatus.accepted;
    final bool isDeclined = request.status == _ReservationStatus.declined;
    final EdgeInsetsGeometry buttonPadding = EdgeInsets.symmetric(
      horizontal: isCompactLayout ? 6 : 12,
      vertical: isCompactLayout ? 8 : 10,
    );

    return SizedBox(
      height: actionHeight,
      child: Row(
        children: [
          if (!isDeclined)
            Expanded(
              child: ElevatedButton(
                onPressed:
                    isAccepted
                        ? null
                        : () => _handleDecision(
                          request,
                          _ReservationStatus.accepted,
                        ),
                child: const Text(
                  'Accept',
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade50,
                  foregroundColor: Colors.green.shade700,
                  elevation: 0,
                  padding: buttonPadding,
                ),
              ),
            ),
          if (!isDeclined && !isAccepted) const SizedBox(width: 8),
          if (!isAccepted)
            Expanded(
              child: OutlinedButton(
                onPressed:
                    isDeclined
                        ? null
                        : () => _handleDecision(
                          request,
                          _ReservationStatus.declined,
                        ),
                child: const Text(
                  'Decline',
                  softWrap: false,
                  overflow: TextOverflow.fade,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: buttonPadding,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
