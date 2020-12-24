--At the meantime,  could you please ask the customer to run the below query in Tfs_Configuration Db. This will update the registry value to refresh the search cache every 1 hr? There will be change that the same issue will occur during the first hour of project creation, after 1 hr, cache will be refreshed and search will be working as expected.

--More detail about TTL:
--Once every hour it will read all identities that are in scope of the collection and build the search cache, this is typically a quick operation and as long as you don’t reduce the TTL to a lower value the customer should be good. If they find any issues with the performance, it will be a trade off and they can increase the TTL accordingly.

GO
DECLARE @registryUpdates typ_KeyValuePairStringTableNullable
INSERT @registryUpdates ([Key], [Value])
VALUES 
('#\Configuration\Identity\Cache\Settings\SearchCacheLargeTimeToLive\', '01:00:00'),
('#\Configuration\Identity\Cache\Settings\SearchCacheMegaTimeToLive\', '01:00:00')
EXEC prc_UpdateRegistry @partitionId = 1, @identityName = '00000000-0000-0000-0000-000000000000', @registryUpdates = @registryUpdates
GO