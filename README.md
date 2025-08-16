# RoguePickPocketTracker

A World of Warcraft addon that tracks pickpocketing statistics for Rogue characters, including total money looted, success rates, and items obtained.

## Features

- **Money Tracking**: Automatically tracks gold, silver, and copper gained from pickpocketing
- **Success Rate Statistics**: Monitors total attempts, successful attempts, and failure rates
- **Item Tracking**: Records all items looted during pickpocketing sessions
- **Session Reports**: Provides detailed reports after each stealth session
- **Persistent Data**: All statistics are saved between game sessions

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
- `/pp reset` - Reset all statistics to zero
- `/pp debug` - Toggle debug mode for troubleshooting
- `/pp items` - Display all items collected from pickpocketing

### Statistics Displayed

- **Total Coinage**: Cumulative money earned from pickpocketing
- **Total Items**: Number of items looted
- **Attempts**: Total pickpocket attempts made
- **Successes**: Successful pickpocket attempts
- **Fails**: Failed pickpocket attempts
- **Average per Attempt**: Average money gained per attempt
- **Average per Success**: Average money gained per successful attempt

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
