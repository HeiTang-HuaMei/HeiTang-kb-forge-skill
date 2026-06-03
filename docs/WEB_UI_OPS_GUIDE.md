# Web UI Ops Guide

This guide explains the v1.2.0 Web UI upgrade.

## Positioning

The Web UI is an optional local operations interface. It is not a production deployment platform, does not implement login, permissions, SaaS multi-tenancy, Tool Runtime, or real business integration.

## Installation

The Web UI uses an optional extra and is not part of the default dependency set.

PowerShell example:

    pip install -e ".[web]"

## Start

PowerShell example:

    heitang-kb-forge web

Alternative:

    python -m heitang_kb_forge.web.app

## Capabilities

The Web UI can read the local workspace registry and expose knowledge package operations views:

- package list
- package detail
- version diff
- quality report
- risk labels
- review queue
- ask test
- refresh plan
- export / publish profile

It can trigger local operations such as diff, refresh-check, review-create, and ask.

## Testing Boundary

Default pytest does not require Streamlit. Web tests should remain lightweight import or function smoke tests and should not require browser e2e.

## Boundaries

The Web UI does not do login, permissions, SaaS multi-tenancy, production deployment, Tool Runtime, real business integration, or real external platform API calls.
