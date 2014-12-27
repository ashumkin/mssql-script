module MSSQL

module ADO
  ADStateClosed = 0 # The object is closed
  ADStateOpen =1  # The object is open
  ADStateConnecting = 2 # The object is connecting
  ADStateExecuting = 4  # The object is executing a command
  ADStateFetching = 8 # The rows of the object are being retrieved

  ADOpenForwardOnly = 0
  ADOpenKeyset = 1
  ADOpenDynamic = 2
  ADOpenStatic = 3
end # module ADO

end # module MSSQL
