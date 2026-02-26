inclusion <- lst(
  pat = lst(
    age = 18,
  ),
  sej = lst(
    date = c(ymd("2023-01-01"), ymd("2023-03-31")),
  ),
  doc = lst(
    date = c(sej$date[1], sej$date[2] %m+% months(6)),
  )
)

exclusion <- lst(
  doc = lst(
    type = c("RSS", "RUM", "LN:11502-2", "HISTORIQUE", "ORDSORT"),
    titre = c("Rapport d'intervention", "check list HAS de l'intervention")
  )
)
