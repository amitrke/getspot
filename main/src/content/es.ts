import type { Dictionary } from "./types";

const es: Dictionary = {
  header: {
    brand: "GetSpot",
    navFeatures: "Características",
    navFaq: "Preguntas",
    openApp: "Abrir la app →",
  },
  footer: {
    copyright: "© 2026 GetSpot ·",
    appLink: "app.getspot.org",
    privacyLink: "Privacidad",
  },
  home: {
    metaTitle: "GetSpot — Organiza encuentros deportivos con facilidad",
    metaDescription:
      "GetSpot ayuda a los organizadores a programar eventos, gestionar participantes y manejar los pagos grupales para bádminton y otros encuentros deportivos.",
    title: "Organiza encuentros deportivos sin el caos de los chats grupales",
    subtitle:
      "GetSpot ayuda a los organizadores a programar eventos, gestionar participantes y listas de espera, y manejar los pagos grupales, todo pensado para bádminton y otros grupos deportivos.",
    ctaOpenApp: "Abrir la app",
    ctaIosApp: "App Store de iOS",
    ctaAndroidApp: "Google Play",
    features: [
      {
        title: "Grupos",
        description:
          "Crea un grupo, comparte un código de acceso y gestiona a los miembros en un solo lugar.",
      },
      {
        title: "Eventos",
        description:
          "Programa sesiones con límites de capacidad, listas de espera y reglas de confirmación justas.",
      },
      {
        title: "Billetera",
        description:
          "Controla los saldos y pagos del grupo sin tener que perseguir a nadie para cobrar.",
      },
    ],
    seeAllFeatures: "Ver todas las características →",
  },
  features: {
    metaTitle: "Características — GetSpot",
    metaDescription:
      "Descubre cómo GetSpot gestiona grupos, programa eventos, listas de espera y pagos para encuentros deportivos recurrentes.",
    title: "Todo lo que necesitas para gestionar encuentros deportivos recurrentes",
    subtitle: "Sin hojas de cálculo, sin perseguir pagos, sin listas de espera manuales.",
    forOrganizers: "Para organizadores",
    forPlayers: "Para jugadores",
    organizerFeatures: [
      {
        title: "Crea eventos en segundos",
        description:
          "Define fecha, hora, ubicación, capacidad y tarifa; publícalo y los miembros reciben la notificación al instante.",
      },
      {
        title: "Listas de espera automáticas",
        description:
          "Cuando un evento se llena, las nuevas inscripciones se añaden automáticamente a la lista de espera. Cuando se libera un lugar confirmado, la siguiente persona en la fila se promueve sin trabajo manual.",
      },
      {
        title: "Sistema de billetera virtual",
        description:
          "Cobra a los miembros como ya lo haces: efectivo, Venmo, Zelle, y luego acredita su billetera en la app. Las tarifas de inscripción se descuentan automáticamente.",
      },
      {
        title: "Fechas límite de compromiso",
        description:
          "Establece una fecha límite después de la cual una cancelación pierde la tarifa (a menos que un miembro en lista de espera tome el lugar), para que tu número de asistentes sea confiable.",
      },
      {
        title: "Anuncios grupales",
        description: "Envía actualizaciones a todos los miembros de un grupo a la vez.",
      },
      {
        title: "Gestión de miembros",
        description:
          "Aprueba solicitudes de ingreso, añade o elimina miembros y acredita billeteras desde una sola pantalla.",
      },
    ],
    playerFeatures: [
      {
        title: "Inscripción con un toque",
        description:
          "Regístrate para un evento al instante; tu tarifa se descuenta de tu saldo de billetera grupal de inmediato.",
      },
      {
        title: "Estado en tiempo real",
        description:
          "Sabe de inmediato si estás confirmado o en lista de espera, y recibe una notificación automática si te promueven desde la lista de espera.",
      },
      {
        title: "Reembolsos automáticos",
        description:
          "Retírate antes de la fecha límite de compromiso y tu tarifa se reembolsa automáticamente a tu billetera.",
      },
      {
        title: "Seguimiento del saldo de billetera",
        description:
          "Consulta tu saldo por grupo en cualquier momento, sin adivinar qué has pagado o qué debes.",
      },
      {
        title: "Notificaciones push",
        description:
          "Recibe notificaciones sobre nuevos eventos, cambios en el estado de inscripción y recordatorios antes de los partidos.",
      },
      {
        title: "Varios grupos, una sola cuenta",
        description:
          "Únete a tantos grupos deportivos como practiques, todo desde un único inicio de sesión.",
      },
    ],
    ctaOpenApp: "Abrir la app",
    ctaReadFaq: "Leer las preguntas frecuentes",
  },
  faq: {
    metaTitle: "Preguntas frecuentes — GetSpot",
    metaDescription:
      "Respuestas a preguntas comunes sobre cómo funcionan la billetera virtual, los reembolsos y el uso compartido de grupos de GetSpot.",
    title: "Preguntas frecuentes",
    introBeforeEmail: "¿Tienes una pregunta que no está respondida aquí? Escribe a",
    introAfterEmail: ".",
    items: [
      {
        question: "¿Es gratis usar GetSpot?",
        answer:
          "Sí. No hay suscripción ni comisión por transacción para organizadores o jugadores.",
      },
      {
        question: "¿Necesito un procesador de pagos o una cuenta comercial?",
        answer:
          "No. GetSpot usa una billetera virtual en lugar de una pasarela de pago. Cobras el pago real a los miembros como ya lo haces (efectivo, Venmo, Zelle, etc.) y luego acreditas su billetera en la app. GetSpot nunca maneja datos de pago reales.",
      },
      {
        question: "¿Cómo funciona realmente la billetera?",
        answer:
          "Los saldos de billetera son por grupo. Un organizador acredita la billetera de un miembro después de cobrar el pago fuera de la app. Cuando ese miembro se registra en un evento del grupo, la tarifa se descuenta automáticamente de su saldo.",
      },
      {
        question: "¿Qué pasa si cancelo después de la fecha límite?",
        answer:
          "Cada evento puede tener una fecha límite de compromiso. Cancelar después de ella hace que pierdas la tarifa, a menos que un miembro en lista de espera tome el lugar libre. Esto mantiene un número de asistentes confiable para el organizador.",
      },
      {
        question: "¿Qué pasa si me retiro antes de la fecha límite?",
        answer:
          "Tu tarifa se reembolsa automáticamente a tu billetera, sin necesidad de solicitud manual.",
      },
      {
        question: "¿Qué pasa si se libera un lugar en la lista de espera?",
        answer:
          "La siguiente persona en la lista de espera se confirma automáticamente y recibe una notificación, sin coordinación manual por parte del organizador.",
      },
      {
        question: "¿Puedo unirme a más de un grupo?",
        answer:
          "Sí. Los jugadores pueden unirse a varios grupos deportivos con una sola cuenta, y los organizadores también pueden crear y gestionar varios grupos.",
      },
      {
        question: "¿Están seguros mis datos e información de pago?",
        answer:
          "GetSpot está construido sobre Firebase con autenticación y reglas de seguridad estándar. Como los pagos reales ocurren fuera de la app entre tú y tu organizador, tus datos de pago nunca pasan por los servidores de GetSpot.",
      },
      {
        question: "¿Para qué deportes funciona GetSpot?",
        answer:
          "Cualquier encuentro deportivo recurrente con un límite de capacidad y una tarifa: bádminton, baloncesto, fútbol, tenis, vóleibol y formatos similares.",
      },
      {
        question: "¿Cómo empiezo?",
        answer:
          "Descarga la app, inicia sesión con Google o Apple, y crea un grupo (obtendrás un código para compartir con tus miembros) o únete a uno con un código de tu organizador.",
      },
    ],
    ctaOpenApp: "Abrir la app",
  },
  privacy: {
    metaTitle: "Política de privacidad — GetSpot",
    metaDescription: "Cómo GetSpot recopila, usa y comparte tu información cuando usas la app.",
  },
};

export default es;
