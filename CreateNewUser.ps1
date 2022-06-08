cls

#Author: Reggie Wilson
#Last Edited: 9/15/2021
#
#
import-Module ActiveDirectory

Add-Type -AssemblyName System.Web
#This script is intended to do the following:
    #Create a new user account from an existing user account
    #Create Surname, Givenname, username, and samaccountname, and userprincipalname for the new user account
    #create a password for the new user account
    #Enable user account
	#
	#This script must be run with the mchadmin credentials on MCHC-DC1
	
	


#Get user to mirror/copy
	$CopyFromUser = Read-Host -Prompt "Enter username of user to be mirrored/copied"
    Get-ADUser $CopyFromUser -Properties showInAddressBook,UserPrincipalName,DistinguishedName
	$User = Get-ADUser $CopyFromUser -Properties showInAddressBook,UserPrincipalName,DistinguishedName
    
#GetUPNSuffix
    $CopyFromUPN = Get-ADUser $CopyFromUser -Properties UserPrincipalName | select -expand UserPrincipalName
    $arr = $CopyFromUPN -split '@'
    $UPNSuffix = "@" + $arr[1]
    

#Create new user, Set username, Set Surname, Set GivenName, Set Password
	$Firstname = Read-Host -Prompt "Enter new user first name"
	$Lastname = Read-Host -Prompt "Enter new user last name"
    #$Username = Read-Host -Prompt "Enter new user's username"
    $CharArray = $Firstname.ToCharArray()
    $Username = $($CharArray[0] + $Lastname).ToLower()	
	$Fullname = $Firstname + " " + $Lastname
    $NewPassword = Read-Host -Prompt "Enter new password"
    #$securePassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force
    $UPN = $Username + $UPNSuffix
    $EmailAddress = $Username + "@mchalbia.com"
    $HomeDrive = "U"
    $HomeDirectory = "\\mchc-file\home$\" + $Username

    #Handles duplicate UPN/username error by appending a "1" to the username
	try {New-ADUser -Name $Fullname -DisplayName $Fullname -GivenName $Firstname -Surname $Lastname -SamAccountName $Username -EmailAddress $EmailAddress -UserPrincipalName $UPN   -Instance $User -AccountPassword (ConvertTo-SecureString $NewPassword -AsPlainText -Force) -ChangePasswordAtLogon $true -Enabled $True} 
    catch{ $Username = $($CharArray[0] + $Lastname).ToLower() + 1
           $UPN = $Username + $UPNSuffix
        New-ADUser -Name $Fullname -DisplayName $Fullname -GivenName $Firstname -Surname $Lastname -SamAccountName $Username -EmailAddress $EmailAddress -UserPrincipalName $UPN   -Instance $User -AccountPassword (ConvertTo-SecureString $NewPassword -AsPlainText -Force) -ChangePasswordAtLogon $true -Enabled $True}

   

    #Set user Home Directory and Home Drive to Create Home Folder
    set-aduser $Username -HomeDirectory $HomeDirectory  -HomeDrive $HomeDrive


    #Get new user distinguished name and assign it to a variable
    get-aduser $Username -Properties DistinguishedName | select -expand DistinguishedName
    $DistinguishedName = get-aduser $Username -Properties DistinguishedName | select -expand DistinguishedName

    #Get copy-from user DN and create target path with it
    get-aduser $CopyFromUser -Properties DistinguishedName | select -expand DistinguishedName
    $CopyFromUserDN = get-aduser $CopyFromUser -Properties DistinguishedName | select -expand DistinguishedName
    $CN,$OUPath = $CopyFromUserDN -split "," , 2
    

    Move-ADObject -Identity $DistinguishedName -TargetPath $OUPath

#Copy Group Membership  
#copy-paste process. Get-ADuser membership     | then selecting membership                       | and add it to the second user
get-ADuser -identity $CopyFromUser -properties memberof | select-object memberof -expandproperty memberof | Add-AdGroupMember -Members $Username


#Print New User Info
get-aduser $Username -Properties Name,SamAccountName,GivenName,Surname,DisplayName,UserPrincipalName,MemberOf, DistinguishedName
   
  
pause


	
	



 