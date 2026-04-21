import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'interactive_motion.dart';

Future<void> showFeedbackSheet(BuildContext context, AppStrings s) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _FeedbackBody(strings: s),
  );
}

class _FeedbackBody extends StatefulWidget {
  const _FeedbackBody({required this.strings});

  final AppStrings strings;

  @override
  State<_FeedbackBody> createState() => _FeedbackBodyState();
}

class _FeedbackBodyState extends State<_FeedbackBody> {
  String _category = 'bug';
  final _text = TextEditingController();
  final _picker = ImagePicker();
  String? _imageName;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottom),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                s.feedbackTitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.category,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'bug', label: Text(s.bug)),
                  ButtonSegment(value: 'suggestion', label: Text(s.suggestion)),
                  ButtonSegment(value: 'complaint', label: Text(s.complaint)),
                ],
                selected: {_category},
                onSelectionChanged: (set) => setState(() => _category = set.first),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _text,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: s.describe,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              MotionButtonTap(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final img = await _picker.pickImage(source: ImageSource.gallery);
                    if (img != null) {
                      setState(() => _imageName = img.name);
                    }
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(s.addPhoto),
                ),
              ),
              if (_imageName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _imageName!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              MotionButtonTap(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            s.isBangla
                                ? 'মতামত সার্ভারে সংযুক্ত হলে জমা হবে।'
                                : 'Feedback submission will be connected in a future release.',
                          ),
                        ),
                      );
                    },
                    child: Text(s.submit),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
