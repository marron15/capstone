import 'dart:ui';
import 'package:flutter/material.dart';

class SignUpModal extends StatefulWidget {
  const SignUpModal({Key? key}) : super(key: key);

  @override
  State<SignUpModal> createState() => _SignUpModalState();
}

class _SignUpModalState extends State<SignUpModal>
    with TickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  late AnimationController _controller;
  Animation<double>? _scaleAnim;
  Animation<double>? _fadeAnim;
  late AnimationController _iconController;
  Animation<double>? _iconAnim;

  int _currentStep = 0;
  String? _selectedMonth;
  int? _selectedDay;
  int? _selectedYear;
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _middleNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _dobDayFocus = FocusNode();
  final FocusNode _dobMonthFocus = FocusNode();
  final FocusNode _dobYearFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _rePassFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _iconAnim = Tween<double>(begin: 0.0, end: 0.12).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _iconController.dispose();
    _firstNameFocus.dispose();
    _middleNameFocus.dispose();
    _lastNameFocus.dispose();
    _contactFocus.dispose();
    _emailFocus.dispose();
    _dobDayFocus.dispose();
    _dobMonthFocus.dispose();
    _dobYearFocus.dispose();
    _passFocus.dispose();
    _rePassFocus.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withAlpha((0.08 * 255).toInt()),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.lightBlueAccent, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withAlpha((0.18 * 255).toInt()),
          width: 1.2,
        ),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: FadeTransition(
        opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
        child: ScaleTransition(
          scale: _scaleAnim ?? const AlwaysStoppedAnimation(1.0),
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  // Glassmorphism effect only behind modal
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width < 600
                              ? MediaQuery.of(context).size.width * 0.99
                              : 560,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withAlpha((0.13 * 255).toInt()),
                            Colors.blueGrey.withAlpha((0.10 * 255).toInt()),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withAlpha((0.25 * 255).toInt()),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withAlpha(
                              (0.18 * 255).toInt(),
                            ),
                            blurRadius: 32,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 38,
                          vertical: 36,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        AnimatedBuilder(
                                          animation:
                                              _iconAnim ??
                                              const AlwaysStoppedAnimation(0.0),
                                          builder: (context, child) {
                                            return Transform.rotate(
                                              angle:
                                                  (_iconAnim ??
                                                          const AlwaysStoppedAnimation(
                                                            0.0,
                                                          ))
                                                      .value,
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.blueAccent
                                                          .withAlpha(
                                                            (0.25 * 255)
                                                                .toInt(),
                                                          ),
                                                      Colors.lightBlueAccent
                                                          .withAlpha(
                                                            (0.18 * 255)
                                                                .toInt(),
                                                          ),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.fitness_center,
                                                  color: Colors.lightBlueAccent,
                                                  size: 24,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            'Get a Membership Now',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 26,
                                      color: Colors.white,
                                    ),
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    tooltip: 'Close',
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Divider(
                                  thickness: 1.5,
                                  color: Colors.lightBlueAccent.withAlpha(
                                    (0.22 * 255).toInt(),
                                  ),
                                  height: 24,
                                  endIndent: 12,
                                  indent: 2,
                                ),
                              ),
                              if (_currentStep == 0) ...[
                                Column(
                                  children: [
                                    TextField(
                                      focusNode: _firstNameFocus,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'First Name',
                                        icon: Icons.person_outline,
                                        focusNode: _firstNameFocus,
                                        hintText: 'First Name',
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      focusNode: _middleNameFocus,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Middle Name',
                                        icon: Icons.person_outline,
                                        focusNode: _middleNameFocus,
                                        hintText: 'M.I.',
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      focusNode: _lastNameFocus,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: _inputDecoration(
                                        label: 'Last Name',
                                        icon: Icons.person_outline,
                                        focusNode: _lastNameFocus,
                                        hintText: 'Last Name',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  focusNode: _contactFocus,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Contact Number',
                                    icon: Icons.phone_outlined,
                                    focusNode: _contactFocus,
                                    hintText: '09XXXXXXXXX',
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  focusNode: _emailFocus,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Email',
                                    icon: Icons.email_outlined,
                                    focusNode: _emailFocus,
                                    hintText: 'example@email.com',
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      backgroundColor: const Color(0xFF1976D2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _currentStep = 1;
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Next',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                const Text(
                                  'Select Birthdate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Column(
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _selectedMonth,
                                      decoration: _inputDecoration(
                                        label: 'Month',
                                        icon: Icons.calendar_today,
                                        focusNode: null,
                                      ),
                                      dropdownColor: Colors.blueGrey[900],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      items:
                                          [
                                                'January',
                                                'February',
                                                'March',
                                                'April',
                                                'May',
                                                'June',
                                                'July',
                                                'August',
                                                'September',
                                                'October',
                                                'November',
                                                'December',
                                              ]
                                              .map(
                                                (month) => DropdownMenuItem(
                                                  value: month,
                                                  child: Text(month),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (val) => setState(
                                            () => _selectedMonth = val,
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<int>(
                                      value: _selectedDay,
                                      decoration: _inputDecoration(
                                        label: 'Day',
                                        icon: Icons.calendar_today,
                                        focusNode: null,
                                      ),
                                      dropdownColor: Colors.blueGrey[900],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      items:
                                          List.generate(31, (i) => i + 1)
                                              .map(
                                                (day) => DropdownMenuItem(
                                                  value: day,
                                                  child: Text(day.toString()),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (val) => setState(
                                            () => _selectedDay = val,
                                          ),
                                    ),
                                    const SizedBox(height: 14),
                                    DropdownButtonFormField<int>(
                                      value: _selectedYear,
                                      decoration: _inputDecoration(
                                        label: 'Year',
                                        icon: Icons.calendar_today,
                                        focusNode: null,
                                      ),
                                      dropdownColor: Colors.blueGrey[900],
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      items:
                                          List.generate(
                                                DateTime.now().year - 1949,
                                                (i) => 1950 + i,
                                              )
                                              .map(
                                                (year) => DropdownMenuItem(
                                                  value: year,
                                                  child: Text(year.toString()),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (val) => setState(
                                            () => _selectedYear = val,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  focusNode: _passFocus,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    focusNode: _passFocus,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscurePassword =
                                                    !_obscurePassword,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  focusNode: _rePassFocus,
                                  obscureText: _obscureRePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    label: 'Re-Enter Password',
                                    icon: Icons.lock_outline,
                                    focusNode: _rePassFocus,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureRePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscureRePassword =
                                                    !_obscureRePassword,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            backgroundColor: const Color(
                                              0xFF1976D2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _currentStep = 0;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            'Back',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            backgroundColor: const Color(
                                              0xFF1976D2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () {
                                            // Handle sign up logic here
                                          },
                                          child: const Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 15,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  const _AnimatedGradientButton({required this.onPressed, required this.child});

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 0.08,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withAlpha((0.28 * 255).toInt()),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}
