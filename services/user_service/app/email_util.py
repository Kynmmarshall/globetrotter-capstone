"""Password-reset email delivery via SMTP - same "optional external
service, gated by env vars, gracefully degrades when unset" pattern as
recommendation_service's ai.py (Groq) and routing.py (ORS) proxies.
"""
import logging
import os
import smtplib
from email.message import EmailMessage

logger = logging.getLogger("trip_io.user_service.email")

SMTP_HOST = os.getenv("SMTP_HOST")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD")
SMTP_FROM_ADDRESS = os.getenv("SMTP_FROM_ADDRESS") or SMTP_USER or "no-reply@trip-io.app"

# Used only to build the logo's <img> src in the HTML email - the asset
# itself lives in the public website, not this service, so this just needs
# to point at wherever that's actually deployed (see website/assets/logo.png).
PUBLIC_SITE_URL = os.getenv("PUBLIC_SITE_URL", "https://trip-io.duckdns.org")


def is_configured() -> bool:
    return bool(SMTP_HOST and SMTP_USER and SMTP_PASSWORD)


def _plain_text_body(code: str) -> str:
    return (
        f"Your trip_io password reset code is: {code}\n\n"
        "Enter this in the app to choose a new password. This code expires "
        "in 30 minutes.\n\n"
        "If you didn't request this, you can safely ignore this email."
    )


def _html_body(code: str) -> str:
    logo_url = f"{PUBLIC_SITE_URL.rstrip('/')}/assets/logo.png"
    # Table-based layout with inline styles only - transactional email
    # clients (Outlook desktop especially) don't reliably support external
    # stylesheets, flexbox/grid, or CSS gradients, so this deliberately
    # stays to the lowest-common-denominator subset that renders
    # consistently everywhere. Colors match the public website's palette
    # (website/css/style.css : --brand-teal, --brand-blue, --bg).
    return f"""\
<!doctype html>
<html>
  <body style="margin:0;padding:0;background-color:#07131a;font-family:'Segoe UI',Helvetica,Arial,sans-serif;">
    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#07131a;padding:32px 16px;">
      <tr>
        <td align="center">
          <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;">
            <tr>
              <td align="center" style="padding-bottom:28px;">
                <img src="{logo_url}" width="44" height="44" alt="trip_io" style="display:block;border-radius:10px;" />
                <div style="margin-top:10px;font-size:20px;font-weight:800;">
                  <span style="color:#ffffff;">trip</span><span style="color:#14b8c4;">_io</span>
                </div>
              </td>
            </tr>
            <tr>
              <td style="background-color:#0d1b24;border:1px solid #1c2e38;border-radius:16px;padding:32px 28px;">
                <p style="margin:0 0 4px;color:#ffffff;font-size:18px;font-weight:700;">Reset your password</p>
                <p style="margin:0 0 24px;color:#b7c2c8;font-size:14px;line-height:1.5;">
                  Enter this code in the app to choose a new password. It expires in 30 minutes.
                </p>
                <table role="presentation" width="100%" cellpadding="0" cellspacing="0">
                  <tr>
                    <td align="center" style="background-color:#0a7e8c;border-radius:12px;padding:18px 0;">
                      <span style="font-family:'Courier New',Courier,monospace;font-size:32px;font-weight:800;letter-spacing:8px;color:#ffffff;">{code}</span>
                    </td>
                  </tr>
                </table>
                <p style="margin:24px 0 0;color:#6b7880;font-size:12.5px;line-height:1.5;">
                  If you didn't request this, you can safely ignore this email - your password won't be changed.
                </p>
              </td>
            </tr>
            <tr>
              <td align="center" style="padding-top:24px;">
                <p style="margin:0;color:#4a555c;font-size:12px;">Built for Yaoundé, Cameroon. &copy; trip_io</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
"""


def send_password_reset_code(to_email: str, code: str) -> None:
    """Best-effort - never raises, so a delivery hiccup never turns into a
    500 on the request-password-reset endpoint (which must always answer
    the same way regardless of delivery outcome - see main.py). If SMTP
    isn't configured at all, logs the code instead of silently discarding
    it, so the flow is still testable without setting up real email
    infrastructure first.
    """
    if not is_configured():
        logger.warning(
            "SMTP not configured - password reset code for %s is %s (would have been emailed)",
            to_email,
            code,
        )
        return

    message = EmailMessage()
    message["Subject"] = "Your trip_io password reset code"
    message["From"] = SMTP_FROM_ADDRESS
    message["To"] = to_email
    # Plain text first (the fallback part), then the HTML alternative - a
    # missing text part hurts spam scoring, and some clients still prefer it.
    message.set_content(_plain_text_body(code))
    message.add_alternative(_html_body(code), subtype="html")

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=10) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(message)
    except Exception as exc:  # noqa: BLE001 - must never break the request flow
        logger.warning("Failed to send password reset email to %s: %s", to_email, exc)
