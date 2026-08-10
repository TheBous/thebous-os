#!/usr/bin/env python3
"""Self-check for filter_messages_in_window.py. Run: python3 scripts/test_filter_messages_in_window.py"""
from filter_messages_in_window import filter_in_window

messages = [
    {"id": "in-window-1", "date": "Mon, 10 Aug 2026 21:00:00 +0000"},
    {"id": "in-window-2", "date": "2026-08-10T23:59:00Z"},
    {"id": "before-window", "date": "2026-08-09T18:00:00Z"},
    {"id": "after-window", "date": "2026-08-11T06:00:00Z"},
]

result = filter_in_window(messages, "2026-08-09T20:00:00Z", "2026-08-11T00:00:00Z")
ids = {m["id"] for m in result}

fail = 0
if ids == {"in-window-1", "in-window-2"}:
    print("PASS: keeps only messages in window, handles RFC2822 and ISO dates")
else:
    print(f"FAIL: expected in-window-1/2, got {ids}")
    fail = 1

if fail == 0:
    print("All filter_messages_in_window checks passed.")
else:
    print("Some checks FAILED.")

exit(fail)
