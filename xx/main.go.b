package main

import (
	"fmt"
	"gopkg.in/rana/ora.v4"
)

func main() {
	// example usage of the ora package driver
	// connect to a server and open a session
	env, err := ora.OpenEnv()
	defer env.Close()
	if err != nil {
		panic(err)
	}
	srvCfg := ora.SrvCfg{Dblink: "DZDZ_DEV_4300"}
	srvCfg.StmtCfg = ora.NewStmtCfg()                ##### 坑1
	srv, err := env.OpenSrv(srvCfg)
	defer srv.Close()
	if err != nil {
		panic(err)
	}
	sesCfg := ora.SesCfg{
		Username: "dzdz",
		Password: "oracle",
	}
	ses, err := srv.OpenSes(sesCfg)
	defer ses.Close()
	if err != nil {
		panic(err)
	}

	// create table
	tableName := "t1"
	/*stmtTbl, err := ses.Prep(fmt.Sprintf("CREATE TABLE %v "+
		"(C1 NUMBER(19,0) GENERATED ALWAYS AS IDENTITY "+
		"(START WITH 1 INCREMENT BY 1), C2 VARCHAR2(48 CHAR))", tableName))*/
	stmtTbl, err := ses.Prep(fmt.Sprintf("CREATE TABLE %v "+
		"(C1 NUMBER(19,0),"+
		"C2 VARCHAR2(48 CHAR))", tableName))
	defer stmtTbl.Close()
	if err != nil {
		panic(err)
	}
	rowsAffected, err := stmtTbl.Exe()
	if err != nil {
		panic(err)
	}
	fmt.Println(rowsAffected)

	// begin first transaction
	tx1, err := ses.StartTx()
	if err != nil {
		panic(err)
	}

	// insert record
	var id uint64
	str := "Go is expressive, concise, clean, and efficient."
	stmtIns, err := ses.Prep(fmt.Sprintf(
		"INSERT INTO %v (C1,C2) VALUES (SEQ_ID.NEXTVAL,:C2) RETURNING C1 INTO :C1", tableName))
	defer stmtIns.Close()
	rowsAffected, err = stmtIns.Exe(str, &id)
	if err != nil {
		panic(err)
	}
	fmt.Println(rowsAffected)

	// insert nullable String slice
	a := make([]ora.String, 4)
	a[0] = ora.String{Value: "Its concurrency mechanisms make it easy to"}
	a[1] = ora.String{IsNull: true}
	a[2] = ora.String{Value: "It's a fast, statically typed, compiled"}
	a[3] = ora.String{Value: "One of Go's key design goals is code"}
	stmtSliceIns, err := ses.Prep(fmt.Sprintf(
		"INSERT INTO %v (C1,C2) VALUES (SEQ_ID.NEXTVAL,:C2)", tableName))
	defer stmtSliceIns.Close()
	if err != nil {
		panic(err)
	}
	rowsAffected, err = stmtSliceIns.Exe(a)
	if err != nil {
		panic(err)
	}
	fmt.Println(rowsAffected)

	// fetch records
	stmtQry, err := ses.Prep(fmt.Sprintf(
		"SELECT C1, C2 FROM %v", tableName))
	defer stmtQry.Close()
	if err != nil {
		panic(err)
	}
	rset, err := stmtQry.Qry()
	if err != nil {
		panic(err)
	}
	for rset.Next() {            ##### 坑1
		fmt.Println(rset.Row[0], rset.Row[1])
	}
	if err := rset.Err(); err != nil {
		panic(err)
	}

	// commit first transaction
	err = tx1.Commit()
	if err != nil {
		panic(err)
	}

	// begin second transaction
	tx2, err := ses.StartTx()
	if err != nil {
		panic(err)
	}
	// insert null String
	nullableStr := ora.String{IsNull: true}
	stmtTrans, err := ses.Prep(fmt.Sprintf(
		"INSERT INTO %v (C2) VALUES (:C2)", tableName))
	defer stmtTrans.Close()
	if err != nil {
		panic(err)
	}
	rowsAffected, err = stmtTrans.Exe(nullableStr)
	if err != nil {
		panic(err)
	}
	fmt.Println(rowsAffected)
	// rollback second transaction
	err = tx2.Rollback()
	if err != nil {
		panic(err)
	}

	// fetch and specify return type
	stmtCount, err := ses.Prep(fmt.Sprintf(
		"SELECT COUNT(C1) FROM %v WHERE C2 IS NULL", tableName), ora.U8)
	defer stmtCount.Close()
	if err != nil {
		panic(err)
	}
	rset, err = stmtCount.Qry()
	if err != nil {
		panic(err)
	}
	row := rset.NextRow()
	if row != nil {
		fmt.Println(row[0])
	}
	if err := rset.Err(); err != nil {
		panic(err)
	}

	// create stored procedure with sys_refcursor
	stmtProcCreate, err := ses.Prep(fmt.Sprintf(
		"CREATE OR REPLACE PROCEDURE PROC1(P1 OUT SYS_REFCURSOR) AS BEGIN "+
			"OPEN P1 FOR SELECT C1, C2 FROM %v WHERE C1 > 2 ORDER BY C1; "+
			"END PROC1;",
		tableName))
	defer stmtProcCreate.Close()
	rowsAffected, err = stmtProcCreate.Exe()
	if err != nil {
		panic(err)
	}

	// call stored procedure
	// pass *Rset to Exe to receive the results of a sys_refcursor
	stmtProcCall, err := ses.Prep("CALL PROC1(:1)")
	defer stmtProcCall.Close()
	if err != nil {
		panic(err)
	}
	procRset := &ora.Rset{}
	rowsAffected, err = stmtProcCall.Exe(procRset)
	if err != nil {
		panic(err)
	}
	if procRset.IsOpen() {
		for procRset.Next() {
			fmt.Println(procRset.Row[0], procRset.Row[1])
		}
		if err := procRset.Err(); err != nil {
			panic(err)
		}
		fmt.Println(procRset.Len())
	}

	// Output:
	// 0
	// 1
	// 4
	// 1 Go is expressive, concise, clean, and efficient.
	// 2 Its concurrency mechanisms make it easy to
	// 3
	// 4 It's a fast, statically typed, compiled
	// 5 One of Go's key design goals is code
	// 1
	// 1
	// 3
	// 4 It's a fast, statically typed, compiled
	// 5 One of Go's key design goals is code
	// 3
}