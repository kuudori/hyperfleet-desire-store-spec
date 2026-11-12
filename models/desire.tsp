import "@typespec/http";
import "@typespec/openapi";

using Http;
using OpenAPI;

namespace HyperFleet.DesireStore;

/** The kind of desire. */
enum DesireType {
  /** Declares a Kubernetes object that the Applier creates or updates. */
  apply,

  /** Declares that the Applier removes a Kubernetes object. */
  delete,

  /** Declares that the Applier mirrors a live Kubernetes object into `status`. */
  read,
}

/**
 * The identifier of a desire: its identity fields joined by `:`, in the order
 * `type`, `group`, `resource`, `namespace`, `name`. An empty field is an empty
 * segment, so `apply:rbac.authorization.k8s.io:clusterroles::admin` names a
 * cluster-scoped object that has no namespace.
 *
 * `type`, `group`, `resource`, and `namespace` are DNS names and cannot
 * contain colons. `name` comes last and may contain colons, for example the
 * built-in ClusterRoles named `system:controller:*`, so a decoder takes the
 * first four segments positionally and joins the remainder as the name. The
 * encoding is unambiguous and reversible. `name` follows Kubernetes
 * path-segment name validation: it is neither `.` nor `..` and contains
 * neither `/` nor `%`. The pattern also requires a non-empty `name`.
 *
 * The sixth identity field, `managementCluster`, is the partition. It travels
 * in the route path and not in the identifier.
 */
@pattern("^(apply|delete|read):[a-z0-9.-]*:[a-z0-9-]+:[a-z0-9-]*:([^/%.][^/%]*|[.][^/%.][^/%]*|[.][.][^/%]+)$")
@example("apply:apps:deployments:kube-system:coredns")
scalar DesireId extends string;

/**
 * The fields that List returns for each desire: the identity fields and the
 * version. `id` is the desire identifier as it appears in the route path, and
 * `type` is the kind of desire.
 */
model DesireReference {
  // No property docs on `id` and `type`. With one, TypeSpec emits `allOf` and
  // oapi-codegen v2.7.2 generates `Id struct{ DesireId }` instead of
  // `Id DesireId`.
  id: DesireId;
  type: DesireType;

  /** The Kubernetes API group of the target object. Empty for the core group. */
  group: string;

  /** The plural resource name of the target object. */
  resource: string;

  /** The namespace of the target object. Empty for a cluster-scoped object. */
  `namespace`: string;

  /** The name of the target object. */
  name: string;

  /**
   * The compare-and-swap version of the record. It is 1 on create and
   * increases by 1 on every update and every ApplyDesire or DeleteDesire status
   * write. A ReadDesire status write does not change it. Versions restart at 1
   * for each record.
   */
  @minValue(1)
  version: int64;
}

/**
 * A desire, as Get returns it. Which optional fields appear depends on
 * `type`:
 *
 * - ApplyDesire carries `kubeContent`.
 * - ReadDesire carries `target_version` and no top-level `kubeContent`. The
 *   mirrored object is in `status.kubeContent`.
 * - DeleteDesire carries neither `kubeContent` nor `target_version`.
 */
model Desire {
  ...DesireReference;

  /**
   * The identity of the caller that wrote the desire: its service-account
   * subject, for example
   * `system:serviceaccount:hyperfleet:cluster-adapter-hyperfleet-adapter`. The
   * API sets it from the authenticated caller, and clients never send it.
   * All desires for one Kubernetes object in one partition have the same
   * `owner`: the caller that created the first of them.
   */
  owner: string;

  /**
   * The HyperFleet resource that triggered the desire, for example
   * `clusters/cls-123`.
   */
  resource_id: string;

  /**
   * The rendered Kubernetes manifest of an ApplyDesire. Its Kubernetes
   * identity must match the path.
   */
  kubeContent?: Record<unknown>;

  /**
   * The Kubernetes API version to read the object as, for example `v1`.
   * Present on a ReadDesire.
   */
  target_version?: string;

  /**
   * The status that the Applier wrote. Its shape is not part of this
   * contract. On a ReadDesire, `status.kubeContent` holds the mirrored live
   * object.
   */
  status?: Record<unknown>;

  /**
   * The desire generation. The API sets it, and clients never send it. It is
   * 1 on create and advances only when an ApplyDesire's `kubeContent`
   * changes. JSON whitespace and object-key order do not count as content
   * changes. It does not change on a status write. It is not the HyperFleet API
   * resource's generation or the Kubernetes `metadata.generation`. A
   * DeleteDesire and a ReadDesire have no update, so their `generation` stays
   * 1.
   */
  @minValue(1)
  generation: int64;
}

/**
 * One page of desire references.
 */
model DesireList {
  /** The references on this page. Get serves the full record of each one. */
  items: DesireReference[];

  /**
   * An opaque cursor for the next page. Omitted on the last page. Pass it
   * unchanged as the `cursor` query parameter.
   */
  next_cursor?: string;
}

/**
 * The body of a Write desire request. It carries no identity or ownership
 * fields, and a body that includes `owner` returns 400.
 *
 * - An ApplyDesire write also carries `kubeContent`.
 * - A ReadDesire write also requires `target_version`. A missing
 *   `target_version` returns 400.
 * - A ReadDesire or DeleteDesire write has no `kubeContent` field.
 */
model DesireWrite {
  /**
   * The HyperFleet resource that triggered the desire, for example
   * `clusters/cls-123`.
   */
  resource_id: string;

  /**
   * Omitted or 0 creates the desire. A non-zero value updates an ApplyDesire
   * at that version. ReadDesire and DeleteDesire have no update, so a
   * non-zero value on either returns 400.
   */
  @minValue(0)
  version?: int64;

  /** The rendered Kubernetes manifest. Required for an ApplyDesire. */
  kubeContent?: Record<unknown>;

  /**
   * The Kubernetes API version to read the object as, for example `v1`.
   * Required for a ReadDesire.
   */
  target_version?: string;
}

/** The body of a Write status request. */
model StatusWrite {
  /**
   * The status object. For a ReadDesire, `status.kubeContent` holds the
   * mirrored live object.
   */
  status: Record<unknown>;

  /**
   * The `version` that the Applier read with the desire. Required for an
   * ApplyDesire or DeleteDesire, and a missing value returns 400. A ReadDesire
   * status write carries no `version`.
   */
  @minValue(1)
  version?: int64;
}
