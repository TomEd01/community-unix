import 'package:flutter/material.dart';
import 'unix_theme.dart';

/// En escritorio el panel de presentación queda fijo. Solo el formulario
/// tiene ScrollController. En móvil se apila dentro de un único desplazamiento.
class UnixRegistrationLayout extends StatefulWidget {
  const UnixRegistrationLayout({
    super.key,
    required this.header,
    required this.intro,
    required this.compactIntro,
    required this.form,
    this.formHeader,
  });
  final Widget header;
  final Widget intro;
  final Widget compactIntro;
  final Widget form;
  final Widget? formHeader;

  @override
  State<UnixRegistrationLayout> createState() => _UnixRegistrationLayoutState();
}

class _UnixRegistrationLayoutState extends State<UnixRegistrationLayout> {
  final _formScroll = ScrollController();

  @override
  void dispose() {
    _formScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UnixTheme.watch(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        final padding = constraints.maxHeight < 560 ? 10.0 : 20.0;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 28 : 14,
            vertical: padding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: Column(
                children: [
                  widget.header,
                  SizedBox(height: padding),
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: UnixColors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: UnixColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: UnixColors.dark ? 0.15 : 0.06,
                            ),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: wide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 3, child: widget.intro),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (widget.formHeader != null)
                                        widget.formHeader!,
                                      Expanded(
                                        child: _scrollable(
                                          widget.form,
                                          showThumb: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : _scrollable(
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  widget.compactIntro,
                                  if (widget.formHeader != null)
                                    widget.formHeader!,
                                  widget.form,
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _scrollable(Widget child, {bool showThumb = false}) => Scrollbar(
    controller: _formScroll,
    thumbVisibility: showThumb,
    child: SingleChildScrollView(
      key: const ValueKey('registration-form-scroll'),
      controller: _formScroll,
      primary: false,
      child: child,
    ),
  );
}
