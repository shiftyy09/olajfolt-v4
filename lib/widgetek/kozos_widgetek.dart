import 'package:flutter/material.dart';

// === EZ A TE MEGLÉVŐ WIDGETED, VÁLTOZATLANUL HAGYVA ===
class KozosMenuKartya extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing; // Opcionális trailing widget (pl. a Switch-nek)

  const KozosMenuKartya({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      color: const Color(0xFF1E1E1E),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15.0),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Row(
            children: [
              // Dekorált Ikon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.6), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 2)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // Szövegek
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Trailing widget (ha van) vagy nyíl
              if (trailing != null)
                trailing!
              else
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// === EZ AZ ÚJ WIDGET, AMIRE SZÜKSÉG VAN A BEVITELI MEZŐKHÖZ ===
class KozosBemenetiKartya extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child; // Ez fogadja be a TextFormField-et, Dropdown-t, stb.
  final Color color;
  final EdgeInsets? padding;

  const KozosBemenetiKartya({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.color = Colors.orange,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      // Kisebb függőleges térköz, hogy jobban nézzen ki a listában
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: color.withOpacity(0.2), width: 1),
      ),
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: padding ??
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            // Dekorált Ikon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.6), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            // Cím és a beviteli mező (child)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  // Itt jelenik meg a beviteli mező (pl. TextFormField)
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}