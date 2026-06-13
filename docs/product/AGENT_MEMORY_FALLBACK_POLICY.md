# Agent Memory Fallback Policy

- If Redis is unavailable, use local JSONL short-term memory metadata or display degraded status.
- If Vector DB is unavailable, use keyword search or structured index fallback.
- Shared memory is closed by default.
- Cross-Agent memory is not shared by default.
