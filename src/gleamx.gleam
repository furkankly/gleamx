import app/db.{migrate_schema}
import app/router
import app/web
import argv
import gleam/erlang/process
import mist
import sqlight
import wisp
import wisp/wisp_mist

pub fn main() {
  // This sets the logger to print INFO level logs, and other sensible defaults
  // for a web application.
  wisp.configure_logger()

  // Here we generate a secret key, but in a real application you would want to
  // load this from somewhere so that it is not regenerated on every restart.
  let secret_key_base = wisp.random_string(64)

  let assert Ok(dsn) = case argv.load().arguments {
    ["-dsn", name] -> Ok(name)
    _ -> {
      Error("usage: ./server -dsn <name>")
    }
  }

  let assert Ok(db) = sqlight.open(dsn)
  let assert Ok(_) = sqlight.with_connection(dsn, migrate_schema)
  let context = web.Context(db: db)
  let request_handler = router.handle_request(_, context)

  // Start the Mist web server.
  let assert Ok(_) =
    request_handler
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  // The web server runs in new Erlang process, so put this one to sleep while
  // it works concurrently.
  process.sleep_forever()
}
