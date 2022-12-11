defmodule ServerWebTest do
  use ExUnit.Case
  doctest ServerWeb

  test "greets the world" do
    assert ServerWeb.hello() == :world
  end
end
