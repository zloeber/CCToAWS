#!/usr/bin/env python3
"""Generate an architecture diagram for the CCToAWS platform using the diagrams package.

Requires:
  - Python 3.10+
  - pip install -r scripts/requirements-diagrams.txt
  - Graphviz installed on the system (https://graphviz.org/download/)

Example:
  python3 scripts/generate_architecture_diagram.py
  python3 scripts/generate_architecture_diagram.py --out docs/cct_to_aws_architecture
"""

from __future__ import annotations

import argparse
from pathlib import Path

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2ContainerRegistry, Lambda
from diagrams.aws.database import Dynamodb
from diagrams.aws.integration import Eventbridge
from diagrams.aws.network import APIGateway
from diagrams.aws.security import IAM
from diagrams.aws.storage import S3


def build_diagram(out_base: Path, direction: str) -> None:
    """Write PNG (and Graphviz source) next to out_base; filename has no suffix."""
    out_base.parent.mkdir(parents=True, exist_ok=True)

    graph_attr = {
        "fontsize": "11",
        "bgcolor": "white",
        "pad": "0.4",
    }

    with Diagram(
        "CCToAWS — shared publishing platform",
        filename=str(out_base),
        show=False,
        direction=direction,
        graph_attr=graph_attr,
    ):
        principals = IAM("IAM principals\n(SSO / SigV4)")

        with Cluster("Registry API"):
            http_api = APIGateway("HTTP API\n$default stage")
            api_lambda = Lambda("registry-api\nLambda")

        with Cluster("Event-driven reconcile"):
            eventbridge = Eventbridge("EventBridge\nrules")
            reconcile_lambda = Lambda("reconcile\nLambda")

        with Cluster("Shared data"):
            table = Dynamodb("registry\nDynamoDB")
            bucket = S3("static site\nS3 bucket")
            ecr = EC2ContainerRegistry("shared\nECR")

        principals >> Edge(label="execute-api:Invoke\n(AWS_IAM)") >> http_api
        http_api >> Edge(label="proxy") >> api_lambda
        api_lambda >> Edge(label="PutItem / Query\nper caller ARN") >> table

        ecr >> Edge(label="ECR Image Action\n(PUSH)") >> eventbridge
        bucket >> Edge(label="Object Created") >> eventbridge
        eventbridge >> Edge(label="invoke") >> reconcile_lambda


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Render CCToAWS architecture (diagrams + Graphviz)."
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "docs" / "cct_to_aws_architecture",
        help="Output path without extension (PNG/SVG/dot written by diagrams).",
    )
    parser.add_argument(
        "--direction",
        choices=("LR", "TB", "RL", "BT"),
        default="LR",
        help="Graph layout direction (default: LR).",
    )
    args = parser.parse_args()

    build_diagram(args.out, args.direction)
    print(f"Wrote diagram files with base path: {args.out}")


if __name__ == "__main__":
    main()
