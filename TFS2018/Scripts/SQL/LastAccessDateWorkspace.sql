SELECT DISTINCT
ws.OwnerId, id.DisplayName, ws.LastAccessDate, ws.WorkspaceName, ws.Computer, id.AccountName
FROM tbl_Workspace ws WITH (NOLOCK)
JOIN tbl_LocalVersion lv WITH (NOLOCK) ON lv.WorkspaceId = ws.WorkspaceId
LEFT OUTER JOIN [Tfs_Configuration].dbo.[tbl_Identity] id WITH (NOLOCK) ON id.Id = ws.OwnerID
WHERE ws.Type = 0
AND ws.LastAccessDate < DATEADD(DAY,-365,GETUTCDATE())