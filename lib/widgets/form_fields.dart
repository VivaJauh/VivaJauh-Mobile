import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';

double? parseFlexibleNumber(String raw) {
  final cleaned = raw.trim().replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(cleaned);
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {this.required = true, super.key});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            fontSize: 13,
          ),
          children: [
            TextSpan(text: text),
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.danger),
              ),
          ],
        ),
      ),
    );
  }
}

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    required this.label,
    required this.controller,
    this.required = true,
    this.hint,
    this.helper,
    this.maxLines = 1,
    this.keyboardType,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final String? hint;
  final String? helper;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
              : null,
          decoration: InputDecoration(hintText: hint, helperText: helper),
        ),
      ],
    );
  }
}

class NoteField extends StatelessWidget {
  const NoteField({required this.controller, this.label = 'Catatan', super.key});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return LabeledTextField(
      label: label,
      controller: controller,
      required: false,
      maxLines: 3,
      hint: 'Opsional',
    );
  }
}

class QtyField extends StatelessWidget {
  const QtyField({
    required this.label,
    required this.controller,
    this.suffix,
    this.helper,
    this.allowDecimal = true,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? suffix;
  final String? helper;
  final bool allowDecimal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '$label wajib diisi';
            final parsed = parseFlexibleNumber(v);
            if (parsed == null || parsed <= 0) return 'Masukkan angka yang valid';
            return null;
          },
          decoration: InputDecoration(
            suffixText: suffix,
            helperText: helper,
          ),
        ),
      ],
    );
  }
}

class RupiahField extends StatelessWidget {
  const RupiahField({
    required this.label,
    required this.controller,
    this.helper,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return '$label wajib diisi';
            final parsed = int.tryParse(v);
            if (parsed == null || parsed <= 0) return 'Masukkan jumlah yang valid';
            return null;
          },
          decoration: InputDecoration(
            prefixText: 'Rp ',
            helperText: helper,
          ),
        ),
      ],
    );
  }
}

class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.required = true,
    this.hint,
    super.key,
  });

  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        DropdownButtonFormField<T>(
          // ignore: deprecated_member_use
          value: value,
          isExpanded: true,
          validator: required
              ? (v) => v == null ? '$label wajib dipilih' : null
              : null,
          hint: hint != null ? Text(hint!) : null,
          decoration: const InputDecoration(),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(itemLabel(item)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class FormSubmitButton extends StatelessWidget {
  const FormSubmitButton({
    required this.label,
    required this.onPressed,
    this.saving = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: saving ? null : onPressed,
      child: saving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(label),
    );
  }
}

class OfflineHintCard extends StatelessWidget {
  const OfflineHintCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Catatan disimpan lokal dulu, sinkronisasi otomatis saat ada koneksi.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.primaryDark,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
