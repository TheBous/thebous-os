#!/usr/bin/env python3
"""Universal Gmail fallback for harnesses without a native Gmail connector
(OpenCode, Codex, etc). Uses IMAP with a Gmail App Password — no OAuth app
registration needed, works identically regardless of which agent harness
calls it, since it's just stdlib + a stored secret.

Requires a Google Account with 2-Step Verification and an App Password
generated at https://myaccount.google.com/apppasswords (16 chars, no spaces).

Usage: gmail_imap_overnight.py <address> <app_password>
Prints JSON array of {"id", "date", "from", "subject"} for unread messages
from the last 2 days (IMAP SEARCH is day-granular) — pipe through
filter_messages_in_window.py for the precise overnight window.
Prints "[]" (not an error) on any auth/connection failure — this data
source is optional, its absence shouldn't break the rest of the briefing.
"""
import sys
import json
import imaplib
import email
from email.header import decode_header
from datetime import datetime, timedelta, timezone


def decode(value):
    if not value:
        return ""
    parts = decode_header(value)
    return "".join(
        p.decode(enc or "utf-8", errors="replace") if isinstance(p, bytes) else p
        for p, enc in parts
    )


def main(address, app_password):
    since = (datetime.now(timezone.utc) - timedelta(days=2)).strftime("%d-%b-%Y")
    try:
        conn = imaplib.IMAP4_SSL("imap.gmail.com")
        conn.login(address, app_password)
        conn.select("INBOX")
        status, data = conn.search(None, f'(UNSEEN SINCE "{since}")')
        if status != "OK":
            return []
        results = []
        for msg_id in data[0].split():
            status, msg_data = conn.fetch(msg_id, "(BODY.PEEK[HEADER.FIELDS (DATE FROM SUBJECT)])")
            if status != "OK":
                continue
            msg = email.message_from_bytes(msg_data[0][1])
            results.append({
                "id": msg_id.decode(),
                "date": msg.get("Date", ""),
                "from": decode(msg.get("From", "")),
                "subject": decode(msg.get("Subject", "")),
            })
        conn.logout()
        return results
    except Exception:
        return []


if __name__ == "__main__":
    address, app_password = sys.argv[1], sys.argv[2]
    print(json.dumps(main(address, app_password)))
