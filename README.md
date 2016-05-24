# ArchiveToAzure

This is a simple script for archiving data to Azure file storage.

1) Use DataGravity UI to filter by files, dormant data, etc
2) Export CSV file
3) Use Excel/OpenOffice if more filtering is needed, use commas only not ;
4) Modify script paths
5) Run script
6) Take DiscoveryPoint and verify file deletion
7) Optional - Verify Archive Stubs if -ArchiveStub parameter specified

Ex. ArchiveDormantData.ps1 -SourceFilePath "\\10.100.15.40\Sales$" -CloudFilePath "\\azure16.file.core.windows.net\archive" -csvFilePath "c:\temp\sales.csv" -logFile "C:\Temp\DataGravity Delete From CSV.log" -ArchiveStub
