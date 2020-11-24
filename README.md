# PostgresqlUri

Simple Elixir module to parse PostgreSQL connection URIs of the form:

```
postgresql://[user[:password]@][netloc][:port][,...][/dbname][?param1=value1&...]
```

returning a keyword list ready for use with `Postgrex.start_link/1`, making connecting to
a database as simple as:

```elixir
Postgrex.start_link(
  PostgresqlUri.parse(
    "postgresql://user:pass@host/somedatabase"
  )
)
```

For more information and examples, refer to the [module documentation on hexdocs.pm](https://hexdocs.pm/postgresql_uri/PostgresqlUri.html).

The URI format largely follows the [PostgreSQL URI description](https://www.postgresql.org/docs/13/libpq-connect.html#id-1.7.3.8.3.6), with
parameter keyword interpretation mostly following the [PostgreSQL libpq parameter keywords listing](https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-PARAMKEYWORDS).

Using this module to handle a single connection URI variable instead of separate host, port, username, databasename, password, ... variables makes runtime configuration a quite a bit tidier, especially if one needs to read these in (with `runtime.exs`) from separately set environment variables, in turn separately set in a systemd environment file, in turn templated out through some configuration management system.
As a bonus, for quotidian configurations, these URIs can be used verbatim with `psql` to quickly test a DB connection.


## Versioning

While it is unlikely that for mundane parameters interpretation will radically change from version to version, be aware that non-point releases might change parsing outcomes from version to version. Hard-pin this package if it currently parses your URIs to satisfaction,
and sleep better for it.

## Installation

The package can be installed by adding `postgresql_uri` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:postgresql_uri, "~> 0.1.0"}
  ]
end
```
