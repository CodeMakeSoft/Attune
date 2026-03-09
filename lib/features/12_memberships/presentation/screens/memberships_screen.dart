import 'package:flutter/material.dart';

class MembershipsScreen extends StatelessWidget {
  const MembershipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Fondo oscuro profundo
      appBar: AppBar(
        title: const Text('Membresías', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Elige el plan ideal para tu empresa',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlanCard(
                    title: 'Prueba',
                    price: '\$0',
                    subtitle: '15 DÍAS',
                    features: ['Hasta 2 empleados', 'Funciones básicas'],
                  ),
                  _buildPlanCard(
                    title: 'Bronce',
                    price: '\$99',
                    unit: '/mes',
                    subtitle: 'MICROEMPRESAS',
                    features: ['1 a 8 empleados', 'Ideal para iniciar'],
                  ),
                  _buildPlanCard(
                    title: 'Plata',
                    price: '\$129',
                    unit: '/mes',
                    subtitle: 'PYMES',
                    isPopular: true,
                    features: ['1 a 50 empleados', 'Módulo de Evaluaciones'],
                  ),
                  _buildPlanCard(
                    title: 'Oro',
                    price: '\$299',
                    unit: '/mes',
                    subtitle: 'CORPORATIVO',
                    features: ['+250 empleados', 'Gestión Avanzada', 'Departamentos'],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                '* Precios informativos. El pago se gestiona directamente con un asesor de Attune.',
                style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    String? unit,
    required String subtitle,
    required List<String> features,
    bool isPopular = false,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Card background
        borderRadius: BorderRadius.circular(20),
        border: isPopular 
          ? Border.all(color: const Color(0xFF00E5FF), width: 2)
          : Border.all(color: Colors.white10),
        boxShadow: [
          if (isPopular)
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'MÁS POPULAR',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 2),
                  child: Text(
                    unit,
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10, thickness: 1.5),
          const SizedBox(height: 20),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.check, color: Color(0xFF00E5FF), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    f,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          )).toList(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isPopular ? const Color(0xFF00E5FF) : Colors.white10,
              foregroundColor: isPopular ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 45),
              elevation: 0,
            ),
            child: Text(title == 'Prueba' ? 'Elegir' : 'Consultar'),
          ),
        ],
      ),
    );
  }
}
