# Directrices de diseño gráfico del tema

## Principios

* **Arte primero:** la UI es neutra; el color lo ponen las obras.
* **Editorial:** tipografía clara, mayúsculas en overlines/títulos de sección.
* **Silencio visual:** sin sombras, sin degradados; márgenes generosos.

## Tokens

* **Tipografía (stack):** `system-ui, -apple-system, "Segoe UI", Roboto, Inter, Arial, sans-serif`
* **Escala:**

  * H1: 48–64 / 600 / tracking +0.02em
  * H2: 32–40 / 600
  * H3: 24–28 / 500
  * Body: 16–18 / 400
  * Overline: 12–14 / 500 / **uppercase** / tracking +0.08em
* **Colores:**

  * Fondo: #FFFFFF
  * Texto: #111111
  * Secundario: #666666
  * Bordes: #EDEDED
  * Estados (hover): opacidad 80% o subrayado fino
* **Espaciado:** escala 8 px (8/16/24/32/48/64)
* **Contenedor:** 1200–1320 px, padding lateral 24–32 px

## Componentes (UI)

* **Header / Nav primaria** (uppercase en 1er nivel).
* **Breadcrumbs** minimal.
* **Cards** (obra/producto): imagen dominante, título 1 línea, precio; ratio consistente (1:1 o 4:5).
* **Grids**: 4 col (desktop), 2 (tablet), 1 (móvil).
* **Ficha de producto**: galería izq., meta+CTAs der.; para **prints** selector de **tamaño** + texto de **edición limitada**.
* **Chips** de categorías/etiquetas enlazables (SEO).
* **Formularios** (contacto, oferta, newsletter): bordes 1 px #EDEDED; focus #111 (2 px).
* **Modales** (oferta/inquire).
* **Footer** con newsletter y enlaces legales.

## Accesibilidad

* Contraste mínimo 4.5:1.
* Focus visible en enlaces/botones.
* Objetivos táctiles ≥ 44×44 px.
* `alt` descriptivo en todas las imágenes de obra.

## Performance (presupuesto)

* CSS tema ≤ **60 KB** gz; JS tema ≤ **15 KB** gz.
* LCP < 2.0 s (4G); INP < 200 ms.
* Sin jQuery en el tema; JS vanilla `defer`.

---