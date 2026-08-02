"""Publishes fire-and-forget domain events to RabbitMQ - the async half of
the inter-service communication this phase asks for, alongside the sync
REST calls in clients.py. A single "trip_io.events" topic exchange is
shared by all three services; each publishes to it and any service that
cares declares its own queue with a binding for the routing keys it wants
(see recommendation_service/app/events_consumer.py for the only current
consumer).

Deliberately best-effort: RabbitMQ being briefly unavailable should never
fail the user-facing request that triggered the event, so every failure
here is caught and logged, not raised.
"""
import json
import logging
import os

import pika

logger = logging.getLogger("trip_io.user_service.events")

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
    except Exception as exc:  # noqa: BLE001 - genuinely must never break the caller
        logger.warning("Failed to publish event %s: %s", routing_key, exc)
