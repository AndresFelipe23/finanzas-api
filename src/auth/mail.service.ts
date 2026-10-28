import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly resend: Resend | null;
  private readonly from: string;
  private readonly webUrl: string;

  constructor(private readonly config: ConfigService) {
    const apiKey = this.config.get<string>('RESEND_API_KEY');
    this.from = this.config.get<string>('MAIL_FROM') || 'Financially <noreply@financially.cloud>';
    this.webUrl = (this.config.get<string>('WEB_URL') || 'http://localhost:5173').replace(/\/+$/, '');
    this.resend = apiKey ? new Resend(apiKey) : null;

    if (!this.resend) {
      this.logger.warn(
        'RESEND_API_KEY no configurada: los correos no se enviarán, se registrará el enlace en el log (modo desarrollo).',
      );
    }
  }

  /**
   * Envía el correo de recuperación de contraseña.
   * Si Resend no está configurado, registra el enlace en el log en vez de fallar,
   * para no bloquear el desarrollo mientras el dominio se verifica.
   */
  async sendPasswordReset(email: string, nombre: string, token: string): Promise<void> {
    const link = `${this.webUrl}/reset-password?token=${token}`;

    if (!this.resend) {
      this.logger.log(`[DEV] Enlace de recuperación para ${email}: ${link}`);
      return;
    }

    try {
      await this.resend.emails.send({
        from: this.from,
        to: email,
        subject: 'Restablece tu contraseña de Financially',
        html: this.passwordResetHtml(nombre, link),
      });
    } catch (error) {
      this.logger.error(`Error al enviar correo de recuperación a ${email}: ${error.message}`);
      // No relanzamos: el endpoint siempre responde igual para no filtrar qué correos existen.
    }
  }

  private passwordResetHtml(nombre: string, link: string): string {
    const primerNombre = (nombre || '').split(' ')[0] || 'Hola';
    return `
<!DOCTYPE html>
<html lang="es">
  <body style="margin:0;padding:0;background:#f1f5f9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
    <div style="max-width:480px;margin:0 auto;padding:32px 20px;">
      <div style="background:#ffffff;border-radius:20px;padding:36px 32px;border:1px solid #e2e8f0;">
        <div style="font-size:20px;font-weight:700;color:#0f172a;letter-spacing:-0.02em;">Financially</div>
        <h1 style="margin:28px 0 8px;font-size:22px;color:#0f172a;letter-spacing:-0.02em;">Restablece tu contraseña</h1>
        <p style="margin:0 0 24px;font-size:15px;line-height:1.6;color:#475569;">
          Hola ${primerNombre}, recibimos una solicitud para restablecer la contraseña de tu cuenta.
          Haz clic en el botón para elegir una nueva. Este enlace caduca en 1 hora.
        </p>
        <a href="${link}" style="display:inline-block;background:#1eb256;color:#ffffff;text-decoration:none;font-size:15px;font-weight:600;padding:13px 28px;border-radius:9999px;">
          Cambiar mi contraseña
        </a>
        <p style="margin:28px 0 0;font-size:13px;line-height:1.6;color:#94a3b8;">
          Si no pediste este cambio, puedes ignorar este correo: tu contraseña seguirá igual.
        </p>
        <p style="margin:16px 0 0;font-size:12px;line-height:1.5;color:#cbd5e1;word-break:break-all;">
          O copia este enlace: ${link}
        </p>
      </div>
      <p style="text-align:center;margin:20px 0 0;font-size:12px;color:#94a3b8;">
        © ${new Date().getFullYear()} Financially
      </p>
    </div>
  </body>
</html>`;
  }
}
