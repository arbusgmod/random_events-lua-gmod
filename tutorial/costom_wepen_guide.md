# Configuration & Customization Guide

This guide explains how to add custom weapons to the **random_events** addon.

---

## 🔫 How to Add Custom Weapons

Follow these step-by-step instructions to configure custom weapons for events (e.g., Zombie Mode).

### Step 1: Copy the Weapon Class Name
1. Download any custom weapon addon from the Steam Workshop.
2. Launch **Garry's Mod** and load into any map.
3. Hold <kbd>Q</kbd> to open the Spawn Menu.
4. Go to the **Weapons** tab.
5. Find the custom weapon you want to use.
   > ⚠️ **Note:** Default Half-Life 2 weapons do not count as custom weapons.
6. Right-click on the desired weapon icon and select **"Copy to Clipboard"**.

---

### Step 2: Edit the Script
1. Close Garry's Mod.
2. Open Steam, right-click on **Garry's Mod** $\rightarrow$ **Manage** $\rightarrow$ **Browse local files**.
3. Navigate to the following path:  
   `garrysmod/garrysmod/addons/random_events/lua/autorun/random_events.lua`
4. Open `random_events.lua` in a text editor (e.g., VS Code or Notepad++).
5. Search for the `custom_weapons` line.
6. You will see a commented-out line starting with two dashes (`--`).
7. **Uncomment the line:** Remove the two dashes (`--`) at the beginning of that line. *(The text inside should change color/highlight).*
8. Replace the default placeholder weapon class name with your copied weapon class name by selecting it and pressing <kbd>Ctrl</kbd> + <kbd>V</kbd>.
9. Save the file using <kbd>Ctrl</kbd> + <kbd>S</kbd> and close it.

---

### Step 3: Verify in Game
1. Launch **Garry's Mod**.
2. Start a game (if you are the server host, press <kbd>Esc</kbd> $\rightarrow$ **Admin Menu**).
3. Select an event (for example, **Zombie Mode**).
4. After the cutscene/intro, check the weapon selection under the **Custom** tab.
5. If your new weapon appears there, congratulations! You have set it up correctly.