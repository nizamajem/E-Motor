import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.length,
    required this.activeIndex,
    required this.activeColor,
  });

  final int length;
  final int activeIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(right: index == length - 1 ? 0 : 8),
          height: 8,
          width: isActive ? 28 : 10,
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFFDDE3EE),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
