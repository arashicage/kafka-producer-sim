
working configuration

```
GOPATH
    D:\workspace\workspace.go\GOPATH                            # my gopath
    D:\workspace\workspace.go\GOCODE                            # my code goes here

GOROOT=
    D:\workspace\workspace.env\go                               # my goroot

NLS_LANG=AMERICAN_AMERICA.ZHS16GBK

PATH=
    D:\Workspace\workspace.env\instantclient_12_1               # oci.dll
    D:\workspace\workspace.env\mingw64\bin                      # gcc.exe
    D:\Program Files\cmder\vendor\git-for-windows\cmd           # git.exe
    D:\workspace\workspace.env\misc\pkg-config-lite-0.28-1\bin  # go.exe

PKG_CONFIG_PATH=
    D:\workspace\workspace.env\PKG_CONFIG_PATH                  # oci8.pc

TNS_ADMIN=
    D:\Workspace\workspace.env\instantclient_12_1\network\admin # tnsnames.ora

```

https://github.com/rana/ora/issues/47

https://andrey.nering.com.br/2016/connecting-golang-to-oracle-database/


##### oci8.pc for ora

```
prefix=D:/workspace/workspace.env/instantclient_12_1/sdk

version=12.1
build=client64

libdir=${prefix}/lib
includedir=${prefix}/include

glib_genmarshal=glib-genmarshal
gobject_query=gobject-query
glib_mkenums=glib-mkenums

Name: oci8
Description: Oracle database engine
Version: ${version}
Libs: -L${libdir} -loci
Libs.private:
Cflags: -I${includedir}
```

##### oci8.pc for go-oci8

```
prefix=D:/workspace/workspace.env/instantclient_12_1/sdk
exec_prefix=${prefix}
libdir=${prefix}/lib
includedir=${prefix}/include

glib_genmarshal=glib-genmarshal
gobject_query=gobject-query
glib_mkenums=glib-mkenums

Name: oci8
Version: 11.2
Description: oci8 library
Libs: -L${libdir} -loci
Cflags: -I${includedir}
```

##### traps

```
example from ora

srvCfg := ora.SrvCfg{Dblink: "DZDZ_DEV_4300"}
	srvCfg.StmtCfg = ora.NewStmtCfg()                ##### 坑1
	srv, err := env.OpenSrv(srvCfg)


/*stmtTbl, err := ses.Prep(fmt.Sprintf("CREATE TABLE %v "+
		"(C1 NUMBER(19,0) GENERATED ALWAYS AS IDENTITY "+
		"(START WITH 1 INCREMENT BY 1), C2 VARCHAR2(48 CHAR))", tableName))*/
	stmtTbl, err := ses.Prep(fmt.Sprintf("CREATE TABLE %v "+
		"(C1 NUMBER(19,0),"+
		"C2 VARCHAR2(48 CHAR))", tableName))

stmtIns, err := ses.Prep(fmt.Sprintf(
		"INSERT INTO %v (C1,C2) VALUES (SEQ_ID.NEXTVAL,:C2) RETURNING C1 INTO :C1", tableName))

stmtSliceIns, err := ses.Prep(fmt.Sprintf(
		"INSERT INTO %v (C1,C2) VALUES (SEQ_ID.NEXTVAL,:C2)", tableName))

for rset.Next() {            ##### 坑1
		fmt.Println(rset.Row[0], rset.Row[1])
	}

```
