import 'package:biyuya/src/core/domain/entities/user_profile.dart';
import 'package:material_ui/material_ui.dart';

/// Shows a modal bottom sheet to select a household member or "all".
/// Returns the selected member [UserProfile.id], or `null` for "all".
Future<String?> showMemberFilterSheet(
  BuildContext context, {
  required List<UserProfile> members,
  String? selectedUuid,
}) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Todos'),
            trailing: selectedUuid == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context),
          ),
          ...members.map(
            (member) => ListTile(
              title: Text('${member.name} ${member.lastName}'),
              trailing: member.id == selectedUuid
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, member.id),
            ),
          ),
        ],
      ),
    ),
  );
}
