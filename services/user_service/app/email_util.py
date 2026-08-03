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


def is_configured() -> bool:
    return bool(SMTP_HOST and SMTP_USER and SMTP_PASSWORD)


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
    message.set_content(
        f"Your trip_io password reset code is: {code}\n\n"
        "Enter this in the app to choose a new password. This code expires "
        "in 30 minutes.\n\n"
        "If you didn't request this, you can safely ignore this email."
    )

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=10) as server:
            server.starttls()
            server.login(SMTP_USER, SMTP_PASSWORD)
            server.send_message(message)
    except Exception as exc:  # noqa: BLE001 - must never break the request flow
        logger.warning("Failed to send password reset email to %s: %s", to_email, exc)
