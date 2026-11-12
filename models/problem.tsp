import "@typespec/http";
import "@typespec/openapi";

using Http;
using OpenAPI;

namespace HyperFleet.DesireStore;

/**
 * Field-level validation error detail.
 */
model ValidationError {
  /** Name of the request field, query parameter, or path parameter that failed validation. */
  @example("version")
  field: string;

  /** The invalid value that was provided, when it is safe to include. */
  value?: unknown;

  /** The validation constraint that was violated. */
  @example("required")
  constraint?:
    | "required"
    | "min"
    | "max"
    | "min_length"
    | "max_length"
    | "pattern"
    | "enum"
    | "format"
    | "unique";

  /** Human-readable error message for this field. */
  @example("version is required")
  message: string;
}

/**
 * Members shared by every RFC 9457 problem response of the Desire Store API.
 * Each problem model adds its own `code`, because a 409 constrains it to the
 * four conflict codes.
 */
alias ProblemBase = {
  /** URI reference that identifies the problem type, in the form `https://api.hyperfleet.io/errors/{problem-type}`. */
  @format("uri")
  type: string;

  /** Short human-readable summary of the problem type. */
  title: string;

  /** HTTP status code of the response. */
  status: int32;

  /** Human-readable explanation specific to this occurrence. */
  detail?: string;

  /** URI reference for this occurrence: the request path. */
  @format("uri-reference")
  instance?: string;

  /** RFC 3339 timestamp of when the error occurred. */
  @format("date-time")
  timestamp?: string;

  /** Distributed trace ID for correlating the response with server logs. */
  trace_id?: string;
};

/** The cause of a 409 response. `ConflictProblem` lists each code. */
union ConflictCode {
  AlreadyExists: "HYPERFLEET-CNF-001",
  VersionConflict: "HYPERFLEET-CNF-002",
  DeletePending: "HYPERFLEET-CNF-003",
  OwnerConflict: "HYPERFLEET-CNF-004",
}

/**
 * RFC 9457 problem details for a 409 response. Each cause has its own `code`,
 * so a client tells a recoverable conflict from an ownership error without
 * parsing `detail`.
 *
 * | Cause | Type | Code | Client action |
 * |-------|------|------|---------------|
 * | The version in a write, a status write, or a delete is not current | `version-conflict` | `HYPERFLEET-CNF-002` | Read the desire again. If the change is still necessary, retry with the current version |
 * | The caller creates a desire that it already has | `resource-conflict` | `HYPERFLEET-CNF-001` | Read the desire, then update it with its version |
 * | The caller creates an ApplyDesire while the DeleteDesire for the object is not confirmed | `resource-conflict` | `HYPERFLEET-CNF-003` | Retry after the Applier confirms the delete. The store then replaces the DeleteDesire with the new ApplyDesire |
 * | A different caller owns the object | `resource-conflict` | `HYPERFLEET-CNF-004` | Do not retry. No request from this caller changes the `owner` |
 *
 * On a write or a delete, the store checks the version before the `owner`.
 * When both are wrong, the response is `HYPERFLEET-CNF-002`. The retry with
 * the current version then gets `HYPERFLEET-CNF-004`. Status writes do not
 * check the `owner`, so `HYPERFLEET-CNF-002` is the only conflict code that a
 * status write can get.
 */
@example(#{
  type: "https://api.hyperfleet.io/errors/version-conflict",
  title: "Version Conflict",
  status: 409,
  detail: "Desire was modified by another request. Expected version 3, found version 7.",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires/apply:apps:deployments:kube-system:coredns",
  code: "HYPERFLEET-CNF-002",
  timestamp: "2026-10-19T10:32:00.789Z",
  trace_id: "6df92f3577b34da6a3ce929d0e0e4738",
  expected_version: 3,
  actual_version: 7,
})
model ConflictProblem {
  ...ProblemBase;

  // No property doc. With one, TypeSpec emits `allOf` and oapi-codegen v2.7.2
  // generates an anonymous struct around `ConflictCode`.
  code: ConflictCode;

  /** The version the request carried. Present on `HYPERFLEET-CNF-002`. */
  expected_version?: int64;

  /** The version stored for the desire. Present on `HYPERFLEET-CNF-002`. */
  actual_version?: int64;
}

/** Problem body for a 400 response. */
@example(#{
  type: "https://api.hyperfleet.io/errors/validation-error",
  title: "Validation Error",
  status: 400,
  detail: "version is required",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires/apply:apps:deployments:kube-system:coredns",
  code: "HYPERFLEET-VAL-001",
  timestamp: "2026-10-19T10:30:00.123Z",
  trace_id: "4bf92f3577b34da6a3ce929d0e0e4736",
  errors: #[#{ field: "version", constraint: "required", message: "version is required" }],
})
model BadRequestProblem {
  ...ProblemBase;

  /** Machine-readable error code in `HYPERFLEET-CAT-NUM` format. */
  code?: string;

  /** Field-level validation errors, present on validation failures. */
  errors?: ValidationError[];
}

/** Problem body for a 401 response that the API produces. */
@example(#{
  type: "https://api.hyperfleet.io/errors/invalid-credentials",
  title: "Invalid Credentials",
  status: 401,
  detail: "The credential is missing, invalid, or expired.",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires",
  code: "HYPERFLEET-AUT-002",
  timestamp: "2026-10-19T10:30:30.000Z",
  trace_id: "4bf92f3577b34da6a3ce929d0e0e4737",
})
model UnauthorizedProblem {
  ...ProblemBase;

  /** Machine-readable error code in `HYPERFLEET-CAT-NUM` format. */
  code?: string;
}

/** Problem body for a 403 response that the API produces. */
@example(#{
  type: "https://api.hyperfleet.io/errors/permission-denied",
  title: "Permission Denied",
  status: 403,
  detail: "The caller class is not permitted to write desired state.",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires/apply:apps:deployments:kube-system:coredns",
  code: "HYPERFLEET-AUZ-003",
  timestamp: "2026-10-19T10:30:45.000Z",
  trace_id: "4bf92f3577b34da6a3ce929d0e0e4738",
})
model ForbiddenProblem {
  ...ProblemBase;

  /** Machine-readable error code in `HYPERFLEET-CAT-NUM` format. */
  code?: string;
}

/** Problem body for a 404 response. */
@example(#{
  type: "https://api.hyperfleet.io/errors/resource-not-found",
  title: "Resource Not Found",
  status: 404,
  detail: "Desire 'apply:apps:deployments:kube-system:coredns' not found.",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires/apply:apps:deployments:kube-system:coredns",
  code: "HYPERFLEET-NTF-001",
  timestamp: "2026-10-19T10:31:00.456Z",
  trace_id: "5cf92f3577b34da6a3ce929d0e0e4737",
})
model NotFoundProblem {
  ...ProblemBase;

  /** Machine-readable error code in `HYPERFLEET-CAT-NUM` format. */
  code?: string;
}

/** Problem body for a 422 response. */
@example(#{
  type: "https://api.hyperfleet.io/errors/validation-error",
  title: "Validation Error",
  status: 422,
  detail: "kubeContent identifies a Deployment named 'other', but the path names 'coredns'.",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires/apply:apps:deployments:kube-system:coredns",
  code: "HYPERFLEET-VAL-002",
  timestamp: "2026-10-19T10:32:30.000Z",
  trace_id: "6df92f3577b34da6a3ce929d0e0e4739",
})
model UnprocessableProblem {
  ...ProblemBase;

  /** Machine-readable error code in `HYPERFLEET-CAT-NUM` format. */
  code?: string;

  /** Field-level validation errors, present on validation failures. */
  errors?: ValidationError[];
}

/** Problem body for a 429 response. */
@example(#{
  type: "https://api.hyperfleet.io/errors/rate-limit-exceeded",
  title: "Rate Limit Exceeded",
  status: 429,
  detail: "Too many requests. Retry after the delay in the Retry-After header.",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires",
  code: "HYPERFLEET-LMT-001",
  timestamp: "2026-10-19T10:33:00.012Z",
  trace_id: "7ef92f3577b34da6a3ce929d0e0e4739",
})
model RateLimitProblem {
  ...ProblemBase;

  /** Machine-readable error code in `HYPERFLEET-CAT-NUM` format. */
  code?: string;
}

/** Problem body for a 500 response. */
@example(#{
  type: "https://api.hyperfleet.io/errors/internal-error",
  title: "Internal Error",
  status: 500,
  detail: "An unexpected error occurred. Please try again later.",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires",
  code: "HYPERFLEET-INT-001",
  timestamp: "2026-10-19T10:34:00.345Z",
  trace_id: "8ff92f3577b34da6a3ce929d0e0e4740",
})
model InternalErrorProblem {
  ...ProblemBase;

  /** Machine-readable error code in `HYPERFLEET-CAT-NUM` format. */
  code?: string;
}

/** Problem body for a 503 response. */
@example(#{
  type: "https://api.hyperfleet.io/errors/service-unavailable",
  title: "Service Unavailable",
  status: 503,
  detail: "The service is temporarily unavailable.",
  instance: "/api/hyperfleet/desire-store/v1/partitions/mc-01/desires",
  code: "HYPERFLEET-SVC-001",
  timestamp: "2026-10-19T10:35:00.000Z",
  trace_id: "8ff92f3577b34da6a3ce929d0e0e4741",
})
model ServiceUnavailableProblem {
  ...ProblemBase;

  /** Machine-readable error code in `HYPERFLEET-CAT-NUM` format. */
  code?: string;
}

@doc("Malformed request: invalid identifier encoding, query parameters, or JSON; a missing or non-integer `version` on a delete or on an ApplyDesire or DeleteDesire status write; `owner` in a write body; `target_version` missing on a ReadDesire write; a non-zero `version` on a ReadDesire or DeleteDesire write.")
model BadRequestResponse {
  @statusCode statusCode: 400;
  @header contentType: "application/problem+json";
  @body body: BadRequestProblem;
}

@doc("""
  The credential is missing, invalid, or expired. The body can be absent, so a client must not require an Error Model body on a 401.
  """)
model UnauthorizedResponse {
  @statusCode statusCode: 401;
  @header contentType: "application/problem+json";
  @body body: UnauthorizedProblem;
}

@doc("""
  The caller class is not permitted for the operation, or the path partition is outside the caller's authorization. The body can be absent, so a client must not require an Error Model body on a 403.
  """)
model ForbiddenResponse {
  @statusCode statusCode: 403;
  @header contentType: "application/problem+json";
  @body body: ForbiddenProblem;
}

@doc("The desire is absent.")
model NotFoundResponse {
  @statusCode statusCode: 404;
  @header contentType: "application/problem+json";
  @body body: NotFoundProblem;
}

@doc("One of four conflicts. The `code` field tells which one; see `ConflictProblem`.")
model ConflictResponse {
  @statusCode statusCode: 409;
  @header contentType: "application/problem+json";
  @body body: ConflictProblem;
}

@doc("Well-formed JSON that fails semantic validation, such as `kubeContent` whose Kubernetes identity does not match the path.")
model UnprocessableEntityResponse {
  @statusCode statusCode: 422;
  @header contentType: "application/problem+json";
  @body body: UnprocessableProblem;
}

@doc("Rate limited. Honor the `Retry-After` header before retrying.")
model TooManyRequestsResponse {
  @statusCode statusCode: 429;
  @header contentType: "application/problem+json";

  /** Delay before the client retries: delay-seconds or an HTTP date (RFC 9110). */
  @header("Retry-After") retryAfter: string;

  @body body: RateLimitProblem;
}

@doc("Internal error.")
model InternalServerErrorResponse {
  @statusCode statusCode: 500;
  @header contentType: "application/problem+json";
  @body body: InternalErrorProblem;
}

@doc("The API is degraded. Retry with capped exponential backoff and jitter.")
model ServiceUnavailableResponse {
  @statusCode statusCode: 503;
  @header contentType: "application/problem+json";
  @body body: ServiceUnavailableProblem;
}
