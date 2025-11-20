import 'package:flutter/material.dart';

import '../sidenav.dart';

class ReservedProductsPage extends StatefulWidget {
  const ReservedProductsPage({super.key});

  @override
  State<ReservedProductsPage> createState() => _ReservedProductsPageState();
}

enum _ReservationStatus { pending, accepted, declined }

class _ReservedProductRequest {
  final int id;
  final String productName;
  final String customerName;
  final String notes;
  final int requestedQty;
  final DateTime requestedAt;
  _ReservationStatus status;

  _ReservedProductRequest({
    required this.id,
    required this.productName,
    required this.customerName,
    required this.notes,
    required this.requestedQty,
    required this.requestedAt,
    this.status = _ReservationStatus.pending,
  });
}

class _ReservedProductsPageState extends State<ReservedProductsPage> {
  final double _drawerWidth = 280;
  bool _navCollapsed = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_ReservedProductRequest> _reservations = [
    _ReservedProductRequest(
      id: 101,
      productName: 'Whey Protein – Chocolate',
      customerName: 'Alicia Santos',
      notes: 'Pickup preferred on Saturday afternoon.',
      requestedQty: 2,
      requestedAt: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    _ReservedProductRequest(
      id: 102,
      productName: 'Serious Mass 12 lbs',
      customerName: 'Michael Reyes',
      notes: 'Needs confirmation before Friday.',
      requestedQty: 1,
      requestedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    _ReservedProductRequest(
      id: 103,
      productName: 'Prothin Creatine',
      customerName: 'Diana Cruz',
      notes: 'Will pay cash upon pickup.',
      requestedQty: 3,
      requestedAt: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
      status: _ReservationStatus.accepted,
    ),
    _ReservedProductRequest(
      id: 104,
      productName: 'Amino 2222 Tabs',
      customerName: 'Jared Mercado',
      notes: 'Requesting delivery to gym locker.',
      requestedQty: 1,
      requestedAt: DateTime.now().subtract(const Duration(days: 3, hours: 3)),
      status: _ReservationStatus.declined,
    ),
  ];

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

  void _handleDecision(_ReservedProductRequest request, _ReservationStatus status) {
    if (request.status == status) return;
    setState(() => request.status = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == _ReservationStatus.accepted
              ? 'Reservation accepted'
              : 'Reservation declined',
        ),
        backgroundColor:
            status == _ReservationStatus.accepted ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
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
                          IconButton(
                            tooltip:
                                _navCollapsed ? 'Open Sidebar' : 'Close Sidebar',
                            onPressed: () => setState(
                              () => _navCollapsed = !_navCollapsed,
                            ),
                            icon: Icon(
                              _navCollapsed ? Icons.menu : Icons.chevron_left,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Reserved Products',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          if (!isMobile)
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
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) =>
                                    setState(() => _searchQuery = value),
                                style: const TextStyle(color: Colors.black87),
                                decoration: InputDecoration(
                                  hintText: 'Search by product, customer, or notes',
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
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!isMobile)
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _searchQuery = ''),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: const BorderSide(color: Colors.black26),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
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
                          if (_filteredReservations.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(48),
                              child: Column(
                                children: const [
                                  Icon(Icons.inventory_2_outlined, size: 60),
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
                              final Color statusColor = _statusColor(request.status);
                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '#${request.id}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            request.productName,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                request.customerName,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
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
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                            horizontal: 8,
                                          ),
                                          child: Text(
                                            request.notes,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'x${request.requestedQty}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(color: statusColor),
                                            ),
                                            child: Text(
                                              _statusLabel(request.status),
                                              style: TextStyle(
                                                color: statusColor.darken(),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed:
                                                  request.status ==
                                                          _ReservationStatus.accepted
                                                      ? null
                                                      : () => _handleDecision(
                                                            request,
                                                            _ReservationStatus
                                                                .accepted,
                                                          ),
                                              icon: const Icon(
                                                Icons.check_circle_outline,
                                                size: 18,
                                              ),
                                              label: const Text('Accept'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green.shade50,
                                                foregroundColor: Colors.green.shade700,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton.icon(
                                              onPressed:
                                                  request.status ==
                                                          _ReservationStatus.declined
                                                      ? null
                                                      : () => _handleDecision(
                                                            request,
                                                            _ReservationStatus
                                                                .declined,
                                                          ),
                                              icon: const Icon(
                                                Icons.cancel_outlined,
                                                size: 18,
                                              ),
                                              label: const Text('Decline'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red.shade600,
                                                side: BorderSide(
                                                  color: Colors.red.shade200,
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8,
                                                ),
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
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute(s) ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour(s) ago';
    }
    return '${diff.inDays} day(s) ago';
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

