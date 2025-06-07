import 'package:flutter/material.dart';
import 'profile_data.dart';

class AddressWidget extends StatefulWidget {
  final ProfileData profileData;
  final void Function({
    required String address,
    required String street,
    required String city,
    required String stateProvince,
    required String postalCode,
    required String country,
  })
  onSave;

  const AddressWidget({
    Key? key,
    required this.profileData,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AddressWidget> createState() => _AddressWidgetState();
}

class _AddressWidgetState extends State<AddressWidget> {
  late TextEditingController _addressController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateProvinceController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.profileData.address ?? '',
    );
    _streetController = TextEditingController(
      text: widget.profileData.street ?? '',
    );
    _cityController = TextEditingController(
      text: widget.profileData.city ?? '',
    );
    _stateProvinceController = TextEditingController(
      text: widget.profileData.stateProvince ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.profileData.postalCode ?? '',
    );
    _countryController = TextEditingController(
      text: widget.profileData.country ?? '',
    );
  }

  bool get _hasAddressChanges {
    return _addressController.text != (widget.profileData.address ?? '') ||
        _streetController.text != (widget.profileData.street ?? '') ||
        _cityController.text != (widget.profileData.city ?? '') ||
        _stateProvinceController.text !=
            (widget.profileData.stateProvince ?? '') ||
        _postalCodeController.text != (widget.profileData.postalCode ?? '') ||
        _countryController.text != (widget.profileData.country ?? '');
  }

  void _cancel() {
    setState(() {
      _addressController.text = widget.profileData.address ?? '';
      _streetController.text = widget.profileData.street ?? '';
      _cityController.text = widget.profileData.city ?? '';
      _stateProvinceController.text = widget.profileData.stateProvince ?? '';
      _postalCodeController.text = widget.profileData.postalCode ?? '';
      _countryController.text = widget.profileData.country ?? '';
    });
  }

  void _save() {
    widget.onSave(
      address: _addressController.text,
      street: _streetController.text,
      city: _cityController.text,
      stateProvince: _stateProvinceController.text,
      postalCode: _postalCodeController.text,
      country: _countryController.text,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _addressController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateProvinceController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Widget _buildLabel(String label, [double fontSize = 15.0]) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: fontSize,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hintText, {
    double fontSize = 16.0,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.black87, width: 1.5),
        ),
      ),
      style: TextStyle(fontSize: fontSize, color: Colors.black87),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelFontSize = 15.0;
    final textFieldFontSize = 16.0;
    final buttonPadding = EdgeInsets.symmetric(vertical: 18);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Address Information', 18.0),
        SizedBox(height: 8),
        _buildLabel('Address', labelFontSize),
        _buildTextField(
          _addressController,
          'Address',
          fontSize: textFieldFontSize,
        ),
        SizedBox(height: 14),
        _buildLabel('Street', labelFontSize),
        _buildTextField(
          _streetController,
          'Street',
          fontSize: textFieldFontSize,
        ),
        SizedBox(height: 14),
        _buildLabel('City', labelFontSize),
        _buildTextField(_cityController, 'City', fontSize: textFieldFontSize),
        SizedBox(height: 14),
        _buildLabel('State / Province', labelFontSize),
        _buildTextField(
          _stateProvinceController,
          'State / Province',
          fontSize: textFieldFontSize,
        ),
        SizedBox(height: 14),
        _buildLabel('Postal Code', labelFontSize),
        _buildTextField(
          _postalCodeController,
          'Postal Code',
          fontSize: textFieldFontSize,
        ),
        SizedBox(height: 14),
        _buildLabel('Country', labelFontSize),
        _buildTextField(
          _countryController,
          'Country',
          fontSize: textFieldFontSize,
        ),
        SizedBox(height: 24),
        if (_hasAddressChanges)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: buttonPadding,
                  ),
                  onPressed: _cancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: buttonPadding,
                  ),
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
