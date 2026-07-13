#!/usr/bin/env python3
"""
Backs up paperless-ngx via document_exporter and reports status to healthchecks.io
"""

import subprocess
import sys
import urllib.request
from typing import Optional, Tuple

# ---- Config ----
HC_URL = "https://hc-ping.com/fb534c8b-8cb6-4e47-b714-68d4567e3f87"
CONTAINER = "ix-paperless-ngx-paperless-1"
EXPORT_PATH = "/mnt/backup"
TIMEOUT = 30  # seconds, for each curl-equivalent request
RETRIES = 5


def hc_ping(url: str, data: Optional[bytes] = None) -> None:
    """Ping healthchecks.io, retrying on transient failures. Never raises."""
    req = urllib.request.Request(url, data=data, method="POST" if data is not None else "GET")
    last_err = None
    for attempt in range(1, RETRIES + 1):
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
                resp.read()  # drain response
            return
        except Exception as e:  # noqa: BLE001 - we want to retry on anything and continue regardless
            last_err = e
    # If we get here, all retries failed. Don't crash the backup over a ping failure;
    # just print a warning to stderr so it shows up in cron mail/logs if configured.
    print(f"WARNING: failed to ping {url}: {last_err}", file=sys.stderr)


def run_backup() -> Tuple[int, str]:
    """Run document_exporter inside the container, capturing combined stdout+stderr."""
    proc = subprocess.run(
        ["/bin/docker", "exec", CONTAINER, "document_exporter", EXPORT_PATH],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    return proc.returncode, proc.stdout


def main() -> int:
    # ---- Signal start ----
    hc_ping(f"{HC_URL}/start")

    # ---- Run backup ----
    exit_code, output = run_backup()

    # ---- Report result ----
    if exit_code == 0:
        hc_ping(HC_URL, data=output.encode("utf-8"))
    else:
        hc_ping(f"{HC_URL}/fail", data=output.encode("utf-8"))

    # Also print output locally so it shows up in cron logs if you redirect them
    print(output)

    return exit_code


if __name__ == "__main__":
    sys.exit(main())