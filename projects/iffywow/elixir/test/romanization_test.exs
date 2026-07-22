defmodule Ithkuil.RomanizationTest do
  @moduledoc """
  Romanization layer: exact round-trips for the supported subset, honest
  {:unsupported, _} errors for everything else (never guess).
  """
  use ExUnit.Case, async: true

  describe "supported formatives (Vv Cr Vr Ca Vc)" do
    test "round-trip: to_latin(from_latin(w)) == {:ok, w}" do
      for word <- ["alala", "akšalëi", "ürzoyu", "opţawä", "ärţüwö", "iňňiri"] do
        assert {:ok, coord} = Ithkuil.from_latin(word), "from_latin failed for #{word}"
        assert {:ok, ^word} = Ithkuil.to_latin(coord)

        # romanization-produced coordinates are canonical and integer-codable
        assert Ithkuil.Coord.validate(coord) == :ok
        assert {:ok, n} = Ithkuil.to_integer(coord)
        assert {:ok, ^coord} = Ithkuil.from_integer(n)
      end
    end

    test "parses onto the documented provisional mapping" do
      # a = stem1/PRC, l = root code 22, a = STA/BSC, l = M perspective, a = THM
      assert {:ok, coord} = Ithkuil.from_latin("alala")

      assert coord ==
               {:ithkuil_word, 1,
                [
                  {:glyph, 0, 22, 1,
                   [
                     {0, {:modifier, 0, 0, [], []}},
                     {1, {:modifier, 0, 0, [], []}},
                     {2, {:modifier, 0, 0, [], []}}
                   ]}
                ]}
    end

    test "input is trimmed, NFC-normalized and downcased" do
      assert {:ok, coord} = Ithkuil.from_latin("  Alala ")
      assert Ithkuil.to_latin(coord) == {:ok, "alala"}
    end

    test "latinized form flows into the scene model and SVG title" do
      assert {:ok, coord} = Ithkuil.from_latin("alala")
      assert {:ok, model} = Ithkuil.to_scene(coord)
      assert model.latinized == "alala"
      assert Ithkuil.SVG.render(model) =~ "<title>alala</title>"
    end
  end

  describe "unsupported forms are rejected, not guessed" do
    test "shape, character, stress and table misses" do
      # consonant-initial (would need Slot I Cc handling)
      assert {:error, {:unsupported, _}} = Ithkuil.from_latin("hjalala")
      # stress-marked vowel (Slot X)
      assert {:error, {:unsupported, _}} = Ithkuil.from_latin("álala")
      # unknown Vc vowel form
      assert {:error, {:unsupported, _}} = Ithkuil.from_latin("alalai")
      # characters outside the inventory
      assert {:error, {:unsupported, _}} = Ithkuil.from_latin("qalala")
      assert {:error, {:unsupported, _}} = Ithkuil.from_latin("")
      # affix-bearing shapes (more than five runs)
      assert {:error, {:unsupported, _}} = Ithkuil.from_latin("alalala")
    end

    test "to_latin rejects coordinates outside the provisional mapping" do
      assert {:error, {:unsupported, _}} = Ithkuil.to_latin({:ithkuil_word, 1, []})

      assert {:error, {:unsupported, _}} =
               Ithkuil.to_latin(["ithkuil-word", 1, [["glyph", 0, 17, 1, []]]])
    end
  end
end
