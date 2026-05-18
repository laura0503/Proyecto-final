# Documento de Diseño de Aplicación (GDD/TDD)
**Proyecto:** Gestión de Ausencias
**Plataforma:** Flutter (Web, Android, Desktop)
**Versión del Documento:** 1.0

---

## 1. Base de Datos
Se utiliza **Supabase (PostgreSQL)** como base de datos relacional (SQL). La base de datos está normalizada (hasta la 3ª Forma Normal) para evitar redundancias y garantizar la integridad referencial.
**Entidades Principales (Modelo E/R):**
1. **Usuarios/Profesores:** Almacena datos del docente, identificador, departamento.
2. **Ausencias:** Registra el día, motivo, estado y profesor ausente.
3. **Guardias (Sustituciones):** Relaciona una ausencia con el profesor que cubre la guardia, el tramo horario y el aula.
4. **Tramos Horarios:** Define las horas de clase (ej. 08:15 a 09:15).
5. **Aulas/Grupos:** Información sobre dónde y a quién se imparte la clase.

## 2. Usuarios
El sistema cuenta con un sistema de registro y autenticación basado en **Google Sign-In** (correos institucionales) con distintos perfiles de acceso:
- **Jefatura de Estudios (Administrador):** Acceso total. Puede ver todas las ausencias, asignar sustitutos manualmente, gestionar horarios y acceder a analíticas globales.
- **Profesor (Usuario Estándar):** Acceso restringido. Puede visualizar su horario, reportar sus propias ausencias futuras y ver las guardias de sustitución que se le han asignado.

## 3. Analítica
- **Plataforma:** Firebase Analytics.
- **Eventos Monitorizados:** `login_success`, `report_absence`, `assign_guard_manual`, `assign_guard_auto`, `view_dashboard`.
- **Funnels (Embudos de conversión):** Analizar el flujo de "Aviso de ausencia": *Inicio de sesión -> Tap en reportar ausencia -> Selección de fecha/motivo -> Confirmación.*
- **A/B Testing:** Mediante Firebase Remote Config, se probarán dos variantes del panel de inicio en la app móvil: Variante A (Vista en formato lista de próximas clases) vs Variante B (Vista de tarjetas/grid), para medir cuál genera una navegación más rápida y menor tasa de rebote.

## 4. Backend
Se hace uso de **Supabase** (plataforma BaaS basada en PostgreSQL) para la gestión de base de datos en la nube y **Firebase** para la autenticación (OAuth de Google) y analítica. Ambos servicios se utilizan apoyándose en su plan gratuito (Free Tier), siendo plenamente capaces de soportar la fase de lanzamiento del proyecto.

## 5. FrontEnd
Desarrollado con el framework **Flutter**, permitiendo un único código fuente compilable en 3 plataformas diferentes:
1. **Web:** Enfocada al uso en la oficina de Jefatura de Estudios (monitores grandes, gestión masiva).
2. **Android:** App nativa para profesores, enfocada en la movilidad (avisar de ausencias o revisar guardias desde el móvil).
3. **Windows/Linux (PC):** Aplicación de escritorio compilada para su uso en los ordenadores corporativos del centro educativo, ofreciendo máximo rendimiento.

## 6. Gráficos y Marca
- **Paleta de Color:** Colores corporativos y serios pero modernos. Tonos predominantes: Azules oscuros (confianza, tecnología) con acentos vibrantes (Ámbar para alertas de ausencias, Esmeralda/Verde para guardias cubiertas exitosamente).
- **Iconografía:** Uso de iconos limpios, de bordes redondeados y consistentes (familia Fluent Icons o Material Design personalizados).
- **Estética Consistente:** Radios de borde uniformes (`borderRadius: 16`), elevaciones consistentes y jerarquía visual clara en todas las plataformas.

## 7. Estilo Gráfico
El estilo general de la aplicación es el **Glassmorphism (Efecto Cristal)**. 
Es una estética *Premium*, moderna y fluida. Se basa en tarjetas semitransparentes con desenfoque de fondo (`BackdropFilter`), fondos abstractos con mallas de degradados (Mesh Gradients) sutiles y micro-animaciones dinámicas al interactuar con los elementos (hover en Web, tap en Android).

## 8. Público Objetivo
- **Demografía:** Hombres y mujeres entre 25 y 65 años (Docentes y Equipo Directivo de institutos y centros de FP).
- **Modo de vida / Intereses:** Profesionales ocupados que buscan eficiencia, reducir la carga burocrática y el uso de papel.
- **Perfil tecnológico:** Desde nativos digitales hasta personas con habilidades ofimáticas básicas. La app debe ser extremadamente intuitiva para no generar rechazo en usuarios menos tecnológicos.

## 9. Horas/Tareas (Metodología)
- **Metodología:** SCRUM apoyado en tableros Kanban (Trello / Jira).
- **Sprints:** Iteraciones de 2 semanas.
- **Pesos (Story Points):** Las tareas no se estiman solo en horas, sino en Puntos de Historia (secuencia de Fibonacci: 1, 2, 3, 5, 8...) según su complejidad, incertidumbre y esfuerzo.
- **Seguimiento:** Uso de gráficos *Burn-down* por cada Sprint para visualizar el ritmo de cierre de tareas frente al tiempo restante.

## 10. Documentación
- Este documento actúa como **GDD / TDD** (Technical & Design Document).
- **Manual de Usuario:** No será un PDF denso. Se integrará un sistema de "Onboarding" interactivo dentro de la propia app (tooltips guiados la primera vez que se entra) y una sección de FAQ en los ajustes.

## 11. Servidor de Versiones
- **Plataforma:** GIT (GitHub).
- **Flujo de trabajo (Git Flow simplificado):**
  - `main`: Rama de producción, siempre estable.
  - `develop`: Rama de integración de nuevas funcionalidades.
  - `feature/*` (ej. `feature/login`, `feature/ausencias`): Ramas individuales para cada nueva historia de usuario.
  - Los commits son descriptivos y cada feature se integra a `develop` mediante Pull Requests.

## 12. Casos de Uso e Historias de Usuario (Backlog Extraído)
- **HU01:** Como Jefe de Estudios, quiero ver un panel visual (Torre de Control) con los profesores ausentes del día para organizar las sustituciones.
- **HU02:** Como Jefe de Estudios, quiero que el sistema asigne automáticamente profesores disponibles a las clases sin cubrir.
- **HU03:** Como Profesor, quiero poder notificar una ausencia médica desde el móvil para avisar al centro antes del inicio de las clases.
- **HU04:** Como Profesor, quiero ver en mi móvil las aulas a las que tengo que ir a hacer guardia.

## 13. Monetización
- **Modelo de Negocio:** Aplicación SaaS (Software as a Service) B2B orientada a Centros Educativos (no se cobra al profesor).
- **Tipos de Planes:**
  - *Freemium:* Gratuito para centros muy pequeños (ej. CEIPs rurales con menos de 10 profesores), funcional pero con historial de datos limitado a 30 días.
  - *Premium (Suscripción):* Licencia anual pagada por el instituto. Acceso a automatización avanzada, estadísticas anuales y soporte técnico.
- **Publicidad:** Cero publicidad. Al ser una herramienta profesional de pago institucional, los anuncios arruinarían la experiencia y la seriedad del producto.
- **Pasarela de Pago:** Integración con **Stripe** para procesar el pago de las suscripciones anuales mediante tarjeta de crédito o transferencia SEPA del centro educativo. (Sin softcoins/hardcoins, pagos directos en divisa real).

## 14. UI Mockup
Se han desarrollado bocetos esquemáticos (*Wireframes*) y diseños en alta fidelidad utilizando **Figma**. 
El diseño establece las diferencias entre el layout de 3 columnas para Web (Navegación lateral, Monitor central, Detalle a la derecha) y el layout móvil basado en BottomNavigationBar.

## 15. Calendario de Builds
- **Build 0.1 (Alpha):** Setup del proyecto, conexión Supabase/Firebase, Login de Google funcionando.
- **Build 0.5 (Beta):** CRUD de profesores y ausencias. Pantallas básicas creadas y navegables.
- **Build 0.8 (RC1):** Algoritmo de asignación de guardias integrado. Torre de control web funcionando.
- **Build 1.0 (Release):** Aplicación de diseño Glassmorphism, animaciones, analíticas integradas. Versión candidata para presentación.

## 16. Código y Arquitectura
- **Paradigma:** Orientado a Objetos (Dart).
- **Arquitectura:** Modelo-Vista-Controlador (MVC) adaptado, utilizando el patrón **Provider / ChangeNotifier** para el manejo del estado global (ej. `AuthProvider`, `AbsenceProvider`).
- **Principios:** Diseño modular. Creación de componentes UI reutilizables (ej. `GlassCard`, `CustomTextField`) para mantener un código *DRY (Don't Repeat Yourself)*, mantenible y escalable.

## 17. QA (Quality Assurance)
- **Metodología:** Testeo continuo por fases (Unit Testing para lógica de negocio, Widget Testing para la UI).
- **Niveles de Bugs clasificados en Jira:**
  - *Blocker:* El login falla o la base de datos no responde. (Resolución inmediata).
  - *Major:* No se puede reportar una ausencia o la asignación automática falla.
  - *Minor:* Fallos de diseño en resoluciones extrañas, problemas de caché.
  - *Trivial:* Errores ortográficos, un color ligeramente desviado de la paleta.

## 18. Accesibilidad
- Diseño pensado para cumplir normas básicas de accesibilidad (WCAG):
- Alto contraste entre textos claros y fondos translúcidos oscuros.
- Los textos utilizan tamaños relativos para que crezcan si el profesor tiene configurada la letra grande en los ajustes de su móvil.
- Etiquetas `Semantics` en Flutter para soporte básico de lectores de pantalla (VoiceOver / TalkBack).

## 19. UX (Experiencia de Usuario)
- **Enfoque:** *Mobile-First* para la vista del profesor (necesitan inmediatez en cualquier lugar) y *Desktop-First* para Jefatura (necesitan densidad de información en pantallas grandes).
- Se prioriza la **Regla de los 3 clics**: Un profesor debe poder reportar una ausencia en un máximo de 3 toques de pantalla.
- Feedback constante: Uso de *Snackbars*, animaciones de carga y transiciones fluidas para que el sistema nunca parezca "congelado".

## 20. Presupuesto (Estimación Inicial)
- **Desarrollo (1 Full-Stack Flutter, 3 meses):** 12.000€
- **Diseño UI/UX (Figma, Branding):** 2.000€
- **Infraestructura (Hosting, Supabase, Dominios - Año 1):** 300€
- **Costes de Pasarela de pago/Tiendas de Apps:** 150€
- **Presupuesto Total Mínimo Viable (MVP):** ~ 14.450€

## 21. Presentación (Pitch Comercial)
La presentación al cliente (Directiva del Instituto o Consejería de Educación) se enfocará en el "Dolor" principal: *Las mañanas caóticas en jefatura cuadrando guardias con papel y bolígrafo*. 
Se mostrará el MVP funcionando, destacando el **ahorro de tiempo** (de horas a minutos) y la **tranquilidad** que aporta la automatización y la centralización de datos.

## 22. Promoción y Adquisición
Al ser un entorno "B2B Cerrado", no depende del posicionamiento ASO en la Play Store.
- **Estrategia de Adquisición:** Venta directa (*Cold Emailing* a directores de IES, presencia en ferias de tecnología educativa como SIMO Educación).
- **Retención (DAU):** Se asegura una alta tasa de Usuarios Activos Diarios porque la herramienta se vuelve obligatoria para la operativa diaria del centro. Se medirá a través de Firebase para asegurar que los profesores realmente revisan su app por las mañanas.

## 23. Estudio de Mercado
- **Competencia Actual:** Séneca/iSéneca (oficial de la Junta de Andalucía), Cuaderno del Profesor (iDoceo), hojas de Excel compartidas.
- **Nuestra Diferencia:** Mientras iSéneca es lenta, burocrática y su UI está anticuada, nuestra app ofrece una solución "láser" hiper-optimizada solo para las ausencias, con un motor de asignación automática (cosa que carecen las apps genéricas) y una interfaz ultrarrápida, moderna e intuitiva que los profesores sí querrán usar.

---

## 24. Futuras Mejoras y Escalabilidad
Una vez lanzado y estabilizado el MVP, se planifican las siguientes vías de mejora y escalado:

### Escalabilidad Técnica:
1. **Migración de lógica pesada:** Mover el algoritmo de asignación de guardias (que actualmente podría correr en el cliente o mediante requests simples) a **Supabase Edge Functions**. Esto permitirá que la asignación automática sea aún más rápida, segura e independiente del dispositivo cliente.
2. **Arquitectura Multi-Tenant real:** Escalar la base de datos implementando *Row Level Security (RLS)* más estricto, para que miles de institutos puedan alojarse en la misma base de datos sin comprometer el rendimiento ni mezclar datos (aislamiento por `tenant_id`).

### Nuevas Funcionalidades:
1. **Inteligencia Artificial (Machine Learning):** Integrar un modelo predictivo basado en datos históricos (ej. TensorFlow Lite / Python backend). El sistema podría alertar a Jefatura de Estudios: *"Históricamente, en la tercera semana de enero las ausencias por gripe aumentan un 40%. Te recomendamos revisar la disponibilidad de guardias"*.
2. **Notificaciones Push en Tiempo Real:** Implementar Firebase Cloud Messaging (FCM). Cuando Jefatura asigne una sustitución urgente a un profesor, su móvil vibrará inmediatamente con una notificación Push, eliminando la necesidad de buscarle por los pasillos.
3. **Integración de Horarios Automática:** Permitir importar los horarios complejos generados por programas externos clásicos como *Peñalara* (formato XML o CSV), haciendo que el *onboarding* de un nuevo instituto tarde 5 minutos en lugar de horas.
4. **Módulo de Estadísticas Avanzadas:** Generación automática de informes en PDF a final de mes justificando las horas de guardia realizadas por cada profesor para presentarlas a inspección educativa.
