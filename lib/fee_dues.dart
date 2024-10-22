import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendFeeScreen extends StatefulWidget {
  @override
  _SendFeeScreenState createState() => _SendFeeScreenState();
}

class _SendFeeScreenState extends State<SendFeeScreen> {
  final TextEditingController _enrollmentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _paymentdate = TextEditingController();

  String? _status; // Variable to hold the selected status
  String? _paymentMode; // Variable to hold the selected payment mode
  final List<String> _statusOptions = ['Paid', 'Unpaid']; // Options for status
  final List<String> _paymentModeOptions = [
    'Online',
    'Offline'
  ]; // Options for payment mode

  void sendFee() async {
    String enrollmentNumber = _enrollmentController.text;
    double amount = double.parse(_amountController.text);
    String month = _monthController.text;
    String dueDate = _dueDateController.text;
    String description = _descriptionController.text;
    String paymentdate = _paymentdate.text;

    try {
      await FirebaseFirestore.instance
          .collection('fees')
          .doc(enrollmentNumber)
          .set({
        'amount': amount,
        'month': month,
        'due_date': dueDate,
        'status': _status ?? 'Unpaid', // Use selected status
        'description': description,
        'payment_date': paymentdate,
        'payment_mode': _paymentMode ?? 'Offline', // Use selected payment mode
        'receipt_no': '#${DateTime.now().millisecondsSinceEpoch}',
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fee sent successfully!'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to send fee: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _paymentdate.text =
            "${picked.toLocal()}".split(' ')[0]; // Format the date as needed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Send Fee')),
      body: Container(
        color: Colors.lightBlue[50], // Soft background color
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            // Allow scrolling if keyboard appears
            child: Column(
              children: [
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: _enrollmentController,
                          decoration: InputDecoration(
                            labelText: 'Enrollment Number',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            prefixIcon: Icon(Icons.money),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _dueDateController,
                          decoration: InputDecoration(
                            labelText: 'Last Date',
                            prefixIcon: Icon(Icons.date_range),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                        SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            _selectPaymentDate(context);
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _paymentdate,
                              decoration: InputDecoration(
                                labelText: 'Payment Date',
                                prefixIcon: Icon(Icons.date_range),
                              ),
                              readOnly: true, // Make the field read-only
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        // Dropdown for status
                        DropdownButtonFormField<String>(
                          value: _status,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            prefixIcon: Icon(Icons.info),
                          ),
                          items: _statusOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _status = value;
                            });
                          },
                        ),
                        SizedBox(height: 10),
                        // Dropdown for payment mode
                        DropdownButtonFormField<String>(
                          value: _paymentMode,
                          decoration: InputDecoration(
                            labelText: 'Payment Mode',
                            prefixIcon: Icon(Icons.payment),
                          ),
                          items: _paymentModeOptions.map((option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _paymentMode = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: sendFee,
                  child: Text('Send Fee'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
