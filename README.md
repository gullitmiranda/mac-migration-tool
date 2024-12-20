# Mac Migration Tool

This tool helps you migrate data and settings from one MacBook to another without using Apple's Migration Assistant or Time Machine.

## Why use this tool?

While Apple provides Migration Assistant and Time Machine for transferring data between Macs, this tool offers several advantages:

1. **Flexibility**: Choose exactly what you want to migrate, from specific folders to individual settings.
2. **Transparency**: See exactly what's being transferred with detailed logs and a dry-run option.
3. **Customization**: Easily modify the migration scripts to suit your specific needs.
4. **No full system backup required**: Unlike Time Machine, you don't need a full system backup to perform the migration.
5. **Incremental updates**: Easily run the tool multiple times to sync changes, making it perfect for gradual transitions.
6. **Cross-version compatibility**: Works across different macOS versions more reliably than Apple's solutions.

This tool is ideal for power users, developers, and anyone who wants more control over their Mac migration process.

## Features

- Sync home folder
- Analyze and filter sync logs
- Export and install applications using Homebrew
- Migrate settings
- Dry-run option for testing

## Prerequisites

Before running the migration script, ensure that:

- Both Macs should be on the same network
- SSH access is enabled on the new Mac
- The terminal (e.g., Terminal, iTerm2, Warp, etc.) that you'll be using has Full Disk Access:

  1. Open System Preferences > Security & Privacy > Privacy.
  2. Select "Full Disk Access" from the left sidebar.
  3. Click the lock icon to make changes (you may need to enter your password).
  4. Click the "+" button and add the terminal you'll be using to the list.
  5. Restart the terminal for the changes to take effect.

> These steps are necessary to allow the script to have the necessary permissions to connect to the new Mac and access all required files and folders during the migration process.

## Preparing the New Mac

Before running the migration tool, you need to prepare the new Mac with these minimal steps:

1. Enable Remote Login (SSH):

   - Go to System Preferences > Sharing
   - Check the box next to "Remote Login"
   - Make note of the IP address shown (e.g., 192.168.68.106)
   - Disable the firewall on both machines
   - Test the connection:
     ```bash
     ssh username@192.168.68.106
     ```

2. Set up 1Password (recommended):

   - Download and install 1Password from the official website or the App Store
   - Sign in to your 1Password account
   - This will help you easily access your passwords and other sensitive information during the migration process

3. Sign in to iCloud:

   - Go to System Preferences > Apple ID
   - Sign in with your Apple ID (you can now easily retrieve it from 1Password if needed)
   - Enable the services you want to sync (e.g., iCloud Drive, Photos, Contacts, etc.)

4. Ensure you know the username and password for the new Mac

That's it! The migration tool will handle the rest of the setup automatically.

## Installation

1. Clone this repository on the old Mac:

   ```bash
   git clone https://github.com/gullitmiranda/mac-migration-tool.git
   cd mac-migration-tool
   ```

That's it! You're ready to use the migration tool.

## Usage

The main script `mac-migrate.sh` provides several subcommands for different migration tasks:

```bash
./mac-migrate.sh [OPTIONS] <command>

Commands:
  sync-home           Sync home folder
  sync-analyze-log    Analyze sync log
  sync-filter-log     Filter sync log
  apps-brew-export    Export list of installed apps
  apps-brew-install   Install apps on the new MacBook

Global options:
  -o, --output-dir    Specify output directory (default: "~/mac-migrate")
  -v, --verbose       Enable verbose output
  -h, --help         Display this help message

Global environment variables:
  MM_OUTPUT_DIR      Directory for output files (default: "~/mac-migrate")
  MM_VERBOSE         Set to "true" to enable verbose output
```

### Examples

1. Sync home folder:

   ```bash
   ./mac-migrate.sh sync-home [OPTIONS] [USER@]HOST:[DEST]
   ```

   Options:

   - `-x, --exclude-file FILE`: Specify exclude file for rsync
   - `-p, --partial VALUE`: Enable/disable partial file transfer support (true/false)
   - `-d, --dry-run`: Perform a dry run without making changes

   Environment variables:

   - `MM_SYNC_HOME_EXCLUDE_FILE`: Path to exclude file
   - `MM_SYNC_PARTIAL`: Enable/disable partial transfer support
   - `MM_SYNC_HOME_DRY_RUN`: Set to "true" for dry run mode

   Example:

   ```bash
   ./mac-migrate.sh -v sync-home johndoe@NewMac.local --dry-run
   ```

2. Analyze sync log:

   ```bash
   ./mac-migrate.sh sync-analyze-log [OPTIONS]
   ```

   Options:

   - `-i, --input FILE`: Specify input sync log file
   - `-o, --output FILE`: Specify analysis output file
   - `-d, --max-depth NUM`: Maximum directory depth to display
   - `-a, --all`: Show all changes, including synced files

3. Filter sync log:

   ```bash
   ./mac-migrate.sh sync-filter-log [OPTIONS]
   ```

   Options:

   - `-i, --input FILE`: Specify input sync log file
   - `-o, --output FILE`: Specify output file for cleaned log
   - `-e, --exclude FILE`: Specify exclude file for filtering

4. Export installed apps:

   ```bash
   ./mac-migrate.sh apps-brew-export [OPTIONS]
   ```

   Options:

   - `-f, --file FILE`: Specify output file for Brewfile

5. Install apps on the new Mac:

   ```bash
   ./mac-migrate.sh apps-brew-install [OPTIONS]
   ```

   Options:

   - `-f, --file FILE`: Specify input file for Brewfile

## Recommended Migration Steps

1. Perform the home folder sync:

   ```bash
   ./mac-migrate.sh -v sync-home gullitmiranda@GullitMirandas-MacBook-Pro.local
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
