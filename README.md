# RoguePickPocketTracker

A World of Warcraft Classic addon that tracks pickpocketing statistics and loot for rogues.

## Features

- Tracks total copper earned from pickpocketing
- Counts successful and failed pickpocket attempts
- Records items obtained through pickpocketing
- Provides detailed statistics and averages
- Options panel for configuration
- Slash commands for quick access
- Optionally shares total stats and your last session summary to your last chat channel, manually or automatically

## Slash Commands

- `/pp` - Show statistics and help
- `/pp options` - Open the options panel
- `/pp togglemsg` - Toggle loot messages
- `/pp share` - Share totals and the most recent session summary
- `/pp auto share` - Toggle automatic sharing
- `/pp reset` - Reset all statistics
- `/pp debug` - Toggle debug mode
- `/pp items` - Show cumulative item counts
- `/pp zone` - Show current zone statistics
- `/pp zone location` - Show current location statistics
- `/pp zone all` - Show statistics for all zones
- `/pp zone [zonename]` - Show detailed statistics for a specific zone
- `/pp zone [zonename] all` - Show all location statistics within a zone

## Installation

1. Download the latest release
2. Extract to your `World of Warcraft\_classic_era_\Interface\AddOns\` directory
3. Restart WoW or reload UI (`/reload`)

## Development Setup

### Automatic Releases

This addon uses GitHub Actions for automatic packaging and release:

#### GitHub Releases
- Triggered automatically when you push a git tag
- Creates a packaged zip file
- Uploads to GitHub releases

### Release Process

run ./buildAndRelease.sh

A World of Warcraft addon that tracks pickpocketing statistics for Rogue characters, including total money looted, success rates, and items obtained.

## Features

- **Money Tracking**: Automatically tracks gold, silver, and copper gained from pickpocketing
- **Success Rate Statistics**: Monitors total attempts, successful attempts, and failure rates
- **Item Tracking**: Records all items looted during pickpocketing sessions
- **Location-Based Analytics**: Tracks statistics by zone and specific locations
- **Heat-Map Data**: Accumulates per-area reports for targeted pickpocketing strategies
- **Session Reports**: Provides detailed reports after each stealth session
- **Persistent Data**: All statistics are saved between game sessions
- **Group Sharing**: Optionally broadcast your totals and last session summary to your last chat channel

## Installation

1. Download or clone this repository
2. Copy the `RoguePickPocketTracker` folder to your WoW `Interface/AddOns/` directory
3. Restart World of Warcraft or reload your UI (`/reload`)
4. The addon will automatically start tracking when you begin pickpocketing

## Usage

### Automatic Tracking

The addon automatically begins tracking when you:
- Enter stealth mode
- Cast Pick Pocket on a target
- Loot money or items from pickpocketing

### Slash Commands

Use `/pp` to access the following commands:

- `/pp` - Display current statistics and totals
- `/pp togglemsg` - Toggle pickup messages on/off
- `/pp share` - Share totals and the most recent session summary
- `/pp auto share` - Toggle automatic sharing
- `/pp reset` - Reset all statistics to zero
- `/pp debug` - Toggle debug mode for troubleshooting
- `/pp items` - Display all items collected from pickpocketing
- `/pp zone` - Display current zone statistics
- `/pp zone location` - Display current location statistics
- `/pp zone all` - Display statistics for all zones
- `/pp zone [zonename]` - Display detailed statistics for a specific zone including top locations
- `/pp zone [zonename] all` - Display all location statistics within a specified zone

### Statistics Displayed

- **Total Coinage**: Cumulative money earned from pickpocketing
- **Total Items**: Number of items looted
- **Attempts**: Total pickpocket attempts made
- **Successes**: Successful pickpocket attempts
- **Fails**: Failed pickpocket attempts
- **Average per Attempt**: Average money gained per attempt
- **Average per Success**: Average money gained per successful attempt

### Location-Based Analytics

The addon now tracks detailed statistics by zone and location:

- **Zone Statistics**: Aggregated data for each zone you've pickpocketed in
- **Location Statistics**: Fine-grained tracking including sub-zones and specific areas
- **Success Rates**: Per-location success rates to identify the best farming spots
- **Heat-Map Data**: Comprehensive area-by-area analysis for optimizing pickpocketing routes

#### Zone Commands

- `/pp zone` - Shows statistics for your current zone
- `/pp zone location` - Shows statistics for your current location (zone + sub-zone)
- `/pp zone all` - Lists all zones with their total earnings, attempts, success rates, and item counts
- `/pp zone Stormwind City` - Shows detailed stats for Stormwind City including top 5 locations
- `/pp zone Stormwind City all` - Shows complete location breakdown for all areas in Stormwind City

The Options panel also includes a "Zone Statistics" section showing the top 10 most profitable zones.

## How It Works

The addon monitors several game events:
- **Stealth Detection**: Tracks when you enter/exit stealth
- **Spell Casting**: Detects Pick Pocket spell usage
- **Money Changes**: Monitors your character's money for increases
- **Loot Messages**: Parses chat messages for pickpocketed items
- **Combat Log**: Tracks spell successes and failures

### Session Management

- A "session" begins when you enter stealth or cast Pick Pocket
- Sessions end when stealth expires plus a 2-second grace period
- At the end of each session, you'll see a summary report if anything was looted

## Configuration

The addon saves the following variables automatically:
- `PPT_ShowMsg` - Whether to show pickup messages
- `PPT_Debug` - Debug mode toggle
- `PPT_TotalCopper` - Total copper earned
- `PPT_TotalAttempts` - Total pickpocket attempts
- `PPT_SuccessfulAttempts` - Successful attempts
- `PPT_TotalItems` - Total items looted
- `PPT_ItemCounts` - Detailed item counts
- `PPT_ZoneStats` - Statistics by zone
- `PPT_LocationStats` - Statistics by specific location

## Requirements

 - World of Warcraft (tested with Interface version 110200)
- Rogue character class (addon is designed specifically for rogues)

## Troubleshooting

If the addon isn't tracking properly:
1. Make sure you're playing a Rogue character
2. Try `/pp debug` to enable debug messages
3. Check that the addon is properly loaded in your AddOns list
4. Verify you're actually pickpocketing (not just looting corpses)

## Contributing

Feel free to submit issues or pull requests if you encounter bugs or have suggestions for improvements.

## License

This project is open source. Feel free to modify and distribute as needed.
