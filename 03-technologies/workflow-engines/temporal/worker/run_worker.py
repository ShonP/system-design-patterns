"""
Worker entrypoint — connects to Temporal and starts polling for tasks.

A "worker" is a long-running process that:
  1. Connects to the Temporal server
  2. Registers which workflows and activities it can handle
  3. Polls a "task queue" for new work
  4. Executes workflow/activity code when tasks arrive

You can run multiple workers for the same task queue (horizontal scaling).
Temporal distributes tasks across all available workers automatically.
"""

import asyncio
import os
import logging

from temporalio.client import Client
from temporalio.worker import Worker

from workflows import OrderWorkflow
from activities import (
    create_order,
    process_payment,
    ship_order,
    cancel_order,
    refund_payment,
    cancel_shipment,
    send_notification,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Read Temporal address from environment variable, default to localhost
TEMPORAL_ADDRESS = os.environ.get("TEMPORAL_ADDRESS", "localhost:7233")
TASK_QUEUE = "demo-task-queue"


async def main():
    logger.info(f"Connecting to Temporal at {TEMPORAL_ADDRESS}...")
    client = await Client.connect(TEMPORAL_ADDRESS)
    logger.info(f"Connected! Starting worker on task queue '{TASK_QUEUE}'...")

    worker = Worker(
        client,
        task_queue=TASK_QUEUE,
        workflows=[OrderWorkflow],
        activities=[
            create_order,
            process_payment,
            ship_order,
            cancel_order,
            refund_payment,
            cancel_shipment,
            send_notification,
        ],
    )

    logger.info("Worker is running. Press Ctrl+C to stop.")
    await worker.run()


if __name__ == "__main__":
    asyncio.run(main())
