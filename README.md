# Gradebook

A complete Ruby on Rails grade-keeping application for **CS403 – Engineering Advanced Web Applications**, implemented from [`aewa-coursework.pdf`](aewa-coursework.pdf).

Repository: [olsihoxha/sindi-uni](https://github.com/olsihoxha/sindi-uni) (public).

Instructors manage courses, students, enrollments, assessments and grades. Students see their own progress. Visitors can explore the last five semesters and view aggregate course statistics.

## Run locally

Requirements: **Ruby 3.4.x** (the project pins 3.4.3), Bundler, and SQLite. Node, Redis and a separate frontend build are not required.

```bash
bundle install
bin/setup
```

Open **http://localhost:3000/welcome**. `bin/setup` prepares the database, adds demo records and starts Rails. To prepare without starting the server:

```bash
bin/setup --skip-server
bin/rails server
```

On this Mac, the shell's default Ruby is too old. Select the installed Homebrew Ruby first:

```bash
export PATH="/opt/homebrew/opt/ruby@3.4/bin:$PATH"
```

### Demo accounts

| Role | Email | Local demo password |
| --- | --- | --- |
| Instructor | `instructor@example.com` | `LearnWell2026` |
| Student | `student1@example.com` | `LearnWell2026` |
| Other students | `student2@example.com` through `student10@example.com` | `LearnWell2026` |

Seed data contains **1 instructor, 10 students, 10 courses, 100 enrollments and 300 grades**. The courses span the current and four preceding semesters at the time of initial seeding. Seeds are idempotent: rerunning them fills missing demo records without resetting existing passwords or overwriting grades. Existing course semesters are preserved.

Use `DEMO_PASSWORD='YourOwnPassword123' bin/rails db:seed` to choose a different password when creating demo accounts. This does not change already-created accounts. Production seeding requires `DEMO_PASSWORD` and refuses to use the local fallback. Change passwords through the instructor profile/student forms after deployment.

## What is included

- A responsive catalog at `/welcome`, a client-side semester filter and an accessible statistics dialog, with a standalone statistics page as a non-JavaScript fallback.
- Session login/logout, role-aware dashboards, protected views and readable validation errors.
- Instructor profile editing and full student/course CRUD.
- Assessment management, enrollment management and individual grade CRUD.
- Student dashboards showing each enrolled course, grading progress, weighted results and assessment breakdowns.
- JSON APIs for student CRUD, semester-filtered transcripts and atomic grade imports.
- SQLite for development/testing, PostgreSQL for production, a Render Blueprint and GitHub Actions CI.
- A [project report and ER diagram](docs/PROJECT_REPORT.md), [API documentation](docs/API.md), and automated tests.

## Walkthrough

1. Open `/welcome`; filter by semester and use **Statistics** on a course.
2. Open a **Class roster** link while logged out; the app redirects to login.
3. Log in as instructor. The dashboard links to courses, students, your profile and the public catalog.
4. Create a course with a unique 5–6 character code. Add assessments until the weights total 1 (100%).
5. Create a student, then enroll them from the course's class roster.
6. Choose **Manage grades** next to the enrolled student. Add, edit or delete grades.
7. Log out and log in as that student to see their results. Students cannot edit records or view another student's grades.

## Grading and semester decisions

- Weights are fractions: `0.25` means 25%. Draft plans may total less than 1; grades can only be entered when the plan totals exactly 1. Once grades exist, edits cannot invalidate that total. Remove grades first to redesign a weighted plan.
- Grades are integers from **0 to 120**, allowing extra credit. Results are not capped at 100.
- The weighted formula is `sum(assessment weight × grade)`. The brief's example, `0.25×80 + 0.35×70 + 0.40×90`, yields **80.5**.
- Missing grades produce **In progress** and a separate earned-points subtotal. They do not become final zeros.
- Public statistics describe **completed weighted overall grades per student**, excluding incomplete results. Standard deviation uses the population formula. Empty statistics return `count: 0` and null numerical measures.
- Semester labels are **`Spr 2026`, `Sum 2026`, `Fall 2026`**. `Spring 2026` is 11 characters and would violate the brief's maximum of 10, so spring and summer are abbreviated. Spring runs January–May; summer June–August; fall September–December. Ranges are inclusive and sorted chronologically.
- Course codes are globally unique, following the validation requirement literally. A repeated offering currently needs a distinct code. The report explains a future course/offering split.
- Instructors share the registry. Authenticated students can view roster names, as the brief requires authentication for rosters, but emails and grade-management links appear only to instructors.

## Tests and checks

```bash
bin/rails test
bin/rails zeitwerk:check
RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
```

**Verified:** 30 tests and 277 assertions pass on both SQLite and PostgreSQL 14.

The suite covers validation boundaries, the 80.5 example, incomplete results, statistics, semester ordering, all main instructor screens, CRUD, role restrictions, transcript ownership and atomic batch rollback. CI repeats the tests and production asset compilation on Linux. Browser interaction and visual checks were unavailable in the implementation session; use the walkthrough above for that final manual review.

After compiling assets locally, run `bin/rails assets:clobber` before editing styles/JavaScript in development so stale compiled files do not hide changes.

## Deploy to Render

The repository includes [`render.yaml`](render.yaml) and [`bin/render-build.sh`](bin/render-build.sh), following [Render's Rails deployment guide](https://render.com/docs/deploy-rails-8). No live Render deployment has been created yet; account access is required.

1. Push this repository to GitHub and connect that repository to Render.
2. In Render, create a **Blueprint** from the repository. It creates a Ruby web service and a PostgreSQL database.
3. Set `DEMO_PASSWORD` to a strong password when prompted. `SECRET_KEY_BASE` is generated automatically; `DATABASE_URL` is wired from the database. No Rails master key is needed because this app uses environment variables for production secrets.
4. Deploy. The build installs gems, compiles assets, migrates PostgreSQL and, on the initial configuration, seeds demo data. The health check is `/up`.
5. Verify login, student permissions, the transcript API and statistics on the deployed URL.
6. Set `SEED_DEMO_DATA` to `false` in the Render environment after the initial seed. This prevents future deployments from recreating intentionally deleted demo records.

The Blueprint selects free plans; availability, retention and limits depend on Render's current account offerings. Choose suitable paid plans if persistent assessment-period hosting requires them. Migration in the build script supports the free plan; for a larger production deployment, move migrations to a pre-deploy step and use backward-compatible migrations.

## Project layout

```text
app/models/          Validations, relationships and semester representation
app/services/        Shared grading, statistics, transcript and import logic
app/controllers/     Session-authenticated HTML workflows
app/controllers/api/ HTTP Basic-authenticated JSON APIs
app/views/           ERB templates and shared forms
app/assets/          CSS and small, dependency-free JavaScript enhancements
db/                  Schema, migrations and deterministic demo seeds
test/                Model and request/integration tests
docs/                Coursework report, ER diagram and API reference
render.yaml          Web service and production PostgreSQL deployment
```

## Submission

The coursework requires the GitHub repository, this documentation, a project report with an ER diagram, and a Render deployment. The PDF lists **December 13, 23:59** as the deadline. See [the project report](docs/PROJECT_REPORT.md) for the requirements mapping, architecture, design decisions and limitations. Add the live Render URL after deployment.
