"""Background consumer for the notification-relevant half of the shared
event bus - see recommendation_service/app/events_consumer.py for the
general rationale (same exchange, same best-effort semantics, same
daemon-thread-from-startup wiring).

Unlike that consumer, this one has a real side effect: a moderation
decision on a submitted destination becomes a persisted notification for
whoever submitted it, so "was my submission approved?" has an answer
inside the app (see /me/notifications in main.py) rather than only in an
admin's own view.
"""
import json
import logging
import threading
import time

import pika

from . import crud
from .events import RABBITMQ_URL, EXCHANGE

logger = logging.getLogger("trip_io.user_service.events_consumer")

QUEUE_NAME = "user_service.events"
ROUTING_KEYS = ("destination.approved", "destination.rejected")


def _handle_message(channel, method, properties, body):
    try:
        payload = json.loads(body.decode("utf-8"))
    except (ValueError, UnicodeDecodeError):
        payload = {}
    try:
        username = payload.get("submitted_by")
        destination_id = payload.get("destination_id")
        name = payload.get("name")
        if username and destination_id and name:
            status = "approved" if method.routing_key == "destination.approved" else "rejected"
            crud.create_notification(
                username=username,
                type_="moderation",
                title_key="notificationDestinationStatusTitle",
                body_key="notificationDestinationApprovedBody"
                if status == "approved"
                else "notificationDestinationRejectedBody",
                body_args={"name": name},
                destination_id=destination_id,
            )
    except Exception:  # noqa: BLE001 - a bad event must never wedge the queue
        logger.exception("Failed to handle %s", method.routing_key)
    channel.basic_ack(delivery_tag=method.delivery_tag)


def _run_forever():
    while True:
        try:
            params = pika.URLParameters(RABBITMQ_URL)
            connection = pika.BlockingConnection(params)
            channel = connection.channel()
            channel.exchange_declare(exchange=EXCHANGE, exchange_type="topic", durable=True)
            channel.queue_declare(queue=QUEUE_NAME, durable=True)
            for key in ROUTING_KEYS:
                channel.queue_bind(exchange=EXCHANGE, queue=QUEUE_NAME, routing_key=key)
            channel.basic_consume(queue=QUEUE_NAME, on_message_callback=_handle_message)
            logger.info("Listening for %s on queue %s", ROUTING_KEYS, QUEUE_NAME)
            channel.start_consuming()
        except Exception as exc:  # noqa: BLE001 - keep retrying, never crash the service
            logger.warning("Event consumer disconnected (%s) - retrying in 5s", exc)
            time.sleep(5)


def start_background_consumer() -> None:
    thread = threading.Thread(target=_run_forever, daemon=True, name="events-consumer")
    thread.start()
