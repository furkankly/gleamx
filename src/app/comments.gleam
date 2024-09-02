import app/web.{type Context}
import gleam/bbmustache
import gleam/dynamic
import gleam/http.{Get, Post}
import gleam/io
import gleam/json
import gleam/list
import gleam/result
import gleam/string_builder

import sqlight
import wisp.{type Request, type Response}

pub fn comments(req: Request, ctx: Context) -> Response {
  case req.method {
    Get -> get_comments(req, ctx)
    Post -> create_comment(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

type Comment {
  Comment(title: String, by: String, content: String)
}

fn comment_from_json(json_string: String) -> Result(Comment, json.DecodeError) {
  let comment_decoder =
    dynamic.decode3(
      Comment,
      dynamic.field("title", of: dynamic.string),
      dynamic.field("by", of: dynamic.string),
      dynamic.field("content", of: dynamic.string),
    )
  json.decode(from: json_string, using: comment_decoder)
}

fn get_comments(_req: Request, ctx: Context) -> Response {
  let comment_decoder =
    dynamic.decode3(
      Comment,
      dynamic.element(0, dynamic.string),
      dynamic.element(1, dynamic.string),
      dynamic.element(2, dynamic.string),
    )
  let result = {
    let sql =
      "
    select title, by, content from comments
    "
    use comments <- result.try(sqlight.query(
      sql,
      ctx.db,
      with: [],
      expecting: comment_decoder,
    ))

    let start_tag = "<ul class='flex flex-col gap-2'>"
    let assert Ok(template) =
      bbmustache.compile(
        "
  <li class='p-4 border border-black rounded'>
    <div class='flex'>
      <div class='text-2xl font-semibold flex-1'>{{title}}</div>
      <span>{{by}}</span>
    </div>
    <div class='p-2 break-words'>{{content}}</div>
  </li>
",
      )
    let html =
      string_builder.from_string({
        let end_tag = "</ul>"
        list.fold(comments, start_tag, fn(html, comment) {
          let comment_string =
            bbmustache.render(template, [
              #("title", bbmustache.string(comment.title)),
              #("by", bbmustache.string(comment.by)),
              #("content", bbmustache.string(comment.content)),
            ])
          html <> comment_string
        })
        <> end_tag
      })
    Ok(html)
  }
  case result {
    Ok(html) -> wisp.html_response(html, 200)
    Error(_) -> {
      wisp.internal_server_error()
    }
  }
}

fn create_comment(req: Request, ctx: Context) -> Response {
  use json <- wisp.require_string_body(req)
  let result = {
    use comment <- result.try(result.nil_error(comment_from_json(json)))
    let sql =
      "
    insert into comments (title, by, content) values(?, ?, ?)
    "
    use result <- result.try(
      result.map_error(
        sqlight.query(
          sql,
          ctx.db,
          with: [
            sqlight.text(comment.title),
            sqlight.text(comment.by),
            sqlight.text(comment.content),
          ],
          expecting: dynamic.dynamic,
        ),
        fn(error) {
          io.debug(error)
          Nil
        },
      ),
    )
    Ok(result)
  }

  case result {
    Ok(_) -> wisp.set_header(wisp.ok(), "HX-Trigger", "newComment")
    Error(_) -> wisp.internal_server_error()
  }
}
