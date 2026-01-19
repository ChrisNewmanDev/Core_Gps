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

### Step 5: Register Item Usage

The script automatically registers the item usage, but ensure your QB-Core is up to date.

## Usage

### For Players

1. **Open GPS Marker**
   - Use the GPS Marker item from your inventory

2. **Mark a Location**
   - Enter a name for the location
   - Click "Mark Current Location"
   - The location will be saved and appear on your map

3. **Manage Markers**
   - **Waypoint**: Set a GPS waypoint to the location
   - **Share**: Share the location with another player by entering their ID
   - **Remove**: Delete the marker (requires confirmation)

4. **Toggle Map Markers**
   - Use the toggle switch to show/hide all markers on the map

### For Admins

**Configuration** is available in `config.lua`:

```lua
Config.ItemName = 'core_gps'  -- Item name
Config.MaxMarkers = 50         -- Maximum markers per player

-- Customize marker appearance
Config.MarkerSettings = {
    type = 1,
    scale = vector3(1.0, 1.0, 1.0),
    color = {r = 255, g = 100, b = 100, a = 200}
}

-- Customize blip appearance
Config.BlipSettings = {
    sprite = 1,
    color = 1,
    scale = 0.8
}
```

## Database Integration

This script uses **oxmysql** for database operations. All markers are automatically saved to the `core_gps` table and persist across server restarts. Each marker is stored individually with:
- Unique ID
- Citizen ID (player identifier)
- Label (location name)
- Coordinates (JSON encoded)
- Street name
- Timestamp

## Configuration

**Configuration** is available in `config.lua`:

```lua
Config.ItemName = 'core_gps'  -- Item name
Config.MaxMarkers = 50         -- Maximum markers per player

-- Customize marker appearance
Config.MarkerSettings = {
    type = 1,
    scale = vector3(1.0, 1.0, 1.0),
    color = {r = 255, g = 100, b = 100, a = 200}
}

-- Customize blip appearance
Config.BlipSettings = {
    sprite = 1,
    color = 1,
    scale = 0.8
}
```

## Credits

- **Framework**: QB-Core
- **Developer**: Chris Newman / Core
- **Version**: 1.0.0

## Support

For issues or suggestions, please open an issue on the GitHub repository.

## License

This project is open source and available under the MIT License.
