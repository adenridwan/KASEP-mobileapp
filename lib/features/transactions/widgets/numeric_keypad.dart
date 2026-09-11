import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onKeyPress;
  final VoidCallback onSave;

  const NumericKeypad({
    super.key,
    required this.onKeyPress,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
              _buildKey('000', isSmall: true, rowSpan: true),
            ],
          ),
          Row(children: [_buildKey('4'), _buildKey('5'), _buildKey('6')]),
          Row(
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
              _buildKey('del', isDelete: true),
            ],
          ),
          Row(children: [_buildKey('0', colSpan: 2), _buildSaveButton()]),
        ],
      ),
    );
  }

  Widget _buildKey(
    String value, {
    bool isSmall = false,
    bool isDelete = false,
    bool rowSpan = false,
    int colSpan = 1,
  }) {
    return Expanded(
      flex: colSpan,
      child: Padding(
        padding: const EdgeInsets.all(4.5),
        child: Material(
          color: isDelete ? Colors.transparent : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () => onKeyPress(value),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: rowSpan ? 110 : 48,
              decoration: BoxDecoration(
                color: isDelete ? Colors.transparent : AppColors.neutral200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: isDelete
                    ? Icon(
                        Icons.backspace_outlined,
                        color: AppColors.neutral700,
                        size: 20,
                      )
                    : Text(
                        value,
                        style: TextStyle(
                          fontSize: isSmall ? 15 : 22,
                          fontWeight: FontWeight.w600,
                          color: isSmall
                              ? AppColors.neutral700
                              : AppColors.text,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Expanded(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(4.5),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onSave,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Simpan catatan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
