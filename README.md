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
- **🎉 Toast Notifications** - Beautiful achievement and session completion alerts
- **📈 Persistent Coin Tracker** - Real-time coinage display that follows you around

---

## 📋 Getting Started

### Installation
1. **Download** the latest release from GitHub or curseforge.
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

**Session & Notifications:**
- `/pp session [toast/print]` - Show last session summary as toast or text
- `/pp toggletoasts` - Toggle session completion toast notifications

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
- `/pp tracker` - Toggle persistent coin tracker display
- `/pp togglemsg` - Toggle loot notification messages
- `/pp toggletoasts` - Toggle session completion toast notifications
- `/pp debug` - Toggle debug mode for troubleshooting
- `/pp ui` - Open standalone options window
- `/pp version` - Show addon version information

---

## 🎉 Toast Notification System

Experience your achievements with beautiful, non-intrusive notifications:

### Achievement Toasts
- **Milestone Celebrations** - Elegant popups when you unlock new achievements
- **Progress Tracking** - Visual feedback for your pickpocketing accomplishments
- **Customizable Opacity** - Adjust transparency to match your UI preferences

### Session Completion Toasts
- **Stealth Session Summary** - Automatic notification when stealth sessions end
- **Loot Summary** - Shows money gained and items obtained at a glance
- **Smart Timing** - Appears after combat ends to avoid UI clutter during fights
- **Manual Control** - Use `/pp session toast` to replay your last session summary

### Toast Features
- **Queue System** - Multiple toasts display in sequence without overlap
- **Achievement-Style Design** - Familiar look and feel like Blizzard's achievement system
- **Fade Animations** - Smooth fade-in, hold, and fade-out transitions
- **Combat-Safe** - Won't interrupt gameplay during critical moments

*Toggle toast notifications with `/pp toggletoasts` or in the options panel.*

---

## 💰 Persistent Coin Tracker

Keep track of your earnings with a sleek, always-visible display:

### Real-Time Display
- **Live Updates** - Shows your current pickpocketing session earnings in real-time
- **Session Coinage** - Displays money gained during your current stealth session
- **Elegant Design** - Minimalist gold-themed UI that matches WoW's aesthetic
- **Moveable Window** - Drag to position anywhere on your screen

### Smart Behavior
- **Auto-Hide** - Disappears when not in a pickpocketing session
- **Combat Safe** - Stays out of the way during important gameplay moments
- **Persistent Position** - Remembers where you placed it between sessions
- **Achievement Integration** - Connects with the toast notification system

### Controls
- **Toggle Display** - Use `/pp tracker` to show/hide the tracker
- **Reset Position** - Use the options panel to reset to default position
- **Manual Control** - Works independently of other addon features

*Access tracker settings in the options panel under "Display Options".*

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
- **Toast Notifications:** Achievement-style popups for session completion and milestones
- **Combat Awareness:** Smart session handling during and after combat encounters

---

## ⚙️ Configuration

All settings auto-save and include:

| Setting | Description |
|---------|-------------|
| **Show Messages** | Toggle pickup notifications |
| **Show Session Toasts** | Toggle achievement-style session completion notifications |
| **Show Coin Tracker** | Toggle persistent real-time coinage display |
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
- 🔓 **Lockbox Tracking** - Monitor lockpicking statistics and success rates
- 🏆 **Lockbox Achievements** - New milestone categories for lockpicking mastery  
- 💬 **Lockpicking Services** - Auto-advertise your skills in trade chat
- � **Mobile-Style Notifications** - Additional notification styles and animations
- 🎯 **Target Highlighting** - Visual indicators for pickpocketable targets
- � **Advanced Analytics** - Heat maps and time-based statistics
- 🔄 **Data Export/Import** - Share statistics between characters

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

**Safety Features:**
- Only allows releases from the `main` branch for consistency
- Automated data version bumping for breaking changes
- Interactive version selection (patch/minor/major/custom)
- GitHub Actions integration for automated distribution

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
