defmodule UUIDMicroTest do
  use ExUnit.Case, async: true

  @fixture_uuid "5c692577-ad0c-51f1-992c-759b5e5fffb5"
  @fixture_token "𓳔𔐮𔘟𔄵"

  test "encodes golden fixture" do
    assert UUIDMicro.token_size() == 5744
    assert UUIDMicro.encode!(@fixture_uuid) == @fixture_token

    assert UUIDMicro.codepoints!(@fixture_uuid) == [
             "U+13CD4",
             "U+1442E",
             "U+1461F",
             "U+14135"
           ]

    assert UUIDMicro.encode(@fixture_uuid) == {:ok, @fixture_token}
  end

  test "validates tokens" do
    assert UUIDMicro.token?(@fixture_token)
    refute UUIDMicro.token?("ABCD")
    refute UUIDMicro.token?("𓳔𔐮𔘟")
  end
end
