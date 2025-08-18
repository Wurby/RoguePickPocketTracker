# RoguePickPocketTracker

**The ultimate pickpocketing companion for World of Warcraft Classic rogues!** Track your thievery with style, compete for achievements, and optimize your routes with detailed analytics.

## 🚀 Key Features at a Glance

- **💰 Automatic Money & Item Tracking** - Never lose track of your ill-gotten gains
- **🏆 Achievement System** - Funny milestone rewards from "Finger Exercises" to "Scrooge McDuck"
- **📍 Location Analytics** - Heat-map style zone and location-based statistics  
- **📊 Session Reports** - Detailed summaries after each stealth session
- **🎯 Success Rate Monitoring** - Track attempts vs. successes for optimization
- **💬 Group Sharing** - Broadcast your accomplishments to party/guild chat
- **⚙️ Rich Options Panel** - Customizable settings and detailed statistics view
- **🔧 Granular Reset Options** - Reset specific data types without losing everything

---

## 📋 Getting Started

### Installation
1. **Download** the latest release from GitHub
2. **Extract** to your `World of Warcraft\_classic_era_\Interface\AddOns\` directory
3. **Restart** WoW or type `/reload` in-game
4. **Start pickpocketing** - the addon begins tracking automatically!

### First Steps
- Type `/pp` to see your current statistics
- Visit `/pp options` to configure settings and view achievements
- Try `/pp zone` to see location-based analytics
- Use `/pp share` to show off your progress to friends

---

## 🏆 Achievement System

Earn bragging rights with our comprehensive achievement system featuring **funny names** and **difficulty scaling**:

### 🎯 Session Challenges
Master single-session pickpocketing sprees:
- **Finger Exercises** → **Shadow Lord** (1 to 25 mobs per session)
- **Shiny Trinket** → **Treasure Hunter** (1 to 5 items per session)

### 📈 Lifetime Milestones  
Build your criminal empire over time:
- **Getting Started** → **Legendary Thief** (10 to 10,000 total pickpockets)
- **Coin Collector** → **Scrooge McDuck** (1 silver to 1,000 gold earned)
- **First Find** → **Museum Curator** (1 to 1,000 total items)
- **Tourist** → **Globe Trotter** (pickpocket across 1 to 20+ zones)

*Access achievements via `/pp achievements` or the options panel!*

---

## 📍 Location Analytics

Optimize your pickpocketing routes with detailed zone and location tracking:

- **Zone Statistics** - See which areas are most profitable
- **Location Breakdown** - Sub-zone analysis for pinpoint accuracy
- **Success Rate Analysis** - Identify the best farming spots
- **Heat-Map Data** - Build comprehensive area-by-area strategies

### Zone Commands
- `/pp zone` - Current zone stats
- `/pp zone all` - All zones overview  
- `/pp zone Stormwind City` - Detailed zone breakdown
- `/pp zone location` - Specific location stats

---
## 💬 Slash Commands

**Main Commands:**
- `/pp` - Show current statistics and help
- `/pp options` - Open the comprehensive options panel
- `/pp achievements` - View your achievement progress

**Sharing & Social:**
- `/pp share` - Share totals and recent session summary
- `/pp share achievements` - Share achievement progress  
- `/pp share locations` - Share your top 3 pickpocket spots
- `/pp auto share` - Toggle automatic sharing to chat

**Data Management:**
- `/pp reset [type]` - Granular reset options:
  - `achievements` - Reset only achievements
  - `coins` - Reset only money and items  
  - `locations` - Reset only zone/location data
  - `all` - Reset everything (requires confirmation)

**Detailed Analytics:**
- `/pp items` - Show cumulative item breakdown
- `/pp zone` - Current zone statistics
- `/pp zone all` - All zones overview
- `/pp zone [name]` - Specific zone details
- `/pp zone [name] all` - Complete location breakdown

**Utilities:**
- `/pp togglemsg` - Toggle loot notification messages
- `/pp debug` - Toggle debug mode for troubleshooting

---

## 🎮 How It Works

The addon seamlessly integrates with your gameplay by monitoring:

- **🥷 Stealth Detection** - Automatically starts sessions when you enter stealth
- **✋ Spell Casting** - Detects Pick Pocket usage and attempts
- **💰 Money Changes** - Tracks increases to your character's money
- **📦 Loot Messages** - Parses chat for pickpocketed items
- **⚔️ Combat Log** - Records successes and failures for analytics

### Session Management
- **Session Start:** Entering stealth or casting Pick Pocket
- **Session End:** Stealth expires + 2-second grace period  
- **Session Reports:** Automatic summary if anything was gained

---

## ⚙️ Configuration

All settings auto-save and include:

| Setting | Description |
|---------|-------------|
| **Show Messages** | Toggle pickup notifications |
| **Auto Share** | Automatically share session summaries |
| **Debug Mode** | Enable detailed logging |
| **Alert Opacity** | Customize achievement notification transparency |

*Plus comprehensive tracking of coins, attempts, items, zones, locations, and achievement progress.*

---

## 🔧 System Requirements

- **Game Version:** World of Warcraft Classic Era (Interface 11507+)
- **Character Class:** Rogue (addon designed specifically for rogues)
- **Dependencies:** None - completely standalone

---

## ❓ Troubleshooting

**Addon not tracking?**
1. ✅ Verify you're playing a Rogue character
2. ✅ Enable debug mode with `/pp debug`
3. ✅ Check addon is loaded in your AddOns menu
4. ✅ Ensure you're pickpocketing (not just looting corpses)
5. ✅ Try `/reload` to refresh the UI

**Need help?** Check the [Issues](https://github.com/Wurby/RoguePickPocketTracker/issues) page or submit a bug report!

---

## 🚀 Future Features

Exciting features in development:
- 🔓 **Lockbox Tracking** - Monitor lockpicking statistics
- 🏆 **Lockbox Achievements** - New milestone categories  
- 💬 **Lockpicking Services** - Auto-advertise your skills
- 🖥️ **Permanent UI Elements** - Optional always-visible tracking
- 📱 **Session Toast Notifications** - Achievement-style alerts

---

## 🤝 Contributing

We welcome contributions from the community! Here's how to get involved:

### 🐛 Reporting Issues
- Use the [GitHub Issues](https://github.com/Wurby/RoguePickPocketTracker/issues) page
- Include your WoW version, addon version, and steps to reproduce
- Check existing issues before submitting duplicates

### 💻 Development Setup
1. **Fork** the repository on GitHub
2. **Clone** your fork locally
3. **Make changes** and test thoroughly in-game
4. **Submit a Pull Request** with a clear description

### 🏗️ Building Releases
```bash
./buildAndRelease.sh  # Automated packaging and GitHub release
```

The project uses GitHub Actions for automated releases when tags are pushed.

### 📝 Code Style
- Follow existing Lua conventions in the codebase
- Comment complex logic clearly
- Test changes with multiple scenarios before submitting

### 💡 Feature Requests
- Open an [Issue](https://github.com/Wurby/RoguePickPocketTracker/issues) with the "enhancement" label
- Describe the feature and its benefits clearly
- Consider contributing the implementation yourself!

---

## 📄 License

This project is **open source** and available under a permissive license. Feel free to:
- ✅ Use and modify for personal use
- ✅ Distribute and share with others  
- ✅ Fork and create derivative works
- ✅ Contribute improvements back to the community

---

**Happy Pickpocketing! 🥷💰**

*Created with ❤️ by [Wurby](https://github.com/Wurby) for the WoW Classic community*
