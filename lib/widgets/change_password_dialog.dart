import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify/config/theme.dart';
import 'package:sportify/providers/auth_provider.dart';
import 'package:sportify/widgets/page_layout.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _hidden = [true, true, true];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await auth.changePassword(_current.text, _password.text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = auth.error ?? 'Couldn’t change your password. Try again.';
        });
      }
    }
  }

  Widget _field(
    int index,
    String label,
    TextEditingController controller,
    String? Function(String?) validator,
  ) => TextFormField(
    controller: controller,
    enabled: !_saving,
    obscureText: _hidden[index],
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [
      index == 0 ? AutofillHints.password : AutofillHints.newPassword,
    ],
    textInputAction: index == 2 ? TextInputAction.done : TextInputAction.next,
    onFieldSubmitted: index == 2 ? (_) => _submit() : null,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: _hidden[index] ? 'Show $label' : 'Hide $label',
        onPressed: _saving
            ? null
            : () => setState(() => _hidden[index] = !_hidden[index]),
        icon: Icon(
          _hidden[index]
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      ),
    ),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      scrollable: true,
      icon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
      title: const Text('Change password'),
      content: SizedBox(
        width: 400,
        child: AutofillGroup(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Confirm your current password, then choose a new one with at least 8 characters.',
                ),
                const SizedBox(height: 20),
                _field(
                  0,
                  'Current password',
                  _current,
                  (value) => value == null || value.isEmpty
                      ? 'Enter your current password'
                      : null,
                ),
                const SizedBox(height: 14),
                _field(1, 'New password', _password, (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters';
                  }
                  if (value == _current.text) {
                    return 'Choose a different password';
                  }
                  return null;
                }),
                const SizedBox(height: 14),
                _field(
                  2,
                  'Confirm new password',
                  _confirmation,
                  (value) =>
                      value != _password.text || value == null || value.isEmpty
                      ? 'Passwords don’t match'
                      : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: ActionLabel(
            busy: _saving,
            label: 'Update password',
            busyLabel: 'Updating…',
          ),
        ),
      ],
    ),
  );
}
