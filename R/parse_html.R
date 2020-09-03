#' @import glue

parse_attribute <- function(attr){
  as.character(glue(
    '`{attr$key}` = "{attr$value}"'
  ))
}

parse_content <- function(node, html){
  code <- if(html){
    gsub(
      "\n", "\n  ",
      paste0(c(
        vapply(
          node[["attributes"]], parse_attribute, character(1L),
          USE.NAMES = FALSE
        ),
        if(length(node[["children"]])){
          sprintf(
            "HTML(\n%s\n)",
            paste0(
              sprintf(
                '  "%s"',
                outdent(
                  gsub('"', '\\\\\"', node[["children"]][[1L]][["content"]])
                )
              ),
              collapse = ",\n"
            )
          )
        }
      ),
      collapse = ",\n"
      )
    )
  }else{
    gsub(
      "\n", "\n  ",
      paste0(
        c(
          vapply(
            node[["attributes"]], parse_attribute, character(1L),
            USE.NAMES = FALSE
          ),
          vapply(
            Filter(includeNode, node[["children"]]), parse_node,
            character(1L), USE.NAMES = FALSE
          )
        ),
        collapse = ",\n"
      )
    )
  }
  if(grepl("^\\s*?$", code)) "" else sprintf("\n  %s\n", code)
}

isSep <- function(node){
  identical(names(node), c("type","content")) &&
    node[["type"]] == "text" && grepl("^\n\\s*?$", node[["content"]])
}

isComment <- function(node){
  identical(names(node), c("type","content")) && node[["type"]] == "comment"
}

includeNode <- function(node){
  !isSep(node) && !isComment(node)
}

outdent <- function(content){
  lines <- strsplit(gsub("(^\n| *$)", "", content), "\n")[[1L]]
  i <- 1L
  while(i <= length(lines) && grepl("^\\s*?$", lines[i])){
    i <- i + 1L
  }
  if(i > 1L) lines <- lines[-seq_len(i-1L)]
  space <- min(nchar(
    sub("(^\\s*).*", "\\1", Filter(function(x) x!= "", lines))
  ))
  sub(sprintf("^\\s{%d}", space), "", lines)
}

parse_node <- function(node){
  code <- ""
  if(node[["type"]] == "element"){
    if(node[["tagName"]] == "!doctype") return("")
    if(node[["tagName"]] == "br") return("tags$br()")
    html <- node[["tagName"]] %in% c("script", "style")# &&
    #      length(node[["attributes"]]) == 0L
    code <- glue(
      "tags${tag}({content})",
      tag = node[["tagName"]],
      content = parse_content(node, html)
    )
  }else if(node[["type"]] == "text" && !isSep(node)){
    code <- glue('"{node[["content"]]}"')
  }
  as.character(code)
}

#' @export
parse_html <- function(html){
  paste0(
    Filter(function(x) x != "", vapply(html, parse_node, character(1L))),
    collapse = ",\n"
  )
}