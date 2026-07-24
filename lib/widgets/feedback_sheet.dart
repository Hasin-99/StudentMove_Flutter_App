import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/auth_provider.dart';
import '../services/feedback_repository.dart';
import '../theme/app_theme.dart';

Future<void> showFeedbackSheet(BuildContext context, AppStrings s) {
  final uid = context.read<AuthProvider>().userId;
  context.read<FeedbackRepository>().bindUser(uid);
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
  final _subject = TextEditingController();
  final _text = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _subject.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final repo = context.read<FeedbackRepository>();
    final ok = await repo.submit(
      subject: _subject.text.trim().isEmpty ? 'App feedback' : _subject.text.trim(),
      message: _text.text,
      rating: _rating,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.strings.isBangla
                ? 'মতামত জমা হয়েছে। ধন্যবাদ!'
                : 'Feedback submitted. Thank you!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(repo.lastError ?? 'Could not submit')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final history = context.watch<FeedbackRepository>().items;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.96,
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
                style: GoogleFonts.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.isBangla
                    ? 'রেটিং দিন এবং আপনার অভিজ্ঞতা লিখুন'
                    : 'Rate your ride and tell the team what to improve',
                style: GoogleFonts.ibmPlexSans(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Text(
                s.isBangla ? 'রেটিং' : 'Rating',
                style: GoogleFonts.ibmPlexSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.accent,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subject,
                decoration: InputDecoration(
                  labelText: s.isBangla ? 'বিষয়' : 'Subject',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _text,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: s.describe,
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(s.submit),
                ),
              ),
              if (history.isNotEmpty) ...[
                const SizedBox(height: 28),
                Text(
                  s.isBangla ? 'ইতিহাস' : 'Your feedback',
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...history.map(
                  (f) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                f.subject,
                                style: GoogleFonts.ibmPlexSans(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '${f.rating}★',
                              style: GoogleFonts.ibmPlexSans(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(f.message),
                        if (f.reply != null && f.reply!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            s.isBangla ? 'টিম রিপ্লাই' : 'Team reply',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brand,
                            ),
                          ),
                          Text(f.reply!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
