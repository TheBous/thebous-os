# Filters an OpenCode /api/session response down to sessions touched within
# [$start, $end) (epoch ms, local-day boundaries). Kept in its own file so
# the same filter can be tested with a fixture and reused by the real script.
[.data[] | select(.time.updated >= $start and .time.updated < $end)]
