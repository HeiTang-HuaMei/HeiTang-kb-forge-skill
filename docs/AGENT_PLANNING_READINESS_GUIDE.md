# Agent Planning Readiness Guide

This guide explains the v1.2.0 Agent Planning Readiness Pack.

## Positioning

Agent Planning Readiness generates planning assets for future Agent Planning or Tool Runtime. It is not Agent Planning Runtime.

It does not execute plans, does not call tools, does not run multi-step workflow runtime, and does not connect to real business systems.

## Command

PowerShell example:

    heitang-kb-forge planning-readiness --package .\output_sample --output .\planning_output

## Outputs

- agent_planning_blueprint.yaml
- tool_requirement_map.json
- planning_eval_cases.jsonl
- planning_risk_report.md

## What These Files Are For

These files help downstream Agent Planning systems understand:

- which tasks the package is suitable for
- which tasks need tools
- which tasks need human confirmation
- which tasks are high risk
- which tasks lack required data
- which citations are required

## Boundaries

This module does not do Tool Runtime, permissions, SaaS, real business integration, CRM calls, product system calls, order system calls, or real external platform API calls.
