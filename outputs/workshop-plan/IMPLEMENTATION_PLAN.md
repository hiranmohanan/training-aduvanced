# Company task management app — implementation plan

Prepared 16 September 2026. Working product name: **TeamFlow**. Example company: **Northstar Studio**. These names can be replaced before development.

## 1. Outcome and planning assumptions

Build a Flutter teaching app for developers who already understand Dart, widgets, forms, asynchronous functions and basic navigation. Participants practise structured BLoC, repository boundaries, role permissions, reusable UI, mock API contracts and testing through a complete task workflow.

Interpret **user = Employee**, **admin = Team Admin**, and **pro admin = Super Admin**. One company, three teams, five employees, three admins and one super admin are in scope. Every account uses the same app and phone sign-in; the stored user record determines the role. There is no role selector that grants access.

Assume two days, **six teaching hours per day**, with setup completed beforehand. Android is the workshop acceptance platform. Flutter UI remains portable; iOS deep-link configuration is documented and must be verified on a Mac/device separately. Web can be a convenient preview, but is not an additional two-day acceptance platform.

This delivery is a **planning and design pack**: implementation plan, client requirements workbook, deterministic sample data, API catalogue and SVG UI specification. No Flutter app has been implemented or tested yet. The SVGs define the UI target; they cannot yet be described as verified replicas of a running app.

The entire app is feasible in two workshop days **with a prepared scaffold and instructor reference implementation**. Recreating every service and screen from an empty project while teaching BLoC is a larger course. Reserve approximately 3–5 trainer workdays to implement, verify and rehearse the starter/reference projects; revise that estimate after the first vertical slice.

## 2. Scope and suggested company operations

| Delivery | Features |
|---|---|
| Participants implement | Phone + mock OTP flow; employee dashboard; task list and filters; task detail; work update form; assignment and review actions; profile work totals; chart data connection; tests for key rules. |
| Trainer prepares and explains | Project structure, theme and shared widgets; immutable models and seeds; API provider scaffold; mock database; repository interfaces; route shell and guards; basic timer service; nine accounts; employee directory; Super Admin overview and role form; about screen; link platform configuration; starter test fixtures. |
| Included read-only company operations | Employee directory with team and reporting manager; seeded announcements; recent activity trail; company information and version/terms screen. |
| After workshop | Announcement authoring, in-app notification inbox, leave request and approval, attachments, recurring tasks, CSV reporting, persistent offline data and a real backend. |
| Separate product phases | Payroll, biometric/GPS attendance, invoices, chat, multi-company tenancy, real SMS delivery, push delivery and app-store release. |

Completion means a usable mock workflow and a codebase with clear boundaries. Offline mock mode makes no HTTP or SMS requests. A device restart restores the seed dataset; mutations remain available across logout/login within the same process. Persistence is an explicit later feature.

## 3. Role and team rules

| Capability | Employee | Admin | Super Admin |
|---|---|---|---|
| Dashboard / charts | Own tasks and hours | Managed team's tasks and hours | Entire company, optionally filter by team |
| Task access | Assigned tasks only | Managed team's tasks | All tasks |
| Create, assign, edit title/due date | No | To active employees in own team | To active employees in any team |
| Update progress / log time | Own active assigned task | No employee impersonation | No employee impersonation |
| Approve / request changes | No | Own team's submitted tasks | Any submitted task |
| Employee profile | Self | Employees in own team | Every employee |
| Role / active status changes | No | No | Employee and Admin accounts, with restrictions below |
| Company information | Read | Read | Read; settings authoring is later scope |
| Announcements | Read | Read | Read |

Apply authorization in **route guards and repository/mock request handling**, including reads by ID. Hidden buttons alone are insufficient. A guessed deep link must never expose another employee's task or profile. Future server implementation must repeat these checks authoritatively.

Each employee belongs to one team and each admin manages one team. Super Admin can select another team's active employee while assigning; the task belongs to the selected employee's team. Normal reassignment stays in the existing task team. Moving an existing task across teams, changing team membership, and deleting users/tasks are deferred to preserve history.

The Super Admin screen can switch Employee ↔ Admin, choose a managed team for a new admin, and activate/deactivate accounts. Prevent demotion/deactivation of the signed-in Super Admin and preserve at least one active Super Admin. Reject an employee role change or deactivation while they have non-Done tasks or an open work entry; explain that reassignment/stopping work is required first. Role changes affect the next login; account switching is sequential in this local demo.

Preserve the designated reporting manager: an Admin referenced by a team's `managerId` cannot be demoted/deactivated during the workshop. Replacing team managers is later scope. A promoted employee keeps their team membership; a managed team is mandatory for the Admin role. Demonstrate an allowed role change after reassigning or completing that employee's active tasks, and test rejection cases separately.

## 4. User journeys and acceptance examples

1. **Login:** select a displayed demo account or enter its phone → send mock code → enter `123456` → load the role dashboard. Unknown phones and wrong/expired codes show an indexed error. No real SMS is sent.
2. **Assignment:** Priya opens Assign task → enters title, description, priority, due date and Rahul → saves → new task appears in Priya's team list. Logout and log in as Rahul → see the same task.
3. **Work update:** Rahul opens his task → starts/stops work or enters a manual work interval → updates progress, note and blockers → saves → the task activity and own work totals update.
4. **Review:** Rahul submits the task → state becomes In review → Priya approves → Done with completion timestamp and 100% progress. Request changes returns it to In progress with a required comment.
5. **Profile and graph:** Asha sees her role, team, manager, phone, join date, total assigned/completed tasks and weekly logged hours. A task edit or closed work entry updates the relevant dashboard and graph without restarting.
6. **Authorization:** Asha opens Rahul's task/profile URL → access-denied view with no private content. Priya cannot load Operations tasks through a URL or repository call.
7. **Super Admin:** Vikram sees all three teams and nine accounts. Employee/Admin role and active-status changes obey the restrictions in section 3.

## 5. Mock data contract

Use `mock_seed.json` in this pack as the planning fixture. Convert it to typed Dart seed objects during trainer preparation. All names and numbers are fictional demo identities. The `+1 202-555-01xx` numbers are example-only inputs; the application never contacts them.

| ID | Name | Role | Team | Phone |
|---|---|---|---|---|
| E001 | Asha Nair | Employee | Product | +12025550101 |
| E002 | Rahul Dev | Employee | Product | +12025550102 |
| E003 | Neha Iyer | Employee | Operations | +12025550103 |
| E004 | Arjun Rao | Employee | Operations | +12025550104 |
| E005 | Kavya Menon | Employee | Sales | +12025550105 |
| A001 | Priya Sharma | Admin | Product | +12025550111 |
| A002 | Karan Mehta | Admin | Operations | +12025550112 |
| A003 | Meera Joseph | Admin | Sales | +12025550113 |
| S001 | Vikram Shah | Super Admin | Company | +12025550199 |

The shared mock code is **123456**. Normalize phone input to E.164. Simulate a challenge ID, five-minute expiry and a 30-second resend delay. Show the mock code in the demo UI. This is a teaching authentication flow, not a production authentication mechanism.

Seed 15 tasks, 15 closed work entries, five employee profiles, three teams, two announcements and a small activity history. Cover Todo, In progress, Blocked, In review and Done, plus at least two overdue non-Done tasks. No account starts with an empty experience. Admin profiles need account details, while employee profiles include work metrics.

Use an injectable `ClockService`. The initial demo time is **16 Sep 2026, 14:30 Asia/Kolkata**, stored as `2026-09-16T09:00:00Z`. Advance elapsed runtime from that anchor so timers work, while reset restores repeatable screenshots. Store timestamps in UTC and render in the company timezone. Do not derive sample labels from the host's calendar date.

At reset: company totals are **15 tasks, 11 active, 4 Done, 2 overdue**, with **54 logged hours** for the current Monday-to-Sunday week. Product has six tasks and 21.5 hours; Operations six tasks and 23 hours; Sales three tasks and 9.5 hours. Asha has three assigned tasks, two active, one Done and 10.5 logged hours. These numbers derive from the fixture, not independently hardcoded dashboard cards.

`MockDatabase` owns one mutable copy of seed records and emits changes. Logout clears the session and user-scoped BLoCs but retains task data for the next account. Stop and save a running entry before logout. Process restart and the explicit trainer reset return to the original fixture. Reset also logs out and clears pending deep links.

## 6. Domain models and business rules

| Model | Minimum fields |
|---|---|
| AppUser | id, name, phoneE164, role, teamId, managedTeamId, designation, joinedAt, isActive |
| AuthSession | userId, mockToken, issuedAt, expiresAt |
| Team | id, name, managerId |
| Task | id, title, description, teamId, assigneeId, createdById, priority, status, progress, dueAt, createdAt, updatedAt, completedAt? |
| WorkEntry | id, taskId, employeeId, startedAt, endedAt?, note, source(timer/manual) |
| TaskUpdate | id, taskId, actorId, note, blocker?, progress, createdAt |
| ActivityEntry | id, actorId, entityId, action, summary, createdAt |
| Announcement | id, title, body, createdAt |
| DashboardSummary | derived status counts, overdue count, loggedMinutes, dailyHours |
| CompanyInfo | id, name, timezone, workdayTargetMinutes |
| ApiResult / AppFailure | typed data or error code, indexed display message, optional field errors |

Tasks use enums for role, priority and status. Models are immutable, use `copyWith`, value equality and explicit JSON mapping. Plain Dart plus `equatable` keeps workshop build steps short; generators can be introduced later.

Allowed lifecycle:

```text
Todo --employee starts--> In progress
In progress --employee adds blocker--> Blocked
Blocked --employee resolves blocker--> In progress
In progress --employee submits--> In review
In review --admin approves--> Done
In review --admin requests changes--> In progress
```

Rules: progress is an integer 0–100; Todo starts at 0; review submission requires progress 100 and a note; completion is set only by approval. Blocked updates require a blocker reason. Done is read-only in the workshop. Opening a running entry can move Todo to In progress. Stop a running entry before blocking or submitting; the transition and saved entry must be one atomic mock operation.

Task form: title 3–100 trimmed characters, description up to 1,000, assignee required, priority required and valid due date. Creation cannot be due before the current company date. Employee update notes are 5–500 characters. Manual work requires start < end, no future end, duration at most 12 hours and no overlap with that employee's other work intervals. One open entry per employee; an overlapping manual entry is rejected. Time can be logged only to an active, assigned task. A timer measures timestamps; it does not increment a stored integer every second or promise background execution after process termination.

Working time means recorded task time, not attendance or payroll. Weekly hours sum closed intervals, splitting at company-day boundaries. Running time is displayed separately until stopped. Overdue means dueAt < now and status != Done. The status graph counts all visible tasks; the daily hours graph uses closed entries in the selected week and same role/team filter. Completion rate = Done / total, with an empty state when total = 0. Chart labels and totals must agree with the visible task scope.

## 7. Architecture and package choices

Use this dependency flow:

```text
View -> BLoC event -> Repository interface -> Repository implementation
                                                |
                                         ApiProviderService
                                         /                \
                              MockApiProvider         DioApiProvider
                                  |                     (later)
                              MockDatabase

Repository streams -> BLoC state -> View
```

The UI never chooses a data mode or parses API JSON. `AppBootstrap` selects one provider using `AppConfig.dataMode`, default `mock`. `MockApiProvider` implements the planned endpoint contract and updates the shared database; `DioApiProvider` is a scaffold until a backend exists. Repositories map payloads, own domain-facing streams and errors, and enforce shared rules. Mock request handlers additionally apply role and entity scope checks to direct calls.

This combines Flutter's recommended separation of UI and data, repositories and dependency injection with the user's requested BLoC presentation layer. Flutter's guide uses MVVM examples; BLoC is the project choice. [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations) and [BLoC architecture](https://bloclibrary.dev/architecture/).

| Dependency | Purpose |
|---|---|
| flutter_bloc | Event/state presentation logic; MultiBlocProvider and RepositoryProvider for injection |
| equatable | Value equality for states, events and models |
| go_router | URL routes, role redirects and shell navigation |
| dio | Future HTTP provider, interceptors, timeouts and error translation |
| fl_chart | Status distribution and daily-hours charts |
| intl | Company-timezone-aware display formatting once UTC values are converted |
| package_info_plus | Read the installed app version/build from platform metadata |
| flutter_lints, bloc_test, mocktail | Static analysis and focused tests |

For this fixed India timezone, use an explicit UTC+05:30 conversion helper; a timezone library becomes necessary when configurable timezones/DST enter scope. Formatting alone does not perform timezone conversion.

Use the trainer's supported Flutter stable SDK, resolve compatible dependency versions once, record `flutter --version`, and commit the application `pubspec.lock`. Do not ask each team to independently upgrade packages during the workshop. Current package capabilities were checked, but compatibility has not been validated by a build. [flutter_bloc](https://pub.dev/packages/flutter_bloc), [go_router](https://pub.dev/packages/go_router), [fl_chart](https://pub.dev/packages/fl_chart).

## 8. File structure

Preserve the requested `app/feature/home/view`, `app/app_constants`, `app/repository` and `app/models` paths:

```text
lib/
  main.dart
  app/
    app.dart
    bootstrap/app_bootstrap.dart
    app_constants/
      app_config.dart             # environment, company timezone, mock mode
      app_metadata.dart           # name, fallback metadata, terms version
      api_endpoints.dart          # paths only, with parameter builders
      app_text.dart               # indexed UI strings and formatters
      app_routes.dart             # route names and path builders
      app_assets.dart
      app_limits.dart             # validation limits, timeout settings
    theme/
      app_theme.dart
      app_colors.dart
      app_spacing.dart
      app_typography.dart
    models/
      app_user.dart
      auth_session.dart
      team.dart
      task.dart
      work_entry.dart
      task_update.dart
      activity_entry.dart
      announcement.dart
      dashboard_summary.dart
      company_info.dart
      enums/
    repository/
      auth/auth_repository.dart
      auth/auth_repository_impl.dart
      task/task_repository.dart
      task/task_repository_impl.dart
      employee/employee_repository.dart
      employee/employee_repository_impl.dart
      work_log/work_log_repository.dart
      work_log/work_log_repository_impl.dart
      company/company_repository.dart
      company/company_repository_impl.dart
      dashboard/dashboard_repository.dart
      dashboard/dashboard_repository_impl.dart
    services/
      api/api_provider_service.dart
      api/mock_api_provider.dart
      api/dio_api_provider.dart
      api/api_result.dart
      api/api_exception_mapper.dart
      navigation/navigation_service.dart
      navigation/app_router.dart
      navigation/router_refresh_notifier.dart
      deep_link/deep_link_service.dart
      clock/clock_service.dart
      timer/work_timer_service.dart
    policies/
      access_policy.dart
      task_transition_policy.dart
      work_entry_policy.dart
    mock/
      mock_database.dart
      mock_seed.dart
      mock_scenarios.dart
    feature/
      auth/{bloc,view,widgets}/
      home/
        bloc/{home_bloc.dart,home_event.dart,home_state.dart}
        view/home_view.dart
        widgets/{summary_card.dart,task_preview_card.dart}
      tasks/{bloc,view,widgets}/
      task_detail/{bloc,view,widgets}/
      task_form/{bloc,view,widgets}/
      work_update/{bloc,view,widgets}/
      employees/{bloc,view,widgets}/
      profile/{bloc,view,widgets}/
      reports/{bloc,view,widgets}/
      super_admin/{bloc,view,widgets}/
      company/{bloc,view,widgets}/
      settings/{view,widgets}/
    shared/
      widgets/{app_button.dart,app_text_field.dart,status_chip.dart,
               app_empty_state.dart,app_error_view.dart,app_loading.dart}
      errors/app_failure.dart
      validators/form_validators.dart
assets/
  fonts/
  legal/{demo_terms.md,demo_privacy.md}
test/                             # mirrors relevant lib/app paths
integration_test/
docs/{requirements,api,ui,workshop}/
```

Braces above abbreviate sibling files/directories. Do not create literal brace-named paths. Add files when a feature needs them; a simple static About view does not need a BLoC.

## 9. BLoC conventions and state ownership

| BLoC | Events | Important state |
|---|---|---|
| AuthBloc | SessionStarted, PhoneSubmitted, OtpSubmitted, ResendRequested, LogoutRequested | auth status, challenge, user/session, field errors |
| HomeBloc | DashboardSubscribed, DateRangeChanged | summary, recent tasks, announcement, loading/error |
| TaskListBloc | TasksSubscribed, SearchChanged, FiltersChanged | records, query, status/priority filters |
| TaskDetailBloc | TaskSubscribed, ReviewApproved, ChangesRequested | selected task, activity, action status |
| TaskFormBloc | DraftChanged, AssignmentSubmitted | form values, assignee options, submit status |
| WorkUpdateBloc | ProgressChanged, TimerStarted, TimerStopped, UpdateSubmitted | draft, open entry, elapsed view, submit status |
| ProfileBloc / ReportsBloc | ProfileSubscribed / ReportsSubscribed | scoped user, task counts, time data |
| EmployeeBloc / SuperAdminBloc | DirectoryRequested / RoleChangeSubmitted | scoped accounts, role form, action result |

States are immutable. Keep loaded data visible during a save using a separate `submissionStatus`; don't replace the whole detail screen with a loading spinner. Use `BlocBuilder`/`BlocSelector` for rendering and `BlocListener` for snackbars and one-time navigation. Business logic never takes `BuildContext`. The [flutter_bloc documentation](https://pub.dev/packages/flutter_bloc) describes these presentation APIs.

Shared task changes travel through repository streams; feature BLoCs do not call each other. Read-only dashboard aggregation subscribes to task and work-log repositories without introducing repository cycles. Dispose subscriptions when BLoCs close. Recreate user-scoped subscriptions on account change and discard late responses from a previous session. Prevent duplicate submissions with disabled actions and explicit in-flight checks; serialize conflicting task mutations. Debounce search and ignore stale results.

Use constructor injection for all dependencies. AppBootstrap owns long-lived services/repositories; feature routes own their BLoCs. Use an AuthBloc-backed refresh notifier for go_router and dispose its stream subscription with the router. Do not introduce both a global service locator and a provider tree during this workshop.

## 10. Constants and service contracts

`ApiEndpoints` holds `/v1` relative paths and ID builders. The base URL lives in AppConfig and is passed at build time in real mode. `https://api.teamflow.example` is a documented placeholder, never a working server or a default endpoint called in mock mode.

`AppText` indexes every visible interface string: `authPhoneLabel`, `authSendCode`, `authMockCodeHint`, `homeMyTasks`, `taskAssign`, `taskStatusInReview`, `workSaveUpdate`, `errorForbidden`, `commonRetry`, and so on. Use formatter methods for counts, durations and names. Status enums map to text keys. Do not use a numeric string index, raw copy in widgets or phone numbers as presentation labels. User-entered content, seed names and task descriptions belong in models/data. An ARB localization catalogue can replace AppText later.

`AppMetadata`: name `TeamFlow`, company `Northstar Studio`, demo mode label, fallback version `1.0.0`, terms/privacy content version `demo-1`, and support label. `pubspec.yaml` is the version source of truth (`1.0.0+1`); read the installed version via package_info_plus. Avoid unrelated version strings drifting across screens. Include clearly labelled demonstration terms/privacy copy, not claims of production legal coverage.

`ApiProviderService` exposes async GET/POST/PATCH with path, query, body and typed result/error handling. Dio implementation configures a base URL, timeouts, JSON headers, token injection and error translation. Log method/path/status only in development; never log OTP/token/phone payloads. Map unauthorized, forbidden, missing resource, validation and transport failures to `AppFailure`. Do not retry non-idempotent task creation/work-log saves automatically.

`MockApiProvider` supports the same response shapes, deterministic IDs, a short configurable delay and explicit failure scenarios (unauthorized, forbidden, validation, offline). Unknown endpoints fail clearly. UI code must not contain `if (mock)` branches. `NavigationService` is a small injected go_router wrapper with methods such as `openTask(id)`, `openEmployee(id)`, `openAssignment()` and `back()`; it has no second route stack and repositories never call it.

## 11. API catalogue

These are proposed contracts, not deployed endpoints. All authenticated reads and writes use session-derived role/team scope. A passed `userId` or `teamId` can narrow authorized results, never widen them. The workbook lists each route and its permission rule.

| Method | Path | Purpose |
|---|---|---|
| POST | /v1/auth/otp/request | Create mock phone challenge |
| POST | /v1/auth/otp/verify | Verify code and return session/user |
| POST | /v1/auth/logout | Invalidate current session |
| GET | /v1/me | Current account |
| GET | /v1/dashboard | Scoped counts and recent tasks |
| GET | /v1/tasks | Search/filter/paginate visible tasks |
| POST | /v1/tasks | Create and assign task |
| GET | /v1/tasks/{taskId} | Visible task detail |
| PATCH | /v1/tasks/{taskId} | Admin edits to task metadata |
| POST | /v1/tasks/{taskId}/assignment | Assign/reassign within permitted scope |
| POST | /v1/tasks/{taskId}/updates | Employee progress/note/blocker/state update |
| POST | /v1/tasks/{taskId}/review | Admin approval or request changes |
| GET | /v1/tasks/{taskId}/activity | Task history |
| GET | /v1/employees | Admin/Super Admin directory |
| GET | /v1/employees/{employeeId} | Self or authorized employee profile |
| PATCH | /v1/users/{userId}/access | Super Admin changes role/active status |
| GET | /v1/users | Super Admin account list, including admins |
| GET | /v1/teams | Team options in role scope |
| GET | /v1/work-entries | Self/team/company intervals |
| POST | /v1/work-entries | Create manual work interval |
| POST | /v1/work-entries/start | Start own task timer |
| POST | /v1/work-entries/{entryId}/stop | Stop own timer |
| GET | /v1/reports/task-status | Scoped status distribution |
| GET | /v1/reports/work-hours | Scoped daily totals for date range |
| GET | /v1/announcements | Company announcements |
| GET | /v1/company | Company metadata |

Responses: `{data: ..., meta: {page, pageSize, total}}` for lists (page starts at 1); `{data: ...}` for single results. Errors: `{error: {code, messageKey, fieldErrors?}}`. Use ISO-8601 UTC timestamps and stable string IDs. Example `POST /v1/tasks`: `{title, description, assigneeId, priority, dueAt}`; infer actor and team from the session and assignee. `review` accepts `{decision: 'approve'|'requestChanges', note}`. `updates` accepts `{progress, note, blocker?, requestedStatus?}` and validates lifecycle transitions.

## 12. Navigation and deep links

Routes: `/login`, `/verify`, `/home`, `/tasks`, `/tasks/new`, `/tasks/:taskId`, `/tasks/:taskId/update`, `/employees`, `/employees/:employeeId`, `/reports`, `/profile`, `/admin/users`, `/company`, `/settings`, `/forbidden`, and `/not-found`. Define literal `new` routes before task-ID matches. Nested bottom navigation retains a consistent shell: Home, Tasks, Reports, Profile. Employee directory and User management are authorized dashboard actions.

The Admin dashboard's Employees action opens the managed directory. Super Admin team rows open a team-filtered directory and Manage users opens account administration. Profile's settings icon opens Settings; the Company row opens company information. Terms/privacy open scrollable sheets from Settings. These entry points keep the supporting screens reachable without adding more bottom tabs.

Use **Flutter's built-in deep-link handling with go_router** for the workshop. `DeepLinkService` normalizes incoming URIs, allows only recognized schemes/hosts and paths, and manages one validated pending destination. It is not a second platform event listener. Avoid installing app_links unless switching intentionally to plugin-based handling; Flutter documents that the default handler must then be disabled. [Flutter deep linking](https://docs.flutter.dev/ui/navigation/deep-linking).

Workshop links: `teamflow://app/tasks/T001` and `teamflow://app/employees/E001`, normalized to internal routes. Configure Android intent filters for scheme `teamflow` and host `app`; document the iOS URL scheme. Later production URLs such as `https://tasks.your-company.com/tasks/T001` require an owned domain, Android assetlinks.json and iOS associated-domain/AASA setup. Merely adding a Dart URL constant does not verify a domain.

Redirect order: session initializing → wait; unauthenticated → login while preserving a validated internal destination; authenticated → resolve resource permissions; permitted → destination; denied/missing → proper error view. Resume after successful login only if the new account is authorized. Discard pending destinations on explicit logout, reset or rejection. Never place an OTP/token in URLs and never accept arbitrary external redirect destinations.

Validate cold launch, warm launch, signed-out→sign-in resume, wrong-role access, malformed ID, unknown route, duplicate link delivery, back navigation and logout. Android is required during the workshop; iOS parity remains unverified until tested on its platform.

## 13. UI and Figma handoff

The `ui/` folder contains **17 individual 390 × 844 SVG screens**, a combined board and an HTML viewing gallery. IDs map to the screen list in `ui/README.md`. Vector shapes and text keep the source editable; system bars are visual reference only. Drag the SVGs into Figma. SVG import alone does not produce Flutter widgets, Auto Layout constraints, reusable Figma components or interactive navigation.

Design language: warm white background, navy headings, blue primary actions, light cards, 20 px page padding, 16 px card radius, 12 px field radius, 52 px primary button, 48 px minimum touch targets. Status colors always have labels. Use one bundled font consistently across Flutter and Figma; the provided SVGs use Arial for deterministic previews. Changing to another font requires updating both designs and screenshot baselines. Fonts are referenced, not embedded or redistributed.

Implement shared AppButton, TaskCard, StatusChip, SummaryCard, EmployeeRow, AppField and ChartCard. Reuse the same dashboard layout with role-specific scope/actions. UI states include loading, empty, failed load, forbidden, validation errors, submitting and success. Main SVGs specify populated states; these additional states are described in the requirements and must be implemented before app acceptance.

UI parity process: freeze seed/clock/viewport/font/theme → implement screen → capture Flutter content at 390 × 844 logical pixels and devicePixelRatio 1 → compare against the matching SVG render → correct spacing, copy, color, typography and data differences. Normalize or exclude OS system bars. For scrollable screens compare the initial viewport first and exercise the rest manually. Also check 360 px width and enlarged text for clipping; the fixed SVG viewport is a reference, not a fixed-size Flutter layout.

## 14. Build sequence and reviewable outputs

| Milestone | Work | Exit criterion |
|---|---|---|
| M0 — Contracts | Freeze requirements, roles, seed, tokens and endpoint shapes | Trainer can explain all roles and reproduce expected totals. |
| M1 — Foundation | Create project, dependencies, constants, theme, injection and lint config | App starts to a themed route with no analysis errors. |
| M2 — Data and auth | Models, mock provider, shared store, auth repository and AuthBloc | All nine accounts resolve correct role; invalid paths fail; no network. |
| M3 — Navigation | Shell, route guards, pending link and access policy | Private deep links cannot bypass login or role scope. |
| M4 — First vertical slice | Employee dashboard, list, detail and work update | Asha's update refreshes detail/list/dashboard using one data source. |
| M5 — Management | Assignment, review, directory and Super Admin role form | Admin → employee → admin workflow persists across account switches. |
| M6 — Reporting and polish | Profile totals, two charts, announcements, about and error states | All totals reconcile with fixture and updates; SVG comparison complete. |
| M7 — Workshop packaging | Focused tests, starter gaps, completed reference and rehearsal | Checkpoint recovery works and a pair completes the lab in allotted time. |

Suggested team ownership: developer A owns auth/router/services; B owns tasks/detail/update; C owns dashboard/reports/profile; D owns admin/directory/shared UI. In smaller groups combine C and D. The trainer/integration owner owns shared models, constants, repository contracts and merges. These are proposed human development roles, not agents dispatched by this plan.

Integrate a working vertical slice before teams branch into features. Use short feature branches and small PRs referencing requirement IDs. Agree interface changes with their owners first and merge shared contracts before consumers. Keep frequent integration checkpoints and a recoverable working app.

## 15. Strict team rules

1. Views render state and send events. No Dio calls, seed access, permission decisions or JSON parsing in widgets.
2. Every business operation goes through a repository contract. UI cannot mutate model collections or MockDatabase.
3. BLoCs do not depend on BuildContext or another feature BLoC. Dispose subscriptions/controllers and clear account-specific state on logout.
4. One authoritative source for records, text keys, routes, endpoints and theme tokens. Do not duplicate dashboard numbers.
5. Use immutable typed models, enums and explicit error types. Avoid `dynamic` outside the provider/JSON boundary and avoid blanket catch-and-ignore.
6. File names use snake_case, classes PascalCase and functions/variables lowerCamelCase. Name presentation files `*_view.dart` and `*_bloc.dart` consistently.
7. Reuse components based on actual repetition. Split oversized files by responsibility; avoid speculative abstractions and unnecessary use-case classes for simple CRUD.
8. Every async view covers loading, content, empty and failure. Every mutation covers validation, submitting, success and failure.
9. Guard access in routing and data operations. Include denial cases in tests and never identify permissions from a UI role toggle.
10. PRs identify behavior changed, requirement IDs, screenshots when visual, and relevant tests. One other developer reviews shared-contract and permission changes.
11. Run `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test` on PRs; keep app builds reproducible with a committed lockfile.
12. Do not log authentication or personal payloads, add real service secrets, or silently switch the demo to real network mode.

Use a PR checklist and standard analyzer configuration for enforcement. Do not claim style guidelines alone enforce architectural imports; review the boundaries and introduce a targeted architecture check only if the team needs it.

## 16. Two-day teaching schedule

Both days: 09:30–17:00. Breaks 11:00–11:15 and 15:45–16:00; lunch 12:30–13:30. Each day has six contact hours.

| Day 1 | Topic | Participant output |
|---|---|---|
| 09:30–10:00 | Product brief, roles, app walkthrough and team rules | Requirement ownership and role matrix understood |
| 10:00–11:00 | Trace a BLoC event through repository/provider; review scaffold | Add one typed model mapping and repository read |
| 11:15–12:30 | Phone/OTP AuthBloc and routing guards | Login and role-specific session flow |
| 13:30–14:30 | Reusable dashboard and task cards | Employee home from repository state |
| 14:30–15:45 | Task list/detail, search and filters | Employee can find and inspect assigned work |
| 16:00–17:00 | Pair integration, errors and BLoC tests | Working employee read flow and day-one checkpoint |

| Day 2 | Topic | Participant output |
|---|---|---|
| 09:30–10:00 | Recap and assignment contract | Agree the state transition and write model |
| 10:00–11:00 | Admin assignment and task form validation | Create/reassign a task inside team scope |
| 11:15–12:30 | Work update, prepared timer and review actions | Employee update → admin approval flow |
| 13:30–14:30 | Profile and chart bindings | Work entries drive totals and graphs |
| 14:30–15:45 | Super Admin scaffold, deep links and permission tests | Run nine-role accounts, denial and link scenarios |
| 16:00–17:00 | Acceptance demo, SVG comparison and review | Demonstrate end-to-end workflow and explain boundaries |

Use prepared checkpoints: `00-starter`, `01-auth`, `02-employee`, `03-management`, `04-complete`. These names describe future workshop checkpoints; they have not been created as Git branches/tags in this planning delivery. Teams that fall behind can restore a known checkpoint and continue learning the next concept. Have Flutter/Android SDK, emulator/device, packages and the selected font ready before the first session.

## 17. Testing and definition of done

Focus on meaningful behavior: phone-to-role mapping for all nine accounts; invalid/expired OTP; task/team access denied; assignment valid/invalid scope; role changes with active tasks; task transitions; timer overlap, stop and cross-day calculations; derived chart totals after updates; stale data on account switching; deep links through login.

Widget checks cover form validation and correct role actions. Integration acceptance logs in as Priya, assigns a Product task to Rahul, switches accounts, records work/submits, switches back and approves, then verifies Done and updated metrics. Separate cases cover Super Admin access changes, missing task, offline mock scenario and reset. Use controlled clocks and no actual network. Add a small set of golden comparisons for shared cards and the main populated screens once the UI is implemented, then verify the remaining SVG screens manually.

Deliverable completion checklist:

- All 5 Employee, 3 Admin and 1 Super Admin accounts work with populated data and correct permissions.
- All required screens and mutations work with one mock dataset; logout does not reseed it.
- No request contacts a real API/SMS service in default mode; deterministic error simulations work.
- All indexed texts, routes, endpoints, version metadata and services live in the agreed folders.
- Charts, task listings, activity and profiles update consistently after successful writes.
- Android deep links pass cold/warm/auth/forbidden tests; other platforms are marked verified or pending truthfully.
- Code is formatted; analyzer, focused tests and Android debug build pass on the locked trainer setup.
- Each required SVG is compared with its corresponding implemented app screen, and 360 px/enlarged text checks pass.
- Trainer guide, account list, client requirements, starter and completed app are packaged.

## 18. Improvements after the workshop

First add local persistence and a clear reset button for repeated demos. Next replace MockApiProvider with authenticated server APIs, server-enforced permissions and real OTP infrastructure while keeping repository contracts. Then add task attachments and review comments, announcement publishing and an in-app notification inbox. Introduce leave requests/approvals if the company needs a second workflow. Add offline synchronization, audit retention, accessibility refinements and localization before broad deployment. Attendance, payroll and multi-company scope each need a separate requirements discussion.

Practical risks: two-day scope depends on scaffold readiness; fixed SVGs do not provide responsive behavior; authentication is deliberately mock; iOS requires platform testing; a future backend may refine the proposed endpoint contract. Resolve these at the relevant milestone, with a working reference app rehearsed before training.
