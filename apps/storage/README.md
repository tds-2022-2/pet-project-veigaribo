# Storage

Allows for persistent data storage. The started application is just a task and should spontaneously die.

Currently uses mnesia but that could change at any point.

Defines `users` (`username`, `password`), `sessions` (`id`, `username`, `password`) and `records` (`id`, `username`, `score`). 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `storage` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:storage, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/storage>.

