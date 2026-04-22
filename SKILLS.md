# VSPIA Skills Reference

Skills live in `.claude/skills/` as `.skill` ZIP archives. This file contains the
full content of each skill so Claude can apply them without extracting the archives.

**When to use each skill** — see [CLAUDE.md](CLAUDE.md) for the full trigger rules.  
Every task: `simplify`  
On I/O, external calls, missing-key risk: `error-handling`  
On any new data entry point or deserialized structure: `data-validation`  
On file paths, credentials, API calls, save schema changes, SQL: `security`  
On mixed concerns, shotgun surgery, parameter sprawl: `architecture`  
End of each phase: `automated-testing`  
Before each new phase, when replacing stubs, after long gaps: `technical-debt`  
On any `ai/` or Anthropic SDK change: `claude-api`  
On setup/CI/launch script changes: `developer-experience`

---

## simplicity

Code should be as simple as it can be while still doing what it needs to do.

**Core principles:**
1. **Readability first** — optimize for the reader; prefer verbose names (`normalize_sensor_readings` not `process_data`)
2. **One thing per unit** — if a function's description has "and", it's two functions
3. **Flat over nested** — >2 nesting levels → use guard clauses / early returns
4. **Explicit over implicit** — no magic numbers, no clever boolean tricks, type hints everywhere
5. **Standard patterns** — use `sorted()`, `enumerate()`, `dataclasses`; avoid custom metaclass magic
6. **Delete mercilessly** — dead code, commented-out blocks, unused imports are noise

**Complexity signals to flag:**
| Signal | Threshold | Action |
|---|---|---|
| Function length | > 30 lines | Split |
| Nesting depth | > 2 levels | Flatten |
| Parameters | > 4 | Group into dataclass |
| Identical logic | 2+ places | Extract |
| Mixed concerns | rendering + logic, UI + state | Separate into layers |

**Simplification checklist:** name audit → function audit → nesting audit → duplication audit → dead code audit → magic values → imports → type hints → comments

**Output:** what was simplified (one sentence per change) + why + full simplified code + what was intentionally kept complex.

---

## error-handling

Errors are routine. A system that fails silently is harder to fix than one that fails loudly.

**Two failure modes to eliminate:**
- **Silent failure** — `except Exception: pass` or `print(f"Error: {e}")` — never acceptable
- **Over-broad catching** — catching `Exception` without understanding what can raise

**Patterns:**
```python
# Catch what you expect, re-raise the rest
try:
    response = requests.get(url, timeout=10)
    response.raise_for_status()
except Timeout:
    logger.warning("Timed out", extra={"url": url})
    raise
except HTTPError as e:
    logger.error("HTTP error", extra={"status_code": e.response.status_code})
    raise
# No bare `except Exception` — let unknown errors surface as bugs
```

**Custom exceptions** — define a hierarchy: `AppError → ValidationError / NotFoundError / ExternalServiceError`

**Context managers** — always for files, DB sessions, connections. Never manual `finally` when a context manager exists.

**Retry logic** — for transient external calls only, with exponential backoff.

**Logging standards:**
- Use `logging`, never `print`
- Levels: DEBUG (dev only) · INFO (normal ops) · WARNING (recovered) · ERROR (operation failed) · CRITICAL (system-level)
- Structured: `logger.error("msg", extra={"order_id": ..., "user_id": ...})`
- Never log: passwords, tokens, API keys, PII, full request bodies

**Checklist:** no bare `except` · no silent swallowing · all I/O has try/except · context managers for resources · custom exceptions · retry for transient calls · no `print` for logging · structured context in every log · no sensitive data in logs

---

## data-validation

Validate at the entry point, trust inside. Every assumption about incoming data must be explicitly enforced at the boundary.

**Entry points requiring validation:** HTTP requests · file uploads · CSV/JSON imports · API responses · database reads (raw SQL) · environment variables · CLI args · inter-service messages

**Three validation layers:**
1. Type and structure — right shape? required fields? correct types?
2. Range and format — values in bounds? strings match patterns?
3. Business rules — domain validity (does this order ID exist? is this date future?)

**Preferred tool — Pydantic:**
```python
class CreateOrderRequest(BaseModel):
    customer_email: EmailStr
    quantity: int = Field(ge=1, le=1000)
    delivery_date: date

    @field_validator("delivery_date")
    @classmethod
    def delivery_must_be_future(cls, v: date) -> date:
        if v <= date.today():
            raise ValueError("Delivery date must be in the future")
        return v
```

**API responses** — always validate the response body shape, not just status code.

**Env vars** — validate at startup with `get_required_env(key)` that raises `EnvironmentError` on missing.

**Fail-fast vs collect-all:** fail-fast for config/single record; collect-all for bulk imports/form validation.

**Checklist:** all entry points validated · types enforced · required fields checked · ranges and formats validated · API responses validated · env vars validated at startup · custom exceptions raised · no validation inside business logic

---

## automated-testing

Test what changed. Not the whole codebase — the behaviors introduced or modified by the most recent changes.

**Workflow:**
1. Identify what changed
2. List behaviors (valid input, invalid input, dependency failures, side effects)
3. Write one test per behavior
4. Verify each test fails before it passes

**Pattern — AAA:**
```python
def test_calculate_discount_applies_ten_percent_for_premium_users():
    # Arrange
    user = User(tier="premium"); order = Order(subtotal=100.00)
    # Act
    discounted = calculate_discount(order, user)
    # Assert
    assert discounted == 90.00
```

**pytest patterns:** `@pytest.mark.parametrize` for multiple cases · `@pytest.fixture` for shared setup · `unittest.mock.patch` for external dependencies

**Priority order:** happy path → validation failures → boundary/adversarial → external failure → authorization → side effects

**Boundary cases to always include:** numeric bounds (0, -1, max+1, int overflow) · dates (today, far past, leap days) · strings (empty, whitespace, >max_length, null bytes, XSS, SQL injection, path traversal) · None/missing fields

**Coverage:** 90%+ for core business logic · 80%+ for utilities · 70%+ for glue code. Coverage is a floor, not a ceiling.

**PyQt6 tests:** use `pytest-qt`'s `qtbot` fixture. `qtbot.addWidget(w)` for cleanup. `qtbot.waitSignal(signal, timeout=3000)` for async signals.

**Naming:** `test_{unit}_{scenario}_{expected_outcome}` — test names are documentation.

**Output:** behaviors covered (one line each) + test code + how to run + what's intentionally not covered.

---

## architecture

Architecture is the structure that determines how easy it is to change your code. Good architecture makes a change local.

**The spectrum:** Single file → Modular monolith → Package monolith → Microservices  
**Default:** modular monolith. Move right only on concrete, demonstrated need.

**Warning signs:**
- File > 300 lines · function > 30 lines · >15 imports in one file
- Shotgun surgery: one change requires edits in 4+ files
- Circular imports
- God module: one file everything imports
- Mixed concerns: data access + business logic + presentation in one function
- Hidden dependencies: function reaches for globals without explicit injection

**Modular monolith structure:**
```
project/orders/
  models.py      # data structures only
  service.py     # business logic — no HTTP, no SQL
  repository.py  # all DB access for this domain
  router.py      # HTTP handlers — thin, delegates to service
```
Dependency rule: `router → service → repository → models`. Services never reach into sibling domain repositories.

**Layer rules:**
| Layer | Must NOT contain |
|---|---|
| Router/Handler | Business logic, DB queries |
| Service | HTTP concepts, SQL |
| Repository | Business logic |
| Model | Logic, queries |

**Microservices only when ALL true:** independent deployment is a real requirement · independent scaling required · operational infrastructure exists · one team per service.

**Review checklist:** size check · concern separation · circular imports · god module · hidden dependencies · shotgun surgery test · naming clarity · test independence · deployment unit

**Output:** current structure assessment → recommended structure (user confirms before any restructuring) → what changes and why → dependency impact → what does NOT change. Never restructure and change behavior in the same pass.

---

## security

Security review is not optional — runs on every piece of code touching external input, credentials, files, databases, or network traffic.

**Vulnerability checklist (in order):**

**1. Injection**
- SQL: always parameterized queries (`cursor.execute("... WHERE name = %s", (username,))`)
- Command: always `subprocess.run(["cmd", arg])`, never `shell=True` with user input
- Path traversal: `os.path.realpath()` + check `startswith(safe_base)`

**2. Secrets** — never hardcode. Always env vars + `load_dotenv()`. `.env` in `.gitignore`. If already committed: rotate credential + purge git history.

**3. Auth/AuthZ** — passwords: bcrypt/argon2/scrypt (never MD5/SHA1). Tokens: 128+ bits, `secrets.token_urlsafe(32)`. Always check ownership server-side, never trust frontend access control.

**4. Input validation** — validate type, range, format at boundary. File uploads: check extension AND actual file signature (not client MIME type).

**5. Sensitive data in logs** — never log passwords, tokens, API keys, full request bodies, PII.

**6. Dependencies** — `pip-audit` before every production deploy. Pin all versions.

**7. HTTPS** — never `verify=False`. Always set explicit `timeout`. SSRF: validate user-supplied URLs against allowlist.

**8. Error messages** — return generic messages to users; log details internally with `logger.exception()`.

**Severity:** CRITICAL (exploitable remotely, no auth) · HIGH (exploitable, significant impact) · MEDIUM (specific conditions, limited blast radius) · LOW (defense-in-depth)

**Output:** risk summary with severity labels · fixed code (complete block, not diff) · what was NOT found (explicitly state) · one follow-up flag (rotate credential, add .gitignore, run pip-audit).

---

## technical-debt

Periodic audit tool — run monthly or before major releases. Covers what simplicity/architecture/security/error-handling miss.

**Six debt categories (audit in this order):**

**1. Dependency debt** — unpinned versions, packages not updated in 12+ months, redundant packages (two HTTP libs), dev deps in production requirements.  
Check: `pip list --outdated`, `pip-audit`, `pipdeptree`

**2. Dead code** — functions never called, unused imports, `if False:` blocks, commented-out code, unreachable code after `return`.  
Check: `pyflakes src/`, `vulture src/ --min-confidence 80`  
Rule: delete it. Version control is the safety net.

**3. Documentation debt** — public functions/classes without docstrings, undocumented env vars, missing README sections.  
Required: every public function in a shared module · every env var · non-obvious config · module purpose (one-line comment).  
Check: `interrogate src/ --verbose`

**4. Test debt** — modules with 0% coverage, business logic with no tests, `@pytest.mark.skip` never re-enabled.  
Priority: auth/payment/deletion > core business logic > utilities > CLI/config.

**5. Abandoned annotations** — TODO/FIXME/HACK older than 6 months. For each: fix it, schedule it (add ticket ref), or accept it (add `# ACCEPTED:` comment with reason).  
Check: `grep -rn "TODO\|FIXME\|HACK" src/`

**6. Duplication debt** — same logic in 2+ places, same validation written twice, config access scattered.  
Rule: 2+ copies of non-trivial logic → extract.

**Output:** debt summary (one line per finding, category + High/Medium/Low) · fix now (with code) · schedule (with effort estimate) · accept or investigate · updated `DEBT.md`.

---

## daily-iterations

Every day ends with something merged, deployed, or demonstrably closer to done — and the codebase is never worse than when the day started.

**Core principle: vertical slices, not horizontal layers.**  
Wrong: Day 1 all models, Day 2 all services, Day 3 all endpoints.  
Right: Day 1 create+retrieve one order (deployable). Day 2 list orders (deployable). Day 3 cancel order (deployable).

**How to slice a feature:**
1. Strip to minimum useful form — that is Iteration 1
2. List increments outward; each must be independently deployable and add value alone
3. Identify ordering dependencies
4. Size-check: each iteration completable in one day including tests

**Daily cycle:** DEFINE → TEST FIRST → BUILD → VERIFY (full suite) → CLEAN (simplicity check) → COMMIT → DEPLOY → RECORD (one sentence learned)

**Commit format:** `feat|fix|refactor|test|chore|docs: <what changed> [<why>]`

**Feature flags** — for genuinely multi-day work, hide behind a flag so main branch never carries broken state.

**Definition of done:** feature works · no regressions · tests written · linter passes · no new TODOs without ticket ref · no hardcoded values · if incomplete: feature flag hides it.

**When an iteration fails:** stash/branch, reduce scope, ship the subset, record what's left.

---

## developer-experience

Developer experience is infrastructure. A slow build or a half-day setup compounding over time produce bad code.

**Area 1: Local setup**  
README must cover: one-sentence purpose · prerequisites · setup steps · `pytest` command · environment variables table · common issues.  
`.env.example` committed with all keys and safe placeholder values — kept in sync with what the code actually reads.

**Area 2: Build speed**  
Targets: <100 tests → <30s · 100–500 → <2min · 500–2000 → <5min.  
Fix slow builds: add `pytest-xdist` (`addopts = "-n auto"`) · mock real I/O in unit tests · lazy imports for heavy deps · enable pip cache in CI.

**Area 3: Test reliability**  
Flaky test = worse than no test (trains developers to ignore failures).  
Common causes: shared mutable state between tests · time-dependent tests (fix with `freezegun`) · test order dependencies (each test sets up its own state) · real external calls in unit tests.  
Detection: `pytest --count=10 -q` or `pytest-flakefinder`.

**Area 4: CI pipeline**  
Minimum: checkout → setup-python → pip cache → install → lint → type check → test with coverage → security audit.  
Health signals: <5min duration · <5% failure rate on main · branch protection enforced (PRs require CI pass) · `--cov-fail-under` set.

**Audit checklist:** README complete · `.env.example` current · setup <30min from clean machine · test suite <2min · parallelization configured · zero flaky tests · CI exists and is enforced · coverage enforced.

---

## environment-parity

"It works on my machine" is an architecture problem. Environment parity = dev, staging, and production are as identical as possible.

**Risk table:**
| What differs | Risk | Fix |
|---|---|---|
| Python version | High | Pin with `.python-version` + pyenv |
| Dependency versions | High | Exact pins in `requirements.txt` |
| OS/system libraries | High | Docker / devcontainer |
| Configuration values | Medium | `.env` files per environment, same keys |

**Python version:** `.python-version` file committed → `3.11.8`. `pyproject.toml` `requires-python = ">=3.11,<3.12"`.

**Dependency pinning:** exact versions always (`requests==2.31.0`). Split `requirements.txt` (prod) and `requirements-dev.txt` (dev/test). Use `pip-tools` to manage: `pip-compile requirements.in`.

**Config as code pattern:**
```python
@dataclass(frozen=True)
class Config:
    api_key: str; debug: bool; max_tokens: int

def load_config() -> Config:
    # validate all vars at startup, raise EnvironmentError with full list if any missing
    ...
config = load_config()  # loaded once at startup
```

**Anti-patterns to eliminate:**
- `if os.environ.get("ENV") == "production":` in application code → use `config.feature_enabled` instead
- Hardcoded URLs → always from config
- Real credentials in `.env` on production servers → use secrets manager (AWS SM, Azure KV, etc.)

**Checklist:** Python version pinned · deps pinned · `.env.example` committed · config validated at startup · no env-name checks in code · no hardcoded URLs · Docker/devcontainer for OS parity · same config keys across all environments.

---

## telemetry

Logging tells you what went wrong. Telemetry tells you what the system is doing right now.

**Three pillars:** Metrics (numbers over time) · Traces (path of a single request) · Logs (structured events)

**Four golden signals (measure all four for every service):**
| Signal | Alert when |
|---|---|
| Rate (req/s) | Drops significantly or spikes |
| Errors (% of requests) | Exceeds 1% sustained |
| Latency (p50/p95/p99) | p99 exceeds SLA threshold |
| Saturation (CPU/memory/queue) | Approaches capacity |

**What to instrument:**
- HTTP: request count + error rate + latency via **middleware** (not per-endpoint)
- Background jobs: start counter · duration histogram · success/failure counter · always in `finally` block
- External calls: per-service duration + error rate
- Queues: queue depth gauge + processing duration

**Business metrics** — at least one metric that reflects user-facing outcomes (orders created, revenue processed, funnel step). Technical metrics alone can't tell you if a deploy hurt the product.

**The high-cardinality trap:**
```python
# NEVER — order_id creates millions of Prometheus time series
http_requests_total.labels(order_id=order_id).inc()
# ALWAYS — low, bounded cardinality (status_code has ~10 values)
http_requests_total.labels(status_code="200").inc()
# High-cardinality data belongs in logs and traces, not metrics
```

**VSPIA-specific:** instrument `core/api_client.py` (per-call cost, token usage, latency) and diagram generators (success rate, fallback rate).

**Alerting:** alert on symptoms (error rate > 1%), not causes (CPU > 80%). Every alert needs a runbook. Tune aggressively — alert fatigue kills response.

**Checklist:** four golden signals covered · middleware-level HTTP instrumentation · all background jobs instrumented · all external calls instrumented · business metric present · no high-cardinality labels · at least one alert with runbook.

---

## Quick lookup — skill × file

| Files touched | Run these skills |
|---|---|
| `core/api_client.py`, `core/conversation.py` | `error-handling`, `telemetry`, `data-validation` |
| `utils/document_parser.py`, `utils/image_utils.py` | `security`, `data-validation`, `error-handling` |
| `diagram/*.py` | `error-handling` (fallback paths), `data-validation` (spec parsing) |
| `config/settings.py`, `.env` | `security` (key handling), `environment-parity` |
| `ui/stages/*.py`, `ui/shell.py`, `ui/main_window.py` | `simplicity`, `architecture` (when >300 lines) |
| `ui/state.py` | `data-validation` (JSON round-trip), `error-handling` |
