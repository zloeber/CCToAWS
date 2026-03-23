"""HTTP API Lambda: register deployment metadata (source of truth)."""

from __future__ import annotations

import json
import os
import re
import time
from typing import Any
from urllib.parse import unquote

import boto3

ddb = boto3.client("dynamodb")
TABLE_NAME = os.environ["TABLE_NAME"]
APP_ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]{1,62}$")


def _response(status: int, body: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _caller_arn(event: dict[str, Any]) -> str | None:
    rc = event.get("requestContext") or {}
    ident = rc.get("identity") or {}
    return ident.get("userArn") or ident.get("callerArn")


def _normalize_path(path: str) -> str:
    p = path or "/"
    if len(p) > 1 and p.endswith("/"):
        p = p[:-1]
    return p


def dispatch(event: dict[str, Any], context: Any) -> dict[str, Any]:
    method = (event.get("requestContext") or {}).get("http", {}).get("method", "GET")
    path = _normalize_path(event.get("rawPath") or "/")
    params = event.get("pathParameters") or {}

    if method == "POST" and path == "/v1/register":
        return handle_register(event)
    if method == "GET" and path == "/v1/apps":
        return handle_list_apps(event)
    if method == "GET" and params.get("appId"):
        return handle_get_app(event, unquote(params["appId"]))
    if method == "GET" and path.startswith("/v1/apps/"):
        app_id = unquote(path.removeprefix("/v1/apps/").split("/", 1)[0])
        return handle_get_app(event, app_id)

    return _response(404, {"error": "not_found", "path": path, "method": method})


def handle_register(event: dict[str, Any]) -> dict[str, Any]:
    arn = _caller_arn(event)
    if not arn:
        return _response(403, {"error": "missing_caller_identity"})

    try:
        payload = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "invalid_json"})

    app_id = str(payload.get("app_id") or "").strip()
    if not app_id or not APP_ID_RE.match(app_id):
        return _response(
            400,
            {"error": "invalid_app_id", "hint": "use lowercase letters, digits, hyphen; 2-63 chars"},
        )

    deployment_type = str(payload.get("deployment_type") or "").strip().lower()
    if deployment_type not in ("static", "container"):
        return _response(400, {"error": "invalid_deployment_type"})

    revision = str(payload.get("revision") or "").strip() or str(int(time.time()))
    now = str(int(time.time()))

    item: dict[str, Any] = {
        "pk": {"S": f"USER#{arn}"},
        "sk": {"S": f"APP#{app_id}"},
        "deployment_type": {"S": deployment_type},
        "revision": {"S": revision},
        "updated_at": {"S": now},
    }

    if deployment_type == "static":
        base = str(payload.get("static_url") or "").strip()
        if not base:
            return _response(400, {"error": "static_url_required"})
        item["static_url"] = {"S": base}
    else:
        image_uri = str(payload.get("image_uri") or "").strip()
        runtime_url = str(payload.get("runtime_url") or "").strip()
        if not image_uri and not runtime_url:
            return _response(400, {"error": "image_uri_or_runtime_url_required"})
        if image_uri:
            item["image_uri"] = {"S": image_uri}
        if runtime_url:
            item["runtime_url"] = {"S": runtime_url}

    ddb.put_item(TableName=TABLE_NAME, Item=item)
    return _response(200, {"ok": True, "app_id": app_id, "revision": revision})


def handle_list_apps(event: dict[str, Any]) -> dict[str, Any]:
    arn = _caller_arn(event)
    if not arn:
        return _response(403, {"error": "missing_caller_identity"})

    resp = ddb.query(
        TableName=TABLE_NAME,
        KeyConditionExpression="pk = :p AND begins_with(sk, :a)",
        ExpressionAttributeValues={
            ":p": {"S": f"USER#{arn}"},
            ":a": {"S": "APP#"},
        },
    )
    apps: list[dict[str, Any]] = []
    for row in resp.get("Items") or []:
        sk = row.get("sk", {}).get("S", "")
        aid = sk.removeprefix("APP#") if sk.startswith("APP#") else sk
        apps.append(_item_to_json(row, aid))
    return _response(200, {"apps": apps})


def handle_get_app(event: dict[str, Any], app_id: str) -> dict[str, Any]:
    arn = _caller_arn(event)
    if not arn:
        return _response(403, {"error": "missing_caller_identity"})
    if not app_id or not APP_ID_RE.match(app_id):
        return _response(400, {"error": "invalid_app_id"})

    resp = ddb.get_item(
        TableName=TABLE_NAME,
        Key={"pk": {"S": f"USER#{arn}"}, "sk": {"S": f"APP#{app_id}"}},
    )
    if "Item" not in resp:
        return _response(404, {"error": "not_found"})
    return _response(200, _item_to_json(resp["Item"], app_id))


def _item_to_json(row: dict[str, Any], app_id: str) -> dict[str, Any]:
    out: dict[str, Any] = {"app_id": app_id}
    for k, v in row.items():
        if k in ("pk", "sk"):
            continue
        if "S" in v:
            out[k] = v["S"]
        elif "N" in v:
            out[k] = v["N"]
    return out
