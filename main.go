package main

import (
	"database/sql"
	"fmt"

	_ "github.com/mattn/go-oci8"
	//"time"
)

func main() {
	db, err := sql.Open("oci8", "dzdz/oracle@DZDZ_DEV_4300")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer db.Close()

	if err = testSelect(db); err != nil {
		fmt.Println(err)
		return
	}
}

/*

topic.fpxx.2017.01
  01	每个分区包含该月的所有发票， key 按 xfsbh 来设计
  02
  ...
  0x

topic.hwxx.2017.01

select * from dzdz_fpxx_zzsfp
  2017,01   topic.2017.01
  2017,02	topic.2017.02


*/


func testSelect(db *sql.DB) error {
	rows, err := db.Query("select fpdm,je,kprq from dzdz_fpxx_zzsfp")
	if err != nil {
		return err
	}
	defer rows.Close()

	for rows.Next() {
		var f1 string
		var f2 string
		var f3 string
		rows.Scan(&f1, &f2, &f3)
		println(f1, f2, f3) // 3.14 foo
	}
	return nil
}