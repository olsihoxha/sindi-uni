# JSON API

Base URL: `http://localhost:3000/api/v1` (use the deployed HTTPS origin in production).

Every endpoint requires **HTTP Basic authentication** with the same email/password used in the UI. API controllers do not accept browser session cookies; session-authenticated UI writes use Rails CSRF protection. Always use HTTPS outside local development. Passwords and password digests never appear in API responses.

For the examples, export local demo credentials. These are sample accounts, not production secrets.

```bash
export GRADEBOOK_URL='http://localhost:3000'
export GRADEBOOK_EMAIL='instructor@example.com'
export GRADEBOOK_PASSWORD='LearnWell2026'
```

## Endpoints

| Method | Path | Access | Success |
| --- | --- | --- | --- |
| GET | `/api/v1/students` | Instructor | 200, `{students: [...]}` |
| POST | `/api/v1/students` | Instructor | 201, `{student: {...}}` |
| GET | `/api/v1/students/:id` | Instructor | 200, `{student: {...}}` |
| PATCH / PUT | `/api/v1/students/:id` | Instructor | 200, `{student: {...}}` |
| DELETE | `/api/v1/students/:id` | Instructor | 204, empty body |
| GET | `/api/v1/transcripts?student_id=:id` | Instructor or that student | 200 |
| GET | `/api/v1/transcripts/:student_id` | Same; alternate URL | 200 |
| POST | `/api/v1/grades` | Instructor | 200, `{count: N, grades: [...]}` |

## Student CRUD

```bash
curl -u "$GRADEBOOK_EMAIL:$GRADEBOOK_PASSWORD" "$GRADEBOOK_URL/api/v1/students"

curl -u "$GRADEBOOK_EMAIL:$GRADEBOOK_PASSWORD" \
  -H 'Content-Type: application/json' \
  -d '{"student":{"name":"Ada","surname":"Leka","email":"ada@example.com","password":"StrongPass123","password_confirmation":"StrongPass123"}}' \
  "$GRADEBOOK_URL/api/v1/students"

# Replace 12 with the ID from the create response.
curl -u "$GRADEBOOK_EMAIL:$GRADEBOOK_PASSWORD" "$GRADEBOOK_URL/api/v1/students/12"

curl -u "$GRADEBOOK_EMAIL:$GRADEBOOK_PASSWORD" -X PATCH \
  -H 'Content-Type: application/json' -d '{"student":{"name":"Adela"}}' \
  "$GRADEBOOK_URL/api/v1/students/12"

curl -u "$GRADEBOOK_EMAIL:$GRADEBOOK_PASSWORD" -X DELETE \
  "$GRADEBOOK_URL/api/v1/students/12"
```

Writable attributes: `name`, `surname`, `email`, `password`, optional `password_confirmation`. The server always assigns the student role; clients cannot create instructors or change roles. Password may be omitted or blank during an update to keep it unchanged. A supplied confirmation must match. Deletion also deletes that student's enrollments and grades.

Student objects include only `id`, `name`, `surname`, `email`, `role`. Email uniqueness is case-insensitive across both roles.

## Transcript

Required: `student_id`. Optional: `start_semester`, `end_semester`. The bounds are inclusive. Invalid semester syntax or a reversed range returns 422. A valid empty range returns an empty `semesters` array.

```bash
# Fresh seeds usually assign student1 ID 2. Obtain the actual ID from /students.
curl -u "$GRADEBOOK_EMAIL:$GRADEBOOK_PASSWORD" --get \
  --data-urlencode 'student_id=2' \
  --data-urlencode 'start_semester=Spr 2026' \
  --data-urlencode 'end_semester=Fall 2026' \
  "$GRADEBOOK_URL/api/v1/transcripts"
```

Example response shape (illustrative grades from the coursework example):

```json
{
  "student": { "id": 2, "name": "Sindi Kola" },
  "semesters": [{
    "semester": "Fall 2026",
    "courses": [{
      "code": "CS403",
      "name": "Engineering Advanced Web Applications",
      "overall_grade": 80.5,
      "earned_points": 80.5,
      "graded_count": 3,
      "assessment_count": 3,
      "complete": true,
      "assessments": [
        { "title": "Midterm", "weight": 0.25, "grade": 80 },
        { "title": "Project", "weight": 0.35, "grade": 70 },
        { "title": "Final Exam", "weight": 0.4, "grade": 90 }
      ]
    }]
  }]
}
```

`overall_grade` is null for incomplete results. A missing assessment grade is null, not zero. Semester groups are oldest first; courses are ordered by code. Students receive 403 when requesting someone else's transcript, even if the other ID does not exist.

## Submit grades

Submit an object containing a non-empty `entries` array, maximum 500 entries. Every entry requires `student_id`, `course_code`, `semester`, `assessment_title`, `grade`.

The course, assessment and student enrollment must already exist. Weights must total 1. Assessment titles are case-sensitive; course codes are normalized to uppercase. Grades must be integers between 0 and 120.

```bash
curl -u "$GRADEBOOK_EMAIL:$GRADEBOOK_PASSWORD" \
  -H 'Content-Type: application/json' \
  -d '{"entries":[
    {"student_id":2,"course_code":"CS403","semester":"Fall 2026","assessment_title":"Midterm","grade":80},
    {"student_id":2,"course_code":"CS403","semester":"Fall 2026","assessment_title":"Project","grade":70},
    {"student_id":2,"course_code":"CS403","semester":"Fall 2026","assessment_title":"Final Exam","grade":90}
  ]}' "$GRADEBOOK_URL/api/v1/grades"
```

Existing student/assessment grades are updated; missing ones are inserted. Submitting the same batch again does not duplicate records. Repeated student/assessment entries within one batch are rejected. All entries run in one database transaction: any failure rolls back the entire batch, including earlier updates. Validation errors identify the failing entry, starting at 1.

Example error:

```json
{"error":"Entry 2: Validation failed: Value must be less than or equal to 120"}
```

## Errors

- **401**: absent or invalid Basic credentials; includes `WWW-Authenticate`.
- **403**: authenticated user lacks the required role or transcript ownership.
- **404**: requested student record does not exist.
- **409**: conflicting unique record created by a concurrent request.
- **422**: missing fields, invalid values or invalid batch references. Student model validation responses also include a `details` array.

The API never redirects to login. A batch with a nonexistent course/student/assessment is a validation error (422), because that reference is part of the submitted document.

## Public statistics

`GET /courses/:id/statistics.json` is unauthenticated and limited to courses in the public five-semester catalog. It contains no names, student IDs or individual grade rows:

```json
{
  "count": 2,
  "min": 80.5,
  "max": 90.5,
  "mean": 85.5,
  "standard_deviation": 5.0,
  "enrolled_count": 2,
  "basis": "Completed weighted overall grades; population standard deviation"
}
```

This aggregate endpoint is separate from the protected `/api/v1` endpoints. With no completed results, count is 0 and min/max/mean/deviation are null.
