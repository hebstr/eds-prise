inclusion <- lst(
  pat = lst(
    age = 18,
  ),
  sej = lst(
    date = c(ymd("2025-01-01"), ymd("2025-01-31")),
  ),
  doc = lst(
    date = c(sej$date[1], sej$date[2] %m+% months(6)),
    uf = c("2438", "3707", "3900", "3910", "3918", "3143", "3144", "3268")
  )
)

exclusion <- lst(
  doc = lst(
    type = c("RSS", "RUM", "LN:11502-2", "HISTORIQUE", "ORDSORT"),
    titre = c("Rapport d'intervention", "check list HAS de l'intervention")
  )
)

.cim10 <- "M1901|M25(3|5)1|M75|S46"

.ccam_list <- list(
  infiltr_ms = "MZLB001|MZLH002|MZLH001|ZZLJ002",
  chir_epaule = list(
    coiffe_rot = "MJEC001|MJEC002|MJEA010|MJEA006|MJMA003",
    acromioplastie = "MEMC003|MEMA006|MEMC005",
    arthroplasties_scapulohum = "MEKA0(0[5-9]|10)",
    reprise_chir = "MEKA002|MEMA015",
    explo_artho = "MEQC002"
  ),
  ponction = "MZJB001"
)
