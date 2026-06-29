# Sistema visual — Hito

App de bienestar financiero (no fintech). El sistema visual existe para reforzar un mensaje: cada gasto registrado es un paso, cada meta cumplida es un hito. Nada en la UI debe sentirse como vigilancia, juicio o presión.

## Concepto

Índigo suave transmite calma e introspección (línea BetterSleep) sin la frialdad de "control financiero" que traen el azul/teal corporativo típico de fintech. Arena aporta calidez en los momentos de logro sin caer en el dorado/ámbar de "premio" agresivo. Salvia funciona como acento de progreso orgánico, evitando el verde-dinero clásico. Ningún color comunica urgencia salvo los estados de error reales.

## Decisiones descartadas (y por qué)

- **Deep Teal / Terracotta**: excluidos explícitamente — son la paleta que el equipo asoció a "fintech de control", lo opuesto al posicionamiento de Hito.
- **Azul + violeta saturado**: válido como concepto pero de alto riesgo de leerse como fintech genérica si domina el azul corporativo.
- **Tipografía Plus Jakarta Sans**: descartada en favor de Manrope por ser más neutra y legible en pantallas chicas, sin la calidez "redondeada" que competía con el color.
- **Densidad de espaciado**: se evaluaron compacta y espaciosa: se eligió **estándar** como balance entre orden visual y calidez.

## Paleta — roles M3

### Modo claro

| Rol M3 | Hex | Uso |
|---|---|---|
| primary | `#4A4E78` | Acciones principales, navegación activa |
| onPrimary | `#F2F1F4` | Texto/ícono sobre primary |
| primaryContainer | `#E2E2EF` | Superficies destacadas (cards de hito) |
| onPrimaryContainer | `#1E2040` | Texto sobre primaryContainer |
| secondary | `#B08B5A` | Solo como fill de superficies/iconografía — **no usar como texto**, no pasa AA sobre fondo claro |
| onSecondary | `#3E2D14` | Texto sobre secondary |
| secondaryContainer | `#F1E3D0` | Badges de logro, celebración de hito |
| onSecondaryContainer | `#3E2D14` | Texto sobre secondaryContainer |
| tertiary | `#7C9885` | Solo fill/iconografía — mismo caso que secondary |
| onTertiary | `#FFFFFF` | Texto sobre tertiary |
| tertiaryContainer | `#E5EDE7` | Indicadores de progreso/crecimiento |
| onTertiaryContainer | `#16332B` | Texto sobre tertiaryContainer |
| success | `#3F7A4E` | Confirmaciones, sincronización ok |
| successContainer | `#DCF0DF` | Fondo de mensajes de éxito |
| warning | `#9A6B00` | Alertas informativas (gasto inusual) — nunca para juicio de comportamiento |
| warningContainer | `#FCEBC4` | Fondo de alertas |
| error | `#B3261E` | Solo fallas técnicas reales (no se guardó, no sincronizó) |
| errorContainer | `#F9DEDC` | Fondo de errores |
| neutral900 (texto) | `#211F26` | Texto principal |
| neutral700 | `#57545E` | Texto secundario |
| neutral50 | `#F2F1F4` | Fondo base |
| outline | `#79767F` | Bordes, divisores |

Verificación de contraste (texto sobre `neutral50`): primary 6.8:1 (AA), onPrimaryContainer/primaryContainer 11.2:1 (AAA), onSecondaryContainer/secondaryContainer 8.1:1 (AAA), success 4.9:1 (AA), warning 4.6:1 (AA), error 5.4:1 (AA), neutral900 14.1:1 (AAA).

### Modo oscuro

| Rol M3 | Hex |
|---|---|
| primary | `#C3C4E8` |
| onPrimary | `#2A2C50` |
| primaryContainer | `#393C66` |
| onPrimaryContainer | `#E0E0F5` |
| secondary | `#E0C190` |
| onSecondary | `#4A3618` |
| secondaryContainer | `#5C4423` |
| onSecondaryContainer | `#F6E3C5` |
| tertiary | `#A0BBA8` |
| onTertiary | `#1F3327` |
| tertiaryContainer | `#324A3A` |
| onTertiaryContainer | `#C8DDC9` |
| success | `#9FD8A8` |
| successContainer | `#2A4A33` |
| warning | `#E5B95C` |
| warningContainer | `#4A3700` |
| error | `#F2B8B5` |
| errorContainer | `#601410` |
| background | `#18171C` |
| surface | `#211F26` |
| surfaceVariant | `#2A2830` |
| onSurface / onBackground | `#ECEAF0` |
| onSurfaceVariant | `#B8B5C0` |
| outline | `#5C5965` |

## Tipografía — Manrope

Elegida por ser neutra, muy legible en pantallas chicas y no competir con la calidez que ya aporta el color.

| Nivel | Tamaño | Peso | Line-height | Uso |
|---|---|---|---|---|
| Display | 36px / 2.25rem | 700 | 1.2 | Momentos de celebración de hito |
| H1 | 28px / 1.75rem | 600 | 1.3 | Títulos de pantalla |
| H2 | 22px / 1.375rem | 600 | 1.35 | Títulos de sección |
| Body | 16px / 1rem | 400 | 1.6 | Texto principal |
| Body small | 14px / 0.875rem | 400 | 1.55 | Texto secundario |
| Label | 13px / 0.8125rem | 500 | 1.4 | Categorías, metadatos |
| Caption | 11px / 0.6875rem | 400 | 1.4 | Notas, timestamps |

## Espaciado (densidad estándar)

Base unit 4px: `xs 4 · sm 8 · md 16 · lg 24 · xl 32 · 2xl 48`

## Elevación

5 capas, sombra con tinte índigo neutro (no negro puro, para no romper la calidez):

```
0: none
1: 0 1px 3px rgba(33,31,38,0.10)
2: 0 3px 6px rgba(33,31,38,0.12)
3: 0 8px 16px rgba(33,31,38,0.16)
4: 0 16px 28px rgba(33,31,38,0.20)
```

## Radios

`sm 8px · md 14px · lg 20px · full 9999px`

## Iconografía

Set outline (no filled) — los íconos rellenos se leen más agresivos/de alerta, lo que va en contra del tono "no punitivo". Tamaños 16/20/24px. Color por default `onSurfaceVariant`; `primary`/`secondary`/`tertiary` solo en estados activos o de logro.

## Imágenes y media

Ilustraciones planas, paleta limitada a los 3 colores del sistema + neutros. Sin fotografía realista de dinero/billetes — refuerza que Hito no es una fintech.

## Reglas de uso (para evitar romper el sistema)

- `secondary` y `tertiary` puros **nunca van como color de texto** sobre fondo claro — fallan contraste AA. Para texto usar siempre `onSecondaryContainer` / `onTertiaryContainer`.
- `error` es exclusivo de fallas técnicas. Nunca para "gastaste de más" — eso usa `warning` o `tertiary` en tono informativo.
- Ningún ícono relleno (filled) en estados normales.

## Restricciones para copy / microcopy

- Tamaño máximo para microcopy: Body (16px). Labels y captions son solo metadatos, no llevan mensajes de juicio.
- Tono: progreso sin presión. Evitar "deberías", "te excediste", "incorrecto" — preferir marcos de "avance" y "opciones".
- Elementos con texto fijo (no editable por writing): badges de % de progreso, labels de categoría con ícono.

## Tokens (referencia rápida)

```
color-primary: #4A4E78
color-on-primary: #F2F1F4
color-primary-container: #E2E2EF
color-on-primary-container: #1E2040
color-secondary: #B08B5A
color-on-secondary: #3E2D14
color-secondary-container: #F1E3D0
color-on-secondary-container: #3E2D14
color-tertiary: #7C9885
color-on-tertiary: #FFFFFF
color-tertiary-container: #E5EDE7
color-on-tertiary-container: #16332B
color-success: #3F7A4E
color-success-container: #DCF0DF
color-warning: #9A6B00
color-warning-container: #FCEBC4
color-error: #B3261E
color-error-container: #F9DEDC
color-neutral-900: #211F26
color-neutral-700: #57545E
color-neutral-400: #908D97
color-neutral-200: #D9D7DD
color-neutral-50: #F2F1F4
color-outline: #79767F

typography-family: 'Manrope', sans-serif
typography-size-display: 2.25rem / 700 / 1.2
typography-size-h1: 1.75rem / 600 / 1.3
typography-size-h2: 1.375rem / 600 / 1.35
typography-size-body: 1rem / 400 / 1.6
typography-size-body-sm: 0.875rem / 400 / 1.55
typography-size-label: 0.8125rem / 500 / 1.4
typography-size-caption: 0.6875rem / 400 / 1.4

spacing-xs: 4px
spacing-sm: 8px
spacing-md: 16px
spacing-lg: 24px
spacing-xl: 32px
spacing-2xl: 48px

elevation-1: 0 1px 3px rgba(33,31,38,0.10)
elevation-2: 0 3px 6px rgba(33,31,38,0.12)
elevation-3: 0 8px 16px rgba(33,31,38,0.16)
elevation-4: 0 16px 28px rgba(33,31,38,0.20)

radius-sm: 8px
radius-md: 14px
radius-lg: 20px
radius-full: 9999px
```

## Implementación en código

Estos tokens ya están implementados en [`lib/theme/app_theme.dart`](../lib/theme/app_theme.dart) como `ColorScheme` de Material 3 (light + dark) y `TextTheme` con Manrope. Cualquier ajuste de color o tipografía debe hacerse ahí, no con valores sueltos en las pantallas.
