import 'package:flutter/material.dart';

class CatalogoCategoria {
  final String id;
  final String nombre;
  final IconData icono;
  final Color color;
  final String tipo; // 'ingreso'|'gasto'|'ambos'

  const CatalogoCategoria({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
    required this.tipo,
  });
}

const List<CatalogoCategoria> catalogoFinanzas = [
  // --- Ingresos (8) ---
  CatalogoCategoria(id: 'salario', nombre: 'Salario', icono: Icons.work, color: Color(0xFF22C55E), tipo: 'ingreso'),
  CatalogoCategoria(id: 'freelance', nombre: 'Freelance', icono: Icons.laptop, color: Color(0xFF10B981), tipo: 'ingreso'),
  CatalogoCategoria(id: 'negocio', nombre: 'Negocio', icono: Icons.store, color: Color(0xFF059669), tipo: 'ingreso'),
  CatalogoCategoria(id: 'arriendo_recibido', nombre: 'Arriendo recibido', icono: Icons.home, color: Color(0xFF16A34A), tipo: 'ingreso'),
  CatalogoCategoria(id: 'intereses', nombre: 'Intereses', icono: Icons.trending_up, color: Color(0xFF15803D), tipo: 'ingreso'),
  CatalogoCategoria(id: 'regalo_ingreso', nombre: 'Regalo', icono: Icons.card_giftcard, color: Color(0xFF4ADE80), tipo: 'ingreso'),
  CatalogoCategoria(id: 'devolucion', nombre: 'Devolución', icono: Icons.undo, color: Color(0xFF86EFAC), tipo: 'ingreso'),
  CatalogoCategoria(id: 'otro_ingreso', nombre: 'Otro ingreso', icono: Icons.add_circle_outline, color: Color(0xFF6EE7B7), tipo: 'ingreso'),
  // --- Gastos (22) ---
  CatalogoCategoria(id: 'alimentacion', nombre: 'Alimentación', icono: Icons.restaurant, color: Color(0xFFF97316), tipo: 'gasto'),
  CatalogoCategoria(id: 'restaurantes', nombre: 'Restaurantes', icono: Icons.dining, color: Color(0xFFEA580C), tipo: 'gasto'),
  CatalogoCategoria(id: 'supermercado', nombre: 'Supermercado', icono: Icons.shopping_cart, color: Color(0xFFFB923C), tipo: 'gasto'),
  CatalogoCategoria(id: 'transporte', nombre: 'Transporte', icono: Icons.directions_bus, color: Color(0xFF3B82F6), tipo: 'gasto'),
  CatalogoCategoria(id: 'salud', nombre: 'Salud', icono: Icons.local_hospital, color: Color(0xFFEF4444), tipo: 'gasto'),
  CatalogoCategoria(id: 'vivienda', nombre: 'Vivienda', icono: Icons.house, color: Color(0xFF8B5CF6), tipo: 'gasto'),
  CatalogoCategoria(id: 'servicios_publicos', nombre: 'Servicios', icono: Icons.bolt, color: Color(0xFFF59E0B), tipo: 'gasto'),
  CatalogoCategoria(id: 'ropa', nombre: 'Ropa', icono: Icons.checkroom, color: Color(0xFFEC4899), tipo: 'gasto'),
  CatalogoCategoria(id: 'entretenimiento', nombre: 'Entretenimiento', icono: Icons.movie, color: Color(0xFFA855F7), tipo: 'gasto'),
  CatalogoCategoria(id: 'educacion', nombre: 'Educación', icono: Icons.school, color: Color(0xFF06B6D4), tipo: 'gasto'),
  CatalogoCategoria(id: 'viajes', nombre: 'Viajes', icono: Icons.flight, color: Color(0xFF0EA5E9), tipo: 'gasto'),
  CatalogoCategoria(id: 'mascotas', nombre: 'Mascotas', icono: Icons.pets, color: Color(0xFFD97706), tipo: 'gasto'),
  CatalogoCategoria(id: 'deporte', nombre: 'Deporte', icono: Icons.fitness_center, color: Color(0xFF10B981), tipo: 'gasto'),
  CatalogoCategoria(id: 'tecnologia', nombre: 'Tecnología', icono: Icons.devices, color: Color(0xFF6366F1), tipo: 'gasto'),
  CatalogoCategoria(id: 'belleza', nombre: 'Belleza', icono: Icons.face, color: Color(0xFFF43F5E), tipo: 'gasto'),
  CatalogoCategoria(id: 'regalos_gasto', nombre: 'Regalos', icono: Icons.redeem, color: Color(0xFFE879F9), tipo: 'gasto'),
  CatalogoCategoria(id: 'ahorros', nombre: 'Ahorros', icono: Icons.savings, color: Color(0xFF14B8A6), tipo: 'gasto'),
  CatalogoCategoria(id: 'inversion', nombre: 'Inversión', icono: Icons.show_chart, color: Color(0xFF0D9488), tipo: 'gasto'),
  CatalogoCategoria(id: 'suscripciones', nombre: 'Suscripciones', icono: Icons.subscriptions, color: Color(0xFF7C3AED), tipo: 'gasto'),
  CatalogoCategoria(id: 'cuidado_personal', nombre: 'Cuidado personal', icono: Icons.spa, color: Color(0xFFDB2777), tipo: 'gasto'),
  CatalogoCategoria(id: 'hogar', nombre: 'Hogar', icono: Icons.weekend, color: Color(0xFF92400E), tipo: 'gasto'),
  CatalogoCategoria(id: 'otro_gasto', nombre: 'Otro gasto', icono: Icons.more_horiz, color: Color(0xFF6B7280), tipo: 'gasto'),
];
