import "@typespec/http";
import "@typespec/openapi";
import "@typespec/openapi3";

using Http;
using OpenAPI;

/**
 * HyperFleet Desire Store API transports desires (apply, delete, read) from
 * Adapters to Appliers.
 *
 * The routes, wire schemas, and error responses come from the Desire Store
 * detailed design in the architecture repository.
 */
@service(#{ title: "HyperFleet Desire Store API" })
@info(#{
  version: "0.1.0",
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
