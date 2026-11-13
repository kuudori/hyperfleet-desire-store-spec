import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

import "./models/desire.tsp";
import "./models/problem.tsp";
import "./services/desires.tsp";

using Http;
using OpenAPI;

/**
 * HyperFleet Desire Store API transports desires (apply, delete, read) from
 * Adapters to Appliers. A caller sends a bearer token for its service account
 * to the gateway. The gateway validates it and passes the caller's identity
 * and authorized partition to the API. The API never takes them from request
 * fields.
 *
 * | Operation | Callers |
 * |-----------|---------|
 * | List desires, Get desire | Adapter, remote Applier, sweeper |
 * | Write desire | Adapter; sweeper for DeleteDesire only |
 * | Write status | Remote Applier |
 * | Delete desire | Adapter, sweeper |
 *
 * Other calls return 403. Errors are RFC 9457 problem details with a
 * `HYPERFLEET-CAT-NUM` code. Do not retry 400, 401, 403, or 422 unchanged.
 * For a 409, follow the client action in `ConflictProblem`. Retry 503,
 * timeouts, and network failures with capped exponential backoff and jitter,
 * and wait for `Retry-After` on 429.
 *
 * **v1 compatibility.**
 *
 * - Supported v1 Appliers must continue working when the API is deployed
 *   independently.
 * - Operation behavior and authorization rules remain stable in v1.
 * - Optional additive request and response fields are compatible within v1.
 * - Changes to required fields, operation behavior, authorization,
 *   compare-and-swap, or idempotency require a new API version.
 */
@service(#{ title: "HyperFleet Desire Store API" })
@info(#{
  version: "0.2.1",
  contact: #{
    name: "HyperFleet Team",
    url: "https://github.com/openshift-hyperfleet",
  },
  license: #{
    name: "Apache 2.0",
    url: "https://www.apache.org/licenses/LICENSE-2.0",
  },
})
@route("/api/hyperfleet/desire-store/v1")
namespace HyperFleet.DesireStore;

// The scheme name is lowercase "bearer", which kin-openapi validates.
model BearerAuth {
  type: AuthType.http;
  scheme: "bearer";
}
