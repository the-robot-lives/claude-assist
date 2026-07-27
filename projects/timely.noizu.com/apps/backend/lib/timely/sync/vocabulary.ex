defmodule Timely.Sync.Vocabulary do
  @moduledoc """
  The closed string vocabularies shared by the schemas, the mutation engine and
  the wire contract.

  Every list here is mirrored by a `CHECK` constraint in `db/changelog/026`
  through `030` and by an `enum` in
  `apps/shared/contracts/timely-api.yaml`. They are spelled out once so a
  changeset and a controller cannot drift apart, and so a contract change fails
  loudly in one place.
  """

  @review_states ~w(unreviewed needs_review reviewed approved locked disputed)
  @span_sources ~w(manual timer pomodoro)
  @upload_states ~w(local_only eligible pending uploaded refused purge_pending purged)
  @privacy_categories ~w(none secret private_email personal_chat adult_material
                         financial identity medical other_private)
  @device_platforms ~w(macos ios android web)
  @settings_kinds ~w(user_settings workspace_policy)

  @entity_kinds ~w(client project ticket time_span screenshot vision_analysis
                   censored_screenshot device user_settings workspace_policy)

  @ops ~w(create update delete)

  @mutation_statuses ~w(applied conflict rejected)

  @mutation_reasons ~w(stale_write duplicate_name tombstoned span_reopen_forbidden
                       immutable_entity not_device_owner unknown_entity
                       validation_failed workspace_mismatch clock_skew_rejected
                       locked_day permission_denied batch_rolled_back)

  @review_codes ~w(suspected_duplicate billing_overlap unresolved_idle_gap
                   low_confidence unresolved_reference auto_created_entity
                   privacy_censored reopened_after_approval)

  @review_resolutions ~w(pending accepted dismissed merged)

  # The nine `ChangeSet` buckets, in the order the contract lists them. Every
  # bucket is present in a response even when empty so clients iterate a fixed
  # key set.
  @buckets ~w(clients projects tickets time_spans screenshots vision_analyses
              censored_screenshots devices settings)

  # ⟦𓂋𓋴𓏏𓋴⟧ review_states :: Closed vocabulary for `review_state`.
  def review_states, do: @review_states

  # ⟦𓋴𓊪𓋴𓂋⟧ span_sources :: Closed vocabulary for `time_span.source`.
  def span_sources, do: @span_sources

  # ⟦𓅱𓊪𓋴𓏏⟧ upload_states :: Closed vocabulary for `screenshot.upload_state`.
  def upload_states, do: @upload_states

  # ⟦𓊪𓂋𓎡𓆓⟧ privacy_categories :: Closed vocabulary for `privacy_category`.
  def privacy_categories, do: @privacy_categories

  # ⟦𓂧𓋴𓊪𓅓⟧ device_platforms :: Closed vocabulary for `device.platform`.
  def device_platforms, do: @device_platforms

  # ⟦𓋴𓏏𓎼𓋴⟧ settings_kinds :: Closed vocabulary for `settings.kind`.
  def settings_kinds, do: @settings_kinds

  # ⟦𓅓𓎡𓈖𓂧⟧ entity_kinds :: The ten `EntityKind` values.
  def entity_kinds, do: @entity_kinds

  # ⟦𓅱𓊪𓋴𓆓⟧ ops :: The three mutation operations.
  def ops, do: @ops

  # ⟦𓅓𓋴𓏏𓋴⟧ mutation_statuses :: The three terminal mutation statuses.
  def mutation_statuses, do: @mutation_statuses

  # ⟦𓅓𓂋𓋴𓈖⟧ mutation_reasons :: Closed vocabulary for `MutationResult.reason`.
  def mutation_reasons, do: @mutation_reasons

  # ⟦𓂋𓆓𓎡𓋴⟧ review_codes :: Closed vocabulary for `ReviewReason.code`.
  def review_codes, do: @review_codes

  # ⟦𓂋𓋴𓅱𓈖⟧ review_resolutions :: Closed vocabulary for `ReviewReason.resolution`.
  def review_resolutions, do: @review_resolutions

  # ⟦𓃀𓎡𓏏𓋴⟧ buckets :: The nine `ChangeSet` bucket names.
  def buckets, do: @buckets
end
