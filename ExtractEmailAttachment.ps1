# link to the folder 
$olDefaultFolderInbox = "\\apps.integrations@activ.asn.au\Inbox"
# set the desired file name
$$ = 'staffTrainingLMS.csv'
# set the location to temporary file
#$filePath = "$ENV:Temp"
$filePath = "C:\Temp"
# use MAPI name space
$outlook = new-object -com outlook.application; 
$mapi = $outlook.GetNameSpace("MAPI");
# set the Inbox folder id
$olDefaultFolderInbox = 6
$olTargetFolder = $mapi.GetDefaultFolder($olDefaultFolderInbox) 


# access the target subfolder
#$olTargetFolder = $inbox.Folders | Where-Object { $_.FolderPath -eq $olFolderPath }


# load emails
$emails = $olTargetFolder.Items
# process the emails
foreach ($email in $emails) {
    
    # format the timestamp
    $timestamp = $email.ReceivedTime.ToString("yyyyMMddhhmmss")
    # filter out the attachments
    $email.Attachments | Where-Object {$_.FileName -eq $attachmentFileName} | foreach {
        
        # insert the timestamp into the file name
        #$fileName = $_.FileName
        #$fileName = $fileName.Insert($fileName.IndexOf('.'),$timestamp)
        # save the attachment
        $_.saveasfile((Join-Path $filePath $fileName)) 
    } 
} 