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
- Export and install applications
- Migrate settings
- Dry-run option for testing
- Automated setup of the new Mac

## Prerequisites

- Both Macs should be on the same network
- SSH access enabled on the new Mac

## Preparing the New Mac

Before running the migration tool, you need to prepare the new Mac with these minimal steps:

1. Enable Remote Login (SSH):
   - Go to System Preferences > Sharing
   - Check the box next to "Remote Login"
   - Make note of the IP address shown (e.g., 192.168.68.106)

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
   ```
   git clone https://github.com/gullitmiranda/mac-migration-tool.git
   cd mac-migration-tool
   ```

That's it! You're ready to use the migration tool.

## Usage

Run the script with the following options:

```
./mac-migrate.sh [OPTIONS]

Options:
  -i, --ip IP_ADDRESS       IP address of the new MacBook
  -u, --username USERNAME   Username on both machines
  -s, --sync-home           Sync home folder
  -e, --export-apps         Export list of installed apps
  -a, --install-apps        Install apps on the new MacBook
  -m, --migrate-settings    Migrate settings
  -d, --dry-run             Perform a dry run without making changes
  -h, --help                Display this help message
```

Example:
```
./mac-migrate.sh -i 192.168.1.100 -u johndoe -s -e -a -m
```

This command will:
1. Set up Homebrew and mas on the new Mac
2. Sync the home folder
3. Export the list of installed apps from the old Mac
4. Install the exported apps on the new Mac
5. Migrate settings to the new Mac at 192.168.1.100 for the user 'johndoe'

## Caution

Always back up your data before performing a migration. This tool comes with no warranties, and you use it at your own risk.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
