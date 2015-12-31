# Sqlpp
plug in for NotePad++ for searching and fetching sql


how to install
----------------------

1.open folder in Command Line:
	Sqlpp/SqlppService/bin/Debug
	
then execute:	
	SqlppService.exe -install

2.open folder SqlppPlugin\bin\Debug in Windows Explorer
then copy "Sqlpp.dll" to "C:\Program Files (x86)\Notepad++\plugins"




the service servs data at http://localhost:8090

test:
http://localhost:8090/api/Db/Search?name=stp
http://localhost:8090/api/Db/Get?name=TBL_USERS
