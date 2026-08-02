"""See user_service/app/events.py for the full rationale - same shared
"trip_io.events" topic exchange, same best-effort semantics. This service
is the one that also *consumes* events - see events_consumer.py."""
import json
import logging
import os

import pika

logger = logging.getLogger("trip_io.recommendation_service.events")

RABBITMQ_URL = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
EXCHANGE = "trip_io.events"


def publish(routing_key: str, payload: dict) -> None:
    try:
        params = pika.URLParameters(RABBITMQ_URL)
        params.socket_timeout = 3
        connection = pika.BlockingConnection(params)
        channel = connection.channel()
        channel.exchange_declare(exchange=EXCHANGE, exchange_type="topic", durable=True)
        channel.basic_publish(
            exchange=EXCHANGE,
            routing_key=routing_key,
            body=json.dumps(payload).encode("utf-8"),
            properties=pika.BasicProperties(content_type="application/json", delivery_mode=2),
        )
        connection.close()
    except Exception as exc:  # noqa: BLE001 - must never break the caller
        logger.warning("Failed to publish event %s: %s", routing_key, exc)
