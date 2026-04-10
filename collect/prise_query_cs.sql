--CREATE TABLE consult_ortho AS
SELECT
   cp.pat_c_ipp ipp,
   rdv_d_rdv cs_date,
   rdv_v_ettrdv cs_etat,
   u.ufo_c_ide cs_uf_code_origine,
   u.ufo_c_sih cs_uf_code_rdv,
   u.ufo_l_lib cs_uf_libelle_rdv,
   nat_c_mne cs_acte_code,
   nat_l_lib cs_acte_libelle,
   a.txs_l_lib cs_note
FROM
   sirdv.rdv@sillage_lec r
   join sirdv.act@sillage_lec a
   on a.rdv_c_ide = r.rdv_c_ide
   join sirdv.ufo@sillage_lec u
   on a.ufp_c_ide = u.ufo_c_ide
   join sirdv.nat@sillage_lec n
   on a.nat_c_ide = n.nat_c_ide
   join sirdv.pat@sillage_lec p
   on r.pat_c_ipp = p.pat_c_ipp
   join sirdv.cmp_pat@sillage_lec cp
   on cp.pat_c_ippbis = p.pat_c_ippbis
WHERE
    rdv_d_rdv between '01-01-2025' and '31-01-2025'
    AND nat_c_mne in ('C_EPAUL', 'CSU_EPAUL');

--select *
--from all_tab_columns@sillage_lec
--where owner = 'SIRDV'
