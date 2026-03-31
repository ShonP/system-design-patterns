"""
Workflows — the orchestration logic for Temporal.

A workflow is a class decorated with @workflow.defn that coordinates activities.
Key rules for workflow code:
  1. Must be DETERMINISTIC — no random(), no datetime.now(), no external I/O
  2. All side effects go in activities
  3. Temporal replays workflow code from event history on recovery

Think of a workflow as a "recipe" and activities as the "cooking steps".
The recipe itself never changes, but the steps might fail and need retrying.
"""

from datetime import timedelta
from temporalio import workflow
from temporalio.common import RetryPolicy

# This import pattern is required because workflow code runs in a sandbox.
# Activities need to be imported through this special context manager.
with workflow.unsafe.imports_passed_through():
    from activities import (
        create_order,
        process_payment,
        ship_order,
        cancel_order,
        refund_payment,
        cancel_shipment,
        send_notification,
    )


@workflow.defn
class OrderWorkflow:
    """
    A simple order processing workflow that demonstrates the Saga pattern.

    Steps: Create Order → Process Payment → Ship Order
    If any step fails, previous steps are compensated (rolled back).
    """

    @workflow.run
    async def run(self, order_id: str) -> dict:
        # This list tracks which compensations to run if something fails.
        # Each time a step succeeds, we add its "undo" action.
        compensations = []

        retry_policy = RetryPolicy(
            initial_interval=timedelta(seconds=1),
            backoff_coefficient=2.0,
            maximum_interval=timedelta(seconds=30),
            maximum_attempts=5,
        )

        try:
            # Step 1: Create the order
            order = await workflow.execute_activity(
                create_order,
                order_id,
                start_to_close_timeout=timedelta(seconds=10),
                retry_policy=retry_policy,
            )
            compensations.append(cancel_order)

            # Step 2: Charge payment
            payment = await workflow.execute_activity(
                process_payment,
                order_id,
                start_to_close_timeout=timedelta(seconds=30),
                retry_policy=retry_policy,
            )
            compensations.append(refund_payment)

            # Step 3: Ship the order
            shipment = await workflow.execute_activity(
                ship_order,
                order_id,
                start_to_close_timeout=timedelta(seconds=10),
                retry_policy=retry_policy,
            )
            # No compensation needed for shipping if it succeeds — we're done!

            # Send success notification
            await workflow.execute_activity(
                send_notification,
                f"Order {order_id} completed! Tracking: {shipment['tracking']}",
                start_to_close_timeout=timedelta(seconds=10),
            )

            return {
                "status": "completed",
                "order": order,
                "payment": payment,
                "shipment": shipment,
            }

        except Exception as e:
            # Something went wrong — run compensations in REVERSE order.
            # This is the heart of the Saga pattern.
            workflow.logger.error(f"Order {order_id} failed: {e}. Running compensations...")

            for compensation in reversed(compensations):
                try:
                    await workflow.execute_activity(
                        compensation,
                        order_id,
                        start_to_close_timeout=timedelta(seconds=10),
                        retry_policy=retry_policy,
                    )
                except Exception as comp_error:
                    # Log but don't stop — we want to run ALL compensations
                    workflow.logger.error(
                        f"Compensation {compensation} failed: {comp_error}"
                    )

            await workflow.execute_activity(
                send_notification,
                f"Order {order_id} failed and was rolled back.",
                start_to_close_timeout=timedelta(seconds=10),
            )

            return {"status": "failed", "error": str(e)}
