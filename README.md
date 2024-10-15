# AutoPilot Info Collection Tools

Hello there! This README will guide you through using our handy AutoPilot info collection tools. We've got two scripts that work together to make your life easier when gathering device information for Windows AutoPilot.

## What's in the Box?

1. **CollectAutoPilotInfo.ps1**: A PowerShell script that does the heavy lifting of collecting AutoPilot information from computers.
2. **RunAutoPilotCollection.bat**: A simple batch file that helps you run the PowerShell script from a USB drive.

## How to Use These Scripts

### Step 1: Set Up Your USB Drive

1. Grab a USB drive.
2. Copy both `CollectAutoPilotInfo.ps1` and `RunAutoPilotCollection.bat` onto the drive.

### Step 2: Collect AutoPilot Info

1. Plug your USB drive into the computer you want to collect info from.
2. Double-click on `RunAutoPilotCollection.bat`.
3. When asked, type in the letter of your USB drive (e.g., "E") and press Enter.
4. Sit back and relax while the script does its job!

### Step 3: Find Your Results

Once the script finishes, you'll find a new file on your USB drive named something like `AutoPilotHash_COMPUTERNAME.csv`. This file contains all the juicy AutoPilot details for the computer.

## What These Scripts Do

- **CollectAutoPilotInfo.ps1**: This clever script gathers all the necessary bits and bobs that AutoPilot needs, like the device's serial number and hardware details.
- **RunAutoPilotCollection.bat**: This friendly batch file makes running the PowerShell script a breeze, even for those who aren't tech wizards.

## A Few Helpful Tips

- Make sure you're logged in as an administrator on the computer you're collecting info from.
- If you run into any hiccups, try running the batch file as an administrator by right-clicking and selecting "Run as administrator".
- Keep your USB drive safe and sound – it'll have important device information on it!

## Need a Hand?

If you get stuck or have any questions, don't hesitate to reach out to your IT support team. They'll be more than happy to help you out!

Happy AutoPilot info collecting!
