"""EventBridge-driven reconciliation (audit); extend to mutate registry later."""

from __future__ import annotations

import json
import logging
import os
from typing import Any

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ.get("TABLE_NAME", "")


def handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Log structured events; optionally correlate with DynamoDB in a later iteration."""
    detail_type = event.get("detail-type") or event.get("detail_type")
    source = event.get("source")
    logger.info(
        "reconcile_event source=%s detail_type=%s region=%s account=%s",
        source,
        detail_type,
        event.get("region"),
        event.get("account"),
    )
    logger.debug("detail=%s", json.dumps(event.get("detail") or {}))
    return {"ok": True, "table_configured": bool(TABLE_NAME)}
