defmodule PostgresqlUri do
  @moduledoc """
  Parse PostgreSQL connection URIs of the form:

  `postgresql://[user[:password]@][netloc][:port][,...][/dbname][?param1=value1&...]`

  and returns a keyword list ready for use with `Postgrex.start_link/1`.

  The URI format largely follows the description at https://www.postgresql.org/docs/13/libpq-connect.html#id-1.7.3.8.3.6, with
  parameter keywords as listed at https://www.postgresql.org/docs/13/libpq-connect.html#LIBPQ-PARAMKEYWORDS .

  There is only partial correspondence between the PostgreSQL parameters and the Postgrex options.
  No validation is performed and unrecognized/unsupported URL parameter keywords are passed verbatim.
  This means that you may be able to stuff simple string parameters into the URL to pass them on to Postgrex, but URIs crafted this way
  may not be compatible with `libpq`.

  In particular, the following PostgreSQL URL phenomena are unhandled/untranslated:
  - Parameter keywords marked as deprectated in the PostgreSQL documentation.
  - Things related to the TCP connection beyond `connect_timeout` (read timeouts, keepalives, ...).
  - Failover (specifying multiple hosts).
  - Advanced SSL configuration (beyond simply turning it on or off)

  Related project: https://github.com/s-m-i-t-a/database_url — gives you an Ecto adapter rather than a keyword list.

  See the documentation of `parse/1`, the only exposed function, for more details and some examples.
  """

  @doc """
  Parse a PostgreSQL URI into a keyword list.

  ## Examples
  These examples should (with suitably chosen values) also work as an argument to the `psql` command-line client and make it
  attempt to do the same thing as Postgrex would.

  ### Quotidian case

      iex> PostgresqlUri.parse("postgresql://someuser:somepassword@some.ser.ver:2345/somedb")
      [
        hostname: "some.ser.ver",
        database: "somedb",
        port: 2345,
        username: "someuser",
        password: "somepassword",
      ]

  ### No-frills SSL

  For the `sslmode` keyword, any value but "disable" will result in enabling SSL.

      iex> PostgresqlUri.parse("postgresql://someuser:somepassword@some.ser.ver/somedb?sslmode=yesplease")
      [
        hostname: "some.ser.ver",
        database: "somedb",
        username: "someuser",
        password: "somepassword",
        ssl: true
      ]

  ### Unix socket
  PostgreSQL has the concept of a "socket directory" which can hold different Unix sockets, named after port numbers.
  So, in order to specify a socket belonging to a server listening on a port different from the default (5432), you need
  to pass in a port number, even though you won't be connecting over TCP.

      iex> PostgresqlUri.parse("postgresql:///somedb?user=someuser&password=somepassword&host=/path/to/socketdir&port=2345")
      [
        database: "somedb",
        socket_dir: "/path/to/socketdir",
        password: "somepassword",
        port: 2345,
        username: "someuser",
      ]

  ### Minimal case - local Unix socket, peer authentication.
  Theoretically, `postgresql:///somedb` should work. However, `Postgrex.start_link/1` works differently from `psql` here.
  `psql`, absent host specification, will try to use a Unix socket, perusing the `libpq` compile-time default socket directory.
  Yet Postgrex will fail for this URI (demanding a password), as it doesn't know what socket directory to use.
  So, to make things work for Postgrex, we will have to pass the socket directory explicitly.
  The resulting URI still works as intended for `psql`.

      iex> PostgresqlUri.parse("postgresql:///some_db?host=/run/postgresql")
      [
        database: "some_db",
        socket_dir: "/run/postgresql",
      ]
  """
  @spec parse(nonempty_charlist()) :: keyword()
  def parse(connurl) do
    uri = URI.parse(connurl)
    "postgresql" = uri.scheme

    uri_params =
      Enum.filter(Map.to_list(uri), fn {k, _v} ->
        k in MapSet.new([:host, :port, :path, :userinfo])
      end)

    query_params =
      case uri.query do
        nil -> []
        _ -> URI.decode_query(uri.query)
      end

    (Enum.map(uri_params, &uri_param_map/1) ++ Enum.map(query_params, &query_param_map/1))
    |> Enum.filter(fn thing -> thing != nil end)
    |> List.flatten()
    |> Keyword.new()
  end

  defp uri_param_map(kvpair) do
    case kvpair do
      {_, nil} -> nil
      {:host, ""} -> []
      {:host, v} -> [hostname: v]
      {:port, v} -> [port: v]
      {:path, v} -> [database: String.replace_prefix(v, "/", "")]
      {:userinfo, v} -> [List.zip([[:username, :password], String.split(v, ":", parts: 2)])]
    end
  end

  defp query_param_map(kvpair) do
    case kvpair do
      {_, ""} ->
        []

      {"port", v} ->
        [port: String.to_integer(v)]

      {"host", v} ->
        case String.starts_with?(v, "/") do
          true -> [socket_dir: v]
          _ -> [hostname: v]
        end

      {"user", v} ->
        [username: v]

      {"dbname", v} ->
        [database: v]

      {"sslmode", "disable"} ->
        [ssl: false]

      {"sslmode", _} ->
        [ssl: true]

      {"connect_timeout", v} ->
        [connect_timeout: String.to_integer(v) * 1000]

      {somek, somev} ->
        Keyword.new([{String.to_atom(somek), somev}])
    end
  end
end
