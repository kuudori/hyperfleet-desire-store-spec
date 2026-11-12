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
 * Adapters to Appliers. A caller authenticates with a bearer token for its
 * service account, and the API takes the caller's identity and authorized
 * partition from it.
 *
 * | Operation | Callers |
 * |-----------|---------|
 * | List desires, Get a desire | Adapter, remote Applier, sweeper |
 * | Create or update a desire | Adapter; sweeper for DeleteDesire only |
 * | Write the status of a desire | Remote Applier |
 * | Delete a desire | Adapter, sweeper |
 *
 * Other calls return 403. Errors are RFC 9457 problem details with a
 * `HYPERFLEET-CAT-NUM` code. Do not retry 400, 401, 403, or 422 unchanged.
 * For a 409, follow the client action in `ConflictProblem`. Retry 503,
 * timeouts, and network failures with capped exponential backoff and jitter,
 * and wait for `Retry-After` on 429.
 *
 * **v1 compatibility.** Supported v1 Appliers keep working when the API is
 * deployed independently. Only optional additive fields can change within
 * v1. Changes to required fields, operation behavior, authorization,
 * compare-and-swap, or idempotency need a new API version.
 */
@service(#{ title: "HyperFleet Desire Store API" })
@info(#{
  version: "0.2.0",
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
