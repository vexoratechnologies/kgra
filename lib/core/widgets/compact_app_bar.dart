import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Reusable Custom Compact App Bar matching the KGRA Internal App Bar specification.
class CompactAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? rightIcon;
  final VoidCallback? onRightTap;
  final Widget? rightAction;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color iconColor;
  final Color waveColor;

  const CompactAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.rightIcon,
    this.onRightTap,
    this.rightAction,
    this.showBackButton = true,
    this.onBackTap,
    this.backgroundColor = Colors.white,
    this.titleColor = const Color(0xFF1B1B1B),
    this.subtitleColor = const Color(0xFF757575),
    this.iconColor = const Color(0xFF8B1E2D),
    this.waveColor = const Color(0xFFFFE9ED),
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64.0,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Background soft wave accent spanning the full width & height of the bar
              Positioned.fill(
                child: CustomPaint(
                  painter: _AppBarWavePainter(waveColor: waveColor),
                ),
              ),
              // Padded content row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (showBackButton) ...[
                      _buildCircularIconButton(
                        context: context,
                        icon: Icons.arrow_back,
                        onTap: onBackTap ??
                            () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else if (context.canPop()) {
                                context.pop();
                              }
                            },
                      ),
                      const SizedBox(width: 14.0),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                              color: titleColor,
                              height: 1.2,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2.0),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: subtitleColor,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (rightAction != null)
                      rightAction!
                    else if (rightIcon != null) ...[
                      const SizedBox(width: 12.0),
                      _buildCircularIconButton(
                        context: context,
                        icon: rightIcon!,
                        onTap: onRightTap,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIconButton({
    required BuildContext context,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36.0,
          height: 36.0,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.06),
                blurRadius: 8.0,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 20.0,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

class _AppBarWavePainter extends CustomPainter {
  final Color waveColor;

  _AppBarWavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Broad soft background wave fill (covers right ~65% of the bar width)
    final fillPaint = Paint()
      ..color = waveColor.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final path1 = Path();
    path1.moveTo(width * 0.32, 0);
    path1.cubicTo(
      width * 0.55, height * 0.10,
      width * 0.40, height * 0.90,
      width * 0.70, height,
    );
    path1.lineTo(width, height);
    path1.lineTo(width, 0);
    path1.close();
    canvas.drawPath(path1, fillPaint);

    // 2. Secondary soft accent wave layer (maroon tint with 8% opacity)
    final accentPaint = Paint()
      ..color = const Color(0xFF8B1E2D).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(width * 0.45, 0);
    path2.cubicTo(
      width * 0.68, height * 0.20,
      width * 0.52, height * 0.85,
      width, height * 0.70,
    );
    path2.lineTo(width, 0);
    path2.close();
    canvas.drawPath(path2, accentPaint);

    // 3. Smooth flowing curve line 1
    final strokePaint1 = Paint()
      ..color = const Color(0xFF8B1E2D).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final linePath1 = Path();
    linePath1.moveTo(width * 0.30, 0);
    linePath1.cubicTo(
      width * 0.52, height * 0.15,
      width * 0.38, height * 0.85,
      width * 0.72, height,
    );
    canvas.drawPath(linePath1, strokePaint1);

    // 4. Smooth flowing curve line 2
    final strokePaint2 = Paint()
      ..color = const Color(0xFF8B1E2D).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final linePath2 = Path();
    linePath2.moveTo(width * 0.38, 0);
    linePath2.cubicTo(
      width * 0.60, height * 0.25,
      width * 0.48, height * 0.95,
      width, height * 0.80,
    );
    canvas.drawPath(linePath2, strokePaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
