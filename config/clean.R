list(
  character = c(
    "\\p{Zs}{2,}|&#160;" = " ",
    "&amp;" = "&",
    "&lt;" = "<",
    "&gt;" = ">",
    "&#34;|’" = "'",
    '</p>\n<p.+">(<(b|i)>)*(er|è(r|m)e|e)(</(b|i)>)*</p>\n<p.+">' = "e",
    "_PATIENT" = ""
  ),
  markup = c(
    "<body.+>" = "<body bgcolor=#333333 vlink=#555555 link=#555555>",
    '(?<=id="page\\d{1,2}-div")' = " class='page'",
    "color:#.{6};" = "color:#555555;"
  )
)
