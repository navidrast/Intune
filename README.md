# AutoPilot Info Collection Tools

Welcome! This guide will walk you through using our AutoPilot info collection tools. We have two methods: a GUI-based approach and a command-line approach that can be used during AutoPilot deployment.

## What's Included

1. **CollectAutoPilotInfo.ps1**: A PowerShell script that collects AutoPilot information from computers.
2. **RunAutoPilotCollection.cmd**: A command file to easily run the PowerShell script.

## Method 1: GUI-Based Approach

### Step 1: Prepare Your USB Drive

1. Insert a USB drive into your computer.
2. Copy both `CollectAutoPilotInfo.ps1` and `RunAutoPilotCollection.cmd` onto the drive.

### Step 2: Collect AutoPilot Info

1. Plug the USB drive into the target computer.
2. Double-click `RunAutoPilotCollection.cmd`.
3. When prompted, enter the letter of your USB drive (e.g., "E") and press Enter.
4. Wait for the script to complete its task.

### Step 3: Retrieve Results

After the script finishes, you'll find a new file on your USB drive named `AutoPilotHash_COMPUTERNAME.csv`.

## Method 2: Command Prompt Approach (During AutoPilot Deployment)

### Step 1: Access Command Prompt

1. During the AutoPilot deployment process, press Shift+F10 to open a command prompt.

### Step 2: Locate Your USB Drive

1. Insert your USB drive containing the scripts.
2. In the command prompt, type `wmic logicaldisk get deviceid, volumename` and press Enter.
3. Note the drive letter assigned to your USB drive.

### Step 3: Run the Script

1. Change to your USB drive by typing the drive letter followed by a colon. For example:
   ```
   E:
   ```
2. Run the command file by typing:
   ```
   RunAutoPilotCollection.cmd
   ```
3. When prompted, enter the USB drive letter and press Enter.
4. Wait for the script to complete its task.

### Step 4: Verify Results

Once the script finishes, check your USB drive for a file named `AutoPilotHash_COMPUTERNAME.csv`.

## What the Scripts Do

- **CollectAutoPilotInfo.ps1**: Gathers essential AutoPilot details like the device's serial number and hardware information.
- **RunAutoPilotCollection.cmd**: Simplifies running the PowerShell script, making it accessible for all skill levels.

## Helpful Tips

- Ensure you have administrator privileges on the target computer.
- For the GUI method, if you encounter issues, try right-clicking the .cmd file and select "Run as administrator".
- When using the command prompt method, if you can't run the .cmd file directly, you can execute the PowerShell script with this command:
  ```
  powershell -ExecutionPolicy Bypass -File CollectAutoPilotInfo.ps1 -OutputFile AutoPilotHash.csv
  ```
- Keep your USB drive secure, as it will contain important device information.

## Need Help?

If you run into any problems or have questions, please reach out to your IT support team. They're here to help!

Happy AutoPilot info collecting!
