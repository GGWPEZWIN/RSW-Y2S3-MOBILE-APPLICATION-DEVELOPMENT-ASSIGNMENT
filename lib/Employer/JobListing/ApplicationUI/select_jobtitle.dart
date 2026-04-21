import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SelectJobTitlePage
// Shown AFTER the user picks an industry. They can tap a suggested title OR
// type their own, then tap Continue to go back into the main create-job flow.
// ─────────────────────────────────────────────────────────────────────────────

class SelectJobTitlePage extends StatefulWidget {
  final String industryName;
  final List<String> suggestedTitles;
  final String? initialTitle; // pre-fill when editing

  const SelectJobTitlePage({
    super.key,
    required this.industryName,
    required this.suggestedTitles,
    this.initialTitle,
  });

  @override
  State<SelectJobTitlePage> createState() => _SelectJobTitlePageState();
}

class _SelectJobTitlePageState extends State<SelectJobTitlePage> {
  static const Color _primaryBlue  = Color(0xFF3B4FD8);
  static const Color _borderColor  = Color(0xFFDDDDDD);
  static const Color _fillColor    = Color(0xFFFAFAFA);
  static const Color _labelColor   = Color(0xFF1A1A2E);
  static const Color _hintColor    = Color(0xFFAAAAAA);
  static const Color _helperColor  = Color(0xFF888888);

  late TextEditingController _customTitleController;
  String _selectedTitle = '';

  @override
  void initState() {
    super.initState();
    _customTitleController = TextEditingController(text: widget.initialTitle ?? '');
    _selectedTitle = widget.initialTitle ?? '';
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    super.dispose();
  }

  bool get _canContinue => _customTitleController.text.trim().isNotEmpty;

  void _onSuggestionTap(String title) {
    setState(() {
      _selectedTitle = title;
      _customTitleController.text = title;
      _customTitleController.selection = TextSelection.fromPosition(
        TextPosition(offset: title.length),
      );
    });
  }

  void _onContinue() {
    final title = _customTitleController.text.trim();
    if (title.isEmpty) return;
    Navigator.pop(context, title); // return the chosen title
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Job Title',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Industry badge ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.business_center_rounded,
                          size: 18, color: _primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.industryName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // ── Custom title input ──────────────────────────────────
                  const Text(
                    'Job Title',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _labelColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customTitleController,
                    onChanged: (v) => setState(() => _selectedTitle = v),
                    decoration: InputDecoration(
                      hintText: 'Type or select a job title below…',
                      hintStyle:
                      const TextStyle(color: _hintColor, fontSize: 13),
                      prefixIcon: const Icon(Icons.edit_note_rounded,
                          color: _primaryBlue),
                      suffixIcon: _customTitleController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 18, color: Colors.grey),
                        onPressed: () => setState(() {
                          _customTitleController.clear();
                          _selectedTitle = '';
                        }),
                      )
                          : null,
                      filled: true,
                      fillColor: _fillColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: _primaryBlue, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Suggested titles ────────────────────────────────────
                  if (widget.suggestedTitles.isNotEmpty) ...[
                    Row(children: const [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 15, color: Color(0xFFE07B39)),
                      SizedBox(width: 6),
                      Text(
                        'Suggested for this industry',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE07B39),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.suggestedTitles.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      itemBuilder: (context, index) {
                        final title = widget.suggestedTitles[index];
                        final isSelected = _selectedTitle == title;
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _onSuggestionTap(title),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 14),
                            child: Row(children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? _primaryBlue
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? _primaryBlue
                                        : _borderColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded,
                                    size: 13, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? _primaryBlue
                                        : _labelColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: _primaryBlue),
                            ]),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),

          // ── Sticky Continue button ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _canContinue ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  disabledBackgroundColor: const Color(0xFFBEC8F5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _canContinue
                      ? 'Continue with "${ _customTitleController.text.trim()}"'
                      : 'Select or type a job title',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}