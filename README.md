# Salesforce Case Workspace (Portfolio Project)

Production-style Salesforce Case Workspace demonstrating **enterprise Apex architecture**, **fflib patterns**, and **testable service-layer design**.

This repository is intended as a **code-quality portfolio**, not a Trailhead demo.

---

## What This Project Demonstrates

- Clean separation of concerns (Controller → Service → Selectors)
- Service-layer business logic (no SOQL/DML in controllers)
- `fflib_SObjectUnitOfWork` for transactional consistency
- Explicit DTOs instead of exposing SObjects to the UI
- Dependency injection with `fflib_ApexMocks`
- Behaviour-driven unit tests (not coverage-only tests)

---

## Core Features

- Retrieve a Case Workspace (Case, Owner, Account)
- Retrieve latest Customer Context for a Case
- Retrieve recent Case Updates (ordered & limited)
- Create Case Updates
- Mark Case as reviewed
- Escalate Case (priority update + audit trail in one transaction)

---

## Architecture Overview

LWC
└── CaseWorkspaceController
└── CaseWorkspaceService (facade)
└── CaseWorkspaceServiceImpl
├── Selectors (SOQL only)
├── Unit of Work (DML)
└── DTO mapping

---

## Architecture Overview
- No business logic in controllers  
- No SOQL outside selectors  
- No DML outside Unit of Work  

---

## Testing Strategy

- Service tests validate behaviour and edge cases
- Controller tests verify delegation only
- Selectors tested only where query logic is non-trivial
- All dependencies mocked via `SFDC_Application`

Test naming convention:
method_given_condition_when_action_then_result

---

## Tech Stack

- Salesforce Apex
- Lightning Web Components (LWC)
- Salesforce DX
- fflib Apex Common
- fflib Apex Mocks

---

## Running Locally

- sf org login web
- sf project deploy start
- sf apex run test --result-format human --synchronous

---

## Why This Repo Exists
This project is intentionally over-engineered to reflect how I build Salesforce solutions in real production environments:

- scalable
- testable
- maintainable
- easy to reason about over time