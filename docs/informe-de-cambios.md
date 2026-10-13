# Informe de cambios — Milestone

Desde la generación del UI Inventory hasta el estado actual de deploy

## 1. UI Inventory

**Qué se hizo:** Análisis completo de /lib y generación de ui_inventory.html — catálogo visual estático con 46 variantes de UI reales (botones, inputs, cards, modales, snackbars, navegación, listas, widgets custom), cada una reconstruida con los tokens reales del tema (colores, Manrope, spacing, radios, sombras) y su referencia exacta de archivo/línea.

**Por qué:** Documentar el estado real del sistema visual de la app para referencia y trazabilidad.

## 2. Fondo de StatValueCard

**Archivo:** lib/widgets/stat_value.dart

**Cambio:** Fondo por defecto de recessedColor() (gris) a theme.colorScheme.primaryContainer (lavanda), igualando el tono de la hero card de ahorro total.

**Alcance:** Aplicado automáticamente a todas las instancias existentes (Home, detalle de presupuesto, tab de presupuestos, creación de presupuesto) sin tocar cada pantalla.

## 3. Fix de ancho — campo de monto en Registrar

**Archivo:** lib/features/register/register_screen.dart (_AmountField)

**Problema:** El TextField vivía dentro de un Center sin ancho explícito, ajustándose al contenido; al escribir montos largos podía desbordar.

**Fix:** Envuelto en SizedBox(width: double.infinity) para forzar ancho completo de pantalla.

## 4. Actualización del UI Inventory

Se reflejaron en el HTML los tres cambios anteriores (fondo de StatValueCard, ancho del amount field, y los ajustes de tipografía/margen del Note Field), con anotaciones de “antes/después” en cada variante afectada.

## 5. Campo de “nota” en Registrar — tipografía y margen

**Archivos:** lib/features/register/register_screen.dart, lib/features/savings/widgets/goal_form_fields.dart (EditableGoalField)

**Problema:** El valor de la nota usaba peso bold (headlineMedium) y el contenedor tenía padding solo horizontal, sin igualar al Date Picker Field de la misma pantalla.

**Fix:** Se agregaron parámetros opcionales valueStyle/labelStyle a EditableGoalField (sin afectar otros usos por default) y se pasó bodyLarge/bodySmall + EdgeInsets.all(md) para igualar exactamente el ritmo visual del Date Picker Field.

## 6. Texto de las cards de metas activas

**Archivo:** lib/features/savings/widgets/goal_summary_card.dart

**Cambio:** El label bajo el monto ahorrado pasó de “Ahorrado” a “de $X” (el targetAmount de la meta), dando contexto de cuánto falta para completarla. Solo aplicado a metas activas (no pausadas ni logradas), según lo pedido.

## 7. Fix crítico — mockup de desktop apareciendo en mobile real

**Archivo:** web/index.html

**Problema:** Faltaba la etiqueta <meta name="viewport">. Sin ella, los navegadores mobile asumen un viewport virtual de ~980px (“modo sitio de escritorio”) y lo achican para que entre en pantalla — eso disparaba falsamente la media query de min-width:900px que activa el mockup de teléfono decorativo, incluso en un celular real.

**Fix:** Agregado <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">.

## 8. Campos “tap-to-edit” — activación solo por ícono

**Archivo:** lib/features/savings/widgets/goal_form_fields.dart (EditableGoalField)

**Problema:** Solo el ícono de lápiz activaba el modo edición; tocar el valor mostrado (ej. “$ 0,00”) no hacía nada.

**Fix:** Toda la zona de label+valor envuelta en GestureDetector (HitTestBehavior.opaque), así cualquier tap dentro del campo activa la edición — no solo el ícono.

## 9. Mensajes de error no visibles al intentar enviar formularios incompletos

**Archivos:** lib/features/savings/create_goal_screen.dart, lib/features/savings/edit_goal_screen.dart

**Problema:** El botón de submit quedaba con onPressed: null cuando el formulario estaba incompleto — al estar deshabilitado, Flutter no registra el tap, así que tocarlo no revelaba ningún error. Tampoco se mostraba error si el usuario saltaba directo a otro campo sin haber “tocado” (enfocado y desenfocado) el anterior.

**Fix:** El botón nunca queda con onPressed: null — sigue pareciendo deshabilitado (mismos colores, vía FilledButton.styleFrom replicando los tokens de disabled de Material 3), pero ahora recibe el tap. Si el formulario es inválido, marca todos los campos como “tocados” y revela los errores correspondientes en vez de no hacer nada.

## 10. Bug del botón “+” del bottom nav — solo respondía la mitad del círculo

**Archivos:** lib/widgets/bottom_nav_bar.dart, lib/features/shell/main_shell.dart

**Problema raíz:** El botón circular flotaba usando Positioned(top: -20) dentro de un Stack que era directamente el bottomNavigationBar de Scaffold. Ese offset negativo quedaba fuera del área que Scaffold le asigna al bottomNavigationBar (el Stack calcula su tamaño solo en base a sus hijos no posicionados), así que la mitad superior del círculo pintaba visualmente arriba de la barra pero no recibía taps — quedaba “detrás” del body para efectos de hit-testing.

**Primer intento (revertido):** reservar el espacio con Padding + ClipRect — funcionó para el tap, pero el recorte de la sombra generó una línea visual dura no deseada.

**Fix final:** Se sacó el botón del Stack de la barra por completo. Ahora es un widget independiente (HitoFab) montado en Scaffold.floatingActionButton con floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked — el mecanismo nativo de Flutter para “FAB flotando mitad adentro/mitad afuera de la bottom bar”. La barra volvió a ser pixel-idéntica a la original (sin Stack, sin Padding, sin ClipRect), y el FAB tiene su propia sombra de Material y su propia región de hit-testing garantizada por Scaffold — sin compartir ni interferir con la barra.

### Deploys realizados

9 deploys a https://milestone-cc9af.web.app a lo largo de esta sesión, cada uno verificado con flutter analyze + flutter build web antes de subir.
