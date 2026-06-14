# =============================================================================
# Import existing Cloudflare Zero Trust resources
# =============================================================================
# Generated from CF API: all access groups, apps, and policies.
# Account: a75e745949fc104ea4c4107a17158f15
# =============================================================================


# ── Access Groups ────────────────────────────────────────────────────────────
import {
  to = cloudflare_zero_trust_access_group.admins
  id = "accounts/a75e745949fc104ea4c4107a17158f15/692347b0-4cb7-444c-aae5-d8065874bc36"
}
import {
  to = cloudflare_zero_trust_access_group.developers
  id = "accounts/a75e745949fc104ea4c4107a17158f15/90e96889-7d65-4cfa-9729-6d5c3597f17f"
}
import {
  to = cloudflare_zero_trust_access_group.friends
  id = "accounts/a75e745949fc104ea4c4107a17158f15/dc8630cd-844c-49a8-8bc6-912de5a731eb"
}
import {
  to = cloudflare_zero_trust_access_group.clients
  id = "accounts/a75e745949fc104ea4c4107a17158f15/9077cbe6-c983-40a4-8df7-87ce9953a370"
}
import {
  to = cloudflare_zero_trust_access_group.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a1fca291-d777-4685-8d20-40b73441c1cd"
}
import {
  to = cloudflare_zero_trust_access_group.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/9e9f5f22-a0e1-44fe-bca1-3f0085b8de76"
}


# ── Explicit apps: argocd ────────────────────────────────────────────────────
import {
  to = module.argocd.cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/af52a43d-6c1c-4289-a3f9-ec3a029e2fcc"
}
import {
  to = module.argocd.cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/fef9cf4f-24dd-44f7-a79b-01daadd24eae"
}
import {
  to = module.argocd.cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/f5860061-34dd-4393-bb7f-6e93ad931dee"
}
import {
  to = module.argocd.cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a5021c3f-8c0b-4e90-bea5-abe6ddb3d923"
}

# ── Explicit apps: livebook ──────────────────────────────────────────────────
import {
  to = module.livebook.cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/fd96fe6e-1065-4963-9119-843723dc453d"
}
import {
  to = module.livebook.cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/d54c744d-e9fd-4304-a6cd-10498f9ba8bb"
}
import {
  to = module.livebook.cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/31c3999c-07cf-4437-91fc-5b4722f45e51"
}
import {
  to = module.livebook.cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/f984586b-b3fd-4063-8875-97120a4e85dd"
}

# ── Explicit apps: livebook_public (standalone resource + bypass policy) ─────
import {
  to = cloudflare_zero_trust_access_application.livebook_public
  id = "accounts/a75e745949fc104ea4c4107a17158f15/b8c1d713-03a5-47e8-961d-2aebd4f0f9ff"
}
import {
  to = cloudflare_zero_trust_access_policy.livebook_public_bypass
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2cb14142-8f43-4789-842a-bfe97e057467"
}

# ── Explicit apps: apm ───────────────────────────────────────────────────────
import {
  to = module.apm.cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/14ef3852-1353-4981-a3e0-821669c93791"
}
import {
  to = module.apm.cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/3706dc65-62b5-4d9b-9b69-1f13d5c9a568"
}
import {
  to = module.apm.cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/4eff34d0-d66a-4666-b3d1-7d34b2d8158a"
}
import {
  to = module.apm.cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/bb7eb5d6-9cda-4649-8861-c478bc2cb9a7"
}

# ── Explicit apps: minio ─────────────────────────────────────────────────────
import {
  to = module.minio.cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/96b43a72-b8f7-443f-9529-17c3098b8817"
}
import {
  to = module.minio.cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/4ef3be5c-abed-4a09-b5e6-fc999793ec56"
}
import {
  to = module.minio.cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/c5200f6b-858e-4e38-b6a6-a147edc02662"
}
import {
  to = module.minio.cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/929bb547-92d4-48f2-a6f7-bcd2ea1c0b04"
}


# ── Bulk apps ────────────────────────────────────────────────────────────────

# appsmith
import {
  to = module.bulk["appsmith"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/64872517-69ba-4df8-a9c6-08921f87f382"
}
import {
  to = module.bulk["appsmith"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/e577790f-278c-4fef-ab98-223524e2bc97"
}
import {
  to = module.bulk["appsmith"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a600b858-bd02-4b8a-a180-1f43b1cd4c1f"
}
import {
  to = module.bulk["appsmith"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/8670007f-eba3-4c12-9b01-fb6c34c857c1"
}

# bottlecrm
import {
  to = module.bulk["bottlecrm"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/9326a17b-d027-4093-9716-133de42f7aca"
}
import {
  to = module.bulk["bottlecrm"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/dbd0ca33-4477-4e33-8d1f-77a680dda80b"
}
import {
  to = module.bulk["bottlecrm"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/dcf26df7-4314-443f-965a-8801da7cf977"
}
import {
  to = module.bulk["bottlecrm"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/5e20a243-ee4f-476f-afc3-989d18d899b2"
}

# chartdb
import {
  to = module.bulk["chartdb"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/128595e6-886f-4c76-b3cf-5fa019da54d5"
}
import {
  to = module.bulk["chartdb"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/1a1cd44b-f943-421f-a36f-f7765e5d1183"
}
import {
  to = module.bulk["chartdb"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/96f4678f-b609-4070-af95-79f435a54096"
}
import {
  to = module.bulk["chartdb"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/309072d1-31d7-40e2-905b-a52f915b3c38"
}

# chatterbox_tts
import {
  to = module.bulk["chatterbox_tts"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a91ab74c-8bfd-438c-be5a-01fd478f5d95"
}
import {
  to = module.bulk["chatterbox_tts"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/15ce09e8-e7a4-4c4f-ae81-06e465558db0"
}
import {
  to = module.bulk["chatterbox_tts"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/e9a6224e-49ad-4339-a175-ac81479c20bf"
}
import {
  to = module.bulk["chatterbox_tts"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/0e641e50-9549-41db-8c39-771c9ebce657"
}

# cockpit
import {
  to = module.bulk["cockpit"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2a33e7da-df07-4b0e-a698-5fa96c67dfaf"
}
import {
  to = module.bulk["cockpit"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ad84804d-7099-440a-a53e-f81807cac7c7"
}
import {
  to = module.bulk["cockpit"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/cc178d6e-325b-4036-80f7-9b332450e4bf"
}
import {
  to = module.bulk["cockpit"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/5e3669c9-b15f-4274-9d42-a1031b941ab5"
}

# code
import {
  to = module.bulk["code"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/27e0dc5e-ba52-460d-a441-502db6aadb00"
}
import {
  to = module.bulk["code"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/27099a24-2314-41b7-9a4f-73a678d805bc"
}
import {
  to = module.bulk["code"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/5e16bcd6-93f3-4090-afbd-1e5bb2189c1c"
}
import {
  to = module.bulk["code"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/99949938-ee8e-4956-a253-d16a43142566"
}

# drawio
import {
  to = module.bulk["drawio"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/c53b3db7-3bae-42b2-9ed6-d258688f6239"
}
import {
  to = module.bulk["drawio"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/b3fb7b2f-a774-4aeb-8457-42cb9f9cb868"
}
import {
  to = module.bulk["drawio"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/8b30fe43-2d3d-4d8f-a215-6acb7100ecdc"
}
import {
  to = module.bulk["drawio"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/4d8d8c46-487d-4bda-b6d8-9acc034d8756"
}

# echelon
import {
  to = module.bulk["echelon"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/0db4d6b2-fb31-4f37-be7d-899b1649e1b4"
}
import {
  to = module.bulk["echelon"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2ac4f94d-b8ef-4c8b-a635-455d364c4907"
}
import {
  to = module.bulk["echelon"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/7a8eca01-9fa1-44e8-8b4e-eff8052db0a8"
}
import {
  to = module.bulk["echelon"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/f595b181-4497-4af6-a2d3-7d818d9ae6db"
}

# espocrm
import {
  to = module.bulk["espocrm"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/b823ad8c-f99b-43d1-a7b6-67529c4a28cd"
}
import {
  to = module.bulk["espocrm"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/b27c00d3-fe48-418c-b4c0-8be1340dca11"
}
import {
  to = module.bulk["espocrm"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/74cf01b0-3039-438e-85b4-86341ce59a2c"
}
import {
  to = module.bulk["espocrm"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/17d136c5-4937-4e8d-a018-99ee8b319215"
}

# eval
import {
  to = module.bulk["eval"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/bbd92042-c45a-44e3-8970-2dd8f528b7aa"
}
import {
  to = module.bulk["eval"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/4e79c2f4-c836-4dc4-8774-9a9b472889cd"
}
import {
  to = module.bulk["eval"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/fdbabc66-d540-458b-8997-d7b66e7392c0"
}
import {
  to = module.bulk["eval"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/002ceeba-dda1-4c04-9511-8b155d497f51"
}

# excalidraw
import {
  to = module.bulk["excalidraw"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/811551b4-2553-48d9-8f60-a07d6f729ac8"
}
import {
  to = module.bulk["excalidraw"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/53e1cd52-bd48-4f0b-9154-659d76e4aea9"
}
import {
  to = module.bulk["excalidraw"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/74342dd1-bdb9-4f1e-b2bc-fbef9f97cd73"
}
import {
  to = module.bulk["excalidraw"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/54839342-30a7-4006-a743-ccb57e30c59a"
}

# ghost
import {
  to = module.bulk["ghost"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/cacaa230-724d-467a-86a0-8dd7afa953e7"
}
import {
  to = module.bulk["ghost"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/1bff9bfd-9037-4a93-8811-9fd692909f2b"
}
import {
  to = module.bulk["ghost"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/331cda4c-3949-4a77-94c7-91195177dfde"
}
import {
  to = module.bulk["ghost"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/43bb679b-f0aa-4125-9018-a3706a2cfa5b"
}

# growthbook
import {
  to = module.bulk["growthbook"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/3b9d4f53-1db9-4fb7-aac0-67be8ff378ee"
}
import {
  to = module.bulk["growthbook"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/64f86b39-b5eb-4dd7-ac7a-d76657b96efe"
}
import {
  to = module.bulk["growthbook"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a2a03b3f-1c93-42f1-bb92-9866e988fb29"
}
import {
  to = module.bulk["growthbook"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/872f668d-eab1-4555-8750-a394caa82ebc"
}

# hakatime
import {
  to = module.bulk["hakatime"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/dde4444d-025e-4acc-adfa-d5c0c4983d1c"
}
import {
  to = module.bulk["hakatime"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a0912b60-335f-4312-8631-b046b07656f2"
}
import {
  to = module.bulk["hakatime"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ecc3467f-8004-4f7e-afdb-c43b0b44f57a"
}
import {
  to = module.bulk["hakatime"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/3aaa8ce9-c417-4b72-9532-99d0f54ff9fe"
}

# headlamp
import {
  to = module.bulk["headlamp"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/66e67b3a-dc46-46d9-bc89-59ec5ed0435c"
}
import {
  to = module.bulk["headlamp"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/4beee311-9e6f-41bf-b083-8e9c25d9e06f"
}
import {
  to = module.bulk["headlamp"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/c8bd97ba-f595-4a31-9bba-85d89daa512a"
}
import {
  to = module.bulk["headlamp"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/13c7f62d-2a9f-4cac-a79f-0bcf03444036"
}

# infisical
import {
  to = module.bulk["infisical"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/c4c1da4a-b41d-4ec8-a63b-e914b3796bdf"
}
import {
  to = module.bulk["infisical"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2134b167-4a65-4265-9833-3a9cf3affb00"
}
import {
  to = module.bulk["infisical"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/5a7441a4-da29-477a-9aa1-fdab8284dab7"
}
import {
  to = module.bulk["infisical"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/918f7cb4-a5e0-4028-85bc-23290cff10db"
}

# infra
import {
  to = module.bulk["infra"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/20aacb72-6c7b-4739-b510-bac559be1078"
}
import {
  to = module.bulk["infra"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2cbf738d-9347-41c2-8f8a-b81de03d0718"
}
import {
  to = module.bulk["infra"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/5aeaf7e6-456e-4dff-83d6-c12cf9091ba5"
}
import {
  to = module.bulk["infra"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/9552913e-192f-4228-8d01-c806d8e163a6"
}

# jupyter
import {
  to = module.bulk["jupyter"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/91092d92-c811-4a38-9e84-2ffa993918b9"
}
import {
  to = module.bulk["jupyter"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/6387eac5-2792-4d2d-97a1-41206713cdb3"
}
import {
  to = module.bulk["jupyter"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/16159e90-61ab-4963-afe0-f9fa0872e64d"
}
import {
  to = module.bulk["jupyter"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/3a0acd96-0ecf-4167-8bd0-780b8bc8a6a4"
}

# kitten_tts
import {
  to = module.bulk["kitten_tts"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/385d7c9a-294c-4ef1-9250-04d0021fd8d3"
}
import {
  to = module.bulk["kitten_tts"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ea92e653-a8ba-4bc3-81aa-6b511767b871"
}
import {
  to = module.bulk["kitten_tts"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/653bfb29-8c69-4cd3-b474-872677c8a7ab"
}
import {
  to = module.bulk["kitten_tts"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/013942e1-3eea-44f5-9846-3dd51785906c"
}

# kroki
import {
  to = module.bulk["kroki"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/bbf2f884-d77a-49cd-a798-c2a3ce08769a"
}
import {
  to = module.bulk["kroki"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ca2518a3-dd79-4ba3-a03d-9a56d05fe336"
}
import {
  to = module.bulk["kroki"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/50fc4f7d-06dc-4250-82bc-1936ff5fdb63"
}
import {
  to = module.bulk["kroki"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/d8a51356-3da7-4314-a8c7-e8f5226d8f69"
}

# labelstudio
import {
  to = module.bulk["labelstudio"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/9280a574-74e9-442f-a846-157535386d75"
}
import {
  to = module.bulk["labelstudio"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/f85d8b5f-6b87-464b-913f-d90b2f4b003e"
}
import {
  to = module.bulk["labelstudio"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/842d987c-bf58-4b2a-8c40-8855ab660297"
}
import {
  to = module.bulk["labelstudio"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/441178e5-bf82-45a6-b033-6f5ce41d0857"
}

# langfuse
import {
  to = module.bulk["langfuse"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/6ac1da32-9f74-4a8c-ba5e-94d865622051"
}
import {
  to = module.bulk["langfuse"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/71dd1608-ce5f-42b1-bff1-b0f971a6e6b0"
}
import {
  to = module.bulk["langfuse"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/55c87f51-619a-4ee6-8d3e-7beed958ceac"
}
import {
  to = module.bulk["langfuse"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/54fbab29-5b55-4615-b159-fcb26149fd16"
}

# litellm
import {
  to = module.bulk["litellm"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ba02bce0-88ec-4bc2-91d2-e40e548c66a3"
}
import {
  to = module.bulk["litellm"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/8953b46b-1eb8-444f-bdc1-29053a815615"
}
import {
  to = module.bulk["litellm"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/cc1727c5-582a-48de-bc50-dfe36712f0b2"
}
import {
  to = module.bulk["litellm"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/0eb2089e-a22a-4dcb-820c-bcfd11856592"
}

# livecodes
import {
  to = module.bulk["livecodes"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2f37d2d8-3cd9-4238-8237-666fe3c4a660"
}
import {
  to = module.bulk["livecodes"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/230849bc-9812-43b7-bf68-3163be510d70"
}
import {
  to = module.bulk["livecodes"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/650b417c-5f6c-46ac-902b-d7194a869736"
}
import {
  to = module.bulk["livecodes"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/12bc5447-1c76-4dd5-a884-b27a1b234382"
}

# matomo
import {
  to = module.bulk["matomo"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/0290896b-e2f2-466a-b7d9-3dba5e3a0a3d"
}
import {
  to = module.bulk["matomo"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/b5601e56-0dde-4ee4-b488-08a9ec0f89ac"
}
import {
  to = module.bulk["matomo"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/16a06e00-3268-498c-b6dd-1ae99ca6c6f9"
}
import {
  to = module.bulk["matomo"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a6c91cbd-9e90-4874-a1e9-2addd9a48be3"
}

# mautic
import {
  to = module.bulk["mautic"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/bd71729e-507b-4fed-b1c0-d28aae8c0a1f"
}
import {
  to = module.bulk["mautic"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/bc449b89-f5f5-4198-a5bc-733582441e31"
}
import {
  to = module.bulk["mautic"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/4250a4b6-df04-49f3-ba3b-800c1064461a"
}
import {
  to = module.bulk["mautic"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/acf6ad9c-2e50-4861-947a-6b9706801e1b"
}

# mermaid
import {
  to = module.bulk["mermaid"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/38d8df97-cae2-4e0a-a400-ed82b25d090a"
}
import {
  to = module.bulk["mermaid"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/22ce7488-ddcc-4810-9ca9-7287d6e79f19"
}
import {
  to = module.bulk["mermaid"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ff5449e6-c740-455c-b56e-6bb6b78cb618"
}
import {
  to = module.bulk["mermaid"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2a8cd4c1-72fb-4ca8-9be8-bb640d745638"
}

# metabase
import {
  to = module.bulk["metabase"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a711ba94-e9e5-4eb2-a108-c998354b56ae"
}
import {
  to = module.bulk["metabase"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ba3856c8-890c-4776-a3c6-3dc2ec33d60c"
}
import {
  to = module.bulk["metabase"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/bdb31dd9-6b2c-4428-bc34-2c1c1b5fa5ad"
}
import {
  to = module.bulk["metabase"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/14543e45-0aed-40e8-98aa-f4610a4108de"
}

# minio_console
import {
  to = module.bulk["minio_console"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a7c2df74-3af1-41c4-b508-7128b5fea581"
}
import {
  to = module.bulk["minio_console"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/8643eca0-4e2d-4153-b2f4-776e4d6e8ab5"
}
import {
  to = module.bulk["minio_console"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/f7e1406f-cda3-4e5e-976a-fe111fb8d91d"
}
import {
  to = module.bulk["minio_console"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/f060b1d0-f7ac-4bda-800f-6c9f2fd076f0"
}

# mydraft
import {
  to = module.bulk["mydraft"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/e5d046c1-d7ec-4c68-9285-408b5a223bee"
}
import {
  to = module.bulk["mydraft"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/54bdd1d1-c9b2-42ae-beea-3297acd5024a"
}
import {
  to = module.bulk["mydraft"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/53ab8683-b021-4f4e-bf5c-3f0f556004a1"
}
import {
  to = module.bulk["mydraft"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/188cc04c-68f9-4553-8bfa-bde6a6087660"
}

# n8n
import {
  to = module.bulk["n8n"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2bc73dc8-7f0e-444e-a5c7-b0a3f65b9f68"
}
import {
  to = module.bulk["n8n"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/7c09ea15-8679-4fb6-9595-51dde9fd0736"
}
import {
  to = module.bulk["n8n"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/cf0eb33a-c563-4907-bff8-2f3609bc4455"
}
import {
  to = module.bulk["n8n"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/c566cb00-fee5-4aa6-83dc-73b1e5e9e631"
}

# oneuptime
import {
  to = module.bulk["oneuptime"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2cd4284e-c19d-4ca1-a319-62470e56ff5e"
}
import {
  to = module.bulk["oneuptime"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/0075b4df-c626-41c4-87b3-5e4acc7ab710"
}
import {
  to = module.bulk["oneuptime"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/de5669ac-e4c0-4acf-a3a5-e35f1cfca0f4"
}
import {
  to = module.bulk["oneuptime"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/123a6a4e-10a4-4d8e-b4f0-fe37aede162f"
}

# penpot
import {
  to = module.bulk["penpot"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a7ad3f96-d958-40b5-8662-5fae3c3e08cf"
}
import {
  to = module.bulk["penpot"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/0b09f579-1a6e-4290-9a26-68a8e4d4f8cb"
}
import {
  to = module.bulk["penpot"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/8c64a5b9-153d-4d9b-a994-637b45ba5d99"
}
import {
  to = module.bulk["penpot"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/8c534d75-2398-44b2-9d06-09309fd15865"
}

# plane
import {
  to = module.bulk["plane"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/6a8f34ba-a78e-4618-85b4-050a866c1ebd"
}
import {
  to = module.bulk["plane"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/d9416551-848d-4a5a-8489-e9818e77433a"
}
import {
  to = module.bulk["plane"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/c06748f0-9481-49b9-b199-e14a842a7541"
}
import {
  to = module.bulk["plane"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/f327e06a-ca74-4b6a-87f7-7127058c1097"
}

# plantuml
import {
  to = module.bulk["plantuml"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/11658d0e-228a-4a1c-b308-a20abde22213"
}
import {
  to = module.bulk["plantuml"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/04239c2c-195c-4de6-8306-4ec48da8e0b4"
}
import {
  to = module.bulk["plantuml"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/49847d96-d035-40e9-bb34-93f8b3e83c15"
}
import {
  to = module.bulk["plantuml"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/788969ac-e3ae-4bb2-b814-572a33b34793"
}

# posthog
import {
  to = module.bulk["posthog"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/0ba968be-1698-4808-b2a6-634e26ed17cc"
}
import {
  to = module.bulk["posthog"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/186c5251-295f-4468-af15-d1553b8c9d03"
}
import {
  to = module.bulk["posthog"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/80867bde-e114-4ec5-9be7-3d1e53378656"
}
import {
  to = module.bulk["posthog"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/5fea564b-6dc2-42e7-94b6-87afc0a77100"
}

# postiz
import {
  to = module.bulk["postiz"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/099b87e1-4e00-4d67-9eb0-1a6ca736891e"
}
import {
  to = module.bulk["postiz"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/bf9893e1-a480-4dda-b4e0-782dfab46b01"
}
import {
  to = module.bulk["postiz"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/d2ac36f4-2ed1-4385-932b-a4d04c6b2cfa"
}
import {
  to = module.bulk["postiz"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/137372c5-469a-4de6-aa19-edb793d262ce"
}

# seonaut
import {
  to = module.bulk["seonaut"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/9c675333-b299-424c-a856-5687fa5a3179"
}
import {
  to = module.bulk["seonaut"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2eceafbb-ca58-493f-9b18-ddc136fd5354"
}
import {
  to = module.bulk["seonaut"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/77ff63fc-470d-4185-b736-102c86d88aaf"
}
import {
  to = module.bulk["seonaut"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/85bf4209-60aa-4e31-8738-499916d3a8f9"
}

# serpbear
import {
  to = module.bulk["serpbear"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/8dfec1d8-31ba-4b57-bff5-427d5eddb6dd"
}
import {
  to = module.bulk["serpbear"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/62afc21c-0cbc-49da-baf8-5b4d28a5ad88"
}
import {
  to = module.bulk["serpbear"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/5ce7d0fd-2da1-41db-9cf7-d5720f336c7d"
}
import {
  to = module.bulk["serpbear"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ecaf3cbf-77a2-4f18-8e4e-d0f3495e8b4e"
}

# taiga
import {
  to = module.bulk["taiga"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ce559c95-f654-459f-ad90-c097e82ab3c5"
}
import {
  to = module.bulk["taiga"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/69fb90af-fcab-4af1-8df4-f4ff555fe583"
}
import {
  to = module.bulk["taiga"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/53bf7d7a-8700-4048-8557-ec7de3e4ccde"
}
import {
  to = module.bulk["taiga"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/652768a2-baeb-4731-9687-bad5d44dacff"
}

# weaviate
import {
  to = module.bulk["weaviate"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/d3382af1-56be-43d3-a6e3-b418fa1ff459"
}
import {
  to = module.bulk["weaviate"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/b55b3f57-b59c-40f5-aa38-e602a63337d3"
}
import {
  to = module.bulk["weaviate"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/2d2a962d-e4dc-432d-ac1b-e7014107cc00"
}
import {
  to = module.bulk["weaviate"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/9242068a-76a9-4296-b8b7-0a3bc9eae8c7"
}

# webstudio
import {
  to = module.bulk["webstudio"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/a5329385-bf82-4ad3-aa75-cd8ea13a303a"
}
import {
  to = module.bulk["webstudio"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/cf5b2f88-646f-40e3-a3f7-6ed827eca9b4"
}
import {
  to = module.bulk["webstudio"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/c7f530de-caf5-4790-86b8-8d7510eb3501"
}
import {
  to = module.bulk["webstudio"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/6109708b-6c49-4829-9059-be4141be19fb"
}

# webui
import {
  to = module.bulk["webui"].cloudflare_zero_trust_access_application.this
  id = "accounts/a75e745949fc104ea4c4107a17158f15/ca0d7130-3c1c-4748-abd1-2ef16d520e52"
}
import {
  to = module.bulk["webui"].cloudflare_zero_trust_access_policy.team
  id = "accounts/a75e745949fc104ea4c4107a17158f15/9f984b7b-dfb1-4586-b027-21e56555a265"
}
import {
  to = module.bulk["webui"].cloudflare_zero_trust_access_policy.service_tokens
  id = "accounts/a75e745949fc104ea4c4107a17158f15/13a91eab-449b-4fc0-ad67-14bc5f778287"
}
import {
  to = module.bulk["webui"].cloudflare_zero_trust_access_policy.trusted_ips
  id = "accounts/a75e745949fc104ea4c4107a17158f15/e3d412a1-3072-4f97-aa7a-81238462f586"
}
