import 'package:flutter/material.dart';


// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT  (remove if embedding into an existing app)
// ─────────────────────────────────────────────────────────────────────────────
void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true),
    home: const UpdateApplicationScreen(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const primary      = Color(0xFF2D3FE0);
  static const primaryLight = Color(0xFFEEF0FC);
  static const textDark     = Color(0xFF0F1020);
  static const textSub      = Color(0xFF5C5F7A);
  static const border       = Color(0xFFE8E9F0);
  static const bg           = Color(0xFFF5F6FA);
  static const white        = Color(0xFFFFFFFF);
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class UpdateApplicationScreen extends StatefulWidget {
  const UpdateApplicationScreen({super.key});
  @override
  State<UpdateApplicationScreen> createState() =>
      _UpdateApplicationScreenState();
}

class _UpdateApplicationScreenState extends State<UpdateApplicationScreen> {
  bool _includeResume = true;
  final _portfolioCtrl =
  TextEditingController(text: 'https://johndoe.design/portfolio');
  final _coverCtrl = TextEditingController(
    text: "I'm excited to apply for the Senior Product Designer role at TechFlow. "
        "With over 6 years of experience in creating user-centric digital products, "
        "I believe my skills in rapid prototyping and strategic design would be a "
        "great asset to your team.",
  );
  final List<String> _skills = [
    'UI Design',
    'Prototyping',
    'Figma',
    'User Research'
  ];

  @override
  void dispose() {
    _portfolioCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _addSkill() async {
    final result = await showDialog<String>(
        context: context, builder: (_) => _AddSkillDialog());
    if (result != null && result.trim().isNotEmpty) {
      setState(() => _skills.add(result.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _C.textDark),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Update Application',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _C.textDark)),
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _C.border)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Job card
                  _Pad(child: _JobCard()),
                  const SizedBox(height: 16),
                  // Resume / CV
                  _Pad(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                              title: 'Resume/CV',
                              actionLabel: 'Update',
                              onAction: () {}),
                          const SizedBox(height: 10),
                          _RadioOption(
                            selected: _includeResume,
                            label: 'Lee_resume_2026.pdf',
                            subtitle: 'Added about 9 hours ago',
                            onTap: () =>
                                setState(() => _includeResume = true),
                          ),
                          const SizedBox(height: 8),
                          _RadioOption(
                            selected: !_includeResume,
                            label: "Don't include a resume",
                            onTap: () =>
                                setState(() => _includeResume = false),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  // Portfolio link
                  _Pad(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(title: 'Portfolio Link'),
                          const SizedBox(height: 10),
                          _InputField(
                              controller: _portfolioCtrl,
                              prefixIcon: Icons.link_rounded),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  // Matched skills
                  _Pad(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                              title: 'Matched Skills',
                              actionLabel: '+ Add New',
                              onAction: _addSkill),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills
                                .map((s) => _SkillTag(
                              label: s,
                              onRemove: () =>
                                  setState(() => _skills.remove(s)),
                            ))
                                .toList(),
                          ),
                        ]),
                  ),
                  const SizedBox(height: 16),
                  // Cover letter
                  _Pad(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(title: 'Cover Letter'),
                          const SizedBox(height: 10),
                          _CoverLetterField(controller: _coverCtrl),
                        ]),
                  ),
                ]),
          ),
        ),
        // Bottom CTA
        Container(
          color: _C.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(children: [
            _PrimaryButton(
              label: 'Save Changes',
              trailing: const Icon(Icons.check_circle_outline_rounded,
                  color: _C.white, size: 18),
              onTap: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Text('Cancel Update',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _C.textSub)),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// JOB CARD
// ─────────────────────────────────────────────────────────────────────────────
class _JobCard extends StatelessWidget {
  const _JobCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _C.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _C.border),
    ),
    child: Row(children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
            color: _C.primaryLight,
            borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.business_center_rounded,
            color: _C.primary, size: 24),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Senior Product Designer',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark)),
              const SizedBox(height: 2),
              Text('TechFlow Inc.',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _C.primary)),
              const SizedBox(height: 2),
              Text('Applied Oct 24, 2023',
                  style: TextStyle(
                      fontSize: 11, color: _C.textSub)),
            ]),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _C.textDark)),
      if (actionLabel != null)
        GestureDetector(
          onTap: onAction,
          child: Text(actionLabel!,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _C.primary)),
        ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RADIO OPTION
// ─────────────────────────────────────────────────────────────────────────────
class _RadioOption extends StatelessWidget {
  final bool selected;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  const _RadioOption(
      {required this.selected,
        required this.label,
        this.subtitle,
        this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: selected ? _C.primary : _C.border, width: 1.5),
      ),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? _C.primary : Colors.transparent,
            border: Border.all(
                color: selected ? _C.primary : _C.border, width: 2),
          ),
          alignment: Alignment.center,
          child: selected
              ? Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: _C.white, shape: BoxShape.circle))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.textDark)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(
                          fontSize: 11, color: _C.textSub)),
                ],
              ]),
        ),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// INPUT FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData? prefixIcon;
  const _InputField({required this.controller, this.prefixIcon});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: TextStyle(
        fontSize: 13,
        color: _C.textDark,
        fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      filled: true,
      fillColor: _C.white,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _C.textSub, size: 18)
          : null,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: _C.border, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: _C.border, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: _C.primary, width: 1.5)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SKILL TAG
// ─────────────────────────────────────────────────────────────────────────────
class _SkillTag extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;
  const _SkillTag({required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: _C.primary,
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label,
          style: TextStyle(
              color: _C.white,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      const SizedBox(width: 6),
      GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded,
              color: _C.white, size: 14)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// COVER LETTER FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _CoverLetterField extends StatelessWidget {
  final TextEditingController controller;
  const _CoverLetterField({required this.controller});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLines: 6,
    style: TextStyle(
        fontSize: 12.5, color: _C.textDark, height: 1.6),
    decoration: InputDecoration(
      filled: true,
      fillColor: _C.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: _C.border, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: _C.border, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: _C.primary, width: 1.5)),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ADD SKILL DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class _AddSkillDialog extends StatelessWidget {
  _AddSkillDialog();
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text('Add Skill',
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _C.textDark)),
    content: TextField(
      controller: _ctrl,
      autofocus: true,
      style: TextStyle(
          fontSize: 13, color: _C.textDark),
      decoration: InputDecoration(
        hintText: 'e.g. Motion Design',
        hintStyle: TextStyle(color: _C.textSub),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
            const BorderSide(color: _C.primary, width: 1.5)),
      ),
      onSubmitted: (v) => Navigator.pop(context, v),
    ),
    actions: [
      TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: TextStyle(color: _C.textSub))),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, _ctrl.text),
        style: ElevatedButton.styleFrom(
            backgroundColor: _C.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: Text('Add',
            style: TextStyle(
                color: _C.white, fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal padding wrapper
class _Pad extends StatelessWidget {
  final Widget child;
  const _Pad({required this.child});
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: _C.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: _C.primary.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _C.white)),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!
                ],
              ]),
        ),
      ),
    ),
  );
}