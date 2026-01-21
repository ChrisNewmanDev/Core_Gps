# Me
Hello! If you’re enjoying the script and feel like supporting the work that went into it, consider buying me a coffee ☕
https://buymeacoffee.com/core_scripts

# core_gps

A FiveM GPS Marker script for QB-Core framework that allows players to mark, manage, and share locations with a radio-style interface.

## Features

- 📍 **Mark Current Location** - Save your current position with a custom label
- 🗺️ **Visual Map Markers** - See all your saved locations on the map (only visible to you when you have the item)
- 🔄 **Toggle Markers** - Show/hide all markers on the map with one click
- 🚩 **Set Waypoints** - Quickly set waypoints to your saved locations
- 🗑️ **Remove Markers** - Delete markers with confirmation dialog
- 📤 **Share Locations** - Share your saved locations with other players via ID
- 💾 **Database Storage** - Markers are permanently saved using oxmysql
- 🎒 **Item-Based Display** - Markers only appear on your map when you have the Core Gps item in your inventory
- 🎨 **Modern UI** - Clean and intuitive interface

## Installation

### Step 1: Database Setup

1. Import the SQL file to create the database table:
   - Run the `core_gps.sql` file in your database
   - Or manually execute:
   ```sql
   CREATE TABLE IF NOT EXISTS `core_gps` (
       `id` int(11) NOT NULL AUTO_INCREMENT,
       `citizenid` varchar(50) NOT NULL,
       `label` varchar(100) NOT NULL,
       `coords` longtext NOT NULL,
       `street` varchar(255) DEFAULT NULL,
       `timestamp` bigint(20) DEFAULT NULL,
       `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
       PRIMARY KEY (`id`),
       KEY `citizenid` (`citizenid`)
   ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
   ```

### Step 2: Add the Resource

1. Copy the `core_gps` folder to your server's `resources` directory
2. Ensure `oxmysql` is installed and running
3. Add the resource to your `server.cfg`:
   ```
   ensure oxmysql
   ensure core_gps
   ```

### Step 3: Add the Item

Add this item to your `qb-core/shared/items.lua`:

```lua
core_gps = {
    name = 'core_gps',
    label = 'GPS',
    weight = 200,
    type = 'item',
    image = 'core_gps.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A GPS device for marking and managing locations'
}
```

### Step 4: Add Item Image (Optional)

Add a `core_gps.png` image to your `qb-inventory/html/images/` folder (or wherever your inventory images are stored).

## Support

For issues or suggestions, please open an issue on the GitHub repository.

## License

This project is open source and available under the MIT License.

## Credits

- **Framework**: QB-Core
- **Developer**: ChrisNewmanDev

## Changelog

### Version 1.0.0 (Initial Release)
- 📍 Mark current location with custom labels
- 🗺️ Visual map markers (only visible when holding GPS item)
- 🔄 Toggle markers on/off
- 🚩 Set waypoints to saved locations
- 🗑️ Remove markers with confirmation
- 📤 Share locations with other players
- 💾 Database storage with oxmysql
- 🎨 Modern UI interface
