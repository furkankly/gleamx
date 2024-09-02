import sqlight.{type Connection}
import wisp

pub type Context {
  Context(db: Connection)
}

pub fn middleware(
  req: wisp.Request,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  // Log information about the request and response.
  use <- wisp.log_request(req)

  // Return a default 500 response if the request handler crashes.
  use <- wisp.rescue_crashes

  // Rewrite HEAD requests to GET requests and return an empty body.
  use req <- wisp.handle_head(req)

  let assert Ok(priv) = wisp.priv_directory("gleamx")
  use <- wisp.serve_static(req, under: "", from: priv)

  // Handle the request!
  handle_request(req)
}
