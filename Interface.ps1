# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Entra Controller - Launcher V.0.1'
$form.Width = 400
$form.Height = 300
$form.StartPosition = 'CenterScreen'

# Create a label for instructions
$label = New-Object System.Windows.Forms.Label
$label.Text = 'Select an option to run the corresponding script:'
$label.Width = 350
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

# Button to Create Users
$btnCreateUsers = New-Object System.Windows.Forms.Button
$btnCreateUsers.Text = '1) Create Users'
$btnCreateUsers.Width = 150
$btnCreateUsers.Location = New-Object System.Drawing.Point(10, 60)
$btnCreateUsers.Add_Click({
    # Your code to create users
    Write-Host 'Creating users...'
    # Call your Create User function or script here
    # For example: Create-UsersFunction
})
$form.Controls.Add($btnCreateUsers)

# Button to Create Basic Group
$btnCreateGroup = New-Object System.Windows.Forms.Button
$btnCreateGroup.Text = '2) Create Basic Group'
$btnCreateGroup.Width = 150
$btnCreateGroup.Location = New-Object System.Drawing.Point(10, 100)
$btnCreateGroup.Add_Click({
    # Your code to create a basic group
    Write-Host 'Creating basic group...'
    # Call your Create Basic Group function or script here
    # For example: Create-GroupFunction
})
$form.Controls.Add($btnCreateGroup)

# Button to Create Dynamic Group and Add License
$btnCreateDynamicGroup = New-Object System.Windows.Forms.Button
$btnCreateDynamicGroup.Text = '3) Create Dynamic Group & Add License'
$btnCreateDynamicGroup.Width = 250
$btnCreateDynamicGroup.Location = New-Object System.Drawing.Point(10, 140)
$btnCreateDynamicGroup.Add_Click({
    # Your code to create dynamic group
    Write-Host 'Creating dynamic group...'
    # Call your Dynamic Group creation function or script here
    # For example: Create-DynamicGroupFunction
})
$form.Controls.Add($btnCreateDynamicGroup)

# Button to Create App Registration and Add Users
$btnCreateAppReg = New-Object System.Windows.Forms.Button
$btnCreateAppReg.Text = '4) Create App Registration & Add Users'
$btnCreateAppReg.Width = 250
$btnCreateAppReg.Location = New-Object System.Drawing.Point(10, 180)
$btnCreateAppReg.Add_Click({
    # Your code to create app registration and add users
    Write-Host 'Creating app registration and adding users...'
    # Call your App Registration function or script here
    # For example: Create-AppRegFunction
})
$form.Controls.Add($btnCreateAppReg)

# Show the form
$form.ShowDialog()



# New-Object System.Windows.Forms.Button | Get-Member | Where { $_ -like "*Text*"}
