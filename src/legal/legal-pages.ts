import type { INestApplication } from '@nestjs/common';

/**
 * Páginas públicas de Política de privacidad (/privacidad) y Términos y
 * condiciones (/terminos). Son HTML estático, sin JavaScript, para que Google
 * Play y cualquier navegador las lean sin problema. Van fuera del prefijo
 * /api y sin autenticación. La app las abre desde el registro y el perfil
 * (AppConfig.privacyPolicyUrl / termsOfServiceUrl).
 *
 * Si cambia lo que la app recoge o con quién se comparte, actualizar el texto
 * y la fecha de ACTUALIZADO.
 */

const ACTUALIZADO = '1 de noviembre de 2026';
const CONTACTO = 'afesdev2025@gmail.com';

const pagina = (titulo: string, cuerpo: string) => `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${titulo} · Financially</title>
  <meta name="description" content="${titulo} de Financially, app de finanzas personales de AFESDEV." />
  <style>
    :root { --bg:#f4f5f1; --surface:#fff; --ink:#10201b; --muted:#5a6762; --border:#e3e6e0; --accent:#0b6e4f; }
    * { box-sizing: border-box; }
    body { margin:0; background:var(--bg); color:var(--ink);
      font: 16px/1.65 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
    header { background:var(--ink); color:#fff; padding:28px 16px; }
    header .wrap, main { max-width:760px; margin:0 auto; }
    header .marca { font-weight:800; letter-spacing:.2px; opacity:.85; font-size:14px; }
    header h1 { margin:6px 0 4px; font-size:28px; line-height:1.2; }
    header p { margin:0; color:#b9c6c0; font-size:14px; }
    main { padding:24px 16px 48px; }
    section { background:var(--surface); border:1px solid var(--border); border-radius:20px;
      padding:20px; margin-bottom:14px; }
    h2 { font-size:18px; margin:0 0 8px; }
    p, li { color:#22312c; }
    ul { padding-left:20px; margin:8px 0; }
    li { margin:4px 0; }
    a { color:var(--accent); }
    nav { margin-top:20px; font-size:14px; color:var(--muted); }
    nav a { margin-right:14px; }
    .nota { color:var(--muted); font-size:14px; }
  </style>
</head>
<body>
  <header><div class="wrap">
    <div class="marca">Financially</div>
    <h1>${titulo}</h1>
    <p>Última actualización: ${ACTUALIZADO}</p>
  </div></header>
  <main>
${cuerpo}
    <nav>
      <a href="/privacidad">Política de privacidad</a>
      <a href="/terminos">Términos y condiciones</a>
      <a href="mailto:${CONTACTO}">Contacto</a>
    </nav>
  </main>
</body>
</html>`;

const PRIVACIDAD = pagina(
  'Política de privacidad',
  `
    <section>
      <p>Financially es una aplicación de finanzas personales desarrollada por
      <strong>AFESDEV</strong> (Montería, Colombia). Esta política explica qué datos
      recogemos, para qué los usamos y qué derechos tienes sobre ellos, de acuerdo con
      la Ley 1581 de 2012 de Colombia y las normas de Google Play.</p>
      <p><strong>Responsable del tratamiento:</strong> AFESDEV · Montería, Córdoba, Colombia ·
      <a href="mailto:${CONTACTO}">${CONTACTO}</a></p>
    </section>

    <section>
      <h2>1. Datos que recogemos</h2>
      <ul>
        <li><strong>Datos de tu cuenta:</strong> nombre, correo electrónico, contraseña y,
        si los das, teléfono, fecha de nacimiento y moneda preferida. La contraseña se
        guarda cifrada (bcrypt); nunca la conocemos en texto plano.</li>
        <li><strong>Información financiera que registras:</strong> cuentas, saldos,
        movimientos (gastos, ingresos y transferencias), categorías, presupuestos, metas,
        préstamos, tarjetas de crédito y pagos recurrentes. Son los datos que tú escribes
        o que la app registra por ti con el registro automático.</li>
        <li><strong>Datos técnicos mínimos:</strong> los que cualquier conexión a internet
        envía al servidor (por ejemplo, la dirección IP), usados solo para responder a la
        app y por seguridad.</li>
      </ul>
      <p>No pedimos ni guardamos números completos de tarjetas, claves bancarias,
      contraseñas de tu banco ni documentos de identidad. No accedemos a tu ubicación,
      contactos, fotos, micrófono ni cámara.</p>
    </section>

    <section>
      <h2>2. Registro automático y lectura de notificaciones</h2>
      <p>El registro automático de compras e ingresos es <strong>opcional</strong> y está
      apagado hasta que lo actives. Si lo activas, la app usa el permiso de acceso a
      notificaciones de Android para leer en tu teléfono los avisos de pago de tu banco o
      billetera (por ejemplo, "Compraste $50.000 en…").</p>
      <ul>
        <li>Solo se procesan avisos de apps de bancos, billeteras y los SMS que nombran un
        banco. Los mensajes de chats, correo y personas se ignoran.</li>
        <li>El aviso se analiza <strong>en tu teléfono</strong>. Al servidor solo se envía
        el movimiento resultante: monto, comercio, fecha, cuenta y, si aparecen, los
        últimos 4 dígitos de la tarjeta.</li>
        <li>El texto de los últimos avisos se guarda solo en tu teléfono para que puedas
        revisar qué se registró; no se envía al servidor.</li>
        <li>Puedes apagarlo en cualquier momento en la app (Perfil → Compras automáticas) o
        quitando el permiso en los ajustes de Android.</li>
      </ul>
    </section>

    <section>
      <h2>3. Para qué usamos tus datos</h2>
      <ul>
        <li>Crear y mantener tu cuenta, e iniciar sesión.</li>
        <li>Guardar y mostrarte tu información financiera, calcular saldos, presupuestos,
        cuotas y resúmenes.</li>
        <li>Enviarte, si lo permites, recordatorios en el teléfono: pagos de tarjeta,
        cuotas de préstamos, presupuestos y el resumen semanal.</li>
        <li>Recuperar tu contraseña cuando lo pidas.</li>
        <li>Mantener la seguridad del servicio.</li>
      </ul>
      <p><strong>No vendemos, alquilamos ni compartimos tus datos con fines
      publicitarios.</strong> La app no tiene anuncios ni herramientas de seguimiento.</p>
    </section>

    <section>
      <h2>4. Con quién se comparten</h2>
      <p>Solo con los proveedores necesarios para que la app funcione, que procesan los
      datos por cuenta nuestra:</p>
      <ul>
        <li><strong>Alojamiento del servidor y de la base de datos</strong> (por ejemplo,
        Vercel), donde se guardan tu cuenta y tu información financiera.</li>
        <li><strong>Tasas de cambio:</strong> si usas varias monedas, la app consulta tasas
        públicas en open.er-api.com. Solo se envían códigos de moneda, nunca datos tuyos.</li>
        <li><strong>Tipografías:</strong> la app puede descargar sus fuentes de Google
        Fonts, que recibe la solicitud técnica de tu teléfono.</li>
      </ul>
      <p>También podríamos entregar datos si una autoridad competente lo exige por ley.</p>
    </section>

    <section>
      <h2>5. Datos que se quedan en tu teléfono</h2>
      <ul>
        <li>La sesión se guarda cifrada en el almacenamiento seguro del teléfono.</li>
        <li>El bloqueo con huella o rostro usa la biometría del sistema: la app nunca recibe
        ni guarda tu huella o tu rostro.</li>
        <li>Los archivos que exportas (Excel o PDF) se crean en tu teléfono y solo se
        comparten si tú decides hacerlo.</li>
      </ul>
    </section>

    <section>
      <h2>6. Seguridad y conservación</h2>
      <p>Toda la comunicación entre la app y el servidor va cifrada (HTTPS). Conservamos
      tus datos mientras tengas una cuenta. Si la eliminas, borramos tu cuenta y tu
      información financiera, salvo lo que la ley nos obligue a conservar.</p>
    </section>

    <section id="eliminar-cuenta">
      <h2>7. Tus derechos y cómo eliminar tu cuenta</h2>
      <p>Puedes conocer, actualizar, rectificar y suprimir tus datos, y revocar la
      autorización para tratarlos. Para ejercer cualquiera de estos derechos o para
      <strong>eliminar tu cuenta y todos tus datos</strong>, escríbenos a
      <a href="mailto:${CONTACTO}?subject=Eliminar%20mi%20cuenta%20de%20Financially">${CONTACTO}</a>
      desde el correo de tu cuenta. Responderemos en un máximo de 15 días hábiles.</p>
      <p>También puedes presentar quejas ante la Superintendencia de Industria y Comercio
      (SIC) de Colombia.</p>
    </section>

    <section>
      <h2>8. Menores de edad</h2>
      <p>Financially no está dirigida a menores de 18 años y no recogemos a sabiendas datos
      de menores. Si crees que un menor nos dio sus datos, escríbenos y los eliminaremos.</p>
    </section>

    <section>
      <h2>9. Cambios a esta política</h2>
      <p>Si cambiamos esta política, publicaremos la nueva versión en esta página con su
      fecha. Si el cambio es importante, te avisaremos en la app.</p>
      <p class="nota">¿Preguntas? Escríbenos a <a href="mailto:${CONTACTO}">${CONTACTO}</a>.</p>
    </section>
`,
);

const TERMINOS = pagina(
  'Términos y condiciones',
  `
    <section>
      <p>Estos términos regulan el uso de Financially, aplicación de finanzas personales de
      <strong>AFESDEV</strong> (Montería, Colombia). Al crear una cuenta o usar la app
      aceptas estos términos y la <a href="/privacidad">Política de privacidad</a>.</p>
    </section>

    <section>
      <h2>1. Qué es Financially</h2>
      <p>Una herramienta para registrar y organizar tus finanzas: cuentas, movimientos,
      presupuestos, metas, préstamos y recordatorios. <strong>Financially no es un banco ni
      una entidad financiera</strong>: no guarda, mueve ni transfiere dinero real, y no se
      conecta a tus cuentas bancarias. Los saldos que ves son los que tú registras.</p>
    </section>

    <section>
      <h2>2. Tu cuenta</h2>
      <ul>
        <li>Debes ser mayor de 18 años y dar datos verdaderos.</li>
        <li>Eres responsable de mantener segura tu contraseña y tu teléfono.</li>
        <li>Si crees que alguien entró a tu cuenta, cambia la contraseña y escríbenos.</li>
      </ul>
    </section>

    <section>
      <h2>3. Información, no asesoría</h2>
      <p>Los cálculos de la app (saldos, cuotas, intereses, tablas de amortización,
      presupuestos y resúmenes) son aproximados y dependen de los datos que registras. No
      constituyen asesoría financiera, tributaria ni legal. Confirma siempre los valores
      oficiales con tu banco o entidad antes de tomar decisiones.</p>
    </section>

    <section>
      <h2>4. Registro automático</h2>
      <p>El registro automático lee los avisos de tu banco para ahorrarte trabajo, pero
      puede equivocarse o no detectar algún movimiento si el banco cambia el formato de sus
      mensajes. Revisa los movimientos registrados y corrígelos cuando haga falta.</p>
    </section>

    <section>
      <h2>5. Uso permitido</h2>
      <p>Usa la app solo para tus finanzas personales y de forma legal. No intentes acceder
      a cuentas ajenas, afectar el funcionamiento del servicio ni copiar o modificar la app.</p>
    </section>

    <section>
      <h2>6. Disponibilidad y responsabilidad</h2>
      <p>Trabajamos para que el servicio esté disponible y tus datos seguros, pero la app se
      ofrece "tal cual" y puede tener interrupciones o errores. En la medida que lo permita
      la ley colombiana, AFESDEV no responde por pérdidas derivadas de decisiones tomadas con
      base en la información de la app, de errores en los datos registrados o de
      interrupciones del servicio.</p>
    </section>

    <section>
      <h2>7. Precio</h2>
      <p>Hoy Financially es gratuita. Si en el futuro se ofrecen funciones de pago, se
      informará el precio y las condiciones antes de cualquier cobro.</p>
    </section>

    <section>
      <h2>8. Terminación</h2>
      <p>Puedes dejar de usar la app y pedir la eliminación de tu cuenta cuando quieras,
      como se explica en la <a href="/privacidad">Política de privacidad</a>. Podemos
      suspender cuentas que incumplan estos términos.</p>
    </section>

    <section>
      <h2>9. Cambios y ley aplicable</h2>
      <p>Podemos actualizar estos términos; publicaremos la nueva versión aquí con su fecha.
      Estos términos se rigen por las leyes de la República de Colombia.</p>
      <p class="nota">Contacto: <a href="mailto:${CONTACTO}">${CONTACTO}</a>.</p>
    </section>
`,
);

/** Registra /privacidad y /terminos (y alias en inglés) como páginas públicas. */
export function registrarPaginasLegales(app: INestApplication) {
  const http = app.getHttpAdapter().getInstance();
  const enviar = (html: string) => (_req: any, res: any) => {
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.setHeader('Cache-Control', 'public, max-age=3600');
    res.send(html);
  };
  for (const ruta of ['/privacidad', '/privacy-policy', '/privacy']) {
    http.get(ruta, enviar(PRIVACIDAD));
  }
  for (const ruta of ['/terminos', '/terms-of-service', '/terms']) {
    http.get(ruta, enviar(TERMINOS));
  }
  // Para el formulario de eliminación de datos de Google Play
  for (const ruta of ['/eliminar-cuenta', '/delete-account']) {
    http.get(ruta, (_req: any, res: any) => res.redirect('/privacidad#eliminar-cuenta'));
  }
}
