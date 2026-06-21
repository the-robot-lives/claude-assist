# ---------------------------------------------------------------------------
# Cloudflare "terraform" admin API token (account-owned).
#
# Broad bootstrap token that drives all Cloudflare Terraform activity during the
# setup phase. IMPORTED from the existing token — do NOT recreate (recreating
# would mint a new secret and break every stack using TF_VAR_noizu_cloudflare_api_token).
# The permission_groups below are Cloudflare's own export of this token; keep them
# byte-for-byte so `tofu plan` shows ZERO diff after import. Scope down / add an
# expiry (see `expires_on`) once setup is complete.
#
# Import (needs the token id — from the dashboard URL or `GET .../tokens`):
#   terragrunt import 'cloudflare_account_token.noizu_terraform_admin' \
#     'a75e745949fc104ea4c4107a17158f15/<TOKEN_ID>'
# Then `terragrunt plan` MUST be 0 to change before any apply.
# ---------------------------------------------------------------------------

locals {
  account_id = "a75e745949fc104ea4c4107a17158f15"

  # Policy 1 — account-scoped permission groups (resources: account "*").
  account_permission_group_ids = [
    "1d9f8b86d5d84ce497fc64a620be96e5", "839a02e413024d06a4e7d8c56d4470d7",
    "76ade66d66184468b2ae2c037e995ac4", "5286f5b44cba457fa75b22f94716b8dd",
    "2f912625599b434a8df3e4e02d64c7b4", "7e252e992042421c8f2cdef3ada208c9",
    "136d0be1ddc64eaf8516fa6994abfad4", "f9e1ba803b8d4d52b4d4184825b07a28",
    "5b1d209212064a84aae4fb68e3908333", "e9f973896a184b1ca9d6a85a44efe55b",
    "ba9adcdbea5940dd84aa692e77e8eaf6", "b714141b1e1941cebb38c017036262a6",
    "521a41dc78f94eaba5e643528846cb7b", "ecbbebe25a014fa793d5226d6218303c",
    "0224cdb141684f0f9760ed0be83b6766", "d376dac8822b439a991b795c87789e6f",
    "d320e35958c845c89e69098a4ea38f64", "e9e3e5ccdebf43dbb1c9576fe74dfaab",
    "aed5acd922ae4fa68560cf0094e3e517", "e7e40392e132414fb68890c3328bdc6a",
    "5541aee5804a4850aa6d77351cc4a610", "f2f1e4d555854b8593912806eb459691",
    "ad7a6f88896d498f98eb30592abfbbf4", "384a77ea7c2e47d898715dc6a064f3f4",
    "cfa2e2893226455c9b945914969dff7c", "5df633d6b41c42bcaf5b4a62b9d14b64",
    "b9ed086b20864ad89c5aac24cdd02365", "db3d398df73946acb755c05b69edfc30",
    "77efc2c0724d4c4eb94bfd9656247130", "f45430d92e2b4a6cb9f94f2594c141b8",
    "cb142f7fbc3540f0bade0cbe75f606dc", "ba6ce7d23a9544ccad0816691ba38e21",
    "d79c5e2a405b4516a322432287d40c31", "e84fd345697c4036a14e7810da036e1a",
    "bdbcd690c763475a985e8641dddc09f7", "82c075da3f4647a2a03becd0fe240f8a",
    "29c629fb7b5e4c408ca0f7b545724fcc", "d229766a2f7f4d299f20eaa8c9b1fde9",
    "e985ca9351db460faebbe8681c48e560", "cc00ebddebca4b8399607562a78df084",
    "adc8fa2bc6124928a8b3314dc63a1235", "6d23f290472f4e6fad5c4398c057c356",
    "3e4e20ee40b9475dae22201c468fdb70", "a1a7389ba7e441dba95852e10970fcc3",
    "7fb8d27511b34d02994d005b520b679f", "120f843a9c074f399b830e542e5616b8",
    "adddda876faa4a0590f1b23a038976e4", "5b7aedd821a548b9bf5a2acabbce98c7",
    "dfe525ec7b07472c827d8d009178b2ac", "419ec42810af4659ade77716dbe47bc6",
    "9bf884ba0de445dab37ea4a3e1a2c9f1", "dc44f27f48ab405392a5f69fe822bd01",
    "2e095cf436e2455fa62c9a9c2e18c478", "e34111af393449539859485aa5ddd5bd",
    "677767156f294485b497a8f103172e7d", "f5d857f67f144e3c8bacea88c17d4a13",
    "a3567c13e074447fb101babac3463566", "6c8a3737f07f46369c1ea1f22138daaf",
    "0caa90c9b186447397c8b00358d34a76", "bacc64e0f6c34fc0883a1223f938a104",
    "366f57075ffc42689627bcf8242a1b6d", "b711942448db4b0aace44d1312f9fdb0",
    "6ffe7f4299db4d4cb54f64e0eb12a456", "64156ba5be47441096c83c7fc17c488b",
    "e2980d9241cf4939bbbd74fdc43b9651", "a7030c9c98d544e092d8b099fabb1f06",
    "5b5c774a5d174ca88d046c8889648b3f", "037b9e348b3b42d4b46ea2fcb1cfb3e7",
    "721b2f51fba74871bd361de65aeb7e03", "bc783549a3a741aaa10556faf8b485bb",
    "26ce6c7d18a346528e7b905d5e269866", "2a400bcb29154daab509fe07e3facab0",
    "d30c9ad8b5224e7cb8d41bcb4757effc", "4e5fd8ac327b4a358e48c66fcbeb856d",
    "7c81856725af47ce89a790d5fb36f362", "a1a6298e52584c8fb6313760a30c681e",
    "92c8dcd551cc42a6a57a54e8f8d3f3e3", "865ebd55bc6d4b109de6813eccfefd13",
    "050531528b044d58bbb71666fef7c07c", "db37e5f1cb1a4e1aabaef8deaea43575",
    "f3604047d46144d2a3e9cf4ac99d7f16", "18555e39c5ba40d284dde87eda845a90",
    "8a9d35a7c8504208ad5c3e8d58e6162d", "8e6ed1ef6e864ad0ae477ceffa5aa5eb",
    "4736c02a9f224c8196ae5b127beae78c", "c6f6338ceae545d0b90daaa1fed855e6",
    "09b2857d1c31407795e75e3fed8617a1", "910b6ecca1c5411bb894e787362d1312",
    "755c05aa014b4f9ab263aa80b8167bd8", "df1577df30ee46268f9470952d7b0cdf",
    "e4589eb09e63436686cd64252a3aebeb", "8d28297797f24fb8a0c332fe0866ec89",
    "abe78e2276664f4db588c1f675a77486", "8bd1dac84d3d43e7bfb43145f010a15c",
    "7a4c3574054a4d0ba7c692893ba8bdd4", "ae16e88bc7814753a1894c7ce187ab72",
    "235eac9bb64942b49cb805cc851cb000", "cde8c82463b6414ca06e46b9633f52a6",
    "4ea7d6421801452dbf07cef853a5ef39", "bf7481a1826f439697cb59a20b22293e",
    "0bc09a3cd4b54605990df4e307f138e1", "618ec6c64a3a42f8b08bdcb147ded4e4",
    "d44ed14bcc4340b194d3824d60edad3f", "56907406c3d548ed902070ec4df0e328",
    "92b8234e99f64e05bbbc59e1dc0f76b6", "05880cd1bdc24d8bae0be2136972816b",
    "b89a480218d04ceb98b4fe57ca29dc1f", "c07321b023e944ff818fec44d8203567",
    "29d3afbfd4054af9accdd1118815ed05", "2fc1072ee6b743828db668fcb3f9dee7",
    "a1c0fec57cf94af79479a6d827fa518c", "b05b28e839c54467a7d6cba5d3abb5a3",
    "6a315a56f18441e59ed03352369ae956", "61ddc58f1da14f95b33b41213360cbeb",
    "2edbf20661fd4661b0fe10e9e12f485c", "2ae23e4939d54074b7d252d27ce75a77",
    "b33f02c6f7284e05a6f20741c0bb0567", "bfe0d8686a584fa680f4c53b5eb0de6d",
    "f7f0eda5697f475c90846e879bab8666", "e086da7e2179491d91ee5f35b3ca210a",
    "d2a1802cc9a34e30852f8b33869b2f3c", "a416acf9ef5a4af19fb11ed3b96b1fe6",
    "da6d2d6f2ec8442eaadda60d13f42bca", "714f9c13a5684c2885a793f5edb36f59",
    "1e13c5124ca64b72b1969a67e8829049",
  ]

  # Policy 2 — zone-scoped permission groups (resources: account → zone "*").
  zone_permission_group_ids = [
    "f6a7a748dad644ba9792d3f1d0204cc2", "86cdbc42964b47fcbe848cd250ef2464",
    "c4df38be41c247b3b4b7702e76eadae0", "685f9605fd4e44ec937b6a0db658e629",
    "4bd3fb513a23494aa1341a7e1eb6e080", "945315185a8f40518bf3e9e6d0bee126",
    "2002629aaff0454085bf5a201ed70a72", "dadeaf3abdf14126a77a35e0c92fc36e",
    "87065285ab38463481e72815eefd18c3", "9110d9dd749e464fb9f3961a2064efc5",
    "c244ec076974430a88bda1cdd992d0d9", "06f0526e6e464647bd61b63c54935235",
    "74e1036f577a48528b78d2413b40538d", "f0235726de25444a84f704b7c93afadf",
    "9ff81cbbe65c400b97d92c3c1033cab6", "a9dba34cf5814d4ab2007b4ada0045bd",
    "79b3ec0d10ce4148a8f8bdc0cc5f97f2", "a4308c6855c84eb2873e01b6cc85cbb3",
    "0fd9d56bc2da43ad8ea22d610dd8cab1", "5ea6da42edb34811a78d1b007557c0ca",
    "0ac90a90249747bca6b047d97f0803e9", "b88a3aa889474524bccea5cf18f122bf",
    "3b94c49258ec4573b06d51d99b6416c0", "fb6778dc191143babbfaa57993f1d275",
    "e0dc25a0fbdf4286b1ea100e3256b0e3", "24fc124dc8254e0db468e60bf410c800",
    "959972745952452f8be2452be8cbb9f2", "3030687196b94b638145a3953da2b699",
    "c8fed203ed3043cba015a93ad1616f1f", "c03055bc037c4ea9afb9a9f104b7b721",
    "c4a30cd58c5d42619c86a3c36c441e2d", "e17beae8b8cb423a99b1730f21238bed",
    "ed07f6c337da4195b4e72a1fb2c6bcae", "6d7f2f5f5b1d4a0e9081fdc98d432fd1",
    "43137f8d07884d3198dc0ee77ca6e79b", "4755a26eedb94da69e1066d98aa820be",
    "9c88f9c5bce24ce7af9a958ba9c504db",
  ]
}

resource "cloudflare_account_token" "noizu_terraform_admin" {
  account_id = local.account_id
  name       = "terraform"

  policies = [
    {
      effect            = "allow"
      permission_groups = [for id in local.account_permission_group_ids : { id = id }]
      resources = jsonencode({
        "com.cloudflare.api.account.${local.account_id}" = "*"
      })
    },
    {
      effect            = "allow"
      permission_groups = [for id in local.zone_permission_group_ids : { id = id }]
      resources = jsonencode({
        "com.cloudflare.api.account.${local.account_id}" = {
          "com.cloudflare.api.account.zone.*" = "*"
        }
      })
    },
  ]
}
