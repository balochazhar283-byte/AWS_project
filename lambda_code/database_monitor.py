"""
lambda_code/database_monitor.py

PURPOSE
    Runs inside the private app subnets every time EventBridge triggers it.
    1. Asks the RDS API for the instance status          (rds:DescribeDBInstances)
    2. Opens a TCP connection to the database port       (proves network + security group)
    3. Logs in and runs simple SQL                       (proves credentials + engine health)
    4. Builds a JSON report and uploads it to S3         (s3:PutObject)
    5. Publishes a summary to SNS -> your email          (sns:Publish)
    Everything printed with logger.* appears in CloudWatch Logs.

CONFIGURATION (environment variables set by Terraform - none of them secret)
    DB_SECRET_ARN, DB_HOST, DB_PORT, DB_NAME, DB_INSTANCE_ID,
    REPORT_BUCKET, SNS_TOPIC_ARN, NOTIFY_ONLY_ON_FAILURE
The username and password are read at run time from Secrets Manager.
"""

import json
import logging
import os
import socket
import ssl
import time
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Clients are created once per container and reused on warm invocations.
rds_client = boto3.client("rds")
s3_client = boto3.client("s3")
sns_client = boto3.client("sns")
secrets_client = boto3.client("secretsmanager")


def _timed(name, func):
    """Run one check, never raise; return a dict describing the outcome."""
    start = time.time()
    try:
        details = func()
        return {
            "check": name,
            "ok": True,
            "duration_ms": round((time.time() - start) * 1000),
            "details": details,
        }
    except Exception as exc:  # noqa: BLE001 - we want to report any failure
        logger.exception("Check '%s' failed", name)
        return {
            "check": name,
            "ok": False,
            "duration_ms": round((time.time() - start) * 1000),
            "details": f"{type(exc).__name__}: {exc}",
        }


def check_rds_status(instance_id):
    """Ask the RDS control plane whether the instance is 'available'."""
    response = rds_client.describe_db_instances(DBInstanceIdentifier=instance_id)
    db = response["DBInstances"][0]
    status = db["DBInstanceStatus"]
    if status != "available":
        raise RuntimeError(f"Instance status is '{status}', expected 'available'")
    return {
        "status": status,
        "engine": f"{db['Engine']} {db['EngineVersion']}",
        "instance_class": db["DBInstanceClass"],
        "multi_az": db["MultiAZ"],
    }


def check_tcp(host, port):
    """Can we reach the database port? Fails on routing/security-group problems."""
    with socket.create_connection((host, port), timeout=5):
        pass
    return f"TCP connection to {host}:{port} succeeded"


def check_sql(secret_arn, host, port, db_name):
    """Log in with the secret's credentials and run simple queries."""
    import pymysql  # packaged with the function by Terraform (see modules/lambda)

    secret = json.loads(
        secrets_client.get_secret_value(SecretId=secret_arn)["SecretString"]
    )

    # MySQL 8.4 uses caching_sha2_password, which needs an encrypted channel.
    # We use TLS but do not verify the server certificate (traffic never leaves
    # the private VPC). To verify, bundle the RDS CA file and set ca=... instead.
    tls = ssl.create_default_context()
    tls.check_hostname = False
    tls.verify_mode = ssl.CERT_NONE

    connection = pymysql.connect(
        host=host,
        port=int(port),
        user=secret["username"],
        password=secret["password"],
        database=db_name,
        connect_timeout=5,
        read_timeout=5,
        ssl=tls,
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.execute("SELECT VERSION()")
            version = cursor.fetchone()[0]
            cursor.execute("SHOW GLOBAL STATUS LIKE 'Threads_connected'")
            threads = cursor.fetchone()[1]
            cursor.execute("SHOW GLOBAL STATUS LIKE 'Uptime'")
            uptime = cursor.fetchone()[1]
    finally:
        connection.close()
    return {
        "mysql_version": version,
        "threads_connected": threads,
        "uptime_seconds": uptime,
    }


def build_message(report):
    lines = [
        f"Database monitoring report - {report['overall_status']}",
        f"Time (UTC): {report['timestamp']}",
        f"Instance:   {report['db_instance_id']}",
        "",
    ]
    for check in report["checks"]:
        mark = "OK  " if check["ok"] else "FAIL"
        lines.append(f"[{mark}] {check['check']} ({check['duration_ms']} ms)")
        lines.append(f"       {check['details']}")
    lines += ["", f"Full report: s3://{report['report_location']}"]
    return "\n".join(lines)


def lambda_handler(event, context):
    host = os.environ["DB_HOST"]
    port = int(os.environ["DB_PORT"])
    db_name = os.environ["DB_NAME"]
    instance_id = os.environ["DB_INSTANCE_ID"]
    secret_arn = os.environ["DB_SECRET_ARN"]
    bucket = os.environ["REPORT_BUCKET"]
    topic_arn = os.environ["SNS_TOPIC_ARN"]
    only_on_failure = os.environ.get("NOTIFY_ONLY_ON_FAILURE", "false").lower() == "true"

    logger.info("Starting database health check for %s", instance_id)

    checks = [
        _timed("RDS instance status", lambda: check_rds_status(instance_id)),
        _timed("TCP connectivity", lambda: check_tcp(host, port)),
        _timed("SQL query", lambda: check_sql(secret_arn, host, port, db_name)),
    ]
    healthy = all(c["ok"] for c in checks)

    now = datetime.now(timezone.utc)
    key = f"reports/{now:%Y/%m/%d}/db-report-{now:%Y%m%dT%H%M%SZ}.json"
    report = {
        "timestamp": now.isoformat(),
        "overall_status": "HEALTHY" if healthy else "UNHEALTHY",
        "db_instance_id": instance_id,
        "checks": checks,
        "report_location": f"{bucket}/{key}",
    }

    # Upload the report. A failure here must not stop the notification.
    try:
        s3_client.put_object(
            Bucket=bucket,
            Key=key,
            Body=json.dumps(report, indent=2).encode("utf-8"),
            ContentType="application/json",
            ServerSideEncryption="AES256",
        )
        logger.info("Report stored at s3://%s/%s", bucket, key)
    except Exception:  # noqa: BLE001
        logger.exception("Could not upload report to S3")
        report["overall_status"] = "UNHEALTHY"
        report["checks"].append(
            {"check": "S3 upload", "ok": False, "duration_ms": 0,
             "details": "Report upload failed - see CloudWatch Logs"}
        )
        healthy = False

    # Notify (unless configured to alert only on failures).
    if healthy and only_on_failure:
        logger.info("Healthy and NOTIFY_ONLY_ON_FAILURE=true: skipping email")
    else:
        subject = f"[{report['overall_status']}] DB monitor: {instance_id}"[:100]
        sns_client.publish(
            TopicArn=topic_arn,
            Subject=subject,
            Message=build_message(report),
        )
        logger.info("Notification published to SNS")

    logger.info("Finished: %s", report["overall_status"])
    return {"status": report["overall_status"], "report": f"s3://{bucket}/{key}"}
