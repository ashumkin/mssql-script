module MSSQL

module SQLDMO

module Script
#ScriptType
Aliases = 16384
AppendToFile=256
Bindings=128
ClusteredIndexes=8
DatabasePermissions = 32
Default=4
DRI_All=532676608
DRI_AllConstraints=520093696
DRI_AllKeys=469762048
DRI_Checks=16777216
DRI_Clustered=8388608
DRI_Defaults=33554432
DRI_ForeignKeys=134217728
DRI_NonClustered=4194304
DRI_PrimaryKey=268435456
DRI_UniqueKeys=67108864
DRIIndexes=65536
DRIWithNoCheck=536870912
Drops=1
IncludeHeaders=131072
IncludeIfNotExists=4096
Indexes=73736
NoCommandTerm=32768
NoDRI=512
NoIdentity=1073741824
NonClusteredIndexes=8192
ObjectPermissions=2
OwnerQualify=262144
PrimaryObject=4
TimestampToBinary=524288
ToFileOnly=64
Triggers=16
UDDTsToBaseType=1024
UseQuotedIdentifiers=-1
Permissions = DatabasePermissions or ObjectPermissions

TransferDefault = PrimaryObject | Drops \
  | Bindings | ClusteredIndexes | NonClusteredIndexes \
  | Triggers | ToFileOnly | Permissions | IncludeHeaders \
  | Aliases | IncludeIfNotExists | OwnerQualify \
  | DRIWithNoCheck

end # module Script

module Script2
#ScriptType2
Seven0Only=16777216
AgentAlertJob=2048
AgentNotify=1024
AnsiFile=2
AnsiPadding=1
Default=0
EncryptPWD=128
ExtendedOnly=67108864
ExtendedProperty=4194304
FullTextCat=2097152
FullTextIndex=524288
JobDisable=33554432
LoginSID=8192
NoCollation=8388608
NoFG=16
NoWhatIfIndexes=512
UnicodeFile=4

end # module Script2

module Obj
# !!! ERROR in MSDN !!!
# SQLDMOObj_UserDefinedDatatype & SQLDMOObj_UserDefinedFunction values are reversed
UserDefinedDatatype = 1
UserDefinedFunction = 4096
View = 4
UserTable = 8
StoredProcedure = 16
Trigger = 256
AllDatabaseUserObjects = 4605

end # module Obj

module XfrFile
SummaryFiles = 1
SingleFilePerObject = 4
SingleSummaryFile = 8
Default = SummaryFiles
end # module Xfr

end # module SQLDMO

end # module MSSQL
