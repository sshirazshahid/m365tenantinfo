class PlannerTaskObject
{
    [string]$PlanName
    [string]$PlanId
    [string]$Title
    [string]$TaskId
    [string]$Notes
    [string]$BucketName
    [string]$BucketId
    [string]$ETag
    [string[]]$Assignments
    [System.Collections.Hashtable[]]$Attachments
    [System.Collections.Hashtable[]]$Checklist
    [string]$StartDateTime
    [string]$DueDateTime
    [string[]]$Categories
    [string]$CompletedDateTime
    [int]$PercentComplete
    [int]$Priority
    [string]$ConversationThreadId
    [string]$OrderHint
    [string]$PreviewType

    [string]GetTaskCategoryNameByColor([string]$ColorName, [string]$PlanId, [System.Management.Automation.PSCredential]$GlobalAdminAccount, [String]$ApplicationId)
    {
        $VerbosePreference = 'Continue'
        Write-Verbose -Message "Searching for Category Mapping for Label {$ColorName}"
        $uri = "https://graph.microsoft.com/beta/planner/plans/$PlanId/Details"
        $planDetails = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
                -ApplicationId $ApplicationId `
                -Uri $uri `
                -Method Get
        Write-Verbose -Message "---------> $uri"
        Write-Verbose -Message "---------> $($planDetails | Out-String)"
        if ($planDetails.categoryDescriptions.category1 -eq $ColorName)
        {
            return "category1"
        }
        elseif ($planDetails.categoryDescriptions.category2 -eq $ColorName)
        {
            return "category2"
        }
        elseif ($planDetails.categoryDescriptions.category3 -eq $ColorName)
        {
            return "category3"
        }
        elseif ($planDetails.categoryDescriptions.category4 -eq $ColorName)
        {
            return "category4"
        }
        elseif ($planDetails.categoryDescriptions.category5 -eq $ColorName)
        {
            return "category5"
        }
        elseif ($planDetails.categoryDescriptions.category6 -eq $ColorName)
        {
            return "category6"
        }
        return $null
    }

    [string]GetTaskColorNameByCategory([string]$CategoryName, [string]$PlanId, [System.Management.Automation.PSCredential]$GlobalAdminAccount, [String]$ApplicationId)
    {
        $uri = "https://graph.microsoft.com/beta/planner/plans/$PlanId/Details"
        $planDetails = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
                -ApplicationId $ApplicationId `
                -Uri $uri `
                -Method Get
        # retrieve Category Labels
        if ($null -eq $planDetails.categoryDescriptions.category1)
        {
                $Category1Value = "Pink"
        }
        else
        {
            $Category1Value = $planDetails.categoryDescriptions.category1
        }

        if ($null -eq $planDetails.categoryDescriptions.category2)
        {
                $Category2Value = "Red"
        }
        else
        {
            $Category2Value = $planDetails.categoryDescriptions.category2
        }

        if ($null -eq $planDetails.categoryDescriptions.category3)
        {
                $Category3Value = "Yellow"
        }
        else
        {
            $Category3Value = $planDetails.categoryDescriptions.category3
        }

        if ($null -eq $planDetails.categoryDescriptions.category4)
        {
                $Category4Value = "Green"
        }
        else
        {
            $Category4Value = $planDetails.categoryDescriptions.category4
        }

        if ($null -eq $planDetails.categoryDescriptions.category5)
        {
                $Category5Value = "Blue"
        }
        else
        {
            $Category5Value = $planDetails.categoryDescriptions.category5
        }

        if ($null -eq $planDetails.categoryDescriptions.category6)
        {
                $Category6Value = "Purple"
        }
        else
        {
            $Category6Value = $planDetails.categoryDescriptions.category6
        }
        switch($CategoryName)
        {
            "category1"{return $Category1Value}
            "category2"{return $Category2Value}
            "category3"{return $Category3Value}
            "category4"{return $Category4Value}
            "category5"{return $Category5Value}
            "category6"{return $Category6Value}
        }
        return $null
    }

    [void]PopulateById([System.Management.Automation.PSCredential]$GlobalAdminAccount, [String]$ApplicationId, [string]$TaskId)
    {
        try
        {
            $uri = "https://graph.microsoft.com/beta/planner/tasks/$TaskId"
            $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
                -ApplicationId $ApplicationId `
                -Uri $uri `
                -Method Get

            $taskDetailsResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
                -ApplicationId $ApplicationId `
                -Uri ($uri + "/details") `
                -Method Get

            #region Assignments
            $assignmentsValue = @()
            if ($null -ne $taskResponse.assignments)
            {
                $allAssignments = $taskResponse.assignments | gm | Where-Object -FilterScript{$_.MemberType -eq 'NoteProperty'}
                foreach ($assignment in $allAssignments)
                {
                    $assignmentsValue += $assignment.Name
                }
           }
                #endregion

            #region Attachments
            $attachmentsValue = @()
            if ($null -ne $taskDetailsResponse.references)
            {
                $allAttachments = $taskDetailsResponse.references | gm | Where-Object -FilterScript{$_.MemberType -eq 'NoteProperty'}
                foreach ($attachment in $allAttachments)
                {
                    $hashEntry = @{
                        Uri   = $attachment.Name
                        Alias = $taskDetailsResponse.references.($attachment.Name).alias
                        Type  = $taskDetailsResponse.references.($attachment.Name).type
                    }
                    $attachmentsValue += $hashEntry
                }
            }
            #endregion

            #region Categories
            $categoriesValue = @()
            if ($null -ne $taskResponse.appliedCategories)
            {
                $allCategories = $taskResponse.appliedCategories | gm | Where-Object -FilterScript{$_.MemberType -eq 'NoteProperty'}
                foreach ($category in $allCategories)
                {
                    $categoriesValue += $this.GetTaskColorNameByCategory($category.Name, $taskResponse.planId, $GlobalAdminAccount, $ApplicationId)
                }
            }
            #endregion

            #region Checklist
            $checklistValue = @()
            if ($null -ne $taskDetailsResponse.checklist)
            {
                $allCheckListItems = $taskDetailsResponse.checklist | gm | Where-Object -FilterScript{$_.MemberType -eq 'NoteProperty'}
                foreach ($checkListItem in $allCheckListItems)
                {
                    $hashEntry = @{
                        Title     = $taskDetailsResponse.checklist.($checkListItem.Name).title
                        Completed = [bool]$taskDetailsResponse.checklist.($checkListItem.Name).isChecked
                    }
                    $checklistValue += $hashEntry
                }
            }
            #endregion
            $this.Etag                 = $taskResponse.'@odata.etag'
            $this.TaskId               = $taskResponse.id
            $this.Title                = $taskResponse.title
            $this.StartDateTime        = $taskResponse.startDateTime
            $this.ConversationThreadId = $taskResponse.conversationThreadId
            $this.DueDateTime          = $taskResponse.dueDateTime
            $this.CompletedDateTime    = $taskResponse.completedDateTime
            $this.Priority             = $taskResponse.priority
            $this.PercentComplete      = [int]$taskResponse.percentComplete
            $this.Notes                = $taskDetailsResponse.description
            $this.PreviewType          = $taskDetailsResponse.previewType
            $this.Assignments          = $assignmentsValue
            $this.Attachments          = $attachmentsValue
            $this.Categories           = $categoriesValue
            $this.Checklist            = $checklistValue
        }
        catch
        {
            if ($_.Exception -like '*Forbidden*')
            {
                Write-Warning $_.Message
            }
            elseif ($_ -like '*requested item is not found*')
            {
                return
            }
            else
            {
                Write-Host $_
                Start-Sleep -Seconds 120
                this.PopulateById($GlobalAdminAccount, $ApplicationId, $TaskId)
            }
        }
    }
    [string]ConvertToJSONTask([System.Management.Automation.PSCredential]$GlobalAdminAccount, [String]$ApplicationId)
    {
        $VerbosePreference = 'Continue'
        $sb = [System.Text.StringBuilder]::New()
        $sb.Append("{") | Out-Null
        $sb.Append("`"planId`":`"$($this.PlanId)`"") | Out-Null
        $titleValue = $this.Title | ConvertTo-Json

        $sb.Append(",`"title`":$titleValue") | Out-Null
        if (-not [System.String]::IsNullOrEmpty($this.BucketId))
        {
            $sb.Append(",`"bucketId`":`"$($this.BucketId)`"") | Out-Null
        }
        if (-not [System.String]::IsNullOrEmpty($this.Priority))
        {
            $sb.Append(",`"priority`": $($this.Priority.ToString())") | Out-Null
        }
        Write-Verbose -Message "Value of PercentComplete in ConvertTaskToJSON = {$($this.PercentComplete)}"
        if (-not [System.String]::IsNullOrEmpty($this.PercentComplete))
        {
            $sb.Append(",`"percentComplete`": $($this.PercentComplete.ToString())") | Out-Null
        }
        if (-not [System.String]::IsNullOrEmpty($this.StartDateTime))
        {
            $sb.Append(",`"startDateTime`":`"$($this.StartDateTime)`"") | Out-Null
        }
        if (-not [System.String]::IsNullOrEmpty($this.DueDateTime))
        {
            $sb.Append(",`"dueDateTime`":`"$($this.DueDateTime)`"") | Out-Null
        }
        if (-not [System.String]::IsNullOrEmpty($this.ConversationThreadId))
        {
            $sb.Append(",`"conversationThreadId`":`"$($this.ConversationThreadId)`"") | Out-Null
        }
        if ($this.Assignments.Length -gt 0)
        {
            $sb.Append(",`"assignments`": {") | Out-Null
            $id = 1
            foreach ($assignment in $this.Assignments)
            {
                if ($id -gt 1)
                {
                    $sb.Append(",") | Out-Null
                }
                $sb.Append("`"$assignment`":{") | Out-Null
                $sb.Append("`"@odata.type`":`"#microsoft.graph.plannerAssignment`"") | Out-Null

                if ([System.String]::IsNullOrEmpty($this.OrderHint))
                {
                    $sb.Append(",`"orderHint`": `" !`"")
                }
                $sb.Append("}") | Out-Null
                $id++
            }
            $sb.Append("}") | Out-Null
        }
        if ($this.Categories.Length -gt 0)
        {
            $sb.Append(",`"appliedCategories`": {") | Out-Null
            $id = 1
            foreach ($category in $this.Categories)
            {
                if ($id -gt 1)
                {
                    $sb.Append(",") | Out-Null
                }
                $categoryName = $this.GetTaskCategoryNameByColor($category, $this.PlanId, $GlobalAdminAccount, $ApplicationId)
                $sb.Append("`"$categoryName`":true") | Out-Null
                $id++
            }
            $sb.Append("}") | Out-Null
        }
        $sb.Append("}") | Out-Null
        $VerbosePreference = "Continue"
        Write-Verbose -Message $sb.Tostring()
        return $sb.ToString()
    }

    [string]ConvertToJSONTaskDetails()
    {
        $sb = [System.Text.StringBuilder]::New()
        $sb.Append("{") | Out-Null
        $notesValue = $this.Notes | ConvertTo-JSON
        $sb.Append("`"description`":$notesValue,") | Out-Null
        $sb.Append("`"previewType`": `"$($this.PreviewType)`"")
        if ($this.Attachments.Length -gt 0)
        {
            $sb.Append(",`"references`": {") | Out-Null
            $i = 1
            foreach ($attachment in $this.Attachments)
            {
                if ($i -gt 1)
                {
                    $sb.Append(",") | Out-Null
                }
                $sb.Append("`"$($attachment.Uri)`": {") | Out-Null
                $sb.Append("`"@odata.type`": `"#microsoft.graph.plannerExternalReference`",") | Out-Null
                $sb.Append("`"alias`":`"$($attachment.Alias)`",") | Out-Null
                $sb.Append("`"type`":`"$($attachment.Type)`"") | Out-Null
                $sb.Append("}") | Out-Null
                $i++
            }
            $sb.Append("}") | Out-Null
        }

        if ($this.Checklist.Length -gt 0)
        {
            $sb.Append(",`"checklist`": {") | Out-Null
            $i = 1
            foreach ($checkListItem in $this.Checklist)
            {
                if ($i -gt 1)
                {
                    $sb.Append(",") | Out-Null
                }
                $sb.Append("`"$((New-Guid).ToString())`": {") | Out-Null
                $sb.Append("`"@odata.type`": `"#microsoft.graph.plannerChecklistItem`",") | Out-Null
                $sb.Append("`"title`":`"$($checkListItem.Title.Replace("\", "\\"))`",") | Out-Null
                $sb.Append("`"isChecked`": $($checkListItem.Completed.ToString().Replace('`$', '').ToLower())") | Out-Null
                $sb.Append("}") | Out-Null
                $i++
            }
            $sb.Append("}") | Out-Null
        }
        $sb.Append("}") | Out-Null
        $VerbosePreference = 'Continue'
        Write-Verbose -Message "TASK DETAILS ---> $($sb.ToString())"
        return $sb.ToString()
    }

    [void]Create([System.Management.Automation.PSCredential]$GlobalAdminAccount, [String]$ApplicationId)
    {
        $VerbosePreference = 'Continue'
        $uri = "https://graph.microsoft.com/beta/planner/tasks"
        $body = $this.ConvertToJSONTask($GlobalAdminAccount, $ApplicationId)
        Write-Verbose -Message "JSON Body {$body}"
        Write-Verbose -Message "Trying to create new Task"
        $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method "POST" `
            -Body $body
        $this.TaskId = $taskResponse.id
        Write-Verbose -Message "New Planner Task created with Id {$($taskResponse.id)}"

        $this.UpdateDetails($GlobalAdminAccount, $ApplicationId)
    }

    [void]Update([System.Management.Automation.PSCredential]$GlobalAdminAccount, [String]$ApplicationId)
    {
        $VerbosePreference = 'Continue'
        Write-Verbose -Message "Trying to update existing Task"
        $uri = "https://graph.microsoft.com/beta/planner/tasks/$($this.TaskId)"
        $body = $this.ConvertToJSONTask()
        $Headers = @{}
        $Headers.Add("If-Match", $this.ETag)
        $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method "PATCH" `
            -Body $body `
            -Headers $Headers

        Write-Verbose -Message "Done updating existing Task"
    }

    [void]UpdateDetails([System.Management.Automation.PSCredential]$GlobalAdminAccount, [String]$ApplicationId)
    {
        $VerbosePreference = 'Continue'
        Write-Verbose -Message "Trying to update existing Task Details"
        $uri = "https://graph.microsoft.com/v1.0/planner/tasks/$($this.TaskId)/details"
        $body = $this.ConvertToJSONTaskDetails()

        # Get ETag for the details
        $currentTaskDetails = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method "GET"
        $Headers = @{}
        $Headers.Add("If-Match", $currentTaskDetails.'@odata.etag')
        $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method "PATCH" `
            -Body $body `
            -Headers $Headers

        Write-Verbose -Message "Done updating Task details"
    }

    [void]Delete([System.Management.Automation.PSCredential]$GlobalAdminAccount, [string]$ApplicationId, [string]$TaskId)
    {
        $VerbosePreference = 'Continue'
        Write-Verbose -Message "Initiating the Deletion of Task {$TaskId}"
        $uri = "https://graph.microsoft.com/v1.0/planner/tasks/$TaskId"

        # Get ETag for the details
        $currentTaskDetails = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method "GET"
        $Headers = @{}
        $Headers.Add("If-Match", $currentTaskDetails.'@odata.etag')
        Write-Verbose -Message "Retrieved Task's ETag {$($currentTaskDetails.'@odata.etag')}"
        $taskResponse = Invoke-MSCloudLoginMicrosoftGraphAPI -CloudCredential $GlobalAdminAccount `
            -ApplicationId $ApplicationId `
            -Uri $uri `
            -Method "DELETE" `
            -Headers $Headers
    }
}
