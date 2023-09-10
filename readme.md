# Workstation Preparation Script (workstationprep.ps1)

This PowerShell script, `workstationprep.ps1`, automates the process of preparing a Windows workstation for a new user. It performs various tasks to set up the workstation environment efficiently.

## How to Use

### Method 1: Run Directly from GitHub

If you're comfortable running the script directly from GitHub, you can use the following command to execute it:

```powershell
iwr -useb https://raw.githubusercontent.com/networkabilityllc/NewWindowsScripts/main/workstationprep.ps1 | iex
```

### Method 2: Clone and Run Manually

Alternatively, you can clone the repository and run the script manually. Here are the steps:

1. Clone the repository to your local machine. These scripts expect to be run from C:\Prep, so first create that folder, then change to it and run:

   ```bash
   git clone https://github.com/networkabilityllc/NewWindowsScripts.git
   ```

2. Navigate to the cloned repository directory.

   ```bash
   cd NewWindowsScripts
   ```

3. Run the script.

   ```powershell
   .\workstationprep.ps1
   ```

## Script Overview

The `workstationprep.ps1` script performs the following tasks:

1. Creates a directory on the new workstation at `C:\prep`.

2. Sets the execution policy to `Bypass` locally to ensure that built-in scripts run properly.

3. Prompts the installer if they want to Download SplashtopSOS to the `C:\Users\Default\Desktop` location, making it available on new user desktops.

4. Checks for and installs Chocolatey and Boxstarter if they are not already installed.

5. Checks for the existence of Python 3.10 and installs it if necessary.

6. Checks for the existence of Git and installs it if necessary. Removes Git context menu options.

7. Detects if the machine is a VMware virtual machine and installs the latest VMware Tools if applicable.

8. Clones the repository into `C:\prep`, creating a folder called `NewWindowsScripts`.

9. Opens a Boxstarter shell and temporarily disables UAC (User Account Control).

10. Disables Bing Search, GameBar Tips, and enables Show Hidden Files and Folders with Show File Extensions.

11. Turns off most Windows telemetry for the user.

12. Restores the classic right-click context menu.

13. Sets the mouse hover time for the taskbar to a very long time, effectively disabling hover text and thumbnails.

14. Creates a shortcut to `post-user-install.bat` as "C:\Users\Default\Desktop\Post User Install.lnk" for easy setup of new user actions.

15. Displays a summary of the performed actions, waits for user confirmation, and exits.

Feel free to customize and use this script according to your workstation preparation needs.

## License

This script is provided under the [MIT License](LICENSE). See the [LICENSE](LICENSE) file for details.

---

**Note:** This README serves as a brief overview of the script's functionality and usage. For more detailed information and explanations of individual tasks within the script, refer to the script comments and documentation.


You can replace `[License Name]` in the template with the specific license name or terms you want to apply to your script, and don't forget to include the actual license file (`LICENSE`) in your repository if applicable.