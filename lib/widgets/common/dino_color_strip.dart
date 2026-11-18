import 'package:material_ui/material_ui.dart';
import '../../models/dino.dart';
import '../../utils/dino_helpers.dart';

class DinoColorStrip extends StatelessWidget {
  final Dino dino;
  final double height;
  
  const DinoColorStrip({
    super.key, 
    required this.dino, 
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: List.generate(6, (i) {
          final id = DinoHelpers.getColorId(dino, i);
          final hex = DinoHelpers.getColorHex(dino, i);
          final isActive = id > 0 && DinoHelpers.isColorActive(hex);
          final color = isActive ? DinoHelpers.parseHex(hex) : const Color(0xFF222222);

          return Expanded(
            child: Container(
              height: height,
              margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isActive 
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
                  width: 1.5,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: color!.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ] : null,
              ),
              alignment: Alignment.center,
              child: Text(
                isActive ? '$id' : '-',
                style: TextStyle(
                  color: isActive
                    ? DinoHelpers.contrastText(color!)
                    : Colors.white.withValues(alpha: 0.3),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: isActive ? [
                    Shadow(
                      color: DinoHelpers.isLight(color!)
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.8),
                      blurRadius: 2,
                    ),
                  ] : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
