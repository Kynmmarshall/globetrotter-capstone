"""Background consumer for the async half of inter-service communication.

Recommendation Service is the natural listener for the domain events the
other two publish - a new account or a newly-planned trip is exactly the
kind of thing that should be able to influence what gets recommended next.
Runs in a daemon thread started from main.py's startup hook (pika's
BlockingConnection isn't asyncio-native, and a whole extra container just
for this one queue would be overkill for what it does).

Currently the handlers just log what they'd act on - there's no
recommendation cache to invalidate yet (recommendations_for() computes
fresh every call), so this is the honest, un-oversold version of "listens
for events and reacts": the wiring is real and running, the reaction is
observability rather than a fabricated side effect.
"""
import json
import logging
import threading
import time

import pika

from .events import RABBITMQ_URL, EXCHANGE

logger = logging.getLogger("trip_io.recommendation_service.events_consumer")

QUEUE_NAME = "recommendation_service.events"
ROUTING_KEYS = ("user.registered", "itinerary.created", "destination.rated")


def _handle_message(channel, method, properties, body):
    try:
        payload = json.loads(body.decode("utf-8"))
    except (ValueError, UnicodeDecodeError):
        payload = {"raw": body}
    logger.info("Received %s: %s", method.routing_key, payload)
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
