"""
Activities — the building blocks of Temporal workflows.

An activity is a regular Python function decorated with @activity.defn.
Activities are where you put code that has side effects:
  - Call external APIs
  - Read/write databases
  - Send emails
  - Process files

Unlike workflows, activities do NOT need to be deterministic.
Temporal automatically retries failed activities based on your retry policy.
"""

import asyncio
import random
from temporalio import activity


@activity.defn
async def create_order(order_id: str) -> dict:
    """Simulate creating an order in the database."""
    activity.logger.info(f"Creating order {order_id}")
    await asyncio.sleep(0.5)  # simulate DB call
    return {"order_id": order_id, "status": "created"}


@activity.defn
async def process_payment(order_id: str) -> dict:
    """Simulate charging a credit card."""
    activity.logger.info(f"Processing payment for order {order_id}")
    await asyncio.sleep(1)  # simulate payment gateway call

    # Simulate occasional failures (20% chance) to demonstrate retries
    if random.random() < 0.2:
        raise RuntimeError(f"Payment gateway timeout for order {order_id}")

    return {"order_id": order_id, "payment_status": "charged"}


@activity.defn
async def ship_order(order_id: str) -> dict:
    """Simulate scheduling a shipment."""
    activity.logger.info(f"Shipping order {order_id}")
    await asyncio.sleep(0.5)  # simulate shipping API call
    return {"order_id": order_id, "tracking": f"TRACK-{order_id[:8]}"}


@activity.defn
async def cancel_order(order_id: str) -> dict:
    """Compensation: cancel the order."""
    activity.logger.info(f"COMPENSATING: Cancelling order {order_id}")
    await asyncio.sleep(0.3)
    return {"order_id": order_id, "status": "cancelled"}


@activity.defn
async def refund_payment(order_id: str) -> dict:
    """Compensation: refund the payment."""
    activity.logger.info(f"COMPENSATING: Refunding payment for order {order_id}")
    await asyncio.sleep(0.5)
    return {"order_id": order_id, "payment_status": "refunded"}


@activity.defn
async def cancel_shipment(order_id: str) -> dict:
    """Compensation: cancel the shipment."""
    activity.logger.info(f"COMPENSATING: Cancelling shipment for order {order_id}")
    await asyncio.sleep(0.3)
    return {"order_id": order_id, "shipment_status": "cancelled"}


@activity.defn
async def send_notification(message: str) -> str:
    """Simulate sending an email or push notification."""
    activity.logger.info(f"Sending notification: {message}")
    await asyncio.sleep(0.2)
    return f"Notification sent: {message}"
