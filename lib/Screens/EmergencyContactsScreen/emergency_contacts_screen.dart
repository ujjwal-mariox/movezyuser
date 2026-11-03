import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:movezy_user_app/CommonWidgets/app_bar.dart';
import 'package:movezy_user_app/CommonWidgets/button_widget.dart';
import 'package:movezy_user_app/Services/account_service.dart';
import 'package:movezy_user_app/Utils/AppColors/app_colors.dart';
import 'package:movezy_user_app/Utils/CustomToast/custome_toast.dart';

const _ink = Color(0xFF14233B);
const _muted = Color(0xFF6B7A90);
const _maxContacts = 5;

const _relationships = {
  'PARENT': 'Parent',
  'SPOUSE': 'Spouse',
  'SIBLING': 'Sibling',
  'FRIEND': 'Friend',
  'OTHER': 'Other',
};

/// The people an SOS texts, with a map pin of where it was raised. Before this
/// screen existed nobody could add any, so an SOS reached only the Movezy
/// safety team.
class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact>? _contacts;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await AccountService.contacts();
    if (!mounted) return;
    setState(() {
      _contacts = list;
      _loading = false;
    });
  }

  Future<void> _remove(EmergencyContact c) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove contact?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        content: Text("${c.name} won't be texted if you press SOS.",
            style: const TextStyle(fontSize: 13.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: TextStyle(color: AppColors.appColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (yes != true) return;
    final ok = await AccountService.deleteContact(c.id);
    if (!mounted) return;
    if (!ok) showCustomToast(context, "Couldn't remove the contact. Try again.");
    _load();
  }

  Future<void> _add() async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddContactSheet(),
    );
    if (added == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _contacts ?? const <EmergencyContact>[];
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          commonAppBar(
            height: 100,
            context: context,
            child: Container(
              padding: const EdgeInsets.only(top: 45),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      width: 40,
                      height: 35,
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                  ),
                  const Text(
                    'Emergency contacts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: AppColors.appColor))
                : _contacts == null
                    ? Center(
                        child: TextButton(
                          onPressed: _load,
                          child: Text("Couldn't load contacts. Try again",
                              style: TextStyle(color: AppColors.appColor)),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: [
                          const Text(
                            "If you press SOS, we text these people your location "
                            "straight away. They aren't contacted otherwise.",
                            style: TextStyle(fontSize: 13.5, height: 1.45, color: _muted),
                          ),
                          const SizedBox(height: 16),
                          if (contacts.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 28),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 26,
                                    backgroundColor: const Color(0xFFFCEDE4),
                                    child: Icon(Icons.contact_emergency_outlined,
                                        color: AppColors.appColor, size: 26),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text('No emergency contacts yet',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600, color: _ink)),
                                ],
                              ),
                            ),
                          for (final c in contacts)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE6EEF2)),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFFCEDE4),
                                    child: Text(
                                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                                      style: TextStyle(
                                          color: AppColors.appColor,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: _ink)),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${c.phone}  ·  ${_relationships[c.relationship] ?? 'Other'}',
                                          style: const TextStyle(fontSize: 12.5, color: _muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove',
                                    onPressed: () => _remove(c),
                                    icon: const Icon(Icons.delete_outline, color: _muted),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (contacts.length < _maxContacts)
                            ButtonWidget(text: 'Add a contact', onTap: _add)
                          else
                            const Text('You can add up to 5 contacts.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12.5, color: _muted)),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet();

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String _relationship = 'PARENT';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty) return setState(() => _error = 'Enter a name.');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      return setState(() => _error = 'Enter a 10-digit mobile number.');
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await AccountService.addContact(
        name: name, phone: phone, relationship: _relationship);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  InputDecoration _field(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.appColor, width: 1.5),
        ),
        floatingLabelStyle: TextStyle(color: AppColors.appColor),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Add emergency contact',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: _field('Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _field('Mobile number'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _relationship,
            decoration: _field('Relationship'),
            items: [
              for (final e in _relationships.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _relationship = v ?? 'OTHER'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Color(0xFFE02D3C), fontSize: 12.5)),
          ],
          const SizedBox(height: 18),
          ButtonWidget(text: _saving ? 'Saving…' : 'Save contact', onTap: _saving ? null : _save),
        ],
      ),
    );
  }
}
