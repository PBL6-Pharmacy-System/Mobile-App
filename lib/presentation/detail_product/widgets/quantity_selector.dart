import 'package:flutter/material.dart';
import 'package:pharmacy_app/configs/common.dart';

class QuantitySelector extends StatefulWidget {
  final int initialValue;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const QuantitySelector({
    super.key,
    this.initialValue = 1,
    this.min = 1,
    this.max = 99,
    required this.onChanged,
  });

  @override
  State<QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  late int quantity;

  @override
  void initState() {
    super.initState();
    quantity = widget.initialValue;
  }

  void _increase() {
    if (quantity < widget.max) {
      setState(() => quantity++);
      widget.onChanged(quantity);
    }
  }

  void _decrease() {
    if (quantity > widget.min) {
      setState(() => quantity--);
      widget.onChanged(quantity);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: radius8,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: InkWell(onTap: _decrease, child: const Icon(Icons.remove)),
          ),
          Expanded(
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: InkWell(onTap: _increase, child: const Icon(Icons.add)),
          ),
        ],
      ),
    );
  }
}
