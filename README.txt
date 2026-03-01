Overview

Vortex Lab is a high-performance 2D visual synthesizer built in Godot 4.6. It allows you to transform static images into evolving, non-Euclidean geometries using math-heavy shaders (Poincaré, Möbius, and Vortex Lattice).

**Key Features**

- **Dynamic Shader Scraper:** The app automatically generates UI controls for any `.gdshader` file. It reads `// DESC:` comments and uniform hints to create labeled sliders, toggles, and color pickers.
- **Non-Euclidean Space:** Warp your visuals with Poincaré Disk distortions and Hyperbolic Inversion logic.
- **Spritesheet Generator:** Toggle **"Save Spritesheet"** to render an animated strip. **Crucial:** Set the `Sync to Loop` slider to **1.0** to ensure the animation cycles perfectly.
- **Preset Engine:**
    - **Saving:** Capture the current state of all 50+ sliders into a named preset.
    - **Transitions:** Smoothly lerp between presets using the **Transition Duration** slider.
    - **Surprise Button:** Randomizes the target preset values and triggers a smooth transition for unexpected "happy accidents."
- **Clipboard Integration:** Click **"Copy Shader"** to copy the current processed GLSL code directly to your clipboard for use in other projects.




**How to Use**

1. **Import:** Click the folder icon to load any `.png` or `.jpg`.
2. **Manipulate:** Adjust the **Vortex**, **Poincaré**, and **Kaleidoscope** sliders.
3. **Animate:** Use the **Swirl Speed** or **Phase** controls to add motion.
4. **Export:** Save as a single image or an animated spritesheet strip.
5. Toggle Fullscreen : Spacebar - this will cause the image to cover the whole screen, hiding the controls
**Installation**

- **Windows:** Download the `.exe` and run. (Ensure the `shaders/` folder is in the same directory).
- **Linux:** Run the `.x86_64` executable. (Requires Vulkan/OpenGL support).
- **Mac:** Open the `.zip`, drag the App to Applications. _Note: You may need to "Allow Anyway" in Security settings._

 "Special thanks to the Google Gemini AI for helping me throughout the entire process of creating this app.  I would have been stuck in tutorial help without the assistance."

** If you'd like to support my work, I would love you for that ** 
You can directly send money to me through Venmo : @boxel is the handle, and my name is Jeffrey Box
Also, or instead, you can support me through GitHub.  I will setup GitHub Sponsors so that I am connected there, and you can use that system to buy me a cup of coffee.  Thank you very much!