import 'package:flutter/material.dart';

class CatalogoCategoria {
  final String id;
  final String nombre;
  final IconData icono;
  final Color color;
  final String tipo; // 'ingreso'|'gasto'|'ambos'
  final String iconoKey; // clave para financeIconMap
  final String? parentId; // null = categoría padre

  const CatalogoCategoria({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.color,
    required this.tipo,
    required this.iconoKey,
    this.parentId,
  });
}

// Categorías padre (agrupadores)
const List<CatalogoCategoria> catalogoCategoriaPadres = [
  CatalogoCategoria(id: 'cat_ingresos_padre', nombre: 'Ingresos', icono: Icons.attach_money, color: Color(0xFF22C55E), tipo: 'ingreso', iconoKey: 'attach_money'),
  CatalogoCategoria(id: 'cat_alimentacion_padre', nombre: 'Alimentación', icono: Icons.restaurant_outlined, color: Color(0xFFF97316), tipo: 'gasto', iconoKey: 'restaurant'),
  CatalogoCategoria(id: 'cat_transporte_padre', nombre: 'Transporte', icono: Icons.directions_car_outlined, color: Color(0xFF3B82F6), tipo: 'gasto', iconoKey: 'directions_car'),
  CatalogoCategoria(id: 'cat_salud_padre', nombre: 'Salud', icono: Icons.local_hospital_outlined, color: Color(0xFFEF4444), tipo: 'gasto', iconoKey: 'local_hospital'),
  CatalogoCategoria(id: 'cat_vivienda_padre', nombre: 'Vivienda', icono: Icons.home_outlined, color: Color(0xFF8B5CF6), tipo: 'gasto', iconoKey: 'home'),
  CatalogoCategoria(id: 'cat_educacion_padre', nombre: 'Educación', icono: Icons.school_outlined, color: Color(0xFF06B6D4), tipo: 'gasto', iconoKey: 'school'),
  CatalogoCategoria(id: 'cat_ocio_padre', nombre: 'Ocio', icono: Icons.movie_outlined, color: Color(0xFFA855F7), tipo: 'gasto', iconoKey: 'movie'),
  CatalogoCategoria(id: 'cat_otros_padre', nombre: 'Otros', icono: Icons.more_horiz, color: Color(0xFF6B7280), tipo: 'ambos', iconoKey: 'more_horiz'),
];

const List<CatalogoCategoria> catalogoFinanzas = [
  // --- Ingresos (8) — padre: cat_ingresos_padre ---
  CatalogoCategoria(id: 'salario', nombre: 'Salario', icono: Icons.work_outline, color: Color(0xFF22C55E), tipo: 'ingreso', iconoKey: 'work', parentId: 'cat_ingresos_padre'),
  CatalogoCategoria(id: 'freelance', nombre: 'Freelance', icono: Icons.laptop_outlined, color: Color(0xFF10B981), tipo: 'ingreso', iconoKey: 'laptop', parentId: 'cat_ingresos_padre'),
  CatalogoCategoria(id: 'negocio', nombre: 'Negocio', icono: Icons.store_outlined, color: Color(0xFF059669), tipo: 'ingreso', iconoKey: 'store', parentId: 'cat_ingresos_padre'),
  CatalogoCategoria(id: 'arriendo_recibido', nombre: 'Arriendo recibido', icono: Icons.home_outlined, color: Color(0xFF16A34A), tipo: 'ingreso', iconoKey: 'home', parentId: 'cat_ingresos_padre'),
  CatalogoCategoria(id: 'intereses', nombre: 'Intereses', icono: Icons.trending_up, color: Color(0xFF15803D), tipo: 'ingreso', iconoKey: 'trending_up', parentId: 'cat_ingresos_padre'),
  CatalogoCategoria(id: 'regalo_ingreso', nombre: 'Regalo', icono: Icons.card_giftcard_outlined, color: Color(0xFF4ADE80), tipo: 'ingreso', iconoKey: 'card_giftcard', parentId: 'cat_ingresos_padre'),
  CatalogoCategoria(id: 'devolucion', nombre: 'Devolución', icono: Icons.swap_horiz_outlined, color: Color(0xFF86EFAC), tipo: 'ingreso', iconoKey: 'swap_horiz', parentId: 'cat_ingresos_padre'),
  CatalogoCategoria(id: 'otro_ingreso', nombre: 'Otro ingreso', icono: Icons.attach_money, color: Color(0xFF6EE7B7), tipo: 'ingreso', iconoKey: 'attach_money', parentId: 'cat_ingresos_padre'),
  // --- Alimentación — padre: cat_alimentacion_padre ---
  CatalogoCategoria(id: 'alimentacion', nombre: 'Alimentación', icono: Icons.restaurant_outlined, color: Color(0xFFF97316), tipo: 'gasto', iconoKey: 'restaurant', parentId: 'cat_alimentacion_padre'),
  CatalogoCategoria(id: 'restaurantes', nombre: 'Restaurantes', icono: Icons.restaurant_outlined, color: Color(0xFFEA580C), tipo: 'gasto', iconoKey: 'restaurant', parentId: 'cat_alimentacion_padre'),
  CatalogoCategoria(id: 'supermercado', nombre: 'Supermercado', icono: Icons.local_grocery_store_outlined, color: Color(0xFFFB923C), tipo: 'gasto', iconoKey: 'local_grocery_store', parentId: 'cat_alimentacion_padre'),
  // --- Transporte — padre: cat_transporte_padre ---
  CatalogoCategoria(id: 'transporte', nombre: 'Transporte', icono: Icons.directions_car_outlined, color: Color(0xFF3B82F6), tipo: 'gasto', iconoKey: 'directions_car', parentId: 'cat_transporte_padre'),
  // --- Salud — padre: cat_salud_padre ---
  CatalogoCategoria(id: 'salud', nombre: 'Salud', icono: Icons.local_hospital_outlined, color: Color(0xFFEF4444), tipo: 'gasto', iconoKey: 'local_hospital', parentId: 'cat_salud_padre'),
  // --- Vivienda — padre: cat_vivienda_padre ---
  CatalogoCategoria(id: 'vivienda', nombre: 'Vivienda', icono: Icons.home_outlined, color: Color(0xFF8B5CF6), tipo: 'gasto', iconoKey: 'home', parentId: 'cat_vivienda_padre'),
  CatalogoCategoria(id: 'servicios_publicos', nombre: 'Servicios', icono: Icons.bolt_outlined, color: Color(0xFFF59E0B), tipo: 'gasto', iconoKey: 'bolt', parentId: 'cat_vivienda_padre'),
  // --- Educación — padre: cat_educacion_padre ---
  CatalogoCategoria(id: 'educacion', nombre: 'Educación', icono: Icons.school_outlined, color: Color(0xFF06B6D4), tipo: 'gasto', iconoKey: 'school', parentId: 'cat_educacion_padre'),
  // --- Ocio — padre: cat_ocio_padre ---
  CatalogoCategoria(id: 'entretenimiento', nombre: 'Entretenimiento', icono: Icons.movie_outlined, color: Color(0xFFA855F7), tipo: 'gasto', iconoKey: 'movie', parentId: 'cat_ocio_padre'),
  CatalogoCategoria(id: 'viajes', nombre: 'Viajes', icono: Icons.flight_outlined, color: Color(0xFF0EA5E9), tipo: 'gasto', iconoKey: 'flight', parentId: 'cat_ocio_padre'),
  CatalogoCategoria(id: 'deporte', nombre: 'Deporte', icono: Icons.fitness_center_outlined, color: Color(0xFF10B981), tipo: 'gasto', iconoKey: 'fitness_center', parentId: 'cat_ocio_padre'),
  // --- Otros — padre: cat_otros_padre ---
  CatalogoCategoria(id: 'ropa', nombre: 'Ropa', icono: Icons.checkroom_outlined, color: Color(0xFFEC4899), tipo: 'gasto', iconoKey: 'checkroom', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'mascotas', nombre: 'Mascotas', icono: Icons.pets_outlined, color: Color(0xFFD97706), tipo: 'gasto', iconoKey: 'pets', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'tecnologia', nombre: 'Tecnología', icono: Icons.devices_outlined, color: Color(0xFF6366F1), tipo: 'gasto', iconoKey: 'devices', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'belleza', nombre: 'Belleza', icono: Icons.fitness_center_outlined, color: Color(0xFFF43F5E), tipo: 'gasto', iconoKey: 'fitness_center', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'regalos_gasto', nombre: 'Regalos', icono: Icons.card_giftcard_outlined, color: Color(0xFFE879F9), tipo: 'gasto', iconoKey: 'card_giftcard', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'ahorros', nombre: 'Ahorros', icono: Icons.savings_outlined, color: Color(0xFF14B8A6), tipo: 'gasto', iconoKey: 'savings', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'inversion', nombre: 'Inversión', icono: Icons.trending_up, color: Color(0xFF0D9488), tipo: 'gasto', iconoKey: 'trending_up', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'suscripciones', nombre: 'Suscripciones', icono: Icons.credit_card_outlined, color: Color(0xFF7C3AED), tipo: 'gasto', iconoKey: 'credit_card', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'cuidado_personal', nombre: 'Cuidado personal', icono: Icons.fitness_center_outlined, color: Color(0xFFDB2777), tipo: 'gasto', iconoKey: 'fitness_center', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'hogar', nombre: 'Hogar', icono: Icons.home_outlined, color: Color(0xFF92400E), tipo: 'gasto', iconoKey: 'home', parentId: 'cat_otros_padre'),
  CatalogoCategoria(id: 'otro_gasto', nombre: 'Otro gasto', icono: Icons.more_horiz, color: Color(0xFF6B7280), tipo: 'gasto', iconoKey: 'more_horiz', parentId: 'cat_otros_padre'),
];

/// Todas las categorías: padres + hijas
List<CatalogoCategoria> get todoCatalogo => [...catalogoCategoriaPadres, ...catalogoFinanzas];
