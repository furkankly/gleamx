import app/comments
import app/web.{type Context}
import gleam/string_builder
import simplifile
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> serve_index_html()
    ["comments"] -> comments.comments(req, ctx)
    _ -> wisp.not_found()
  }
}

fn serve_index_html() -> Response {
  let assert Ok(priv) = wisp.priv_directory("gleamx")
  let assert Ok(index_html) = simplifile.read(priv <> "/index.html")
  string_builder.from_string(index_html) |> wisp.html_response(200)
}
