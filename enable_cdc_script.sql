EXEC sys.sp_cdc_enable_table  
            @source_schema = N'AppManagement',@source_name = N'tblAppError'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'AppManagement',@source_name = N'tblAppRating'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'UserCommunication',@source_name = N'tblBirthDayCommunication'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Booking',@source_name = N'tblBookingItemInitial'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Orders',@source_name = N'tblCancelOrderSMS'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Orders',@source_name = N'tblChildOrderGrouping'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'UserManagement',@source_name = N'tblCustomerOrderSummaryStaged'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Promotion',@source_name = N'tblCustSSCurrencyHistory'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'AppManagement',@source_name = N'tblDBAppSMS'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'dbo',@source_name = N'tblInSourceCompProcess'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Orders',@source_name = N'tblOrderOtherDetails'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Orders',@source_name = N'tblOrderStatHistoryByHBEmp'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Orders',@source_name = N'tblPendingHBDAFeedback'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'HBERP',@source_name = N'tblReOrderReminderMode'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Reports',@source_name = N'tblSalesDayWiseHbWiseCustPlaceOnly'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Orders',@source_name = N'tblSalesReturnItemInitial'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Orders',@source_name = N'tblSHBLSyncprocessedOrders'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'dbo',@source_name = N'tblSMLSHBLIntegration'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'Reports',@source_name = N'tblSoldandAvailableQty'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO
EXEC sys.sp_cdc_enable_table  
            @source_schema = N'dbo',@source_name = N'tblSSSPLError'  
          , @role_name = NULL 
		  ,@supports_net_changes = 1
		  GO