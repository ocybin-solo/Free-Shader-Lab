🌀 Kaleidoscope VFX Generator (Alpha)
A specialized tool for generating seamless, high-frequency animated patterns and symmetry art. Built with Godot 4, this application allows you to transform static images into hypnotic visual loops.

    [!CAUTION]
    ⚠️ PHOTOSENSITIVITY WARNING
    This application generates intense geometric patterns, high-contrast symmetry, and rapid color shifts. It may trigger photosensitive epilepsy or other neurological responses. Viewer discretion is advised.

🎨 Creative Controls
1. Symmetry Styles
You can layer multiple symmetry modes simultaneously for complex patterns:

    Classic Radial: Mirror segments around a central point (adjust Kaleido Sides).
    Geometric Folding: Repeatedly "folds" space for a fractal, diamond-like look.
    Hexagonal Tiling: Creates an infinite honeycomb grid across the entire screen.
    4-Way Mirror: Simple Cartesian symmetry (X and Y axis) for Rorschach-style patterns.

2. Distortion & Motion

    Master Swirl: Twists the entire composition into a vortex.
    Wave & Fisheye: Adds liquid-like ripples or lens distortion.
    Pixelate: Lowers the resolution for a retro, lo-fi aesthetic.
    Independent Speeds: Each major effect (Swirl, Fold, Hex) has its own rotation speed. Set these to whole numbers (1, 2, 3) to ensure a perfectly seamless animation loop.

3. Color & Effects

    Hue Shift: Cycles the entire image through the color spectrum.
    Radial Plasma: Generates synchronized expanding rings of color from the center.
    Rainbow Pulse: A pulsing color overlay that is mathematically locked to your animation loop.

💾 Exporting & Previews
Animated Strip Export

    Frame Count: Set how many total frames you want in your animation.
    Rows: Determine how many horizontal rows the final spritesheet will have.
    Speed Slider: For the export, this acts as the Loop Count. Setting it to 1.0 ensures the animation completes exactly one cycle.
    Save: Click export and choose your .png destination.

Live GIF Preview
Once an export is finished, the Preview Mode will automatically start:

    Playback Slider: Adjust the FPS (Frames Per Second) to see how the animation will feel as a final GIF.
    GIF Delay: The label displays the Delay Time (in 1/100s). Use this exact number when using external converters.
    Stop Preview: Click the button to return to the live editor and continue tweaking your design.

🛠️ How to make a GIF
This app exports Spritesheets (.png). To convert them to a GIF: 

    Upload your spritesheet to a tool like EzGif Sprite Cutter.
    Enter the Rows and Columns you used during the export.
    Set the Delay Time to the number shown on the GIF Delay label in the app's preview mode.
    Download your finished, perfectly looping GIF!
----------------------FOR LINUX INSTALL-------------
🐧 Linux Installation (Alpha Testers)
If you are running the Linux build, you may need to grant execution permissions:

    Right-click the .x86_64 file.
    Go to Properties > Permissions.
    Check "Allow executing file as program."
-----------------------MAC INSTALL----------------------
🍎 macOS Installation (Alpha Testers)
Because this is an Alpha build, macOS will likely block it. Follow these steps to bypass the security:

    Extract the Zip: Unzip the downloaded file to your Applications folder or Desktop.
    The Initial Block: Double-click the app. You will likely see a message saying: "App can’t be opened because it is from an unidentified developer." Click OK.
    The Manual Override:
        Open System Settings (or System Preferences).
        Go to Privacy & Security.
        Scroll down to the Security section.
        You will see a message about your app being blocked. Click "Open Anyway."
    Confirm: Enter your Mac password if prompted, then click Open.

🛠️ "App is Damaged" Fix (The Terminal Command)
If your Mac says the app is "damaged" (this is a common error for Godot exports), copy and paste this into your Terminal app:
xattr -cr /path/to/your_app_name.app
(Tip: You can type xattr -cr and then drag the app icon into the terminal window to get the path automatically!)
Why this happens:

    Gatekeeper: Apple requires developers to pay $99/year to "sign" their apps. Since this is a free Alpha, your Mac thinks it's a security risk.
    Quarantine: macOS "quarantines" downloaded apps. The xattr command simply tells the Mac, "I trust this file, let me run it."