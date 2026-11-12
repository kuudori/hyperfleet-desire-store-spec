import "@typespec/http";
import "@typespec/openapi";

import "../models/desire.tsp";
import "../models/problem.tsp";

using Http;
using OpenAPI;

namespace HyperFleet.DesireStore;

/** The desire list page. */
model DesireListResponse {
  @statusCode statusCode: 200;
  @body body: DesireList;
}

/** The desire. */
model DesireOkResponse {
  @statusCode statusCode: 200;
  @body body: Desire;
}

/** The desire was created. */
model DesireCreatedResponse {
  @statusCode statusCode: 201;
  @body body: Desire;
}

/** Path parameters shared by every operation. */
model PartitionPath {
  /**
   * The partition that the request targets, which is the `managementCluster`
   * of the desire identity. A partition needs no setup: the first write to it
   * creates it.
   *
   * - A remote Applier's path partition must equal the partition in its
   *   binding. A mismatch returns 403.
   * - The Adapter and the sweeper may target any partition per request.
   */
  @path
  partition: string;
}

/** The desire identifier path parameter. */
model DesireIdPath {
  /** The desire identifier. See `DesireId` for the encoding. */
  @path("desire-id")
  desireId: DesireId;
}

@tag("Desires")
@useAuth(BearerAuth)
@route("/partitions/{partition}/desires")
interface Desires {
  /**
   * Lists the references of the desires in a partition, one page at a time.
   * Get serves the full record of each desire.
   *
   * Pages use an opaque keyset cursor and carry no total count. A multi-page
   * read is not a consistent snapshot: a desire that changes during the read
   * can show up only on the next list. A client must not treat an incomplete
   * or failed list as an empty partition.
   */
  @summary("List desires")
  @operationId("listDesires")
  @get
  listDesires(
    ...PartitionPath,

    /** Return only desires of this type. Omitted returns all types. */
    @query type?: DesireType,

    /** The `next_cursor` of the previous page. Omitted returns the first page. */
    @query cursor?: string,

    /**
     * The maximum number of references on the page. A value above the maximum
     * returns 400 and is not clamped.
     */
    @query
    @minValue(1)
    @maxValue(1000)
    limit?: int32 = 100,
  ): DesireListResponse | BadRequestResponse | UnauthorizedResponse | ForbiddenResponse | TooManyRequestsResponse | InternalServerErrorResponse | ServiceUnavailableResponse;

  /**
   * Gets one desire with its full record.
   */
  @summary("Get a desire")
  @opExample(
    #{
      returnType: #{
        statusCode: 200,
        body: #{
          id: "apply:apps:deployments:kube-system:coredns",
          type: DesireType.apply,
          group: "apps",
          resource: "deployments",
          `namespace`: "kube-system",
          name: "coredns",
          owner: "system:serviceaccount:hyperfleet:cluster-adapter-hyperfleet-adapter",
          resource_id: "clusters/cls-123",
          kubeContent: #{ apiVersion: "apps/v1", kind: "Deployment", metadata: #{ name: "coredns", `namespace`: "kube-system" } },
          generation: 2,
          version: 3,
        },
      },
    },
    #{ title: "ApplyDesire" },
  )
  @opExample(
    #{
      returnType: #{
        statusCode: 200,
        body: #{
          id: "read:apps:deployments:kube-system:coredns",
          type: DesireType.read,
          group: "apps",
          resource: "deployments",
          `namespace`: "kube-system",
          name: "coredns",
          owner: "system:serviceaccount:hyperfleet:cluster-adapter-hyperfleet-adapter",
          resource_id: "clusters/cls-123",
          target_version: "v1",
          status: #{ kubeContent: #{ apiVersion: "apps/v1", kind: "Deployment", metadata: #{ name: "coredns", `namespace`: "kube-system" } } },
          generation: 1,
          version: 1,
        },
      },
    },
    #{ title: "ReadDesire" },
  )
  @operationId("getDesire")
  @get
  @route("/{desire-id}")
  getDesire(...PartitionPath, ...DesireIdPath): DesireOkResponse | BadRequestResponse | UnauthorizedResponse | ForbiddenResponse | NotFoundResponse | TooManyRequestsResponse | InternalServerErrorResponse | ServiceUnavailableResponse;

  /**
   * Creates or updates a desire. The path is the only source of its identity.
   *
   * **Create and update.** A create returns 201, or 409 `HYPERFLEET-CNF-001`
   * when the caller already has the desire. An ApplyDesire update succeeds
   * only at the stored version: it increases the version and returns 200. A
   * stale version returns 409 `HYPERFLEET-CNF-002`, and an update of an absent
   * ApplyDesire returns 404. ReadDesire and DeleteDesire have no update. See
   * `DesireWrite.version`.
   *
   * **Owner.** All desires for one Kubernetes object in one partition have the
   * same `owner`: the caller that created the first of them. While one of them
   * exists, a create, write, or delete by a different caller returns 409
   * `HYPERFLEET-CNF-004`. Only the sweeper is exempt from this check.
   *
   * **Delete supersedes apply.** Creating a DeleteDesire atomically removes
   * the ApplyDesire for the same object at any version and returns 201. An
   * in-flight update or status write to that ApplyDesire then returns 404. The
   * ReadDesire for the object does not change. A second DeleteDesire create
   * returns 409 `HYPERFLEET-CNF-001`. An ApplyDesire create returns 409
   * `HYPERFLEET-CNF-003` until the Applier confirms the delete, and then
   * replaces the DeleteDesire.
   *
   * **Timed-out writes.** The client reads the desire. When it already shows
   * the change, the write succeeded. Otherwise the client re-evaluates and
   * retries.
   */
  @summary("Create or update a desire")
  @operationId("writeDesire")
  @put
  @route("/{desire-id}")
  writeDesire(
    ...PartitionPath,
    ...DesireIdPath,
    @body body: DesireWrite,
  ): DesireCreatedResponse | DesireOkResponse | BadRequestResponse | UnauthorizedResponse | ForbiddenResponse | NotFoundResponse | ConflictResponse | UnprocessableEntityResponse | TooManyRequestsResponse | InternalServerErrorResponse | ServiceUnavailableResponse;

  /**
   * Writes the status of a desire and returns 204. It does not check the
   * `owner`, because the Applier writes status on desires that adapters own.
   *
   * **ApplyDesire and DeleteDesire.** The write succeeds only at the stored
   * version, and it increments the version. A stale version returns 409
   * `HYPERFLEET-CNF-002`. A spec update and a status write share the version,
   * so a status computed for an older spec returns `HYPERFLEET-CNF-002`, and
   * so does an Adapter update that loses a race with a status write.
   * A retry of a status write that already succeeded also returns
   * `HYPERFLEET-CNF-002`. Versions restart at 1 when a desire is created
   * again, so a stale status write can match the new record.
   *
   * **ReadDesire.** The write has no version check and does not change the
   * version. A late write can overwrite a newer status.
   *
   * A status write to an ApplyDesire that a DeleteDesire superseded returns
   * 404.
   */
  @summary("Write the status of a desire")
  @operationId("writeDesireStatus")
  @put
  @route("/{desire-id}/status")
  writeDesireStatus(
    ...PartitionPath,
    ...DesireIdPath,
    @body body: StatusWrite,
  ): NoContentResponse | BadRequestResponse | UnauthorizedResponse | ForbiddenResponse | NotFoundResponse | ConflictResponse | TooManyRequestsResponse | InternalServerErrorResponse | ServiceUnavailableResponse;

  /**
   * Deletes a desire at its current version and returns 204. A stale version
   * returns 409 `HYPERFLEET-CNF-002`, a desire that a different caller owns
   * returns 409 `HYPERFLEET-CNF-004`, and an absent desire returns 404. Only
   * the sweeper is exempt from the owner check. To remove an applied object,
   * the Adapter creates a DeleteDesire instead.
   *
   * **Timed-out delete recovery.** The client reads the desire:
   *
   * - Absent: the delete succeeded.
   * - Present at the same version: the client retries the delete.
   * - Present at a different version: the desire changed or was created
   *   again. The client does not retry and re-evaluates instead.
   *
   * An Adapter can also retry the delete directly. A 404 then means success.
   *
   * Versions restart at 1 when a desire is created again, so a retried delete
   * can remove a new record at the same version. The sweeper retries only
   * when the stored `owner` is still its own identity.
   */
  @summary("Delete a desire")
  @operationId("deleteDesire")
  @delete
  @route("/{desire-id}")
  deleteDesire(
    ...PartitionPath,
    ...DesireIdPath,

    /** The current version of the desire. */
    @query
    @minValue(1)
    version: int64,
  ): NoContentResponse | BadRequestResponse | UnauthorizedResponse | ForbiddenResponse | NotFoundResponse | ConflictResponse | TooManyRequestsResponse | InternalServerErrorResponse | ServiceUnavailableResponse;
}
