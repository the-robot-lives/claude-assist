# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Therobotplans.Repo.insert!(%Therobotplans.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

require SeedHelper
import SeedHelper
SeedHelper.begin_session()

dir = Path.dirname(__ENV__.file)
# In a release SEED_ENV is set by Therobotplans.Release.seed/1 (Mix is absent).
# Under `mix run` SEED_ENV is unset, so we fall back to Mix.env() (dev/test
# convenience). `||` is lazy: Mix.env() is never evaluated when SEED_ENV is set.
env = System.get_env("SEED_ENV") || to_string(Mix.env())
Code.eval_file("#{dir}/seeds/#{env}-seeds.exs")

# Will throw if any requires_seeds blocks were not resolved during execution.
:ok = end_session()
