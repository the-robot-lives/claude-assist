import assert from "node:assert/strict";
import {
  emailDomain,
  matchingSsoProviders,
  postAuthPath,
  userNeedsProfile,
  userPendingApproval,
} from "./auth-flow";
import type { User } from "./api";

function user(overrides: Partial<User>): User {
  return {
    id: "user-1",
    email: "ada@example.com",
    profile_complete: true,
    requires_profile_completion: false,
    status: "active",
    ...overrides,
  };
}

assert.equal(emailDomain(" Ada@Example.COM "), "example.com");
assert.deepEqual(
  matchingSsoProviders("ada@sso.example.com", {
    "sso.example.com": ["oidc", "google"],
  }),
  ["oidc", "google"]
);
assert.deepEqual(matchingSsoProviders("ada@example.com", {}), []);

assert.equal(userNeedsProfile(user({ profile_complete: false })), true);
assert.equal(userNeedsProfile(user({ requires_profile_completion: true })), true);
assert.equal(userNeedsProfile(user({ profile_complete: true })), false);

assert.equal(userPendingApproval(user({ status: "pending" })), true);
assert.equal(userPendingApproval(user({ status: "waitlist" })), true);
assert.equal(userPendingApproval(user({ status: "active" })), false);

assert.equal(postAuthPath(user({ requires_profile_completion: true })), "/complete-registration");
assert.equal(postAuthPath(user({ status: "pending" })), "/pending-approval");
assert.equal(postAuthPath(user({ status: "active" })), "/app");

console.log("auth-flow tests passed");
