# Sitemap — Milestone (Hito)

App de bienestar financiero personal. Flutter (web / PWA + Android + iOS), backend Firebase (Auth + Firestore).

> **Nota de arquitectura:** la app es single-page y **no usa rutas por URL**. La navegación
> es por estado: un shell con `IndexedStack` para las 5 secciones del bottom nav, y
> `Navigator.push` (pantallas completas) o bottom sheets para todo lo que va "encima".
> Este sitemap refleja el **grafo de pantallas**, no un árbol de URLs.

---

## 1. Arranque y sesión

```
Splash (SplashScreen)
  │
  ├─ Usuario recurrente (sesión real previa)      ─►  Main Shell / Inicio
  ├─ ?skip_onboarding=1 (bypass de testing)       ─►  Main Shell / Inicio
  └─ Usuario nuevo / anónimo                       ─►  Onboarding
```

- **Deep link / Magic link:** al volver a la app con el link de acceso confirmado,
  el onboarding salta directo a **"Todo listo"**.
- El envío real de magic link está en modo demo (se autoavanza tras ~2 s).

---

## 2. Onboarding

Flujo lineal, coordinado por `OnboardingFlow`:

```
Bienvenida (WelcomeScreen)
  └─► Email (EmailScreen)
        └─► Revisá tu email (CheckEmailScreen)   ◄─ botón "volver" a Email
              └─► Todo listo (AllDoneScreen)      ◄─ se alcanza al confirmar el link
                    └─► Tu nombre (NameScreen)         · "Omitir por ahora"
                          └─► Tema claro/oscuro (ThemeScreen)
                                └─► Main Shell / Inicio
```

Al entrar a Inicio por primera vez tras el onboarding se muestra una sola vez el
sheet **"Milestone es mejor en la app"** (`download_app_sheet`), salvo que la PWA ya
esté instalada.

---

## 3. Main Shell — barra de navegación inferior

`MainShell` con 5 destinos (`IndexedStack`). El FAB central abre **Registrar**.

| # | Sección   | Pantalla          |
|---|-----------|-------------------|
| 0 | Inicio    | `HomeScreen`      |
| 1 | Ahorro    | `SavingsScreen`   |
| 2 | Registrar | `RegisterScreen`  |
| 3 | Historial | `HistoryScreen`   |
| 4 | Perfil    | `ProfileScreen`   |

> En **Registrar** el bottom nav y el FAB se ocultan (tiene su propia navegación con X y CTA).

---

### 3.0 · Inicio (`HomeScreen`)

Contenido:
- Saludo ("Bienvenido" / "Bienvenido, {nombre}") + **campana de notificaciones**.
- Card de meta destacada (la de fecha más próxima).
- Stats: "Ahorro mensual", "Dinero disponible".
- "Registros pendientes" (pagos programados vencidos: **Aceptar** / **Reprogramar**).
- "Registros recientes" (últimos 5 movimientos).

Navega a:

```
Inicio
  ├─ campana ─────────────► Notificaciones (NotificationsScreen)
  │                           └─ "Marcar todo como leído"
  ├─ card meta (con meta) ─► Detalle de meta (GoalDetailScreen)      → ver 3.1
  ├─ card meta (sin meta) ─► Crear meta (CreateGoalScreen)           → ver 3.1
  ├─ "Ahorro mensual" ────► pestaña Ahorro / Metas
  ├─ "Dinero disponible" ─► pestaña Historial / Estadística
  ├─ "Ver todo" recientes ► pestaña Historial / Registro
  ├─ registro reciente ───► Detalle de movimiento (sheet)  /  Detalle de programado (sheet)
  └─ registro pendiente ──► (acciones inline: Aceptar / Reprogramar con date picker)
```

---

### 3.1 · Ahorro (`SavingsScreen`)

Toggle superior: **Metas** | **Presupuesto**.

#### Pestaña Metas

- Card "Total ahorrado" + **Nueva meta**.
- Análisis de progreso (ritmo actual, próximo hito).
- "Proyección de metas" (lista de metas activas) + **Ver todo**.

```
Ahorro / Metas
  ├─ "Nueva meta" / "+"  ──►  Crear meta (CreateGoalScreen)
  │                             └─► Meta creada (GoalCreatedScreen)
  │                                   ├─ "Añadir ahorro" (sheet)
  │                                   │     └─ si completa la meta ►  Meta lograda (GoalAchievedScreen)
  │                                   └─ "Volver a Ahorro"
  ├─ "Ver todo"  ─────────►  Lista de metas (GoalsListScreen)
  │                             Tabs: Activas | Pausadas | Logradas
  │                             ├─ meta activa/pausada ►  Detalle de meta (GoalDetailScreen)
  │                             └─ meta lograda        ►  Detalle de meta lograda (AchievedGoalDetailScreen)
  ├─ card de meta ────────►  Detalle de meta (GoalDetailScreen)
  └─ "Añadir ahorro" ────►  Sheet de teclado numérico (add_savings_sheet)
                               └─ si completa la meta ►  Meta lograda (GoalAchievedScreen)

Detalle de meta (GoalDetailScreen)
  ├─ "Editar meta"  ──────►  Editar meta (EditGoalScreen)   · pausar / reanudar / eliminar
  └─ "Añadir ahorro" ────►  Sheet  ─►  (posible) Meta lograda (GoalAchievedScreen)
```

#### Pestaña Presupuesto (`BudgetTabView`)

```
Ahorro / Presupuesto
  ├─ SIN presupuesto (estado vacío)
  │    ├─ "Crear presupuesto"  ─►  Crear presupuesto (CreateBudgetScreen)
  │    │                             └─ selector de categorías (sheet)
  │    ├─ "Cargar un ejemplo"  ─►  presupuesto de muestra (local, no persiste)
  │    └─ "Ver historial…"     ─►  Historial de presupuestos (BudgetHistoryScreen)
  │
  └─ CON presupuesto activo
       ├─ card / "Ver detalle del presupuesto" ─►  Detalle de presupuesto (BudgetDetailScreen)
       │                                             ├─ editar límite (sheet)
       │                                             ├─ reasignar montos (sheet)
       │                                             ├─ pausar / cancelar
       │                                             └─ "Ver historial" ► BudgetHistoryScreen
       └─ "Salir de la exploración" (solo en modo ejemplo)
```

---

### 3.2 · Registrar (`RegisterScreen`)

Pantalla completa (sin bottom nav). Toggle **Ingreso** | **Gasto**.

- Monto, categoría (obligatoria), y "Configuración avanzada" (fecha, hora, nota).
- **X** → vuelve a Inicio · **Registrar** → guarda y vuelve a Inicio.

```
Registrar
  ├─ "Elegí una categoría"  ─►  Selector de categorías (category_picker_sheet)
  ├─ fecha / hora           ─►  date picker / time picker nativos
  └─ ícono "Programar"      ─►  Programar registro (SchedulePaymentScreen)
                                  └─ guarda y vuelve a Inicio
```

---

### 3.3 · Historial — "Actividad" (`HistoryScreen`)

Toggle superior: **Registro** | **Estadística**.

#### Registro (`RegistroView`)
- Buscador (categoría o texto de nota) + filtro por tipo/período.
- Lista de movimientos agrupada por día.

```
Historial / Registro
  ├─ ícono filtro  ────────►  Filtros (history_filter_sheet)
  ├─ movimiento ───────────►  Detalle de movimiento (transaction_detail_sheet)
  │                             └─ editar categoría (category_picker_sheet)
  └─ registro programado ──►  Detalle de programado (scheduled_detail_sheet)
                                ├─ editar categoría (sheet)
                                └─ "Configuración avanzada" ► SchedulePaymentScreen
```

#### Estadística (`EstadisticasView`)
- Saldo, flujo semanal (gráfico), registros programados, distribución por categoría (donut).

```
Historial / Estadística
  ├─ filtro de período  ──►  Filtros (history_filter_sheet, sin filtro de tipo)
  └─ "Ver todos" programados ► Historial / Registro (filtrado por "programados")
```

---

### 3.4 · Perfil (`ProfileScreen`)

Todo en una pantalla scrolleable:

- **Header:** avatar + nombre (tap → editar nombre en diálogo).
- **Cuenta:** Nombre.
- **Apariencia:** switch Tema oscuro.
- **Notificaciones:** Recordatorio para registrar · Resumen diario · Alertas de gasto · Metas de ahorro.
- **Acciones de cuenta:**
  - **Cerrar sesión** → diálogo → reinicia app → Onboarding / Bienvenida.
  - **Eliminar cuenta** → doble confirmación (escribir "ELIMINAR") → borra datos → reinicia app.

---

## 4. Pantallas / overlays globales

| Elemento | Tipo | Se dispara desde |
|---|---|---|
| `SplashScreen` | pantalla | arranque de la app |
| `NotificationsScreen` | pantalla (push) | campana en Inicio |
| `download_app_sheet` ("Milestone es mejor en la app") | bottom sheet | 1ª entrada a Inicio post-onboarding |
| PWA install prompt (`pwa_install`) | banner del navegador | web, según criterio del navegador |
| `app_snackbar` / toasts | snackbar | confirmaciones y errores en toda la app |
| `confirm_dialog` | diálogo | acciones destructivas (eliminar meta, cancelar presupuesto, eliminar cuenta) |

---

## Índice de pantallas (archivos)

**Onboarding / Auth**
- `features/onboarding/splash_screen.dart` — Splash
- `features/onboarding/welcome_screen.dart` — Bienvenida
- `features/auth/email_screen.dart` — Email
- `features/auth/check_email_screen.dart` — Revisá tu email
- `features/onboarding/all_done_screen.dart` — Todo listo
- `features/onboarding/name_screen.dart` — Tu nombre
- `features/onboarding/theme_screen.dart` — Tema
- `features/onboarding/onboarding_flow.dart` — coordinador

**Shell**
- `features/shell/main_shell.dart` — shell + bottom nav
- `widgets/bottom_nav_bar.dart` — barra (Inicio · Ahorro · Registrar · Historial · Perfil)

**Inicio**
- `features/home/home_screen.dart`
- `features/notifications/notifications_screen.dart`

**Ahorro — Metas**
- `features/savings/savings_screen.dart`
- `features/savings/goals_list_screen.dart`
- `features/savings/create_goal_screen.dart`
- `features/savings/goal_created_screen.dart`
- `features/savings/goal_detail_screen.dart`
- `features/savings/edit_goal_screen.dart`
- `features/savings/goal_achieved_screen.dart`
- `features/savings/achieved_goal_detail_screen.dart`
- `features/savings/widgets/add_savings_sheet.dart`

**Ahorro — Presupuesto**
- `features/savings/budget_tab_view.dart`
- `features/savings/create_budget_screen.dart`
- `features/savings/budget_detail_screen.dart`
- `features/savings/budget_history_screen.dart`

**Registrar**
- `features/register/register_screen.dart`
- `features/register/schedule_payment_screen.dart`
- `features/register/category_picker_sheet.dart`

**Historial**
- `features/history/history_screen.dart`
- `features/history/registro_view.dart`
- `features/history/estadisticas_view.dart`
- `features/history/transaction_detail_sheet.dart`
- `features/history/scheduled_detail_sheet.dart`
- `features/history/widgets/history_filter_sheet.dart`

**Perfil**
- `features/profile/profile_screen.dart`
