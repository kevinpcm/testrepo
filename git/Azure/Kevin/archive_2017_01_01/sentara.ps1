#################################################################################
# Please run Exchange Best Practice Analyzer/Exchange Health Check/provide report
#################################################################################
# Please run 2 Exchange Remote Connectivity Analyzer Test 
# (https://testconnectivity.microsoft.com/)
# Please provide the HTML Reports linked in top right-hand corner
#    1. Exchange Server Tab: Outlook Connnectivity
#    2. Exchange Server Tab: Outlook Autodiscover
#################################################################################
#
# Script 1 
.\Accepted_Domains.ps1
# Script 2 (dot sourced)
. .\get-virdirinfo.ps1
get-virdirinfo -filepath "."
# Script 3
.\Get-DAGHealth.ps1 -Detailed -HTMLFile
# Script 4
.\Get-ExchangeEnvironmentReport.ps1 -HTMLReport .\ExEnvironment.html
# Script 5
.\OutlookVersion.ps1
# Script 6
.\Get-MailboxReport.ps1 -all
# Script 7
.\Get-NonMatchingUPNtoSMTP.ps1
# Script 8
.\RoomMBXdontProcessExternalMessages.ps1
# Script 9
.\EquipmentMBXdontProcessExternalMessages.ps1
# Script 10
.\EmailPolicyNotEnabled.ps1
# Script 11
.\Get-PublicFolderReplicationReport.ps1 -Filename PFreport.html