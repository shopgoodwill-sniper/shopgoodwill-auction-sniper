# ShopGoodwill Auction Sniper
## Windows PowerShell Install/Update Instructions
Copy and paste the following command into your Windows PowerShell app and then press enter to install/update:
```sh
Invoke-WebRequest -Uri "https://shopgoodwill-sniper.github.io/shopgoodwill-auction-sniper/Bid_Sniper_Windows_Installer.vbs" -OutFile "$env:TEMP\Bid_Sniper_Windows_Installer.vbs"; wscript "$env:TEMP\Bid_Sniper_Windows_Installer.vbs"
```
If you run into any errors during installation then run Powershell as Administrator by right-clicking on the Powershell app instead of left-clicking and then click on the "Run As Administrator" menu item from the context-menu!
### How to Install or Update ShopGoodwill Auction Sniper for Windows - Video Tutorial
[![How to install or update ShopGoodwill Auction Sniper on Windows video tutorial instructions](https://img.youtube.com/vi/MR4wrGBBgfM/maxresdefault.jpg)](https://www.youtube.com/watch?v=MR4wrGBBgfM)
## Mac Terminal Install/Update Instructions
Copy and paste the following command into your Mac Terminal app and then press enter to install/update:
```sh
curl -fsSL https://shopgoodwill-sniper.github.io/shopgoodwill-auction-sniper/Bid_Sniper_Mac_Installer.sh | bash || { (command -v brew >/dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)") && brew install curl && $(command -v /usr/local/opt/curl/bin/curl || command -v /opt/homebrew/opt/curl/bin/curl) -fsSL https://shopgoodwill-sniper.github.io/shopgoodwill-auction-sniper/Bid_Sniper_Mac_Installer.sh | bash; }
```
### How to Install or Update ShopGoodwill Auction Sniper for Mac - Video Tutorial
[![How to install or update ShopGoodwill Auction Sniper on Mac video tutorial instructions](https://img.youtube.com/vi/VK2tm3c7CrY/maxresdefault.jpg)](https://www.youtube.com/watch?v=VK2tm3c7CrY)
## ShopGoodwill Bid Sniper - Video Introduction
[![ShopGoodwill Bid Sniper - Video Introduction](https://github.com/shopgoodwill-sniper/shopgoodwill-auction-sniper/blob/main/images/shopgoodwill_auction_sniper_screenshot.jpeg?raw=true)](https://www.youtube.com/watch?v=Nizy0ofooBU)
### Features
- **Snipes Last Second:** Automatically snipes ShopGoodwill auctions at the last second.
- **Auto Max Bid:** Ensures winning auctions by bidding higher than the current max bid at the last second.
- **Multi-Auction Sniping:** Snipe multiple auctions simultaneously.
- **Password Security:** Self-hosted setup; never share your password with us.
- **Background Sniping:** Minimize to system tray for background sniping.
- **Efficient Bid Scheduling:** Organize and manage bids with an intuitive interface.
- **Real-Time Snipe Monitoring:** Track bids with built-in status indicators.
- **Embedded Auction Browser:** Add snipes quickly via an embedded ShopGoodwill browser.
- **Sound Effects:** Get themed audio cues for important sniping events.
- **Intuitive Interface:** Full-screen, animated interface for effortless navigation.
- **Cross-Platform Compatibility:** Compatible with both Windows and Mac.
#### Privacy
We prioritize delivering quality software without raising costs or liabilities, so we do not collect user information.