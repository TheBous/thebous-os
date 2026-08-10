#!/usr/bin/env python3
"""Pure filtering logic for overnight email messages, kept separate from the
IMAP connection so it's testable with a fixture (no live mailbox needed).

Input: JSON array on stdin, each item {"date": "<RFC2822 or ISO date str>", ...}
Args: start_iso end_iso (both ISO 8601, UTC)
Output: JSON array of items whose parsed date falls in [start, end)
"""
import sys
import json
from email.utils import parsedate_to_datetime
from datetime import datetime, timezone


def parse_date(value):
    try:
        dt = parsedate_to_datetime(value)
    except (TypeError, ValueError):
        dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def filter_in_window(messages, start_iso, end_iso):
    start = parse_date(start_iso)
    end = parse_date(end_iso)
    return [m for m in messages if start <= parse_date(m["date"]) < end]


if __name__ == "__main__":
    start_iso, end_iso = sys.argv[1], sys.argv[2]
    messages = json.load(sys.stdin)
    print(json.dumps(filter_in_window(messages, start_iso, end_iso)))
